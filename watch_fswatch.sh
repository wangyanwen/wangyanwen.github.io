#!/bin/bash
# watch_fswatch.sh
# 请将 REPO_PATH 替换为你的 Git 仓库路径
REPO_PATH="/Users/juan/MyBlog/wangyanwen.github.io"
cd "$REPO_PATH" || { echo "无法进入仓库目录"; exit 1; }

# 监控整个仓库目录（可根据需要修改匹配模式，此处监控所有文件变化）
fswatch -o . | while read -r event_count; do
    echo "检测到变化($event_count)，等待稳定后执行自动更新..."
    # 调用自动提交脚本
    /Users/juan/MyBlog/wangyanwen.github.io/auto_push.sh
done

