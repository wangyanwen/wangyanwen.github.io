#!/bin/bash
# optimized_auto_push.sh - 自动拉取远端更新、提交并推送，并显示通知

# 配置仓库路径和最小提交间隔（秒）
REPO_PATH="/Users/juan/MyBlog/wangyanwen.github.io"
THRESHOLD=60

cd "$REPO_PATH" || { osascript -e 'display notification "无法进入仓库目录" with title "AutoPush Error"'; exit 1; }

# 检查是否有未提交的修改，如果有则暂存起来
if [ -n "$(git status --porcelain)" ]; then
    echo "检测到本地修改，暂存中..."
    git stash save "Auto stash before pull"
    STASHED=1
else
    STASHED=0
fi

# 拉取远端更新并进行 rebase
echo "拉取远端更新..."
if ! git pull --rebase origin "$(git symbolic-ref --short HEAD)"; then
    osascript -e 'display notification "拉取远端更新失败，请手动解决冲突" with title "AutoPush Error"'
    # 如果之前暂存了，尝试恢复以避免丢失修改
    if [ "$STASHED" -eq 1 ]; then
        git stash pop
    fi
    exit 1
fi

# 如果之前暂存了修改，恢复暂存内容
if [ "$STASHED" -eq 1 ]; then
    echo "恢复暂存的修改..."
    if ! git stash pop; then
        osascript -e 'display notification "恢复暂存内容时产生冲突，请手动解决" with title "AutoPush Warning"'
        exit 1
    fi
fi

# 检查上次提交时间，防止过于频繁提交
LAST_COMMIT_TIME=$(git log -1 --format=%ct 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)
TIME_DIFF=$(( CURRENT_TIME - LAST_COMMIT_TIME ))
if [ "$TIME_DIFF" -lt "$THRESHOLD" ]; then
    echo "上次提交距今 ${TIME_DIFF}s，低于阈值 ${THRESHOLD}s，跳过提交。"
    osascript -e 'display notification "提交间隔不足，已跳过自动提交" with title "AutoPush Info"'
    exit 0
fi

# 检查是否有未提交更改
if [ -z "$(git status --porcelain)" ]; then
    echo "没有检测到新的更改，跳过提交。"
    osascript -e 'display notification "未检测到更改" with title "AutoPush Info"'
    exit 0
fi

# 统计更改的文件数，并生成提交信息
NUM_CHANGED_FILES=$(git status --porcelain | wc -l | tr -d ' ')
DEFAULT_MSG="Auto commit at $(date '+%Y-%m-%d %H:%M:%S'): ${NUM_CHANGED_FILES} file(s) changed."
if [ -n "$CUSTOM_COMMIT_MSG" ]; then
    COMMIT_MSG="$CUSTOM_COMMIT_MSG"
else
    COMMIT_MSG="$DEFAULT_MSG"
fi

echo "提交信息：$COMMIT_MSG"

git add .
if git commit -m "$COMMIT_MSG"; then
    if git push origin "$(git symbolic-ref --short HEAD)"; then
        osascript -e 'display notification "自动提交与推送成功" with title "AutoPush Success"'
    else
        osascript -e 'display notification "推送到远端失败" with title "AutoPush Error"'
    fi
else
    osascript -e 'display notification "提交失败，可能没有检测到更改" with title "AutoPush Info"'
fi
