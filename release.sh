#!/bin/bash

set -e

# ========= 参数 =========
VERSION=$1
PLATFORM=$2   # ios / android / all

# ========= 默认值 =========
if [ -z "$VERSION" ]; then
  VERSION="0.0.1"
fi

if [ -z "$PLATFORM" ]; then
  PLATFORM="all"
fi

# ========= 平台校验 =========
if [[ "$PLATFORM" != "ios" && "$PLATFORM" != "android" && "$PLATFORM" != "all" ]]; then
  echo "❌ 平台必须是 ios / android / all"
  exit 1
fi

# ========= 当前分支 =========
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "🌿 当前分支: $CURRENT_BRANCH"

# ========= 提交未提交代码 =========
if [[ -n $(git status -s) ]]; then
  echo "⚠️ 有未提交代码，正在自动提交..."
  git add .
  git commit -m "chore: auto commit before release v$VERSION-$PLATFORM"
fi

# ========= 合并到 release =========
echo "🔀 合并当前分支 $CURRENT_BRANCH 到 release 分支"
git fetch origin
git checkout release
git pull origin release
git merge --no-ff "$CURRENT_BRANCH" -m "chore: merge $CURRENT_BRANCH into release for v$VERSION-$PLATFORM"

# ========= 生成 tag =========
TAG="v$VERSION"
if [[ "$PLATFORM" != "all" ]]; then
  TAG="$TAG-$PLATFORM"
fi

echo "🚀 发布版本: $TAG"

# ========= 防止重复 tag =========
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "❌ Tag 已存在: $TAG"
  exit 1
fi

# ========= 打 tag =========
git tag "$TAG"

# ========= 推送 release 分支和 tag =========
git push origin release
git push origin "$TAG"

# ========= 更新 GitHub Release latest =========
echo "✨ GitHub Release latest will be updated via workflow"

echo "✅ 发布完成！GitHub Actions 已触发构建"