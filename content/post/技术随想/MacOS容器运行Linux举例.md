+++
date = '2025-10-30T13:53:46+01:00'
draft = false
title = 'MacOS容器运行Linux举例'
+++

## 1️⃣ 安装 Docker（如果还没安装）

在 macOS 10.15 上下载 Docker Desktop for Mac：[https://docs.docker.com/desktop/mac/install/](https://docs.docker.com/desktop/mac/install/)

安装后验证：

```bash
docker --version
```

---

## 2️⃣ 拉一个 Ubuntu 镜像

```bash
docker pull ubuntu:22.04
```

---

## 3️⃣ 创建 Docker 容器并进入

```bash
docker run -it --name test-build ubuntu:22.04 /bin/bash
```

---

## 4️⃣ 更新系统

在容器里运行：

```bash
apt-get update
apt-get upgrade
```

---

✅ 这样，你在 macOS 10.15 上也能使用Linux了。

---
