+++
date = '2025-04-02T18:04:19+02:00'
draft = false
title = '自动commit和push的脚本'
+++

下面提供一个基于 fswatch 的自动更新方案示例，满足以下需求：

1. **在 commit 前判断上次提交时间**  
    如果上次提交距离当前时间太近（例如小于 60 秒），则跳过这次自动提交，防止频繁提交。
    
2. **在脚本中增加对 commit 信息的自定义逻辑**  
    根据变化的文件数量或当前时间自动生成提交信息，也支持通过环境变量覆盖默认信息。
    
3. **让这个监控脚本始终运行**  
    你可以直接在后台运行该脚本，也可以将其封装成 launchd 服务。
    
<
下面提供两个脚本示例和一个 launchd 配置文件示例：

---

### 脚本 1：自动提交和推送脚本 (auto_push.sh)

```bash
#!/bin/bash
# auto_push.sh
# 请将 REPO_PATH 替换为你的 Git 仓库路径
REPO_PATH="/path/to/your/repo"
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
```

> **注意：**
> 
> - 请确保脚本具有可执行权限：
>     
>     ```bash
>     chmod +x auto_push.sh
>     ```
>     
> - 若无变化时 `git commit` 会返回非零状态，这里直接退出，不报错。
>     

---

### 脚本 2：使用 fswatch 监控并触发自动提交 (watch_fswatch.sh)

```bash
#!/bin/bash
# watch_fswatch.sh
# 请将 REPO_PATH 替换为你的 Git 仓库路径
REPO_PATH="/path/to/your/repo"
cd "$REPO_PATH" || { echo "无法进入仓库目录"; exit 1; }

# 监控整个仓库目录（可根据需要修改匹配模式，此处监控所有文件变化）
fswatch -o . | while read -r event_count; do
    echo "检测到变化($event_count)，等待稳定后执行自动更新..."
    # 调用自动提交脚本
    /path/to/auto_push.sh
done
```

> **说明：**
> 
> - 这里使用 fswatch 的 `-o` 参数，每当检测到变化时输出一个事件计数，然后立即调用 auto_push.sh。
>     
> - 如果你想防止因连续变化产生频繁触发，可通过 auto_push.sh 内部判断上次提交时间来控制提交频率。
>     

同样，请确保该脚本具有可执行权限：

```bash
chmod +x watch_fswatch.sh
```

---

### 3. 使用 launchd 将监控脚本设为后台服务

创建一个 plist 文件（例如 `com.yourname.autogitupdate.plist`），内容如下（请根据实际路径修改）：

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

将该文件保存到 `~/Library/LaunchAgents/` 目录下，然后加载服务：

```bash
launchctl load ~/Library/LaunchAgents/com.yourname.autogitupdate.plist
```

这样，launchd 会保持该脚本常驻后台运行，一旦有文件变化，就会自动执行更新操作。

---

### 总结

- **auto_push.sh**：判断上次提交时间（防止频繁提交）、生成自定义 commit 信息，并自动执行 `git add`、`git commit` 和 `git push`。
    
- **watch_fswatch.sh**：利用 fswatch 监控仓库文件变化，一旦变化触发调用 auto_push.sh。
    
- **launchd plist**：将监控脚本设为后台服务，确保系统启动后自动运行。
    

这样就能实现一个较为优雅的自动提交和更新工作流了。如果有其他需求或改进建议，欢迎继续讨论！