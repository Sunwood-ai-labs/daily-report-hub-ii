# 💻 Daily Code Changes

```diff
commit 1ca73ff50aa812f89434e9b7f13e1190b8a2dc63
Author: maki <sunwood.ai.labs@gmail.com>
Date:   Sun Aug 31 12:06:34 2025 +0000

    add

diff --git a/.forgejo/workflows/sync-to-github.yml b/.forgejo/workflows/sync-to-github.yml
index b3c901e..eb8ffdb 100644
--- a/.forgejo/workflows/sync-to-github.yml
+++ b/.forgejo/workflows/sync-to-github.yml
@@ -41,7 +41,7 @@ jobs:
 
           # Add GitHub remote with token (fixed target repo)
           git remote remove github 2>/dev/null || true
-          git remote add github "https://${GH_TOKEN}@github.com/Sunwood-ai-labs/forgejo-to-github.git"
+          git remote add github "https://${GH_TOKEN}@github.com/Sunwood-ai-labs/daily-report-hub-ii.git"
 
           # Mirror all refs (branches, tags, deletions) to GitHub
           git push --mirror github
diff --git a/README.md b/README.md
index 68f67cd..fed1183 100644
--- a/README.md
+++ b/README.md
@@ -1,6 +1,6 @@
 <div align="center">
 
-<h1>forgejo-to-github</h1>
+<h1>daily-report-hub-ii</h1>
 
 <img src="header.jpg" alt="Forgejo to GitHub mirror workflow" width="720" />
 
```
