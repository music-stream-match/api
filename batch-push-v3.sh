#!/usr/bin/env bash
#
# batch-push-v3.sh — Zoptymalizowany batch push dla setek tysięcy plików
#
set -euo pipefail

# ------------------------- Konfiguracja (env / flagi) -------------------------
BRANCH="${BRANCH:-main}"
REMOTE="${REMOTE:-github}"
BATCH_SIZE="${BATCH_SIZE:-25000}"       # 25k plików = ok. 3-3.5 MB na push
PUSH_RETRIES="${PUSH_RETRIES:-5}"
PUSH_RETRY_DELAY="${PUSH_RETRY_DELAY:-10}"
COMMIT_MSG="${COMMIT_MSG:-Updated API data}"
TARGET_DIR="/mnt/radiomore/raiomore/compose_projects/music-stream-match-api"
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --batch-size) BATCH_SIZE="$2"; shift ;;
    --branch) BRANCH="$2"; shift ;;
    --remote) REMOTE="$2"; shift ;;
    -h|--help)
      echo "Użycie: $0 [--batch-size N] [--branch <branch>] [--remote <remote>] [--dry-run]"
      exit 0
      ;;
    *) echo "Nieznany parametr: $1" >&2; exit 2 ;;
  esac
  shift
done

log() { printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
die() { log "BŁĄD: $*"; exit 1; }

# ----------------- Wymuszenie bezpośredniej ścieżki NVMe XFS -----------------
# Omijamy /mnt/user (FUSE shfs), który drastycznie spowalniał operacje I/O.
if [ -d "$TARGET_DIR" ]; then
  cd "$TARGET_DIR"
else
  cd "$(git rev-parse --show-toplevel)" || die "Nie mogę wejść do katalogu repozytorium."
fi

CURRENT_DIR="$(pwd -P)"
log "Katalog roboczy: $CURRENT_DIR"
if [[ "$CURRENT_DIR" =~ ^/mnt/user/ ]]; then
  log "UWAGA: Wykryto ścieżkę FUSE /mnt/user. Zalecane uruchomienie z /mnt/radiomore."
fi

# --------------------------------- Blokada ------------------------------------
LOCK_FILE="$(git rev-parse --git-dir)/batch-push-v3.lock"
exec 9>"$LOCK_FILE" || die "Nie mogę utworzyć pliku blokady."
if command -v flock >/dev/null 2>&1; then
  flock -n 9 || die "Inna instancja batch-push już działa ($LOCK_FILE)."
fi

# SSH optymalizacja - unikanie problemu FAT32 /root/.ssh na Unraidzie
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/run/known_hosts -o StrictHostKeyChecking=accept-new"

# Sprawdzenie gałęzi
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[ "$CURRENT_BRANCH" = "$BRANCH" ] || die "Jesteś na '$CURRENT_BRANCH', a skrypt ma pushować '$BRANCH'."

# ---------------------------- Przygotowanie listy -----------------------------
TMP_DIR="$(mktemp -d /tmp/git-batch-push.XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "$LOCK_FILE"
}
trap cleanup EXIT INT TERM

log "Skanowanie zmian w katalogu api/ (jeden szybki przebieg)..."
PENDING_FILE="$TMP_DIR/all_pending.txt"
git ls-files --modified --deleted --others --exclude-standard api/ > "$PENDING_FILE"

TOTAL_PENDING="$(wc -l < "$PENDING_FILE")"
log "Łącznie oczekujących plików: $TOTAL_PENDING"

if [ "$TOTAL_PENDING" -eq 0 ]; then
  log "Brak oczekujących zmian w api/. Wszystko aktualne."
  exit 0
fi

CHUNKS_DIR="$TMP_DIR/chunks"
mkdir -p "$CHUNKS_DIR"
split -l "$BATCH_SIZE" -d -a 4 "$PENDING_FILE" "$CHUNKS_DIR/chunk_"

CHUNKS=( "$CHUNKS_DIR"/chunk_* )
TOTAL_CHUNKS="${#CHUNKS[@]}"
log "Podzielono na $TOTAL_CHUNKS batchy po max $BATCH_SIZE plików."

if [ "$DRY_RUN" -eq 1 ]; then
  log "[DRY RUN] Utworzonoby $TOTAL_CHUNKS commitów i pushy. Zakończono."
  exit 0
fi

# ------------------------------- Push logic ----------------------------------
do_push() {
  local attempt=1 delay="$PUSH_RETRY_DELAY"
  while [ "$attempt" -le "$PUSH_RETRIES" ]; do
    log "Push na $REMOTE $BRANCH (próba $attempt/$PUSH_RETRIES)..."
    if git push "$REMOTE" "$BRANCH"; then
      return 0
    fi
    log "Push nieudany, próba rebase i ponowienie za ${delay}s..."
    git pull --rebase "$REMOTE" "$BRANCH" || git rebase --abort 2>/dev/null || true
    sleep "$delay"
    delay=$(( delay * 2 ))
    attempt=$(( attempt + 1 ))
  done
  return 1
}

# ------------------------------ Główna pętla ---------------------------------
START_ALL=$(date +%s)
PROCESSED=0
idx=0

for chunk in "${CHUNKS[@]}"; do
  idx=$(( idx + 1 ))
  chunk_files="$(wc -l < "$chunk")"
  PROCESSED=$(( PROCESSED + chunk_files ))
  PCT=$(( PROCESSED * 100 / TOTAL_PENDING ))
  
  START_CHUNK=$(date +%s)
  log "=== Batch [$idx/$TOTAL_CHUNKS] | $chunk_files plików | Postęp: $PROCESSED/$TOTAL_PENDING ($PCT%) ==="

  # Dodanie plików z przygotowanej listy
  git add -A --pathspec-from-file="$chunk"

  if git diff --cached --quiet; then
    log "Brak różnic w indeksie dla batcha $idx, pomijam commit."
    continue
  fi

  git commit -q -m "${COMMIT_MSG} (batch $idx/$TOTAL_CHUNKS, $chunk_files files)" || die "Błąd git commit."

  do_push || die "Push nie powiódł się po $PUSH_RETRIES próbach dla batcha $idx."
  
  END_CHUNK=$(date +%s)
  CHUNK_DURATION=$(( END_CHUNK - START_CHUNK ))
  log "Batch [$idx/$TOTAL_CHUNKS] wysłany w ${CHUNK_DURATION}s."
done

END_ALL=$(date +%s)
TOTAL_DURATION=$(( (END_ALL - START_ALL) / 60 ))
log "============================================================"
log "ZAKOŃCZONO POMYŚLNIE w ${TOTAL_DURATION} minut!"
log "Wysłano $PROCESSED plików w $TOTAL_CHUNKS batchach."
log "============================================================"
