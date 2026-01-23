+++
date = '2026-01-23T20:12:19+01:00'
draft = false
title = '安装outline排障'
+++

这个错误提示非常明确：**Docker 无法连接到 Docker Hub 镜像仓库**（`i/o timeout`）。

简单来说，你的服务器在尝试下载 `watchtower`（用于自动更新 Outline 的组件）时，网络请求超时了。这通常是因为服务器所在的环境存在网络限制（GFW 拦截）或 DNS 解析问题。

你可以尝试以下几种解决方案：

### 1. 设置 Docker 国内镜像加速器

如果你使用的是中国大陆境内的服务器，直接访问 Docker Hub 经常会超时。你可以配置国内的镜像源来绕过这个问题。

编辑 Docker 配置文件（如果文件不存在则创建一个）：

Bash

```
sudo nano /etc/docker/daemon.json
```

将以下内容粘贴进去（这里以几个常用的镜像源为例）：

JSON

```
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://huecker.io",
    "https://dockerhub.timeweb.cloud",
    "https://noohub.net"
  ]
}
```

保存退出后，重启 Docker 服务：

Bash

```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

**重启后，重新运行 Outline 的安装脚本。**

---

### 2. 手动拉取镜像（测试连接）

在再次运行安装脚本前，你可以手动测试 Docker 能否拉取镜像：

Bash

```
docker pull containrrr/watchtower:latest
```

如果这一步依然报错 `Timeout`，说明镜像源失效或网络依然不通。

---

### 3. 检查 DNS 设置

有时是因为服务器无法正确解析 `registry-1.docker.io` 的 IP 地址。你可以尝试修改 DNS 配置文件：

Bash

```
sudo nano /etc/resolv.conf
```

将内容修改为 Google 的公共 DNS（或保持现有的，增加这两行）：

Plaintext

```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

---

### 4. 使用代理安装（进阶）

如果你的服务器环境极其严格，你可能需要为 Docker 配置全局代理。

1. 创建目录：`sudo mkdir -p /etc/systemd/system/docker.service.d`
    
2. 创建文件：`sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf`
    
3. 加入代理配置：
    
    Plaintext
    
    ```
    [Service]
    Environment="HTTP_PROXY=http://你的代理地址:端口/"
    Environment="HTTPS_PROXY=http://你的代理地址:端口/"
    ```
    
4. 重启 Docker。
    

---

### 总结建议

**最快的方法通常是方案 1（更换镜像源）。** 由于 2024 年以来国内对 Docker Hub 的访问限制收紧，很多老旧的镜像源已经失效，建议多试几个最新的加速地址。

