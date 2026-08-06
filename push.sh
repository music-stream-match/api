#!/usr/bin/env bash
set -uo pipefail

BATCH_SIZE=10000
MAX_PUSH_RETRIES=5

batch_num=0

get_pending_files() {
    {
        git diff --no-renames --name-only -z HEAD 2>/dev/null
        git ls-files --others --exclude-standard -z
    }
}

while true; do
    mapfile -d '' -t files < <(get_pending_files | head -z -n "$BATCH_SIZE")

    if [ "${#files[@]}" -eq 0 ]; then
        echo "Wszystkie pliki zostały dodane i zatwierdzone!"
        break
    fi

    batch_num=$((batch_num + 1))
    echo "== Partia #${batch_num}: ${#files[@]} plik(ów) =="

    # Dodaje wybraną partię plików do poczekalni (staging); "--" chroni przed
    # interpretacją nazw zaczynających się od "-" jako opcji
    printf '%s\0' "${files[@]}" | xargs -0 git add --

    if ! git commit -m "Batch update: ${batch_num}"; then
        echo "Commit nie powiódł się (być może brak zmian po 'git add') - przerywam, aby uniknąć pętli w nieskończoność."
        exit 1
    fi

    attempt=0
    until git push; do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge "$MAX_PUSH_RETRIES" ]; then
            echo "Push nie powiódł się po ${MAX_PUSH_RETRIES} próbach. Commit jest zapisany lokalnie - uruchom skrypt ponownie później."
            exit 1
        fi
        echo "Push nie powiódł się (próba ${attempt}/${MAX_PUSH_RETRIES}), ponawiam za 5s..."
        sleep 5
    done

    echo "Zatwierdzono i wypchnięto partię #${batch_num} (${#files[@]} plików)."
done
