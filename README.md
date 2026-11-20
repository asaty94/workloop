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
- `specification/work/道具/` の、ログのひな形などの道具とその使い方

### Issue・PR のテンプレート（任意）

テンプレートがなくても、スキルが決めた項目で Issue と PR を書きます。`.github/` に同じ見出しのテンプレートを置くと、人が GitHub の画面から作る Issue・PR も同じ形になります。テンプレートに独自の項目を足すと、AI もその項目を埋めます。

`.github/ISSUE_TEMPLATE/作業.md`

```markdown
---
name: 作業
about: 作業の目的と完了条件
---

## 概要

<!-- 目的と背景 -->

## 要件

- [ ] <!-- 完了を判定できる条件 -->
```

`.github/pull_request_template.md`

```markdown
## 背景

<!-- なぜ変更が必要か。Closes #番号 / Refs #番号 -->

## 変更

<!-- 何を変え、どう確かめたか -->

## レビュー項目

<!-- 人の判断・情報・権限が必要なことと、未達の要件。なければ「なし」 -->
```

## 更新の配り方

1. `skills/` などを編集する。
2. `.claude-plugin/plugin.json` の `version` を上げる。**上げないと配信されません。**
3. main に push する。

push せずに試すときは `claude --plugin-dir .` を使います。
