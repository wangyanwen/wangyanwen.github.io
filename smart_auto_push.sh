#!/bin/bash
# smart_auto_push.sh - 智能自动拉取、提交并推送，并显示Mac通知

# 配置仓库路径和最小提交间隔（秒）
REPO_PATH="/Users/juan/MyBlog/wangyanwen.github.io"
THRESHOLD=60  # 最小提交间隔（秒）

cd "$REPO_PATH" || {
    osascript -e 'display notification "无法进入仓库目录" with title "AutoPush Error"'
    exit 1
}

# 先检测是否有本地未提交更改
HAS_CHANGES=0
if [ -n "$(git status --porcelain)" ]; then
    HAS_CHANGES=1
fi

# 检查远端是否有更新
git fetch origin

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

NEED_PULL=0
if [ "$LOCAL" = "$REMOTE" ]; then
    echo "本地已是最新，无需pull。"
elif [ "$LOCAL" = "$BASE" ]; then
    echo "远端有新提交，准备pull。"
    NEED_PULL=1
else
    echo "本地提交领先远端，或者产生分叉，需要手动处理。"
    osascript -e 'display notification "本地与远端分叉，请手动处理" with title "AutoPush Warning"'
    exit 1
fi

# 如果远端有更新，需要pull --rebase --autostash
if [ "$NEED_PULL" -eq 1 ]; then
    echo "拉取远端更新..."
    if ! git pull --rebase --autostash origin "$(git symbolic-ref --short HEAD)"; then
        osascript -e 'display notification "拉取远端更新失败，请手动解决冲突" with title "AutoPush Error"'
        exit 1
    fi
fi

# 检查上次提交时间，防止频繁提交
LAST_COMMIT_TIME=$(git log -1 --format=%ct 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)
TIME_DIFF=$(( CURRENT_TIME - LAST_COMMIT_TIME ))
if [ "$TIME_DIFF" -lt "$THRESHOLD" ]; then
    echo "上次提交距今 ${TIME_DIFF}s，低于阈值 ${THRESHOLD}s，跳过提交。"
    osascript -e 'display notification "提交间隔不足，已跳过自动提交" with title "AutoPush Info"'
    exit 0
fi

# 再次检测是否有更改需要提交
if [ "$HAS_CHANGES" -eq 0 ]; then
    echo "没有检测到新的本地更改，跳过提交。"
    osascript -e 'display notification "未检测到更改" with title "AutoPush Info"'
    exit 0
fi

# 准备提交
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
        osascript -e 'display notification "推送到远端失败，请手动检查" with title "AutoPush Error"'
    fi
else
    osascript -e 'display notification "提交失败，可能没有实际变更" with title "AutoPush Info"'
fi

