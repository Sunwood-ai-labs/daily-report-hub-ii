<div align="center">

<h1>daily-report-hub-ii</h1>

<img src="header.jpg" alt="Forgejo to GitHub mirror workflow" width="720" />

<p>
  <img alt="CI" src="https://img.shields.io/badge/CI-Forgejo_Actions-2185D0?logo=githubactions&logoColor=white" />
  <img alt="Git" src="https://img.shields.io/badge/Git-mirror-orange?logo=git&logoColor=white" />
  <img alt="Bash" src="https://img.shields.io/badge/Shell-bash-4EAA25?logo=gnubash&logoColor=white" />
  <img alt="License" src="https://img.shields.io/badge/License-MIT-lightgrey" />
  <!-- 上記バッジは必要に応じて調整してください -->
  
</p>

</div>

Forgejo から GitHub へリポジトリを自動同期する Forgejo Actions ワークフローです。

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
