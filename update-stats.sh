#!/usr/bin/env bash
#
# update-stats.sh — Zlicza utwory w api/providers/*/tracks i aktualizuje README.md, index.md oraz api/status.json
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$SCRIPT_DIR"

DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      echo "Użycie: $0 [--dry-run]"
      echo "  Zlicza pliki w api/providers/*/tracks i aktualizuje tabele oraz badge w README.md, index.md oraz api/status.json."
      exit 0
      ;;
    *) echo "Nieznany parametr: $1" >&2; exit 2 ;;
  esac
  shift
done

PROVIDERS_DIR="$SCRIPT_DIR/api/providers"
if [ ! -d "$PROVIDERS_DIR" ]; then
  echo "BŁĄD: Nie znaleziono katalogu $PROVIDERS_DIR" >&2
  exit 1
fi

echo "Zliczanie plików w folderach tracks..."

count_provider() {
  local provider="$1"
  local dir="$PROVIDERS_DIR/$provider/tracks"
  if [ -d "$dir" ]; then
    find "$dir" -type f -name '*.json' | wc -l
  else
    echo 0
  fi
}

APPLE_COUNT=$(count_provider "apple")
DEEZER_COUNT=$(count_provider "deezer")
TIDAL_COUNT=$(count_provider "tidal")
SPOTIFY_COUNT=$(count_provider "spotify")

TOTAL_COUNT=$(( APPLE_COUNT + DEEZER_COUNT + TIDAL_COUNT + SPOTIFY_COUNT ))

# Formatowanie liczb z przecinkami (np. 1,571,169)
format_number() {
  echo "$1" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
}

APPLE_FMT=$(format_number "$APPLE_COUNT")
DEEZER_FMT=$(format_number "$DEEZER_COUNT")
TIDAL_FMT=$(format_number "$TIDAL_COUNT")
SPOTIFY_FMT=$(format_number "$SPOTIFY_COUNT")
TOTAL_FMT=$(format_number "$TOTAL_COUNT")

# Badge format (np. 1.57M+)
BADGE_VAL=$(awk -v t="$TOTAL_COUNT" 'BEGIN { printf "%.2fM+\n", t/1000000 }')
BADGE_PARAM="Tracks-${BADGE_VAL}%2B-blue"

echo "-----------------------------------------"
printf "%-15s: %s\n" "Apple Music" "$APPLE_FMT"
printf "%-15s: %s\n" "Deezer" "$DEEZER_FMT"
printf "%-15s: %s\n" "Tidal" "$TIDAL_FMT"
printf "%-15s: %s\n" "Spotify" "$SPOTIFY_FMT"
echo "-----------------------------------------"
printf "%-15s: %s\n" "Łącznie" "$TOTAL_FMT"
printf "%-15s: %s\n" "Badge" "$BADGE_VAL"
echo "-----------------------------------------"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[DRY RUN] Pominięto zapisywanie plików."
  exit 0
fi

# Aktualizacja plików README.md, index.md oraz api/status.json za pomocą Node.js
node -e '
const fs = require("fs");
const path = require("path");

const [
  appleFmt, deezerFmt, tidalFmt, spotifyFmt, totalFmt, badgeParam,
  appleRaw, deezerRaw, tidalRaw, spotifyRaw, totalRaw, badgeVal
] = process.argv.slice(1);

const table = [
  "| Provider | Track Mappings |",
  "| :--- | :--- |",
  `| **Apple Music** | ${appleFmt} |`,
  `| **Deezer** | ${deezerFmt} |`,
  `| **Tidal** | ${tidalFmt} |`,
  `| **Spotify** | ${spotifyFmt} |`,
  `| **Total Track Mappings** | **${totalFmt}** |`
].join("\n");

const tableRegex = /\| Provider \| Track Mappings \|[\s\S]*?\|\s*\*\*Total Track Mappings\*\*\s*\|\s*\*\*[^|*]+\*\*\s*\|/;
const badgeRegex = /\[!\[Track Mappings\]\(https:\/\/img\.shields\.io\/badge\/Tracks-[^)]+-blue\)\]/;

if (fs.existsSync("README.md")) {
  let content = fs.readFileSync("README.md", "utf8");
  content = content.replace(badgeRegex, `[![Track Mappings](https://img.shields.io/badge/${badgeParam})]`);
  content = content.replace(tableRegex, table);
  fs.writeFileSync("README.md", content, "utf8");
  console.log("Zaktualizowano README.md");
}

if (fs.existsSync("index.md")) {
  let content = fs.readFileSync("index.md", "utf8");
  content = content.replace(tableRegex, table);
  fs.writeFileSync("index.md", content, "utf8");
  console.log("Zaktualizowano index.md");
}

const statusData = {
  status: "ok",
  updatedAt: new Date().toISOString(),
  total: Number(totalRaw),
  totalFormatted: totalFmt,
  badge: badgeVal,
  providers: {
    apple: {
      count: Number(appleRaw),
      formatted: appleFmt
    },
    deezer: {
      count: Number(deezerRaw),
      formatted: deezerFmt
    },
    tidal: {
      count: Number(tidalRaw),
      formatted: tidalFmt
    },
    spotify: {
      count: Number(spotifyRaw),
      formatted: spotifyFmt
    }
  }
};

const apiDir = path.resolve("api");
if (!fs.existsSync(apiDir)) {
  fs.mkdirSync(apiDir, { recursive: true });
}

fs.writeFileSync(path.join(apiDir, "status.json"), JSON.stringify(statusData, null, 2) + "\n", "utf8");
console.log("Zaktualizowano api/status.json");
' "$APPLE_FMT" "$DEEZER_FMT" "$TIDAL_FMT" "$SPOTIFY_FMT" "$TOTAL_FMT" "$BADGE_PARAM" \
  "$APPLE_COUNT" "$DEEZER_COUNT" "$TIDAL_COUNT" "$SPOTIFY_COUNT" "$TOTAL_COUNT" "$BADGE_VAL"

echo "Gotowe!"
