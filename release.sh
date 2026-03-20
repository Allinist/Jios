#!/bin/bash
set -e

PLATFORM=$1
if [ -z "$PLATFORM" ]; then
  PLATFORM="all"
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "🌿 当前分支: $CURRENT_BRANCH"

# 提交未提交代码
if [[ -n $(git status -s) ]]; then
  echo "⚠️ 有未提交代码，正在自动提交..."
  git add .
  git commit -m "chore: auto commit before release"
fi

# 获取最新 tag
git fetch --tags
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"

# 循环生成一个不存在的 tag
while true; do
  PATCH=$((PATCH+1))
  TAG="v$MAJOR.$MINOR.$PATCH"
  if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    break
  fi
done

echo "🚀 发布版本: $TAG"

# 打 tag 并 push 当前分支
git tag "$TAG"
git push origin "$CURRENT_BRANCH"
git push origin "$TAG"
echo "✅ 当前分支提交 + tag 完成"

# 合并到 release
echo "🔀 合并当前分支 $CURRENT_BRANCH 到 release"
git fetch origin
git checkout release
git pull origin release
git merge --no-ff "$CURRENT_BRANCH" -m "chore: merge $CURRENT_BRANCH into release for $TAG"

git push origin release
echo "✅ release 分支更新完成"

echo "🚀 GitHub Actions workflow 将在 release 分支或 tag 上触发构建"
echo "🌐 平台: $PLATFORM (iOS / Android / All)"
echo "📦 Release 将被标记为 latest"

git checkout "$CURRENT_BRANCH"
