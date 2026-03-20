#!/bin/bash

set -e

# ========= 参数 =========
PLATFORM=$1   # ios / android / all
if [ -z "$PLATFORM" ]; then
  PLATFORM="all"
fi

# ========= 当前分支 =========
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "🌿 当前分支: $CURRENT_BRANCH"

# ========= 提交当前分支未提交代码 =========
if [[ -n $(git status -s) ]]; then
  echo "⚠️ 有未提交代码，正在自动提交..."
  git add .
  git commit -m "chore: auto commit before release"
fi

# ========= 自动生成 tag =========
# 获取最新 tag 的版本号
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
PATCH=$((PATCH+1))
TAG="v$MAJOR.$MINOR.$PATCH"
echo "🚀 发布版本: $TAG"

# ========= 打 tag =========
git tag "$TAG"

# ========= push 当前分支和 tag =========
git push origin "$CURRENT_BRANCH"
git push origin "$TAG"

# ========= 合并到 release 分支 =========
echo "🔀 合并当前分支 $CURRENT_BRANCH 到 release"
git fetch origin
git checkout release
git pull origin release
git merge --no-ff "$CURRENT_BRANCH" -m "chore: merge $CURRENT_BRANCH into release for $TAG"

# ========= push release =========
git push origin release

echo "✅ 发布完成！GitHub Actions 将触发自动构建 (平台: $PLATFORM)"
echo "👉 Release 将被标记为 latest"