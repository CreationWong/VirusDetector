#!/bin/bash
# Virus Detector — 扩展打包脚本 (Bash)
# 用法: bash scripts/package.sh [输出路径]
# 默认输出: _dist/VirusDetector.zip

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT="${1:-$PROJECT_DIR/_dist/VirusDetector.zip}"

# 确保输出目录存在
mkdir -p "$(dirname "$OUTPUT")"

# 用 git archive 从当前 HEAD 创建 zip，排除开发文件
# 自动保留完整目录结构
git archive --format=zip -o "$OUTPUT" HEAD -- \
  manifest.json LICENSE \
  icons/ background/ content/ popup/ warning/ utils/ \
  ':(exclude).gitignore' \
  ':(exclude).vscode/*' \
  ':(exclude)README.md'

echo "✅ 打包完成: $(du -h "$OUTPUT" | cut -f1) — $OUTPUT"
echo "   文件数: $(unzip -l "$OUTPUT" | tail -1 | awk '{print $2}')"
