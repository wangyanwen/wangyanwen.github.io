+++
date = '2025-10-20T12:36:46+02:00'
draft = false
title = 'Hiddify配置要点'
+++

## 提问：settings里面domains选哪个，direct/reality/fake site

## gpt回答：

非常好，这两个问题实际上是相互关联的 💡  
因为你要的是：

> ✅ Hiddify 使用 **Reality 核心（xray+Reality）**  
> ✅ 同时让普通浏览器访问域名时显示 **本地伪装网页**

我来一次性帮你解决：

---

## 🧩 一、面板里的正确选项选择（Settings → Domains）

在 Hiddify 管理面板中（`Admin Panel > Settings > Domains`），你会看到三类域名类型：

|类型|含义|用途|选哪个|
|---|---|---|---|
|**Direct**|明文传输，主要给自建反代、内网节点、探针等使用|一般指纯 HTTP(S) 访问，**不加密传输**|❌ 不选|
|**Reality**|使用 Xray Reality 协议（即真正的代理流量）|给客户端连接代理使用（VLESS + Reality）|✅ 选这个用于节点主域名|
|**Fake Site / Decoy Site**|伪装站点（Decoy 页面）|提供浏览器访问时显示的网页（假网站）|✅ 若启用伪装页面，选此项作为备用域名|

> 🔹 实际配置中：
> 
> - **Reality 域名**：用于客户端连接代理
>     
> - **Fake Site 域名**（Decoy Site）：浏览器访问显示网页
>     

---

## ✅ 二、推荐设置组合（最稳妥）

|功能|域名|在 Settings 中的类型|说明|
|---|---|---|---|
|Reality 节点|`yourdomain.com`|**Reality**|客户端使用|
|本地伪装网页|同一个或子域，如 `www.yourdomain.com`|**Fake Site**|浏览器访问时显示网页|

👉 如果你只想用一个域名（比如 `yourdomain.com`），那你可以：

- 仍然将其类型设为 **Reality**；
    
- 但开启 Nginx 的本地伪装网页（我们下面给出配置），这样 Reality 客户端和普通浏览器都可访问，不冲突。
    

---

## 🧱 三、完整可部署方案（HAProxy + Nginx 本地伪装网页）

下面是一套适配你当前环境的配置模板，可直接添加：

---

### 1️⃣ 新建伪装网页目录与文件

```bash
sudo mkdir -p /opt/hiddify-manager/nginx/html
echo '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Welcome</title></head><body><h1>Welcome</h1><p>This is a decoy page served by Nginx.</p></body></html>' | sudo tee /opt/hiddify-manager/nginx/html/index.html
sudo chown -R root:root /opt/hiddify-manager/nginx/html
sudo chmod -R 755 /opt/hiddify-manager/nginx/html
```

---

### 2️⃣ 新增 nginx 配置文件

创建文件：

```bash
sudo nano /opt/hiddify-manager/nginx/conf.d/decoy_site.conf
```

写入内容：

```nginx
server {
    listen 80;
    server_name _;

    # 本地伪装网页目录
    root /opt/hiddify-manager/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

保存后：

```bash
sudo systemctl reload hiddify-nginx || sudo systemctl reload nginx
```

---

### 3️⃣ 确认 HAProxy fallback 正常指向 nginx

在 `/opt/hiddify-config/haproxy/haproxy.cfg` 中，确保 fallback backend 是：

```haproxy
default_backend nginx_dispatcher_http_h2
```

查看：

```bash
grep "default_backend" /opt/hiddify-config/haproxy/haproxy.cfg
```

---

### 4️⃣ 测试

**本机：**

```bash
curl -I http://127.0.0.1:80/
```

**从外部访问（经 HAProxy）：**

```bash
curl -I --resolve yourdomain.com:443:YOUR_SERVER_IP https://yourdomain.com/
```

应返回：

```
HTTP/1.1 200 OK
Content-Type: text/html
```

然后浏览器打开 `https://yourdomain.com`，看到你刚写的网页内容。

---

## 🧠 四、进阶选项（如要反代外部站）

如果不想维护自己的 HTML 文件，而想伪装成某个网站（比如 Cloudflare），  
可以改用外部 Decoy：

在 Hiddify 管理面板：

> Settings → Domains → Decoy Site  
> 填写：

```
https://www.cloudflare.com
```

系统自动生成：

```haproxy
backend tgdecoy_http
    mode http
    server tgdecoy_http www.cloudflare.com
```

此时浏览器访问你的域名就会看到 Cloudflare 首页。

---

## ✅ 五、推荐组合总结

|需求|域名类型|Nginx 配置|备注|
|---|---|---|---|
|Reality 节点（代理）|Reality|默认即可|Hiddify 自动配置|
|本地伪装网页|Fake Site 或与 Reality 同域|加上上面 decoy_site.conf|显示 HTML 页面|
|外部网站伪装|Fake Site|设置 Decoy Site 域名|自动反代，无需 nginx 伪装页|

---

是否希望我帮你生成一个一键脚本（自动创建目录、生成 HTML、写入 `decoy_site.conf` 并重载 nginx）？  
那样你直接复制粘贴运行即可完成配置。