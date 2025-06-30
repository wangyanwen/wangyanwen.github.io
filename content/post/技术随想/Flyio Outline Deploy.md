+++
date = '2025-06-30T13:32:19+02:00'
draft = false
title = 'Flyio Outline Deploy'
+++

这是 Fly.io 的官方网站及关于英国伦敦节点的关键信息：

---

## 🌐 Fly.io 官网

- **官网主页**：Fly.io 是一个面向开发者的现代化公共云平台，旨在快速部署全球应用 ([community.fly.io](https://community.fly.io/t/london-lhr-region-network-issues/822?utm_source=chatgpt.com "London (lhr) region network issues? - Fly.io community"), [fly.io](https://fly.io/?utm_source=chatgpt.com "Deploy app servers close to your users · Fly"))。
    
- 访问他们的官网了解入门文档、CLI、定价政策等：[Fly.io – A Public Cloud Built For Developers] ([fly.io](https://fly.io/?utm_source=chatgpt.com "Deploy app servers close to your users · Fly"))。
    

---

## 📍 支持的英国区域（伦敦 `lhr`）

- Fly.io 提供全球 35 个以上部署区域，其中 **包括伦敦（lhr）**，适合英国用户或想使用 UK 节点的项目 ([community.fly.io](https://community.fly.io/t/deployment-in-lhr-region-behaves-like-a-us-deployment/8193?utm_source=chatgpt.com "deployment in LHR region behaves like a US deployment"))。
    
- 官方文档中用 `fly platform regions` 命令可以查看支持区域，`lhr` 正是其中之一 ([community.fly.io](https://community.fly.io/t/source-of-truth-for-regions/7245?utm_source=chatgpt.com "Source of truth for regions - Questions / Help - Fly.io community"))。
    

---

## ⚠️ 区域情况提醒

- 多位用户反映 **LHR 区可能存在网络不稳定**问题，如包丢、时延或 DNS 请求timeout([community.fly.io](https://community.fly.io/t/london-lhr-region-network-issues/822?utm_source=chatgpt.com "London (lhr) region network issues? - Fly.io community"))。
    
- 如果你所在地区网络极端敏感，可考虑作为备用节点而非唯一部署地。
    

---

### ✅ 建议使用流程

1. 打开官网，注册并安装 CLI 工具：
    
    ```bash
    curl -L https://fly.io/install.sh | sh
    fly auth login
    ```
    
2. 使用 `fly platform regions` 查看可用区域，确保 `lhr` 在列。
    
3. 运行 `fly launch` 并选择 `lhr` 区域部署你的服务。
    
4. 部署后通过 `fly status` 确认实例运行在伦敦节点。
    

---

以下是简化版流程，帮你快速上手：

1. **注册 Fly.io**
    
    - 使用邮箱或 GitHub 登录
        
    - 推荐绑定 PayPal（Revolut 卡可以先关联 PayPal）
        
2. **安装命令行工具**
    
    ```bash
    curl -L https://fly.io/install.sh | sh
    
    fly auth login
    ```
    
    登录后即连接你的帐户。
    
3. **部署应用并选择英国伦敦地区**
    
    ```bash
    fly launch
    ```
    
    - 在 Region 选项中输入 `lhr`，使用 London 节点
        
    - 系统会生成 `fly.toml` 文件，请确保 `primary_region = "lhr"`
        
4. **部署并运行你的服务**
    
    - 默认会运行一个简单的 HTTP 应用
        
    - 或者准备你的自定义 Dockerfile 一键部署（如 Outline、MinIO 等场景）
        

---

### ✅ 小贴士

- 默认免费额度为每月 **3 台 x 256MB 实例 + 3GB 存储 + 160 小时运行时间**
    
- 部署完后，可通过 `fly status` 或 `fly platform regions` 查看你的应用实例是否真正运行在 `lhr`
    

---

以下是使用 **Fly.io 免费套餐** 在英国节点（伦敦 `lhr`）**部署 Outline VPN Server** 的完整教程，包括：

- 配置文件（`Dockerfile`、`fly.toml`）
    
- 一键部署命令
    
- 获取管理密钥供 Outline Manager 使用
    

---

## 🧰 一、准备环境

确保本地已有：

```bash
fly --version    # 安装 Fly.io CLI
docker --version # 若使用自定义镜像构建
```

如未安装：

```bash
curl -L https://fly.io/install.sh | sh
```

登录账号：

```bash
fly auth login
```

---

## 📁 二、项目结构

新建一个目录并添加下列文件：

### 🔹 `Dockerfile`

```Dockerfile
FROM ghcr.io/jigsaw-code/outline-server:latest
```

---

### 🔹 `fly.toml`

```toml
app = "outline-server-uk"
primary_region = "lhr"

[build]
  image = "ghcr.io/jigsaw-code/outline-server:latest"

[[services]]
  protocol = "tcp"
  internal_port = 443
  ports = [{ port = 443 }]
```

> 🚨 注意：
> 
> - `app = "outline-server-uk"` 中的名称需全球唯一，出错可换名字再部署
>     
> - `lhr` 是伦敦节点（UK），可改成其他如 `mad`, `fra` 代表马德里、法兰克福等
>     

---

## 🚀 三、部署步骤

在项目目录中运行：

```bash
fly launch --no-deploy
fly deploy
```

---

## 🔐 四、获取 Outline 管理地址

连接服务器：

```bash
fly ssh console
```

查看 access 密钥（注意保存）：

```bash
cat /opt/outline/access.txt
```

复制完整 JSON，如：

```json
{
  "apiUrl": "https://xxx.fly.dev",
  "certSha256": "...",
  "apiPort": 443
}
```

---

## 💻 五、使用 Outline Manager 添加服务器

1. 打开 Outline Manager 客户端（[官网下载](https://getoutline.org))
    
2. 点击「添加服务器」 → 粘贴上一步复制的 JSON
    
3. 成功后可生成访问密钥（QR 码），供 Outline 客户端使用
    

---

## 📦 六、Fly.io 免费额度说明

|项目|额度|
|---|---|
|实例数量|每月最多 3 个实例|
|CPU / RAM|每个实例默认 256MB 内存|
|运行时间|每月 160 小时/实例（5.3 小时/天）|
|出站流量|每月 160 GB|
|存储|免费 3 GB Volume|

⚠️ 注意：如果要 24 小时全天运行 Outline，可绑定信用卡或升级至 $5/month 套餐。

---

## ✅ 成功部署标志

- `fly status` 显示实例运行中
    
- `fly open` 或通过访问 `https://your-app-name.fly.dev` 可访问 Outline 服务端
    
- Outline Manager 成功连接并生成密钥
    

---

# **具体实施步骤：。。。。**

# ✅ Fly.io Outline VPN 部署包（带 IPv4 + Volume 支持）

# 👉 第一步：初始化目录
mkdir fly-outline && cd fly-outline

# 👉 第二步：创建 Dockerfile
cat <<EOF > Dockerfile
FROM ghcr.io/jigsaw-code/outline-server:latest
EOF

# 👉 第三步：创建 fly.toml（请将 app 名改成你自己的唯一名称）
cat <<EOF > fly.toml
app = "outline-server-uk-demo"  # ❗改成你自己的唯一名称
primary_region = "lhr"  # 🗽  英国伦敦lhr，美国东部iad（华盛顿），也可改为 sjc（加州）、ord（芝加哥）、mad（马德里）、fra（法兰克福）等

[build]
  image = "ghcr.io/jigsaw-code/outline-server:latest"

[[mounts]]
  source = "outline_data"
  destination = "/opt/outline"

[[services]]
  protocol = "tcp"
  internal_port = 443
  ports = [{ port = 443 }]
EOF

# 👉 第四步：登录 Fly.io 并初始化项目
fly auth login
fly launch --no-deploy  # 不要自动部署，我们还需要设置 volume

# 👉 第五步：创建 Volume（持久化 Outline 配置）
fly volumes create outline_data --region lhr --size 3

# 👉 第六步：申请公网 IPv4 地址（可选但推荐）
fly ips allocate-v4

# 👉 第七步：部署实例
fly deploy

# 👉 第八步：连接容器查看 Outline 配置信息
fly ssh console
cat /opt/outline/access.txt  # 复制 JSON 粘贴到 Outline Manager 客户端

# 👉 停止实例节省额度
fly scale count 0

# 👉 重新开启服务
fly scale count 1

# 🎉 完成！使用 Outline Manager 管理 VPN，支持 QR 扫码，随时控制密钥权限。

**问题：fly.io实例如果部署outline，会分配ipv4地址吗？免费时间不够，不用的时候停机是不是不算使用的免费时间，再开机是不是又要重新连接配置outline**

这是关于你提出的几个关键问题在 **Fly.io 上部署 Outline Server** 时的详解回答：

---

## 🧭 问题一：Fly.io 实例会分配公网 IPv4 吗？

### ✅ 会分配，但需要手动添加：

默认情况下，**Fly.io 分配的是一个 `.fly.dev` 的域名**（使用其内部 IPv6 网络），**不会自动分配公网 IPv4 地址**。  
但你可以 **手动申请一个静态 IPv4 地址（免费）**：

```bash
fly ips allocate-v4
```

这条命令会为你的应用分配一个公网 IPv4 地址，你就可以通过这个 IP 在 Outline Manager 中连接和管理了。

---

## 🕒 问题二：Fly.io 的免费时间怎么算？实例停机是否节省额度？

### 📊 免费额度详情（每月）

- **每月 3 台实例 × 256MB 内存**
    
- 每月最多 **160 小时/实例**
    
- 160 GB 出站流量 + 3 GB 存储
    

### ❗Fly.io 的时间计算机制：

|状态|是否计入免费运行时间|
|---|---|
|实例运行中|✅ 是|
|实例**关机（fly scale count 0）**|✅ 不计入 ✅（节省额度）|
|实例 `fly suspend`（不可用）|❌ 不支持 suspend 功能，需通过 scale 设置|

### 💡 如何“停机保资源”又省时间：

```bash
fly scale count 0
```

这会将你的实例数量设为 0，相当于停机。你以后再开启：

```bash
fly scale count 1
```

---

## 🧩 问题三：停机再开后，Outline 配置会丢失吗？

### 🚨 默认情况：**配置可能丢失**，因为 Fly.io 使用临时文件系统（Ephemeral）

> Fly.io 容器默认不保留任何数据，包括 Outline 安装生成的访问密钥。

---

### ✅ 解决方案：使用 Volume 挂载持久化数据

1. 创建 Volume：
    
    ```bash
    fly volumes create outline_data --region lhr --size 3
    ```
    
2. 修改 `fly.toml` 添加 Volume：
    
    ```toml
    [[mounts]]
      source = "outline_data"
      destination = "/opt/outline"
    ```
    
3. 然后重新部署：
    
    ```bash
    fly deploy
    ```
    

这样 Outline 的配置文件（位于 `/opt/outline`）就会保存在 Volume 中，即使停机也不丢失。

---

## ✅ 最佳实战策略总结

|目标|推荐做法|
|---|---|
|拥有固定 IP 地址|使用 `fly ips allocate-v4` 分配 IPv4|
|节省免费额度（不使用时停机）|使用 `fly scale count 0` 手动停机|
|保留 Outline 配置 / 密钥|使用 Volume 挂载 `/opt/outline`|
|防止下次重连失败|保持 IP、配置文件不变 + 使用 Volume|
