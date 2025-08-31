#!/usr/bin/env python3
"""
Generate an AI-written weekly report across all repos for the current week.

- Computes the current week folder using WEEK_START_DAY (0=Sun..6=Sat, default 1=Mon).
- Aggregates daily metadata/summaries from docs/activities/<YEAR>/<WEEK_FOLDER>/
- Sends a concise weekly summary prompt to Gemini, expects <output-report> wrapper.
- Saves ai_weekly_report.md into the week directory root.

Env:
- GOOGLE_API_KEY (required)
- DOCS_ACTIVITIES_DIR (optional, default: docs/activities)
- WEEK_START_DAY (optional, default: 1)
"""

import os
import re
import json
from pathlib import Path
from datetime import datetime, timedelta
import litellm


def compute_week_info(today: datetime, week_start_day: int = 1):
    # Convert Python weekday (Mon=0..Sun=6) to our scheme (Sun=0..Sat=6)
    # Python: Monday=0..Sunday=6
    py_wd = today.weekday()  # 0..6 where 6=Sunday
    # Map to Sun=0..Sat=6
    sun0 = (py_wd + 1) % 7
    days_since_week_start = (sun0 - week_start_day + 7) % 7
    week_start = today - timedelta(days=days_since_week_start)
    week_end = week_start + timedelta(days=6)

    year = week_start.strftime('%Y')

    # Compute week number relative to first week start of the year
    year_start = datetime(int(year), 1, 1)
    year_start_sun0 = (year_start.weekday() + 1) % 7
    first_week_start_offset = (week_start_day - year_start_sun0 + 7) % 7
    first_week_start = year_start + timedelta(days=first_week_start_offset)
    days_diff = (week_start - first_week_start).days
    week_number = (days_diff // 7) + 1

    week_folder = f"week-{week_number:02d}_{week_start.strftime('%Y-%m-%d')}_to_{week_end.strftime('%Y-%m-%d')}"
    return {
        'DATE': today.strftime('%Y-%m-%d'),
        'YEAR': year,
        'WEEK_NUMBER': week_number,
        'WEEK_START_DATE': week_start.strftime('%Y-%m-%d'),
        'WEEK_END_DATE': week_end.strftime('%Y-%m-%d'),
        'WEEK_FOLDER': week_folder,
    }


def collect_week_data(week_dir: Path):
    summary = {
        'total_commits': 0,
        'total_files_changed': 0,
        'repos': {},  # repo -> {'commits': x, 'files_changed': y, 'days': set([...])}
        'days': [],   # list of {'date': 'YYYY-MM-DD', 'repos': {name: {...}}}
        'daily_snippets': [],  # list of (date, repo, snippet)
    }
    if not week_dir.exists():
        return summary

    for date_dir in sorted([d for d in week_dir.iterdir() if d.is_dir()]):
        date_str = date_dir.name
        day_rec = {'date': date_str, 'repos': {}}
        for repo_dir in sorted([p for p in date_dir.iterdir() if p.is_dir()]):
            repo_name = repo_dir.name
            meta_path = repo_dir / 'metadata.json'
            commits = 0
            files_changed = 0
            if meta_path.exists():
                try:
                    meta = json.loads(meta_path.read_text(encoding='utf-8'))
                    commits = int(meta.get('daily_commit_count', 0) or 0)
                    files_changed = int(meta.get('daily_files_changed', 0) or 0)
                except Exception:
                    pass

            summary['total_commits'] += commits
            summary['total_files_changed'] += files_changed

            if repo_name not in summary['repos']:
                summary['repos'][repo_name] = {
                    'commits': 0,
                    'files_changed': 0,
                    'days': set(),
                }
            summary['repos'][repo_name]['commits'] += commits
            summary['repos'][repo_name]['files_changed'] += files_changed
            summary['repos'][repo_name]['days'].add(date_str)

            day_rec['repos'][repo_name] = {
                'commits': commits,
                'files_changed': files_changed,
            }

            # Small snippet from daily summary to feed LLM
            ds_path = repo_dir / 'daily_summary.md'
            if ds_path.exists():
                try:
                    txt = ds_path.read_text(encoding='utf-8')
                    # Trim to keep prompt compact
                    snippet = txt.strip()
                    snippet = snippet[:1200]
                    summary['daily_snippets'].append((date_str, repo_name, snippet))
                except Exception:
                    pass

        summary['days'].append(day_rec)

    # Convert set to counts for serialization later
    for r in summary['repos'].values():
        r['active_days'] = len(r['days'])
        r['days'] = sorted(list(r['days']))

    return summary


def build_weekly_prompt(week_info: dict, week_data: dict) -> str:
    header = (
        f"{week_info['WEEK_START_DATE']}〜{week_info['WEEK_END_DATE']}の週間活動を要約してください。\n"
        f"週番号: 第{week_info['WEEK_NUMBER']}週\n\n"
        f"合計コミット: {week_data['total_commits']}\n"
        f"合計ファイル変更: {week_data['total_files_changed']}\n\n"
        "リポジトリ別の集計（コミット/変更/活動日数）:\n"
    )
    repo_lines = []
    for name, rec in sorted(week_data['repos'].items(), key=lambda x: (-x[1]['commits'], x[0])):
        repo_lines.append(f"- {name}: commits={rec['commits']}, files={rec['files_changed']}, days={rec['active_days']}")
    repo_block = "\n".join(repo_lines) or "(該当なし)"

    # Include selected daily snippets to provide context
    snippets = [
        f"### {d} - {r}\n{snip}\n" for (d, r, snip) in week_data['daily_snippets'][:10]
    ]
    snippets_block = "\n".join(snippets) or "(サマリーなし)"

    tail = (
        """
週報の要件:
- 1週間の全体像（ハイライト、達成、変更の大枠）
- 進捗と成果（定量: コミット/ファイル、定性: 意味や影響）
- リスク/課題/技術的負債の整理
- 次週の注力ポイントと提案（具体的で優先度つき）
- 日本語で読みやすく、見出し・箇条書き・表を適切に使用
- 重要: 完成した週報は<output-report>と</output-report>で全体を囲むこと

最後に以下の3名の一言レビューを添えてください。

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

    return (
        header
        + repo_block
        + "\n\n---\n\n代表的な日次サマリー（抜粋）:\n\n"
        + snippets_block
        + "\n\n" + tail
    )


def call_gemini(prompt: str) -> str | None:
    print("🤖 Calling Gemini (gemini-2.5-pro) for weekly report...")
    try:
        response = litellm.completion(
            model="gemini/gemini-2.5-pro",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.6,
        )
        content = response.choices[0].message.content
        if content and content.strip():
            return content.strip()
    except Exception as e:
        print(f"❌ LLM error: {e}")
    return None


def save_weekly_report(week_dir: Path, week_info: dict, clean_md: str):
    out_path = week_dir / 'ai_weekly_report.md'
    fm = (
        f"---\n"
        f"title: \"AI週報 - 第{week_info['WEEK_NUMBER']}週\"\n"
        f"date: \"{week_info['WEEK_END_DATE']}\"\n"
        f"sidebar_position: 1\n"
        f"description: \"AI生成の週間サマリー ({week_info['WEEK_START_DATE']}〜{week_info['WEEK_END_DATE']})\"\n"
        f"tags: [\"weekly-report\", \"ai-generated\", \"week-{week_info['WEEK_NUMBER']}\"]\n"
        f"---\n\n"
    )
    out_path.write_text(fm + clean_md, encoding='utf-8')
    print(f"✅ Saved: {out_path}")


def main():
    print("🚀 Gemini-based Weekly Report Generator")
    # Accept both env names to be flexible
    api_key = os.getenv('GEMINI_API_KEY') or os.getenv('GOOGLE_API_KEY')
    if not api_key:
        print("❌ GEMINI_API_KEY / GOOGLE_API_KEY is not set. Aborting.")
        return
    os.environ['GEMINI_API_KEY'] = api_key
    os.environ.setdefault('GOOGLE_API_KEY', api_key)

    base_dir = Path(os.getenv('DOCS_ACTIVITIES_DIR', 'docs/activities'))
    week_start_day = int(os.getenv('WEEK_START_DAY', '1'))
    # Target the week that just finished (use "yesterday" to avoid entering the new week)
    today = datetime.now() - timedelta(days=1)
    week_info = compute_week_info(today, week_start_day)

    year_dir = base_dir / week_info['YEAR']
    week_dir = year_dir / week_info['WEEK_FOLDER']
    print(f"📁 Target week dir: {week_dir}")
    week_data = collect_week_data(week_dir)

    if week_data['total_commits'] == 0 and len(week_data['repos']) == 0:
        print("📝 No week data found. Nothing to generate.")
        return

    prompt = build_weekly_prompt(week_info, week_data)
    ai_resp = call_gemini(prompt)
    if not ai_resp:
        ai_resp = (
            f"<output-report>\n# AI週報 (第{week_info['WEEK_NUMBER']}週)\n\n"
            f"AI生成に失敗しました。週次データは存在します。\n\n</output-report>"
        )

    print("🔍 Extracting content between <output-report> tags...")
    m = re.search(r"<output-report>(.*?)</output-report>", ai_resp, re.DOTALL)
    if m:
        clean = m.group(1).strip()
    else:
        print("⚠️ <output-report> not found. Using raw response.")
        clean = ai_resp.strip()
    if not clean:
        clean = f"# AI週報 (第{week_info['WEEK_NUMBER']}週)\n\n内容が空でした。"

    save_weekly_report(week_dir, week_info, clean)
    print("\n✅ Weekly AI report generated.")


if __name__ == "__main__":
    main()
