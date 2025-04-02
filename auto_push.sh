#!/bin/bash
# auto_push.sh
# 请将 REPO_PATH 替换为你的 Git 仓库路径
REPO_PATH="/Users/juan/MyBlog/wangyanwen.github.io"
# 设置最小间隔（秒），小于该间隔则跳过提交
THRESHOLD=60

cd "$REPO_PATH" || { echo "无法进入仓库目录"; exit 1; }

# 获取上次 commit 的时间（Unix 时间戳）
LAST_COMMIT_TIME=$(git log -1 --format=%ct 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)
TIME_DIFF=$(( CURRENT_TIME - LAST_COMMIT_TIME ))

if [ "$TIME_DIFF" -lt "$THRESHOLD" ]; then
    echo "上次提交距今仅 ${TIME_DIFF}s，低于阈值 ${THRESHOLD}s，跳过自动提交。"
    exit 0
fi

# 检查是否有未提交的更改
if [ -z "$(git status --porcelain)" ]; then
    echo "没有检测到更改，跳过提交。"
    exit 0
fi

# 自定义 commit 信息逻辑：
# 统计更改的文件数，并生成带有当前时间的提交信息
NUM_CHANGED_FILES=$(git status --porcelain | wc -l | tr -d ' ')
DEFAULT_MSG="Auto commit at $(date '+%Y-%m-%d %H:%M:%S'): ${NUM_CHANGED_FILES} file(s) changed."
# 如果环境变量 CUSTOM_COMMIT_MSG 有设置，则优先使用它
if [ -n "$CUSTOM_COMMIT_MSG" ]; then
    COMMIT_MSG="$CUSTOM_COMMIT_MSG"
else
    COMMIT_MSG="$DEFAULT_MSG"
fi

echo "提交信息：$COMMIT_MSG"

# 执行 Git 操作：添加、提交、推送
git add .
git commit -m "$COMMIT_MSG"
git push origin "$(git symbolic-ref --short HEAD)"

