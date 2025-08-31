# 🔄 Latest Code Changes

```diff
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
```
