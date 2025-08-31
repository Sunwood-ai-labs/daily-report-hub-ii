#!/usr/bin/env python3
"""
Generate AI-written daily reports per repository using Gemini via LiteLLM.

- Scans docs/activities/<YEAR>/week-XX_YYYY-MM-DD_to_YYYY-MM-DD/<DATE>/<REPO>/
  for metadata.json and daily_* markdown files.
- Sends a constrained prompt to Gemini (gemini-2.5-pro) and expects the
  completed report to be wrapped in <output-report> ... </output-report>.
- Saves a clean ai_daily_report.md (frontmatter + extracted content) in each repo dir.

Env:
- GOOGLE_API_KEY (required by LiteLLM for Gemini)
- DOCS_ACTIVITIES_DIR (optional, default: docs/activities)
"""

import os
import re
from pathlib import Path
from datetime import datetime
import litellm


def find_todays_repos(base_dir: Path):
    today = datetime.now().strftime('%Y-%m-%d')
    year = today.split('-')[0]

    print(f"🔍 Searching activities for {today}")
    activities_dir = base_dir

    repo_dirs = []
    if not activities_dir.exists():
        print(f"❌ Base activities dir does not exist: {activities_dir}")
        return today, repo_dirs

    year_dir = activities_dir / year
    if not year_dir.exists():
        print(f"❌ Year dir not found: {year_dir}")
        return today, repo_dirs

    for week_dir in sorted(year_dir.glob('week-*')):
        date_dir = week_dir / today
        if date_dir.exists():
            for repo_dir in sorted([p for p in date_dir.iterdir() if p.is_dir()]):
                if (repo_dir / 'metadata.json').exists():
                    repo_dirs.append(repo_dir)
                    print(f"✅ Found repo for today: {repo_dir.name}")

    print(f"📊 Total repos found for today: {len(repo_dirs)}")
    return today, repo_dirs


def load_repo_data(repo_dir: Path):
    print(f"\n📖 Loading repo data: {repo_dir.name}")
    repo_data = {'name': repo_dir.name, 'path': repo_dir}
    files_to_check = [
        ('summary', 'daily_summary.md'),
        ('commits', 'daily_commits.md'),
        ('changes', 'daily_cumulative_diff.md'),
        ('stats', 'daily_diff_stats.md'),
        ('code_diff', 'daily_code_diff.md'),
    ]
    for key, filename in files_to_check:
        fpath = repo_dir / filename
        if fpath.exists():
            try:
                text = fpath.read_text(encoding='utf-8')
                if key == 'commits':
                    text = text[:3000]
                repo_data[key] = text
            except Exception as e:
                print(f"    ❌ {filename}: read error: {e}")
    return repo_data


def build_prompt(repo_name: str, date: str, repo_data: dict) -> str:
    parts = [
        f"以下の{repo_name}リポジトリの{date}の活動データから、日報をMarkdown形式で作成してください:\n",
    ]
    if 'summary' in repo_data:
        parts.append(f"## サマリー:\n{repo_data['summary']}\n")
    if 'commits' in repo_data:
        parts.append(f"## コミット詳細:\n{repo_data['commits']}\n")
    if 'changes' in repo_data:
        parts.append(f"## ファイル変更:\n{repo_data['changes']}\n")
    if 'stats' in repo_data:
        parts.append(f"## 統計:\n{repo_data['stats']}\n")

    parts.append(
        """
日報作成要求:
- 今日の開発活動を要約
- 主要な変更点と技術的ポイントをハイライト
- 進捗状況を評価（完了/着手/保留）
- 改善点や次の一手があれば記載
- 日本語で簡潔に、適度に絵文字を使用
- 重要: 完成した日報は、必ず <output-report> と </output-report> で全体を囲むこと

下記のテンプレの一言レビューも付けてください。
PANDA 先生は客観的評価、FOX 教官は厳しめ、キャット ギャルはギャル口調で本質と経営視点。

:::tip PANDA 先生

一言レビュー

:::

:::danger FOX 教官

一言レビュー

:::

:::caution キャット ギャル

一言レビュー

:::
"""
    )

    return "\n".join(parts)


def call_gemini(prompt: str) -> str | None:
    print("🤖 Calling Gemini (gemini-2.5-pro)...")
    try:
        response = litellm.completion(
            model="gemini/gemini-2.5-pro",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
        )
        content = response.choices[0].message.content
        if content and content.strip():
            return content.strip()
    except Exception as e:
        print(f"❌ LLM error: {e}")
    return None


def save_daily_report(repo_name: str, repo_dir: Path, date: str, clean_md: str):
    out_path = repo_dir / 'ai_daily_report.md'
    fm = (
        f"---\n"
        f"title: \"{repo_name} - AI日報\"\n"
        f"date: \"{date}\"\n"
        f"sidebar_position: 1\n"
        f"description: \"AI生成による{repo_name}の開発日報\"\n"
        f"tags: [\"daily-report\", \"ai-generated\", \"{repo_name}\", \"{date}\"]\n"
        f"---\n\n"
    )
    out_path.write_text(fm + clean_md, encoding='utf-8')
    print(f"✅ Saved: {out_path}")


def main():
    print("🚀 Gemini-based Daily Report Generator")
    # Accept both env names: GEMINI_API_KEY (LiteLLM common) and GOOGLE_API_KEY (official SDK examples)
    api_key = os.getenv('GEMINI_API_KEY') or os.getenv('GOOGLE_API_KEY')
    if not api_key:
        print("❌ GEMINI_API_KEY / GOOGLE_API_KEY is not set. Aborting.")
        return
    # Normalize for downstream libs
    os.environ['GEMINI_API_KEY'] = api_key
    os.environ.setdefault('GOOGLE_API_KEY', api_key)

    base_dir = Path(os.getenv('DOCS_ACTIVITIES_DIR', 'docs/activities'))
    date, repo_dirs = find_todays_repos(base_dir)
    if not repo_dirs:
        print("📝 No activities found for today.")
        return

    for idx, repo_dir in enumerate(repo_dirs, 1):
        print(f"\n--- {idx}/{len(repo_dirs)}: {repo_dir.name} ---")
        repo_data = load_repo_data(repo_dir)
        prompt = build_prompt(repo_dir.name, date, repo_data)
        ai_resp = call_gemini(prompt)

        if not ai_resp:
            # Minimal fallback content
            ai_resp = (
                f"<output-report>\n# 📅 {repo_dir.name} - 日報 ({date})\n\n"
                f"AI生成に失敗しました。収集データを参照してください。\n\n"
                f"</output-report>"
            )

        print("🔍 Extracting content between <output-report> tags...")
        m = re.search(r"<output-report>(.*?)</output-report>", ai_resp, re.DOTALL)
        if m:
            clean = m.group(1).strip()
        else:
            print("⚠️ <output-report> not found. Using raw response.")
            clean = ai_resp.strip()
        if not clean:
            clean = f"# 📅 {repo_dir.name} - 日報 ({date})\n\n内容が空でした。"

        save_daily_report(repo_dir.name, repo_dir, date, clean)

    print("\n✅ All daily AI reports generated.")


if __name__ == "__main__":
    main()
