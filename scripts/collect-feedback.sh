#!/usr/bin/env bash
# workloop を使っているリポジトリの作業ログ（work/log/*.md）から、
# 「workloop への気づき」の欄とプラグインの版を集め、Markdown で標準出力に書く。
#
# 使い方:
#   scripts/collect-feedback.sh [owner/repo ...]
#
# リポジトリを指定しないときは、GitHub のコード検索で `.claude/settings.json` に
# "workloop@workloop" を書いているリポジトリ（gh の認証で見えるもの）を対象にする。
# 必要なもの: gh（認証済み）、awk
set -euo pipefail

# 作業ログ 1 件（標準入力）から、版の行と「workloop への気づき」の欄を取り出す。
# 1 行目に版（なければ空）、2 行目以降に欄の本文を書く。HTML コメントと空の箇条書きは除く。
extract() {
  awk '
    /^- workloop:/ && version == "" { version = $0; sub(/^- workloop:[ \t]*/, "", version); sub(/[ \t]*<!--.*$/, "", version) }
    /^## / { in_section = ($0 ~ /^## workloop への気づき[ \t]*$/); next }
    in_section {
      line = $0
      if (in_comment) { if (line ~ /-->/) { sub(/^.*-->/, "", line); in_comment = 0 } else next }
      gsub(/<!--[^>]*-->/, "", line)
      if (line ~ /<!--/) { sub(/<!--.*$/, "", line); in_comment = 1 }
      if (line ~ /^[ \t]*-?[ \t]*$/) next
      body = body line "\n"
    }
    END { print version; printf "%s", body }
  '
}

if [ "$#" -gt 0 ]; then
  repos=("$@")
else
  repos=()
  while IFS= read -r r; do repos+=("$r"); done < <(
    gh search code '"workloop@workloop"' --filename settings.json --limit 100 \
      --json repository,path --jq '.[] | select(.path == ".claude/settings.json") | .repository.nameWithOwner' | sort -u
  )
fi

logs=0; with_feedback=0
echo "# workloop への気づき（$(date '+%Y-%m-%d') 収集）"
for repo in ${repos[@]+"${repos[@]}"}; do
  files=$(gh api "repos/$repo/contents/work/log" --jq '.[] | select(.type == "file" and (.name | endswith(".md"))) | .name' 2>/dev/null) || {
    echo "skip: ${repo}（work/log/ がない、または読めない）" >&2; continue
  }
  for f in $files; do
    logs=$((logs + 1))
    out=$(gh api "repos/$repo/contents/work/log/$f" -H 'Accept: application/vnd.github.raw' | extract)
    version=$(printf '%s\n' "$out" | head -n 1)
    body=$(printf '%s\n' "$out" | tail -n +2)
    [ -z "$body" ] && continue
    [ "$(printf '%s' "$body" | sed 's/^[ \t]*-[ \t]*//')" = "なし" ] && continue
    with_feedback=$((with_feedback + 1))
    printf '\n## %s work/log/%s（workloop %s）\n\n%s\n' "$repo" "$f" "${version:-不明}" "$body"
  done
done
echo "リポジトリ ${#repos[@]} 件、ログ ${logs} 件、気づきのあるログ ${with_feedback} 件" >&2
