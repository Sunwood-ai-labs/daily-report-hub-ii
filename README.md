<div align="center">

<h1>daily-report-hub-ii</h1>

<img src="header.jpg" alt="Forgejo to GitHub mirror workflow" />

<p>
  <img alt="CI" src="https://img.shields.io/badge/CI-Forgejo_Actions-2185D0?logo=githubactions&logoColor=white" />
  <img alt="Git" src="https://img.shields.io/badge/Git-mirror-orange?logo=git&logoColor=white" />
  <img alt="Bash" src="https://img.shields.io/badge/Shell-bash-4EAA25?logo=gnubash&logoColor=white" />
  <img alt="License" src="https://img.shields.io/badge/License-MIT-lightgrey" />
  <!-- 上記バッジは必要に応じて調整してください -->
  
</p>

</div>

Forgejo から GitHub へリポジトリを自動同期する Forgejo Actions ワークフローです。

あわせて、Forgejo 側で事前にリスト化した複数リポジトリから日次の差分レポートを生成し、本リポジトリ内に保存する定時ジョブも用意しました。

## 🚀 使い方

1) Forgejo のこのリポジトリに Secrets を設定

- `GH_TOKEN`: GitHub の個人用アクセストークン（repo 権限）
- `GH_REPO`: 同期先の GitHub リポジトリの `owner/repo` 形式（例: `your-org/your-repo`）
  - 注: 現在のワークフロー例は固定リポジトリに push する設定です。任意のリポジトリへミラーする場合は、下記「ワークフローの修正（任意）」を参照してください。

2) ランナーラベルの確認（必要に応じて修正）

- デフォルトでは `.forgejo/workflows/sync-to-github.yml` の `runs-on: docker` を使用しています。
- ご利用の Forgejo ランナーのラベルに合わせて `docker` を `self-hosted` や `ubuntu-latest` などへ変更してください。

3) トリガー

- ブランチ/タグの push、削除、手動実行（workflow_dispatch）で起動します。

## ✏️ ワークフローの修正（任意）

任意の GitHub リポジトリにミラーするには、`.forgejo/workflows/sync-to-github.yml` の GitHub リモート追加部分を `GH_REPO` を使う形に変更してください。例:

```yaml
env:
  GH_TOKEN: ${{ secrets.GH_TOKEN }}
  GH_REPO:  ${{ secrets.GH_REPO }}
run: |
  # ...（前略）
  git remote remove github 2>/dev/null || true
  git remote add github "https://${GH_TOKEN}@github.com/${GH_REPO}.git"
  git push --mirror github
```

## ⚙️ 仕組み（概要）

- `actions/checkout@v4` で履歴を全取得（fetch-depth: 0）。
- GitHub リモートをトークン付き URL で追加し、`git push --mirror` でブランチ/タグ/削除をミラーリングします。

## ⚠️ 注意事項

- `--mirror` は削除も含め「Forgejo 側の状態を GitHub 側に反映」します。意図しない上書きにご注意ください。
- LFS を使用している場合、ランナーに `git-lfs` のインストールが必要です（必要ならワークフローに追加してください）。

## 🧩 トラブルシュート

- 403/404 エラー: アクセストークンのスコープ（repo 権限）と `GH_REPO` の指定（`owner/repo`）を再確認してください。
- LFS オブジェクトが同期されない: ランナーに `git-lfs` をインストールし、`git lfs install` を実行してください。

## 📄 ファイル

- `.forgejo/workflows/sync-to-github.yml`: 同期用ワークフロー本体。

---

## 📊 日次差分レポート（Forgejo スケジュール実行）

### 概要

`.forgejo/workflows/daily-diff-reports.yml` が毎日 00:10 (UTC) に起動し、`repos.list` に列挙した各リポジトリをクローンして当日の変更を解析し、`docs/activities/<年>/<週>/YYYY-MM-DD/<リポジトリ名>/` に Markdown レポートを生成・コミットします。

### 設定手順

1) リポジトリ一覧を編集

`repos.list` にクローン URL またはパスを 1 行ずつ列挙します。空行と `#` で始まる行は無視されます。

```
# 例: 同一 Forgejo の公開リポジトリ
https://forgejo.example.com/your-org/awesome-repo.git

# 例: GitHub 上の公開リポジトリ
https://github.com/your-org/another-repo.git

# 例: このリポジトリ自身（デモ）
./
```

環境変数を含めて記述することもできます（実行時に展開）。例:

```
https://${FORGEJO_TOKEN}@forgejo.example.com/your-org/private-repo.git
```

必要に応じて Forgejo リポジトリの「Settings > Actions > Secrets」に `FORGEJO_TOKEN` などを設定し、ワークフローの「Generate reports」ステップに `env` として渡してください。

2) 週の開始曜日や実行時刻の調整（任意）

- 週の開始曜日は `WEEK_START_DAY`（0=日, 1=月, ...）で制御します（デフォルト: 1）。
- 実行時刻はワークフロー内の `cron` を編集してください。

### 出力パス例

```
docs/activities/
└── 2025/
    └── week-06_2025-08-04_to_2025-08-10/
        └── 2025-08-05/
            └── your-repo/
                ├── daily_summary.md
                ├── daily_commits.md
                ├── daily_cumulative_diff.md
                ├── daily_diff_stats.md
                ├── daily_code_diff.md
                ├── latest_diff.md
                ├── latest_code_diff.md
                ├── README.md
                └── metadata.json
```

### スクリプト

- `scripts/week-info.sh`: 日付から週情報を計算
- `scripts/analyze-git-activity.sh`: Git ログと差分の生データ抽出
- `scripts/generate-markdown-reports.sh`: Markdown 生成
- `scripts/create-docusaurus-structure.sh`: 出力ディレクトリ構成作成
- `scripts/report-one.sh`: 1 リポジトリの一括処理
- `scripts/run-batch.sh`: リスト全体の処理
- `scripts/run-backfill-weeks.sh`: 指定した週間分（今日を含む過去N週間）の日次レポートを一括生成（コミットがない日はスキップ）

### 注意

- プライベートリポジトリにアクセスする場合は、`repos.list` でトークン埋め込み URL を使用するか、ランナーに適切な資格情報を設定してください。
- 一時/作業ディレクトリ（`work/`, `.tmp/`）は `.gitignore` 済みです。

### 初期スタートセット（過去N週間の一括生成）

過去N週間分のレポートをまとめて作成するには、次のスクリプトを使います。コミットが無い日は自動的にスキップされ、レポートは作成されません。

```
# 例: 過去4週間を対象に backfill（repos.list を使用）
./scripts/run-backfill-weeks.sh 4

# 例: リポジトリ一覧を指定し、週の開始曜日を変更（0=日,1=月,...）
WEEK_START_DAY=1 ./scripts/run-backfill-weeks.sh 6 path/to/repos.list
```

メモ: 日次定期実行（`daily-diff-reports.yml`）は当日分のみ実行しますが、backfill スクリプトは指定した期間を日毎に遡って処理します。
