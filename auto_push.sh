#!/bin/bash
# optimized_auto_push.sh - 自动拉取远端更新、暂存本地修改、提交并推送

# 配置仓库路径和最小提交间隔（秒）
REPO_PATH="/Users/juan/MyBlog/wangyanwen.github.io"
THRESHOLD=60

cd "$REPO_PATH" || { echo "无法进入仓库目录"; exit 1; }

# 检查是否有未提交的修改，如果有则 stash 起来
if [ -n "$(git status --porcelain)" ]; then
    echo "检测到本地修改，正在暂存 (stash) 这些修改..."
    git stash save "Auto stash before pull"
    STASHED=1
else
    STASHED=0
fi

# 拉取远端更新并进行 rebase
echo "拉取远端最新更新（使用 rebase）..."
if ! git pull --rebase origin "$(git symbolic-ref --short HEAD)"; then
    echo "拉取或 rebase 失败，请手动解决冲突。"
    # 如果之前暂存了，尝试恢复以避免丢失修改
    if [ "$STASHED" -eq 1 ]; then
        echo "恢复暂存的修改..."
        git stash pop
    fi
    exit 1
fi

# 如果之前暂存了修改，恢复暂存内容
if [ "$STASHED" -eq 1 ]; then
    echo "恢复暂存的修改..."
    if ! git stash pop; then
        echo "恢复暂存内容时产生冲突，请手动解决。"
        exit 1
    fi
fi

# 检查上次提交时间，避免过于频繁提交
LAST_COMMIT_TIME=$(git log -1 --format=%ct 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)
TIME_DIFF=$(( CURRENT_TIME - LAST_COMMIT_TIME ))
if [ "$TIME_DIFF" -lt "$THRESHOLD" ]; then
    echo "上次提交距今仅 ${TIME_DIFF}s，低于阈值 ${THRESHOLD}s，跳过自动提交。"
    exit 0
fi

# 检查是否有新的更改需要提交
if [ -z "$(git status --porcelain)" ]; then
    echo "没有检测到更改，跳过提交。"
    exit 0
fi

# 统计更改的文件数，并生成提交信息
NUM_CHANGED_FILES=$(git status --porcelain | wc -l | tr -d ' ')
DEFAULT_MSG="Auto commit at $(date '+%Y-%m-%d %H:%M:%S'): ${NUM_CHANGED_FILES} file(s) changed."
# 支持使用环境变量 CUSTOM_COMMIT_MSG 来自定义提交信息
if [ -n "$CUSTOM_COMMIT_MSG" ]; then
    COMMIT_MSG="$CUSTOM_COMMIT_MSG"
else
    COMMIT_MSG="$DEFAULT_MSG"
fi

echo "提交信息：$COMMIT_MSG"

# 执行添加、提交和推送操作
git add .
git commit -m "$COMMIT_MSG"
git push origin "$(git symbolic-ref --short HEAD)"
