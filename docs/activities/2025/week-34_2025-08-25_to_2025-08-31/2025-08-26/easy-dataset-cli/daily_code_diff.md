# 💻 Daily Code Changes

```diff
diff --git a/easy_dataset_cli/prompts/qa_generation.md b/easy_dataset_cli/prompts/qa_generation.md
index e51c26f..511bbe8 100644
--- a/easy_dataset_cli/prompts/qa_generation.md
+++ b/easy_dataset_cli/prompts/qa_generation.md
@@ -9,6 +9,13 @@
 4. 質問のスタイルと複雑さは、「目標とする読者」の視点に合わせてください。
 5. 回答のスタイル、トーン、詳細さは、「目標とする体裁」に合わせてください。
 
+## QAペア作成における重要なルール:
+- **代名詞の使用禁止**: 質問と回答では、「彼」「彼女」「それ」「これ」「その人」「その会社」などの代名詞を使用せず、具体的な名詞や固有名詞を使用してください
+- **文脈の自己完結性**: 各QAペアは、そのペア単体で意味が完全に理解できるようにしてください
+- **具体的な言及**: 人物、物事、概念について言及する際は、必ず具体的な名前や説明を含めてください
+- **省略の回避**: 「前述の」「上記の」「先ほどの」「該当する」などの他の箇所を参照する表現は避けてください
+- **文章内情報の厳守**: 与えられた文章に記載されている情報のみを使用し、推測や外部知識を加えないでください
+
 ## 目標とする体裁:
 {genre_title}
 {genre_description}
@@ -37,8 +44,8 @@
 <Answer>ミトコンドリアの主な機能は、細胞のエネルギー通貨であるアデノシン三リン酸（ATP）の大部分を生成することです。</Answer>
 </Pair>
 <Pair>
-<Question>ATPは細胞内でどのように利用されますか？</Question>
-<Answer>ATPは細胞内の様々な化学反応のエネルギー源として利用されます。</Answer>
+<Question>田中教授が開発した新しい治療法はどのような特徴を持っていますか？</Question>
+<Answer>田中教授が開発した新しい治療法は、従来の化学療法と比較して副作用が少なく、治療効果が30%向上するという特徴を持っています。</Answer>
 </Pair>
 </QAPairs>
 \```
diff --git a/easy_dataset_cli/prompts/qa_generation_with_fulltext.md b/easy_dataset_cli/prompts/qa_generation_with_fulltext.md
index a41ae1f..4baefd9 100644
--- a/easy_dataset_cli/prompts/qa_generation_with_fulltext.md
+++ b/easy_dataset_cli/prompts/qa_generation_with_fulltext.md
@@ -10,6 +10,12 @@
 5. 回答のスタイル、トーン、詳細さは、「目標とする体裁」に合わせてください。
 6. **重要**: 質問と回答は主に「チャンク」の内容に基づいて作成し、「全文」は文脈理解のための補助情報として活用してください。
 
+## QAペア作成における重要なルール:
+- **代名詞の使用禁止**: 質問と回答では、「彼」「彼女」「それ」「これ」「その人」などの代名詞を使用せず、具体的な名詞や固有名詞を使用してください
+- **文脈の自己完結性**: 各QAペアは、そのペア単体で意味が完全に理解できるようにしてください
+- **具体的な言及**: 人物、物事、概念について言及する際は、必ず具体的な名前や説明を含めてください
+- **省略の回避**: 「前述の」「上記の」「先ほどの」などの他の箇所を参照する表現は避けてください
+
 ## 目標とする体裁:
 {genre_title}
 {genre_description}
@@ -43,8 +49,8 @@
 <Answer>ミトコンドリアの主な機能は、細胞のエネルギー通貨であるアデノシン三リン酸（ATP）の大部分を生成することです。</Answer>
 </Pair>
 <Pair>
-<Question>ATPは細胞内でどのように利用されますか？</Question>
-<Answer>ATPは細胞内の様々な化学反応のエネルギー源として利用されます。</Answer>
+<Question>田中博士が発見した新しい酵素の名前は何ですか？</Question>
+<Answer>田中博士が発見した新しい酵素の名前はプロテアーゼXです。</Answer>
 </Pair>
 </QAPairs>
 \```
diff --git a/easy_dataset_cli/prompts/qa_generation_with_thinking.md b/easy_dataset_cli/prompts/qa_generation_with_thinking.md
index 2bb04fe..45a1a7d 100644
--- a/easy_dataset_cli/prompts/qa_generation_with_thinking.md
+++ b/easy_dataset_cli/prompts/qa_generation_with_thinking.md
@@ -11,6 +11,13 @@
 6. **重要**: 質問と回答は主に「チャンク」の内容に基づいて作成し、「全文」は文脈理解のための補助情報として活用してください。
 7. 各Q&Aペアには、思考プロセスを明示的に記述してください。
 
+## QAペア作成における重要なルール:
+- **代名詞の使用禁止**: 質問と回答では、「彼」「彼女」「それ」「これ」「その人」などの代名詞を使用せず、具体的な名詞や固有名詞を使用してください
+- **文脈の自己完結性**: 各QAペアは、そのペア単体で意味が完全に理解できるようにしてください
+- **具体的な言及**: 人物、物事、概念について言及する際は、必ず具体的な名前や説明を含めてください
+- **省略の回避**: 「前述の」「上記の」「先ほどの」などの他の箇所を参照する表現は避けてください
+- **思考フロー内でも自己完結**: `<think>`タグ内の思考プロセスでも、代名詞や省略表現を使わず、具体的な名詞を使用してください
+
 ## 目標とする体裁:
 {genre_title}
 {genre_description}
@@ -33,19 +40,21 @@
 **必ず**、ルート要素が `<QAPairs>` である単一の有効なXMLとして応答してください。XML以外の説明文は一切含めないでください。
 各Q&Aペアは `<Pair>` タグで囲み、その中に `<Question>` と `<Answer>` タグを含めてください。
 
-**重要**: 回答は必ず`<Answer><think>思考フロー...</think>回答...</Answer>`のように、思考フローを`<think>`タグで囲み、回答本文の直前に含めてください。
-回答文に改行を含めず、一行で記述してください。
+**重要**: 
+- 回答は必ず`<Answer><think>思考フロー...</think>回答...</Answer>`のように、思考フローを`<think>`タグで囲み、回答本文の直前に含めてください。
+- XMLの特殊文字（&, <, >, ", '）は適切にエスケープしてください（例：& → &amp;, < → &lt;）。
+- 回答文に改行を含めず、一行で記述してください。
 
 ## 出力例:
 \```xml
 <QAPairs>
 <Pair>
 <Question>ミトコンドリアの主な機能は何ですか？</Question>
-<Answer><think>ミトコンドリアは細胞の「発電所」として知られており、細胞呼吸を通じて栄養素からエネルギーを産生する。その主な産物がATPであり、細胞のあらゆる生命活動のエネルギー源となる。</think>ミトコンドリアの主な機能は、細胞のエネルギー通貨であるアデノシン三リン酸（ATP）の大部分を生成することです。</Answer>
+<Answer><think>ミトコンドリアは細胞の「発電所」として知られており、ミトコンドリアは細胞呼吸を通じて栄養素からエネルギーを産生する。ミトコンドリアの主な産物がATPであり、ATPは細胞のあらゆる生命活動のエネルギー源となる。</think>ミトコンドリアの主な機能は、細胞のエネルギー通貨であるアデノシン三リン酸（ATP）の大部分を生成することです。</Answer>
 </Pair>
 <Pair>
-<Question>ATPは細胞内でどのように利用されますか？</Question>
-<Answer><think>ATPはアデノシン三リン酸であり、リン酸結合の加水分解によってエネルギーを放出する。このエネルギーはタンパク質の合成、物質の輸送、細胞分裂など、細胞内のあらゆるエネルギー需要に供給される。</think>ATPは細胞内の様々な化学反応のエネルギー源として利用されます。</Answer>
+<Question>田中博士が発見した新しい酵素はどのような特徴を持っていますか？</Question>
+<Answer><think>田中博士が発見したプロテアーゼXという酵素は、従来のプロテアーゼとは異なる基質特異性を示す。プロテアーゼXは高温環境でも安定して機能し、産業応用の可能性が高い酵素である。</think>田中博士が発見したプロテアーゼXは、高温環境でも安定して機能し、従来の酵素にはない独特な基質特異性を持つ画期的な酵素です。</Answer>
 </Pair>
 </QAPairs>
 \```
diff --git a/example/scripts/orin.bat b/example/scripts/orin.bat
index cb3391b..01e62f9 100644
--- a/example/scripts/orin.bat
+++ b/example/scripts/orin.bat
@@ -1,5 +1,5 @@
-uv run easy-dataset create-ga .\example\input\documents\Touhou_Chireiden.md --output-dir .\example\output\Touhou_Chireiden --num-ga-pairs 10
+uv run easy-dataset create-ga .\example\input\documents\Touhou_Chireiden.md --output-dir .\example\output\Touhou_Chireiden10 --num-ga-pairs 3
 
-uv run easy-dataset generate .\example\input\documents\Touhou_Chireiden.md  --ga-file .\example\output\Touhou_Chireiden\ga\ga_definitions.xml --output-dir .\example\output\Touhou_Chireiden\ --chunk-size 3000 --use-fulltext --append
+uv run easy-dataset generate .\example\input\documents\Touhou_Chireiden.md  --ga-file .\example\output\Touhou_Chireiden10\ga\ga_definitions.xml --output-dir .\example\output\Touhou_Chireiden10\ --chunk-size 1000 --use-fulltext --append
 
-uv run easy-dataset convert-to-alpaca .\example\output\Touhou_Chireiden\qa --output-file example\output\Touhou_Chireiden\dataset.json --upload-hf --hf-repo-name MakiAi/Orin-Instruct-Alpaca-JP-v7
+uv run easy-dataset convert-to-alpaca .\example\output\Touhou_Chireiden10\qa --output-file example\output\Touhou_Chireiden10\dataset.json --upload-hf --hf-repo-name MakiAi/Orin-Instruct-Alpaca-JP-v10
```
