#!/usr/bin/env bash
# 交互式安装本仓库的 skill。
# 全局安装：软链接到 ~/.claude/skills/，仓库内修改即时生效。
# 项目安装：复制到 <项目>/.claude/skills/，已存在则跳过，需手动删除旧副本后重新运行以同步。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

skills=()
for dir in "$REPO_DIR"/*/; do
  [ -f "${dir}SKILL.md" ] && skills+=("$(basename "$dir")")
done

if [ ${#skills[@]} -eq 0 ]; then
  echo "仓库中没有找到包含 SKILL.md 的子目录。"
  exit 1
fi

echo "可安装的 skill："
for i in "${!skills[@]}"; do
  echo "  $((i + 1))) ${skills[$i]}"
done
read -r -p "输入编号（空格分隔），a 表示全选：" choice

selected=()
if [ "$choice" = "a" ]; then
  selected=("${skills[@]}")
else
  for n in $choice; do
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le ${#skills[@]} ]; then
      selected+=("${skills[$((n - 1))]}")
    else
      echo "无效编号：$n"
      exit 1
    fi
  done
fi

if [ ${#selected[@]} -eq 0 ]; then
  echo "未选择任何 skill。"
  exit 1
fi

echo "安装位置："
echo "  1) 全局（~/.claude/skills，软链接）"
echo "  2) 项目（<项目>/.claude/skills，复制）"
read -r -p "选择 1 或 2：" scope

case "$scope" in
  1)
    mode="link"
    target="$HOME/.claude/skills"
    ;;
  2)
    mode="copy"
    read -r -p "项目路径：" project
    project="${project/#\~/$HOME}"
    if [ ! -d "$project" ]; then
      echo "目录不存在：$project"
      exit 1
    fi
    target="$(cd "$project" && pwd)/.claude/skills"
    ;;
  *)
    echo "无效选择：$scope"
    exit 1
    ;;
esac

mkdir -p "$target"

for name in "${selected[@]}"; do
  src="$REPO_DIR/$name"
  dest="$target/$name"

  if [ "$mode" = "link" ]; then
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      echo "已安装，跳过：$name"
    elif [ -e "$dest" ] || [ -L "$dest" ]; then
      echo "目标已存在且不是本仓库的软链接，跳过：$dest"
    else
      ln -s "$src" "$dest"
      echo "已链接：$dest -> $src"
    fi
  else
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      echo "目标已存在，跳过：${dest}（如需更新，请先手动删除该目录后重新运行）"
    else
      cp -R "$src" "$dest"
      echo "已复制：$dest"
    fi
  fi
done
