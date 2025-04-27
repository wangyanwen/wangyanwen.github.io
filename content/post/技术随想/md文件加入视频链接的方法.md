+++
date = '2025-04-27T21:32:19+02:00'
draft = false
title = 'md文件加入视频链接的方法'
+++

经过与小助手的几次对答，总算实现在md文件中加入视频。

1.首先根据小助手给的意见，在md文件中直接编写html标签`<video>`，但没有用处，网站上没有内容。

2.然后又根据建议，转换视频格式为mp4，因为苹果默认视频格式是mov，说是浏览器不太支持，仍然不行。

3.最后几个来回，终于看到gpt给出的一个可能原因，

**Hugo安全策略（Goldmark Safe Mode）**

Hugo 0.60版本之后，默认启用了 Goldmark Safe Mode，禁止了 Markdown 文件中某些 HTML 标签，比如 `<script>`、`<iframe>`、`<video>`。

解决办法：

用 Hugo 的 Shortcode（推荐）

可以自定义个 Hugo Shortcode，例如：

在你的 Hugo 项目的 layouts/shortcodes/ 目录下，创建一个 video.html 文件，内容：

```
<video src="{{ .Get "src" }}" controls style="max-width: 100%;" preload="metadata"></video>
```

然后在你的 `.md` 文件里这样写：

```
{{< video src="https://res.cloudinary.com/你的cloud_name/video/upload/f_auto,q_auto/你的public_id" >}}
```
