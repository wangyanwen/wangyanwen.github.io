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

在你的 Hugo 项目的 `layouts/shortcodes/` 目录下，创建一个 `video.html` 文件，内容：

``` html
<video src="{{ .Get "src" }}" controls style="max-width: 100%;" preload="metadata"></video>
```

然后在你的 `.md` 文件里这样写：

``` markdown
{{</* video src="https://res.cloudinary.com/你的cloud_name/video/upload/f_auto,q_auto/你的public_id" */>}}
```

这样更安全、统一、且支持 Hugo 各种主题。

---
**学习资料：**

问题：`.md` 文件里按下面写会显示无法加载视频界面，而不是我期望的示例代码？

``` markdown
{{</* video src="https://res.cloudinary.com/你的cloud_name/video/upload/f_auto,q_auto/你的public_id" */>}}
```

gpt：明白了！你只是想在 .md 文件里展示你写的代码示例，不是真正插入视频对吧？

而且你用的是 Markdown 的代码块标记（就是三个反引号），但是实际上 Hugo 把它当成真正的 Shortcode 执行了，所以它去加载了` <video>`，结果又找不到视频，才出错。

为什么会这样？

因为 Hugo 默认 .md 文件里的{{</*...*/>}}是Shortcode语法，即使你包在 Markdown 代码块里，它还是会解析执行，不会单纯地显示出来。

正确解决方法

要让 Hugo 只显示文字内容而不是执行 Shortcode，有两种做法：



方法一：用 `{{</*`  `*/>}}` 包裹

比如像上面写的一样

注意，加了`/* */`，Hugo 就不会执行里面的 shortcode，只是把它当普通文本显示。


方法二：用`{{%` raw `%}}` ... `{{ %` /raw `%}}`包住

比如这样写：

`{{%` raw `%}}`

`{{<` video src="https://res.cloudinary.com/你的cloud_name/video/upload/f_auto,q_auto/你的public_id" `>}}`

`{{%` /raw `%}}`


这样 Hugo也不会执行 `{{<` video `>}}`，而是直接原样输出。

这种方法适合你文档中有很多段需要展示 Hugo 代码的情况。