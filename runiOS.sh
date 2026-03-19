#!/bin/bash
# DayMaster iOS 快速调试脚本
# 用法: ./runiOS.sh <device_id或名称>

set -e

# ----------------------------
# 1. 配置 CocoaPods 本地路径
# ----------------------------
COCOAPODS_PATH="/Users/user/Projects/SDKs/CocoaPods-1.15.2/bin"
export PATH="$COCOAPODS_PATH:$PATH"

# ----------------------------
# 2. 设置 Flutter iOS 目录
# ----------------------------
PROJECT_ROOT="$(pwd)"
IOS_DIR="$PROJECT_ROOT/ios"

cd "$IOS_DIR" || exit 1

# ----------------------------
# 3. 安装依赖
# ----------------------------
# pod cache clean --all

echo "==> Installing pods..."
pod install || {
    echo "Error: pod install failed"
    exit 1
}

# ----------------------------
# 4. 返回 Flutter 根目录并运行
# ----------------------------
cd "$PROJECT_ROOT" || exit 1

echo "==> Fetching Flutter packages..."
flutter pub get

DEVICE="$1"
if [ -z "$DEVICE" ]; then
    echo "==> No device specified. Using default."
    flutter run
else
    echo "==> Launching on device $DEVICE"
    flutter run -d "$DEVICE"
fi
