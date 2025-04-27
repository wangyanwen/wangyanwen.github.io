+++
date = '2025-04-02T18:04:19+02:00'
draft = false
title = '自动commit和push的脚本'
+++

**简化操作，不再纠结全自动，编写完后就手动点击autopush脚本实现提交。**

你可以用 Automator 或 AppleScript 制作一个桌面应用，当你点击它时自动运行 autopush 脚本。这是一种比较优雅且直观的方式。下面介绍两种方案：
<!--more-->

---

### 方案 1：使用 Automator 制作“应用程序”

1. 打开 **Automator**（在“应用程序”中找到 Automator）。
    
2. 选择“**新建文稿**”，然后选择“**应用程序**”类型。
    
3. 在左侧搜索栏中输入“**运行 Shell 脚本**”，将该操作拖到右侧工作区。
    
4. 在 Shell 脚本编辑区域中输入：
    
    ```bash
    /path/to/auto_push.sh
    ```
    
    请将 `/path/to/auto_push.sh` 替换为你的实际脚本路径。如果脚本需要特定环境变量，也可以在这里进行设置。
    
5. 保存这个应用程序，例如命名为 **AutoPush.app**，并放到桌面上。
    
6. 每次点击桌面上的 AutoPush.app 就会执行你的 autopush 脚本。
    

---

### 方案 2：使用 AppleScript 制作桌面快捷方式

1. 打开 **Script Editor**（脚本编辑器）。
    
2. 输入以下 AppleScript 代码：
    
    ```applescript
    do shell script "/path/to/auto_push.sh"
    display notification \"提交成功！\" with title \"AutoPush\""
    ```
    
    这样执行后，会弹出系统通知。记得把 `/path/to/auto_push.sh` 替换成你的实际路径。
    
3. 从“文件”菜单中选择“导出…”，格式选择“应用程序”，保存到桌面。
    
4. 这样你就有一个桌面图标，双击即可运行脚本并弹出提示。
    

---

这两种方式都能简化操作，让你只需点击桌面图标即可触发自动提交，非常适合需要手动执行但又希望操作简便的场景。选择你喜欢的方案试试吧！

因为经常会报“恢复暂存内容时产生冲突，请手动解决”，将脚本上传并请教小助手如何优化这个脚本

然后，哈哈，小助手就乱讲了，先是不准确的内容：

以下是你脚本的内容（我刚从文件里提取的）：
```
#!/bin/bash
cd "$(dirname "$0")"
git add .
git stash
git pull
git stash pop
git add .
git commit -m "auto push"
git push
```
我指出来并贴上正确内容后，总算开始能够回答了。

经过几轮对答，最后就是下面的优化脚本：
```

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
```

~~你可以在自动提交脚本中加入 macOS 的通知命令，这样每次执行时就能在桌面上弹出提示信息，让你直观地知道脚本的执行状态。下面提供一种优化方案，在 auto_push.sh 脚本中利用 osascript 显示通知：~~

~~---~~

### ~~示例：优化后的 auto_push.sh~~

```bash
#!/bin/bash
# optimized_auto_push.sh - 自动拉取远端更新、提交并推送，并显示通知

# 配置仓库路径和最小提交间隔（秒）
REPO_PATH="/path/to/your/repo"
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
        echo "恢复暂存的修改..."
        if ! git stash pop; then
            osascript -e 'display notification "恢复暂存内容时产生冲突，请手动解决" with title "AutoPush Warning"'
            exit 1
        fi
    fi
    exit 1
fi

<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes
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
```

~~---~~

### ~~脚本说明~~

1. ~~**加入通知**~~  
    ~~每个关键步骤后使用 `osascript -e 'display notification "消息内容" with title "标题"'` 来显示提示信息。例如：~~
    
    - ~~无法进入仓库目录时显示错误通知。~~
        
    - ~~拉取更新失败、恢复暂存失败时显示错误或警告通知。~~
        
    - ~~成功提交和推送后显示成功通知。~~
        
2. ~~**优化执行流程**~~
    
    - ~~如果工作区有未提交更改，则先 stash，执行 rebase 后恢复 stash，降低冲突风险。~~
        
    - ~~使用 `git pull --rebase` 同步远端更新。~~
        
    - ~~检查上次提交时间，避免过于频繁的自动提交。~~
        
3. ~~**自定义提交信息**~~  
    ~~根据更改的文件数量和当前时间生成默认提交信息，同时支持通过环境变量 `CUSTOM_COMMIT_MSG` 自定义提交信息。~~
    

~~---~~

### ~~使用方法~~

1. ~~**保存脚本**~~  
    ~~将上面脚本保存为 `optimized_auto_push.sh` 并替换路径。~~
    
2. ~~**赋予执行权限**~~
    
    ```bash
    chmod +x optimized_auto_push.sh
    ```
    
3. ~~**在桌面创建快捷方式**~~  
    ~~你可以使用 Automator 创建应用程序或者直接创建一个 `.command` 文件（参考前面的回答），双击即可执行该脚本，并弹出 macOS 通知显示执行结果。~~
    

~~这样，你就可以在手动点击触发自动提交脚本时，通过桌面提示消息及时了解脚本运行状态，实现一个更优雅的体验。~~

~~下面提供一个基于 fswatch 的自动更新方案示例，满足以下需求：~~

1. ~~**在 commit 前判断上次提交时间**~~  
    ~~如果上次提交距离当前时间太近（例如小于 60 秒），则跳过这次自动提交，防止频繁提交。~~
    
2. ~~**在脚本中增加对 commit 信息的自定义逻辑**~~  
    ~~根据变化的文件数量或当前时间自动生成提交信息，也支持通过环境变量覆盖默认信息。~~
    
3. ~~**让这个监控脚本始终运行**~~  
    ~~你可以直接在后台运行该脚本，也可以将其封装成 launchd 服务。~~
    

~~继续完善：~~  
~~问题：“上面方案可以解决本地自动更新的问题，如果远端更新后，能不能自动pull回本地”~~  
~~chatgpt：~~
1. ~~定时任务（cron 或 launchd）~~
2. ~~扩展现有自动更新脚本~~
3. ~~利用 Webhook 或 CI/CD 系统~~
~~我们无法完全保证冲突绝对不会发生，但可以采取措施降低发生冲突的概率。一种常见方法是在执行自动提交前自动将本地修改暂存（stash），然后先拉取远端最新更新（使用 `git pull --rebase`），待拉取完成后再将暂存的修改恢复（stash pop），这样能够让 rebase 过程在工作区干净的情况下进行，从而减少冲突的可能性。下面给出一个优化后的脚本示例：~~
~~<!--more-->~~

~~下面提供两个脚本示例和一个 launchd 配置文件示例：~~

~~---~~

### ~~脚本 1：自动提交和推送脚本 (auto_push.sh)~~

```bash

#!/bin/bash
# optimized_auto_push.sh - 自动拉取远端更新、暂存本地修改、提交并推送

# 配置仓库路径和最小提交间隔（秒）
REPO_PATH="/path/to/your/repo"
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

```

> ~~**注意：**~~
> 
> ~~- 请确保脚本具有可执行权限：~~
>     
>     ~~```bash~~
>     ~~chmod +x auto_push.sh~~
>     ~~```~~
>     
> ~~- 若无变化时 `git commit` 会返回非零状态，这里直接退出，不报错。~~
>     

~~---~~

### ~~脚本 2：使用 fswatch 监控并触发自动提交 (watch_fswatch.sh)~~

~~下面是一个经过优化的 watch_fswatch 脚本示例，主要改进点包括：~~

1. ~~**日志记录**：将输出写入日志文件，方便排查问题。~~
    
2. ~~**防抖处理**：在检测到变化后增加一定延迟（如 5 秒），确保文件修改稳定后再触发自动提交。~~
    
3. ~~**错误处理**：在切换目录失败时及时退出，确保脚本不会在错误状态下运行。~~
    

~~优化后的脚本如下（请将 `/path/to/your/repo` 和 `/path/to/auto_push.sh` 替换为你的实际路径）：~~

```bash
#!/bin/bash
# optimized_watch_fswatch.sh
# 优化后的 fswatch 监控脚本，用于监控当前目录下所有 .md 文件，
# 当文件修改稳定后自动调用 auto_push.sh 进行自动提交和推送

# 配置 Git 仓库路径
REPO_PATH="/path/to/your/repo"

# 日志文件路径（可选）
LOGFILE="/tmp/watch_fswatch.log"

# 切换到仓库目录
cd "$REPO_PATH" || { echo "无法进入仓库目录 $REPO_PATH"; exit 1; }

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 启动 fswatch 监控..." | tee -a "$LOGFILE"

# 使用 fswatch 监控当前目录下所有扩展名为 .md 的文件
fswatch -o -i '.*\.md$' . | while read -r event_count; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检测到变化($event_count)，等待稳定后执行自动更新..." | tee -a "$LOGFILE"
    
    # 防止因连续多次触发导致频繁提交，等待 5 秒后再执行更新操作
    sleep 5
    
    # 调用自动提交脚本，并将输出追加到日志文件
    /path/to/auto_push.sh >> "$LOGFILE" 2>&1
done

```

> ~~**说明：**~~
> 
> ~~- 这里使用 fswatch 的 `-o` 参数，每当检测到变化时输出一个事件计数，然后立即调用 auto_push.sh。~~
>     
> ~~- 如果你想防止因连续变化产生频繁触发，可通过 auto_push.sh 内部判断上次提交时间来控制提交频率。~~
>     

~~同样，请确保该脚本具有可执行权限：~~

```bash
chmod +x watch_fswatch.sh
```

~~---~~

### ~~3. 使用 launchd 将监控脚本设为后台服务~~

~~创建一个 plist 文件（例如 `com.yourname.autogitupdate.plist`），内容如下（请根据实际路径修改）：~~

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.yourname.autogitupdate</string>
    <key>ProgramArguments</key>
    <array>
      <string>/path/to/watch_fswatch.sh</string>
    </array>
    <!-- 如果需要在特定条件下定时重启，可添加 StartInterval -->
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/autogitupdate.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/autogitupdate.err</string>
  </dict>
</plist>
```

~~将该文件保存到 `~/Library/LaunchAgents/` 目录下，然后加载服务：~~

```bash
launchctl load ~/Library/LaunchAgents/com.yourname.autogitupdate.plist
```

~~这样，launchd 会保持该脚本常驻后台运行，一旦有文件变化，就会自动执行更新操作。~~

~~---~~

### ~~总结~~

- ~~**auto_push.sh**：判断上次提交时间（防止频繁提交）、生成自定义 commit 信息，并自动执行 `git add`、`git commit` 和 `git push`。~~
    
- ~~**watch_fswatch.sh**：利用 fswatch 监控仓库文件变化，一旦变化触发调用 auto_push.sh。~~
    
- ~~**launchd plist**：将监控脚本设为后台服务，确保系统启动后自动运行。~~
    

~~这样就能实现一个较为优雅的自动提交和更新工作流了。如果有其他需求或改进建议，欢迎继续讨论！~~