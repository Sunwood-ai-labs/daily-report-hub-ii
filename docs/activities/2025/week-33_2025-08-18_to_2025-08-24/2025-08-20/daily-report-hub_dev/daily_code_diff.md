# 💻 Daily Code Changes

```diff
diff --git a/.forgejo/scripts/calculate-week-info.sh b/.forgejo/scripts/calculate-week-info.sh
index 6bccc1b..253ca59 100644
--- a/.forgejo/scripts/calculate-week-info.sh
+++ b/.forgejo/scripts/calculate-week-info.sh
@@ -8,7 +8,7 @@ set -e
 WEEK_START_DAY=${1:-1}  # デフォルトは月曜日
 
 # リポジトリ名と日付を取得
-REPO_NAME=${FORGEJO_REPO_NAME}
+REPO_NAME=${GITHUB_REPOSITORY##*/}
 DATE=$(date '+%Y-%m-%d')
 YEAR=$(date '+%Y')
 
diff --git a/.forgejo/scripts/sync-to-hub-fj.sh b/.forgejo/scripts/sync-to-hub-fj.sh
index a3abce9..0211d0e 100644
--- a/.forgejo/scripts/sync-to-hub-fj.sh
+++ b/.forgejo/scripts/sync-to-hub-fj.sh
@@ -120,17 +120,21 @@ PR_BODY="## 📊 デイリーレポート同期
 *Forfejo Actions により自動生成（YUKIHIKO権限）*"
 
 echo "📝 YUKIHIKOアカウントでPR作成中..."
+
+# jq を使って安全にJSONペイロードを生成
+JSON_PAYLOAD=$(jq -n \
+  --arg title "$COMMIT_MESSAGE" \
+  --arg body "$PR_BODY" \
+  --arg head "$BRANCH_NAME" \
+  --arg base "main" \
+  '{title: $title, body: $body, head: $head, base: $base}')
+
 # Forfejo APIでPR作成
 PR_RESPONSE=$(curl -s -X POST \
   -H "Authorization: token ${PR_CREATOR_TOKEN}" \
   -H "Content-Type: application/json" \
   "${FORGEJO_API_URL}/repos/${REPORT_HUB_REPO}/pulls" \
-  -d "{
-    \"title\": \"${COMMIT_MESSAGE}\",
-    \"body\": \"${PR_BODY}\",
-    \"head\": \"${BRANCH_NAME}\",
-    \"base\": \"main\"
-  }")
+  -d "$JSON_PAYLOAD")
 
 PR_NUMBER=$(echo "${PR_RESPONSE}" | jq -r '.number // empty')
 PR_URL=$(echo "${PR_RESPONSE}" | jq -r '.html_url // empty')
diff --git a/.forgejo/workflows/sync-to-report.yml b/.forgejo/workflows/sync-to-report.yml
index f0591fd..427a146 100644
--- a/.forgejo/workflows/sync-to-report.yml
+++ b/.forgejo/workflows/sync-to-report.yml
@@ -9,7 +9,7 @@ env:
   # Forfejoの環境に合わせて設定
   FORGEJO_HOST: "192.168.0.131:3000"
   FORGEJO_API_URL: "http://192.168.0.131:3000/api/v1"
-  REPORT_HUB_REPO: "Sunwood-ai-labs/daily-report-hub.git" # Forfejo上のリポジトリ (例)
+  REPORT_HUB_REPO: "Sunwood-ai-labs/daily-report-hub" # Forfejo上のリポジトリ (例)
 
   # ワークフロー設定
   WEEK_START_DAY: 1
```
