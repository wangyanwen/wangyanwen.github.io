+++
date = '2025-10-30T13:53:46+01:00'
draft = false
title = 'MacOS容器运行Linux举例'
+++

我们可以通过 **Docker 容器在 Linux 环境里编译 OpenJPH**，这样完全绕过 macOS 10.15 的兼容问题。下面是详细步骤：

---

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
docker run -it --name openjph-build ubuntu:22.04 /bin/bash
```

---

## 4️⃣ 安装编译依赖

在容器里运行：

```bash
apt update
apt install -y git build-essential cmake wget
```

---

## 5️⃣ 下载 OpenJPH 源码

```bash
cd /root
git clone https://github.com/aous72/OpenJPH.git
cd OpenJPH
git checkout 0.24.2   # 切换到你想要的版本
```

---

## 6️⃣ 编译 OpenJPH

```bash
cmake -S . -B build
cmake --build build
```

编译完成后，二进制文件在：

```
/root/OpenJPH/build/src/openjph
```

---

## 7️⃣ 拷贝二进制到 macOS

在另一个终端里运行：

```bash
docker cp openjph-build:/root/OpenJPH/build/src/openjph ~/Desktop/openjph
```

然后你就可以在 macOS 上运行这个二进制了：

```bash
~/Desktop/openjph --help
```

---

## 8️⃣ 清理 Docker（可选）

```bash
docker rm -f openjph-build
docker image prune -f
```

---

✅ 这样，你在 macOS 10.15 上也能使用 OpenJPH，而不用升级系统或修改源码。

---
