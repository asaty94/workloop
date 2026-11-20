# workloop

計画・仕様・実装・検証で構成する業務と、定義から完了処理までの作業の進め方を、Claude Code に守らせるプラグインです。

## インストール

Claude Code で、次の 2 つを別々に送ります。

```
/plugin marketplace add asaty94/workloop
```
```
/plugin install workloop@workloop
```

### 自動更新

`/plugin` → Marketplaces → `workloop` を選び、auto-update を有効にします（既定ではオフ）。有効にすると、Claude Code の起動時に新しいバージョンが自動で適用されます。

### チームのリポジトリで案内する

作業対象リポジトリの `.claude/settings.json` に次を書くと、そのフォルダを開いたメンバーにインストールが案内されます。

```json
{
  "extraKnownMarketplaces": {
    "workloop": {
      "source": { "source": "github", "repo": "asaty94/workloop" }
    }
  },
  "enabledPlugins": {
    "workloop@workloop": true
  }
}
```

## 中身

| スキル | 使う場面 |
|---|---|
| `workflow` | リポジトリのファイルを変える依頼を受けたとき（入口） |
| `layout` | 業務の構成と、plan/・specification/・verification/・work/ の置き場所 |
| `issue-pr` | Issue・PR・レビュー項目の書き方、計画との紐付け |
| `execution` | 実装・調査（実行エージェント、または main） |
| `verification` | 検証（検証エージェント、または main） |
| `confirmation` | 確認（確認エージェント、または main） |
| `merge` | 担当者が対象 PR のマージを明示的に指示したとき |
| `work-log` | 作業のログ |

サブエージェント `execution`・`verification`・`confirmation` は、対応するスキルを読み込んで動きます。

スキルは `/workloop:workflow` のように呼び出せます。内容に合う作業では Claude が自動で使います。

## 作業対象リポジトリ側に必要なもの

スキルは、作業対象リポジトリにある次の文書・ファイルを参照します。

- `specification/業務/` の「振り返りのタイミング」「業務の改善方法」「時間の記録」「レビュー項目の例」「利用手順」
- `specification/業務/実施/エージェント設定.md`
- `.github/` の Issue・PR テンプレート
- `work/実施/templates/log.md`、`work/実施/tools/work_log.py`

## 更新の配り方

1. `skills/` などを編集する。
2. `.claude-plugin/plugin.json` の `version` を上げる。**上げないと配信されません。**
3. main に push する。

push せずに試すときは `claude --plugin-dir .` を使います。
