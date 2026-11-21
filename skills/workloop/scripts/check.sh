#!/usr/bin/env bash
# 作業ログ・PR・Issue の形式を、このスキルのひな形（template/）と照らして確かめる。
# 確かめるのは形式だけで、内容が依頼を満たすかは確かめない。
#
# 使い方:
#   check.sh log <ログのファイル>    ログの形式を確かめる
#   check.sh time <ログのファイル>   時間の記録の所要・合計・経過時間を計算して書き込む
#   check.sh pr <PR番号>             PR 本文の形式を確かめる（gh で取得）
#   check.sh issue <Issue番号>       Issue 本文の形式を確かめる（gh で取得）
#
# 問題があれば 1 行ずつ書き、終了コード 1 で終わる。必要なもの: bash、awk、gh（pr・issue のとき）
set -euo pipefail

tpl="$(cd "$(dirname "$0")/.." && pwd)/template"
errors=0
err() { echo "$*"; errors=$((errors + 1)); }

usage() { sed -n '5,9p' "$0" | sed 's/^# //' >&2; exit 2; }

# ひな形と共通の形式: 見出し、ひな形のコメント、空の箇条書き、空の節
check_common() { # $1: 本文のファイル, $2: ひな形
  local body=$1 template=$2 h
  while IFS= read -r h; do
    grep -qxF "$h" "$body" || err "見出しがない: $h"
  done < <(grep '^## ' "$template")
  local l empty
  while IFS= read -r l; do err "${l%%:*} 行目: ひな形のコメントが残っている"; done < <(grep -n '<!--' "$body" || true)
  while IFS= read -r l; do err "${l%%:*} 行目: 空の箇条書き"; done < <(grep -nE '^[[:space:]]*- (\[[ xX]\] )?[[:space:]]*$' "$body" || true)
  empty=$(awk '
    /^## / { if (h != "" && !filled) print h; h = $0; filled = 0; next }
    h != "" && $0 !~ /^[[:space:]]*$/ { filled = 1 }
    END { if (h != "" && !filled) print h }
  ' "$body")
  if [ -n "$empty" ]; then
    while IFS= read -r h; do err "節が空（該当がなければ「なし」と書く）: $h"; done <<<"$empty"
  fi
}

# 時間の記録。mode=check は誤りを書き、mode=fix は計算した値で書き換えた本文を書く
time_awk() { # $1: check | fix, $2: ログのファイル
  awk -v mode="$1" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function minutes(s,  p, y, m, d) {
      if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]$/) return -1
      split(s, p, /[- :]/); y = p[1] + 0; m = p[2] + 0; d = p[3] + 0
      if (m <= 2) { y--; m += 12 }
      return ((365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d) * 24 + p[4]) * 60 + p[5]
    }
    function cell(x) { return (x == "" ? " " : " " x " ") "|" }
    function out(s) { if (mode == "fix") print s }
    function bad(s) { if (mode == "check") print s }
    /^## / { in_time = ($0 == "## 時間の記録") }
    in_time && /^\|/ {
      n = split($0, c, "|")
      step = trim(c[2])
      if (n < 7 || step == "手順" || step ~ /^-+$/) { out($0); next }
      s = trim(c[4]); e = trim(c[5]); got = trim(c[6])
      ms = minutes(s); me = minutes(e)
      if (s != "" && ms < 0) bad(NR " 行目: 開始の時刻は YYYY-MM-DD HH:MM で書く: " s)
      if (e != "" && me < 0) bad(NR " 行目: 終了の時刻は YYYY-MM-DD HH:MM で書く: " e)
      if (ms >= 0 && me >= 0) {
        want = me - ms
        if (want < 0) bad(NR " 行目: 終了が開始より前")
        else if (got != want "") bad(NR " 行目: 所要は " want " 分（書かれているのは「" got "」）")
        got = want
        if (first == "" || ms < first) first = ms
        if (last == "" || me > last) last = me
      }
      if (got ~ /^[0-9]+$/) { total += got; rows++ }
      out("|" cell(step) cell(trim(c[3])) cell(s) cell(e) cell(got))
      next
    }
    in_time && /^- 所要の合計:/ {
      if (rows) {
        v = $0; sub(/^- 所要の合計:[ \t]*/, "", v)
        if (v != total " 分") bad(NR " 行目: 所要の合計は " total " 分（書かれているのは「" v "」）")
        out("- 所要の合計: " total " 分"); next
      }
    }
    in_time && /^- 経過時間/ {
      if (first != "") {
        i = index($0, ":"); v = trim(substr($0, i + 1)); el = last - first
        if (v != el " 分") bad(NR " 行目: 経過時間は " el " 分（書かれているのは「" v "」）")
        out(substr($0, 1, i) " " el " 分"); next
      }
    }
    { out($0) }
  ' "$2"
}

check_log() { # $1: ログのファイル
  local f=$1 key placeholder value name
  check_common "$f" "$tpl/log.md"
  # 先頭の「- 項目: 値」。ひな形の値のまま、または空なら誤り
  while IFS='|' read -r key placeholder; do
    value=$(awk -v k="- $key:" 'index($0, k) == 1 { v = substr($0, length(k) + 1); sub(/<!--.*$/, "", v); gsub(/^[ \t]+|[ \t]+$/, "", v); print v; exit }' "$f")
    if [ -z "$value" ]; then err "「- $key:」の値がない"
    elif [ "$value" = "$placeholder" ]; then err "「- $key:」がひな形のまま: $value"
    fi
  done < <(awk '/^## /{exit} /^- [^:]+:/{ k = $0; sub(/^- /, "", k); sub(/:.*/, "", k); v = $0; sub(/^- [^:]+:[ \t]*/, "", v); sub(/[ \t]*<!--.*$/, "", v); print k "|" v }' "$tpl/log.md")
  # ファイル名と番号
  name=$(basename "$f" .md)
  case "$name" in
    pr-[0-9]*) grep -qE "^- PR: #${name#pr-}([^0-9]|$)" "$f" || err "ファイル名 $name.md と「- PR:」の番号が合わない" ;;
    [0-9]*) grep -qE "^- Issue: #${name}([^0-9]|$)" "$f" || err "ファイル名 $name.md と「- Issue:」の番号が合わない" ;;
    *) err "ファイル名は Issue番号.md か pr-PR番号.md にする: $name.md" ;;
  esac
  local t
  t=$(time_awk check "$f")
  if [ -n "$t" ]; then
    while IFS= read -r l; do err "$l"; done <<<"$t"
    echo "（所要・合計・経過時間は check.sh time $f で計算し直せる）"
  fi
}

check_remote() { # $1: pr | issue, $2: 番号
  local kind=$1 n=$2
  body=$(mktemp); trap 'rm -f "$body"' EXIT # trap は関数の外で動くので local にしない
  gh "$kind" view "$n" --json body --jq .body >"$body"
  if [ "$kind" = pr ]; then
    check_common "$body" "$tpl/pull_request.md"
  else
    check_common "$body" "$tpl/issue.md"
    awk '/^## /{ s = ($0 == "## 要件") } s && /^[[:space:]]*- \[[ xX]\] /{ found = 1 } END { exit !found }' "$body" ||
      err "「## 要件」にチェックボックスがない"
  fi
}

[ "$#" -eq 2 ] || usage
case "$1" in
  log) check_log "$2" ;;
  time)
    tmp=$(mktemp); time_awk fix "$2" >"$tmp" && cat "$tmp" >"$2"; rm -f "$tmp"
    sed -n '/^## 時間の記録/,$p' "$2"; exit 0 ;;
  pr | issue) check_remote "$1" "$2" ;;
  *) usage ;;
esac

if [ "$errors" -gt 0 ]; then echo "形式の問題: $errors 件"; exit 1; fi
echo "形式の問題なし（内容は確かめていない）"
