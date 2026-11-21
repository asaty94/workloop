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
├── SKILL.md         ディレクトリ構成、役割と委任、権限、手順 1〜12、
│                    Issue・PR、検証と確認、作業のログ、マージ
└── template/        ひな形
    ├── log.md           作業のログ
    ├── issue.md         Issue
    └── pull_request.md  PR
agents/              サブエージェント execution・verification・confirmation
scripts/             プラグインの改善に使う情報の収集（作業対象リポジトリには不要）
```

サブエージェントは決まりを持たず、`workloop` を読み込んで対応する節に従います。

## 作業対象リポジトリ側に置くとよいもの

スキルは、作業対象リポジトリにある `specification/work/` の「レビュー項目の例」を参照します。なくても動きます。

### Issue・PR のテンプレート（任意）

テンプレートがなくても、スキルの `template/` のひな形で Issue と PR を書きます。`template/issue.md` を `.github/ISSUE_TEMPLATE/作業.md` に、`template/pull_request.md` を `.github/pull_request_template.md` にコピーすると、人が GitHub の画面から作る Issue・PR も同じ形になります。テンプレートに独自の項目を足すと、AI もその項目を埋めます。

## 改善のための情報収集

作業のログ（`work/log/*.md`）には、使ったプラグインの版と「workloop への気づき」の欄があります。`scripts/collect-feedback.sh` は、この欄を各リポジトリから集めて Markdown で出力します。

```sh
scripts/collect-feedback.sh > /tmp/workloop-feedback.md                     # 自動で探す
scripts/collect-feedback.sh owner/repo-a owner/repo-b > /tmp/workloop-feedback.md   # 指定する
```

- リポジトリを指定しないときは、GitHub のコード検索で `.claude/settings.json` に `workloop@workloop` があるリポジトリを探します。対象は、`gh` の認証で見えるリポジトリのうち、検索の索引に入っているものだけです。`.claude/settings.json` を置かずに使っているリポジトリは見つからないので、指定してください。
- 出力には業務の内容が混じることがあります。このリポジトリは公開されているので、出力はコミットせず、内容を確かめて必要なことだけを Issue にしてください。

## 更新の配り方

1. `skills/` などを編集する。
2. `.claude-plugin/plugin.json` の `version` を上げる。**上げないと配信されません。**
3. main に push する。

push せずに試すときは `claude --plugin-dir .` を使います。
