# workloop

計画・仕様・実装で構成する業務と、定義から完了処理までの作業の進め方を、Claude Code に守らせるプラグインです。

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

スキルは `workloop` の 1 つです。リポジトリのファイルを変える依頼で自動的に使われ、`/workloop:workloop` で呼び出すこともできます。

```
skills/workloop/
└── SKILL.md         ディレクトリ構成、役割と委任、権限、手順 1〜12、
                     Issue・PR、検証と確認、作業のログ、マージ
agents/              サブエージェント execution・verification・confirmation
```

サブエージェントは決まりを持たず、`workloop` を読み込んで対応する節に従います。

## 作業対象リポジトリ側に必要なもの

スキルは、作業対象リポジトリにある次の文書・ファイルを参照します。

- `specification/work/` の「時間の記録」「レビュー項目の例」
- `specification/work/実施/エージェント設定.md`
- `.github/` の Issue・PR テンプレート
- `specification/work/道具/` の、ログのひな形などの道具とその使い方

## 更新の配り方

1. `skills/` などを編集する。
2. `.claude-plugin/plugin.json` の `version` を上げる。**上げないと配信されません。**
3. main に push する。

push せずに試すときは `claude --plugin-dir .` を使います。
