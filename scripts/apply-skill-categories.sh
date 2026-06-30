#!/usr/bin/env bash
# ============================================================
#  apply-skill-categories.sh
#  批量为 skills/*/_meta.json 补 category / domain / tags 字段
#  （已存在的字段不会被覆盖）
#
#  用法：bash scripts/apply-skill-categories.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$ROOT/skills"

# slug → category 映射（基于 docs/skill-metadata-spec.md）
declare -A META=(
  # code 域
  ["architecture-patterns"]="code.architecture|code|architecture,backend,DDD,clean"
  ["code-review"]="code.review|code|review,quality"
  ["refactor-safely"]="code.review|code|refactor,safe"
  ["requesting-code-review"]="code.review|code|review,workflow"
  ["simplify"]="code.review|code|simplify,quality"
  ["verification-before-completion"]="code.testing|code|verify,completion"
  ["security-auditor"]="code.security|code|security,audit"
  ["dispatching-parallel-agents"]="code.ai-agent|code|parallel,agent,dispatch"
  ["subagent-driven-development"]="code.ai-agent|code|SDD,agent,subagent"
  ["prompt-engineering-expert"]="code.ai-agent|code|prompt,LLM"
  ["self-improving"]="code.ai-agent|code|self-improve,learning"
  ["superdesign"]="code.frontend|code|design,UI"
  ["ui-ux-pro-max"]="code.frontend|code|UI,UX"
  ["using-git-worktrees"]="code.tooling|code|git,worktree"

  # novel 域
  ["inkos"]="novel.creation|novel|创作,系统"
  ["novel-generator"]="novel.creation|novel|爽文,生成"
  ["story-cog"]="novel.creation|novel|creative,writing"
  ["humanizer"]="novel.polish|novel|humanizer,AI痕迹"
  ["fanqie"]="novel.publish|novel|番茄,平台"
  ["fanqie-novel-auto-publish"]="novel.publish|novel|番茄,自动发布"
  ["web-novel-publishing-readiness-and-quality-check-skill"]="novel.publish|novel|发布,质检"
  ["novel-to-drama-script"]="novel.transform|novel|短剧,剧本"

  # shared 域
  ["brainstorming"]="shared.planning|shared|头脑风暴,设计"
  ["writing-plans"]="shared.planning|shared|plan,writing"
  ["executing-plans"]="shared.planning|shared|plan,execute"
  ["planning-with-files"]="shared.planning|shared|plan,files"
  ["project-planner"]="shared.planning|shared|plan,project"
  ["deep-research"]="shared.research|shared|研究,搜索"
  ["playwright"]="shared.workflow|shared|browser,automation"
  ["find-skills"]="shared.workflow|shared|skill,discover"
  ["skill-vetter"]="shared.workflow|shared|skill,vet,security"
  ["auto-updater"]="shared.workflow|shared|update,cron"
  ["free-ride"]="shared.workflow|shared|model,free"
  ["summarize"]="shared.workflow|shared|summarize"
  ["edge-tts"]="shared.media|shared|TTS,voice"
  ["pdf"]="shared.docs|shared|pdf,document"
  ["word-docx"]="shared.docs|shared|word,document"
  ["excel-xlsx"]="shared.docs|shared|excel,spreadsheet"
  ["human-writing"]="shared.docs|shared|writing,human"
)

# 检查 _meta.json 是否有指定字段
has_field() {
  local file="$1" field="$2"
  grep -qE "\"${field}\"\s*:" "$file" 2>/dev/null
}

# 注入字段
inject_field() {
  local file="$1" field="$2" value="$3" type="$4"
  if has_field "$file" "$field"; then
    echo "  [skip] $field already exists"
    return 0
  fi

  # 找到最后一个 } 之前的逗号位置
  if grep -qE "^\s*[\"a-zA-Z_].*[,]\s*$" "$file"; then
    # 文件最后有逗号，直接在末尾加
    sed -i "$ s/^\(\s*\)\([\"a-zA-Z_].*\),$/\1\2,/" "$file"
  fi

  # 在最后 } 之前插入新字段
  if [ "$type" = "string" ]; then
    # 转义双引号
    local escaped
    escaped=$(echo "$value" | sed 's/"/\\"/g')
    sed -i "s/^\(\s*\)\(}\)\s*$/\1  \"${field}\": \"${escaped}\",\n\1\2/" "$file"
  elif [ "$type" = "array" ]; then
    # value 格式: "a,b,c"
    local arr=""
    IFS=',' read -ra parts <<< "$value"
    for p in "${parts[@]}"; do
      arr+="\"$p\", "
    done
    arr="${arr%, }"
    sed -i "s/^\(\s*\)\(}\)\s*$/\1  \"${field}\": [${arr}],\n\1\2/" "$file"
  fi
}

# 移除最后一个字段的尾随逗号
cleanup_trailing_comma() {
  local file="$1"
  # 找到最后一个 , 后面紧跟着 " 字段": 的模式，删除那个逗号
  python3 -c "
import json, sys
p='$file'
with open(p,'r',encoding='utf-8') as f: data=f.read()
try:
    obj=json.loads(data)
    with open(p,'w',encoding='utf-8') as f: json.dump(obj,f,ensure_ascii=False,indent=2)
    print('  [json-fixed]',p)
except Exception as e:
    print('  [json-skip]',p,e)
" 2>/dev/null || true
}

count_updated=0
count_skipped=0
count_missing_meta=0

for dir in "$SKILLS_DIR"/*/; do
  slug=$(basename "$dir")
  meta_file="$dir/_meta.json"
  [ -f "$meta_file" ] || { count_missing_meta=$((count_missing_meta+1)); continue; }

  if [ -z "${META[$slug]:-}" ]; then
    count_skipped=$((count_skipped+1))
    continue
  fi

  IFS='|' read -r cat_id domain tags <<< "${META[$slug]}"
  echo "→ $slug [$cat_id]"

  inject_field "$meta_file" "category" "$cat_id" "string"
  inject_field "$meta_file" "domain" "$domain" "string"
  inject_field "$meta_file" "tags" "$tags" "array"

  # JSON 格式化修复
  cleanup_trailing_comma "$meta_file"
  count_updated=$((count_updated+1))
done

echo ""
echo "✅ 完成"
echo "  - 已补全 $count_updated 个 skill"
echo "  - 跳过 (无映射): $count_skipped 个"
echo "  - 无 _meta.json: $count_missing_meta 个"
echo ""
echo "下一步：bash scripts/gen-skill-index.sh 重新生成 INDEX.md"
