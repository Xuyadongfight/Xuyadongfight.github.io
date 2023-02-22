## 1.setup设置
通过gem安装jekyll和bunlder（如果没有gem，先安装gem）
终端输入
![IMAGE](resources/1890349CE0EEC6D9B268781F921CD333.jpg =667x86)
安装完毕之后，可以在终端输入
`jekyll -v`和`bundle -v`检查是否成功安装。

创建一个存放blog的文件夹
进入文件夹，终端输入
`bundle init`
会发现blog目录中多了一个Gemfile文件
再输入
`bundle add jekyll`
会发现目录中又多了一个Gemfile.lock文件
然后在blog目录下创建一个index.html文件
并且写入以下内容
```
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Home</title>
  </head>
  <body>
    <h1>Hello World!</h1>
  </body>
</html>
```
终端执行
`jekyll serve`
可以看到目录下多了一个_site文件夹
浏览器打开
`http://127.0.0.1:4000`就可以看到我们写的index.html文件了

此时blog文件夹中的内容为
![IMAGE](resources/4DF03E921C2626A579CF095861B58895.jpg =204x246)

### 创建Markdown文件

在blog目录下创建一个Markdown文件about.md,写入以下内容
![IMAGE](resources/E7E004A24147124B6AC40A36AE0A19FF.jpg =745x199)
此时会发现blog目录下的_site文件夹中自动生成了about.html
打开`http://127.0.0.1:4000/about.html`会发现进入了我们刚刚生成的about.md文章。实际上，jekyll就是帮我们自动将Markdown文件生成对应的html文件。
注意在文章内容前一定要有两行开头的三虚线
```
---
---
```
否则不会在_site文件夹下生成about.html文件。
显然我们现在已经可以生成Markdown文件并且自动生成对应的html文件，但是没有导航页面，需要手动修改地址比如
`http://127.0.0.1:4000/about.html`才能访问对应的文章。那么怎样才能生成一个包含多个文件的导航页面，并且点击对应文章标题就跳转的对应的文章那。在开始之前，我们需要先了解一些其它知识。


## 2.Liquid
1,为什么文章要添加两行3虚线。添加之后才告诉jekyll加载Liquid模板语言。
liquid是一个模板语言，主要有三个组成部分。**objects;tags;filters**

### objects对象
通过两个大括号`\{\{\}\}`加载变量。
告诉liquid将预定义变量作为页面上的内容输出。修改index.html文件。在三虚线之间定义一个变量text，值为Hello World!
再在**html**文件中使用\{\{ page.text \}\}输出。定义的变量都属于page
![IMAGE](resources/31FBDFEB73492E919F239E48E673065E.jpg =329x226)

### tags标签
使用`\{\%\%\}`加载逻辑控制
标记定义模板的逻辑和控制流。比如定义showtext控制是否显示text内容
![IMAGE](resources/C0D47BFC3CCDC29DB33FE52D445BF785.jpg =419x332)
再将定义的showtext改为false试试，看看打开之后是否还会显示Liquid定义的text内容。

### filters过滤器
过滤器通过`|`符号改变liquid对象的输出。
比如将全部大写定义的HELLO WORLD!通过过滤器改为小写
![IMAGE](resources/2EB4C3A2717EF815E49D534C659956CE.jpg =509x297)


## 3.front matter前置内容
就是定义在两个三虚线之间的内容，它是YAML的一个片段，可以在这里为页面page设置变量。在上一节我们已经使用过了。
YAML 是一种数据序列化语言，通常用于编写配置文件。了解这些就够了。
了解YAML可以参考
https://www.runoob.com/w3cnote/yaml-intro.html
https://www.redhat.com/sysadmin/yaml-beginners


## 4.Layouts布局
通过index.html文件 我们知道显示的内容是通过<h1></h1>标签显示的。但是如果我们创建多个文件，那么不是就都需要复制index的内容，并修改显示的内容吗。这显然是浪费时间。
我们可以通过在blog文件夹下创建一个_layouts文件夹，并在此文件夹中创建一个defult.html文件。作为默认是样式。写入以下内容
![IMAGE](resources/01C9AE9C3E5C35D41D09AC2D035BF6A9.jpg =391x203)
这个default.html与最开始创建index.html几乎相同，除了没有三虚线和将`\{\{ page.text \}\}`替换为了`\{\{ content \}\}`。
page.title不需要介绍了吧 就是我们在三虚线中定义的title变量。
主要注意这里的content。它是一个特殊的变量，返回调用它的页面呈现的内容。什么意思那，就是哪个页面使用了default.html，那么`\{\{ content \}\}`就会替换为那个页面的内容。比如我们现在要改造index.html并使用_layouts文件夹中的default.html。
将blog文件夹中的index.html修改为
![IMAGE](resources/4530C7857EA7F2BC18C7ACB2F7D2600F.jpg =359x146)
查看http://localhost:4000可以看到重新显示了页面。

在根文件夹下添加_layouts文件夹，并且创建一个默认的default.html样式。
注意这里面两个双大括号包裹的上面讲到的liquid的对象。title会被替换为index.html中front matter中定义的title,而content则会被替换为使用该layout的页面内容。
实际上就是我们定义了layout使用_layouts文件夹里面的default.html。并且定义了title。所以default.html里面可以使用`\{\{ page.title \}\}`。同时将`\{\{ content \}\}`替换为了index.html中的`<h1>\{\{ "Hello World!" | downcase \}\}</h1>`这部分内容。
接下来我们在blog文件夹中创建一个Markdown文件，about.md
写入以下内容
![IMAGE](resources/5146A944C1248E9B99EF083579DB0941.jpg =472x226)
接着打开http://localhost:4000/about.html
可以看到显示了about.md内容的页面。原理同index.html一样。我们在about.md中使用了默认的布局`layout : default`,并且定义了`title : About`。同时将除了三虚线中的内容替换为default.html中的content。
此时我们的blog目录下有以下文件
![IMAGE](resources/3FB7938ED0678663077DC0F2A594628D.jpg =334x166)
现在我们有一个两页的网站了。可以查看_site文件夹下的网页。
![IMAGE](resources/181EE669423156E7A468D76DE15CBE71.jpg =337x184)


## 5.Includes包含
我们现在有了两个index.html和about.md生成的两个页面。但是两个页面的跳转还是使用的是手动修改网页地址。这显然并不是我们想要的。
我们显然需要一个导航页面，能够点击导航的标签跳转到对应的页面。
正好我们来学习一下liquid `include`标记的用法。include标记允您包含存储在_includes文件夹中的另一个文件的内容。
我们在blog目录中创建一个_includes文件夹，并在其中创建一个navigation.html文件。
![IMAGE](resources/DB7301E3A4DED6807A7757452228318B.jpg =421x181)
并在navigation.html中写入以下内容
![IMAGE](resources/C5CB8C7543FA85C059DC07D9E385C548.jpg =679x136)
接着在_layouts中的default.html中使用include标签包含navigation.html。
![IMAGE](resources/4F32DC337E05B0E394B9CB6AC5868A22.jpg =352x255)
接着打开地址http://localhost:4000就可以看到我们能够切换两个页面了。
![IMAGE](resources/B8BA72A0FFAFEC34974191FA7FF9799E.jpg =682x300)

接着我们可以在试着使用liquid的标记控制流功能将这个导航稍稍改造以下，使得当前选中的页面的标记变红。修改_includes文件夹下的navigation.html为
![IMAGE](resources/C09912E529D09E460ECB75A3987A8166.jpg =675x203)
可以看到我们使用了`\{\%\%\}`控制流语句来进行判断。同时有jekyll已经定义好的变量，page.url。用来判断当前显示的是哪个页面的路径。至于style，你可以看一下html中<a></a>标签的style属性有哪些。
现在我们不仅有了导航能够自由的切换两个页面，并且还将当前显示的页面的链接设为了红色。
此时的blog目录如下:
![IMAGE](resources/9906A6545B840F150069F542EA5333EA.jpg =393x192)


## 6.Data Files 数据文件
jekyll支持从本地_data文件夹下加载YAML,JSON,和CSV文件。
数据文件是将内容与源代码分离的好方法，可以使站点更容易维护。
我们在这一步学习将导航中的内容存储到数据文件中，然后在导航文件中遍历它。

在blog文件夹中创建_data文件夹，再在_data文件夹中创建一个YAML文件navigation.yml
![IMAGE](resources/18448E137E1A9F464CB395B4EC7FCD26.jpg =417x247)
在navigation.yml文件中写入以下内容
![IMAGE](resources/288079F10CAA4526634527E7AA63A862.jpg =310x151)
jekyll使得这个文件能在site.data.navigation中使用。可以在navigation中遍历这个变量。
这样就不需要一行一行的去写<a></a> html标签
修改_includes文件夹下的navigation.html文件为以下内容

![IMAGE](resources/6A2CC11F5D37082E81A3BC669A3B33BB.jpg =783x141)

这里面主要注意两个地方一个是item.link和item.name,实际上看看我们刚刚在_data中创建的navigation.yml就会发现link和name都是我们在YAML文件中定义的内容。通过遍历的方式我们可以仅仅修改YMAL文件就可以添加新的导航内容，不需要在去修改_includes中的navigation.html文件。

## 7.Assets资源
一个网站不可能不使用CSS,JS和images文件。我们看看jekyll是怎么管理这些资源文件的。
在jekyll中使用CSS,JS,图片和其它资源文件是很简单的。只要在blog目录下创建assets文件夹，并在assets文件夹下分别创建css,js,images三个文件夹如下:
另外在blog目录下再创建一个_sass文件夹，很快就会用到这个文件夹。
![IMAGE](resources/CFADC7480D850A22ABADBDCE859C8E67.jpg =337x273)

### sass
在navigation.html中使用内联的样式并不是最好的方式。相反，让我们通过在一个新的css文件中定义第一个类来设置当前页面的样式。
要这样做，先要在_includes文件夹中的navigation.html中引用类。修改navigation.html中的内容为:
![IMAGE](resources/203C4EA5619BA92136064EC21EC60A9A.jpg =783x162)
我们可以使用一个标准的CSS文件来进行样式化，但我们使用Sass来更进一步，Sass是CSS一个很棒的扩展应用于Jekyll。
首先创建一个Sass文件styles.scss在assets文件夹下的css文件夹中
![IMAGE](resources/1A04CA7DB82406083BE5BB8F0B44CDA0.jpg =636x284)
在styles.scss中写入以下内容
![IMAGE](resources/1AC56C8171FF2E2D81A3EED6D006E9C6.jpg =254x144)
两个三虚线告诉Jekyll需要加载这个文件。@import "main"告诉Sass查找一个名为main的文件。SCSS在blog目录下的_sass中查找，在刚刚我们已经在blog目录中创建了_sass文件夹。
在这个阶段，将只有一个主CSS文件。对于较大的项目，这是保持CSS有组织的好方法。
在_sass文件夹中创建main.scss文件，写入以下内容:
![IMAGE](resources/0EDB53C7B3A021AF003A43D04BD37F5A.jpg =467x121)
接下来需要在布局中引用样式表。
修改_layouts/default.html为:
![IMAGE](resources/6A9D7DE5DFF315CF567D666C54DB22F9.jpg =494x247)
然后运行`bundle exec jekyll serve`
**这里发现一个小问题，如果直接运行`jekyll serve`会因为cpu类型判断错误，导致加载不了styles.css。所以一定要使用`bundle exec jekyll serve`来执行**


## 8.Blogging
您可能想知道如何在没有数据库的情况下创建一个博客。在真正的Jekyll风格中，博客仅由文本文件驱动。

### Posts
博客文章位与一个名为_posts的文件夹中，如果blog目录下没有_posts文件夹。自己创建一个。文章的文件名是一种特殊的格式日期-标题-扩展名。比如在_posts文件夹下创建一个`2018-08-20-bananas.md`的Markdown文件。写入以下内容
![IMAGE](resources/31C62528E5D447DFCF4AF92E140E0FC9.jpg =693x263)
显然和普通的Markdown文件比。多了两行3虚线(front matter)以及在其中定义的layout和author。
显然现在post样式的layout并不存在，所以我们需要在_layouts文件夹中添加post.html。在_layouts中创建post.html并写入以下内容:
![IMAGE](resources/20B11CFAFADD6126004E20143834BF1A.jpg =506x201)
这是一个布局继承的例子。文章布局输出的标题，日期，作者和内容主体是由默认布局包装。

还要注意date_to_string筛选器，它将日期格式化为更好的格式。

### List posts文章列表
目前没有办法导航到博客文章，通常一个博客有一个页面列出了所有的文章。我们接下来来做这个页面。
在blog目录下创建blog.html文件，并写入以下内容:
![IMAGE](resources/F5AA91AA0880B05B79078E335ADB9915.jpg =523x278)
在这个文件中有以下几点要注意
post.url由Jekyll自动设置为文章的输入路径。
post.title是从文件名中提取的，也可以通过front matter中设置title来覆盖。
post.excerpt默认为内容的第一段。

有了文章列表页之后，当然也需要能够导航的列表页面。打开_data文件夹下的navigation.yml。添加到blog.html的导航。
![IMAGE](resources/D9B683920E3902E48CD12819295A43D7.jpg =341x145)

### More posts更多的文章
创建更多的文章来看看文章列表有没有正常生成。
![IMAGE](resources/619B0C6DAA4F7C0003AAD4C837E11431.jpg =704x776)

## 9.Collections收藏
接下来我们看看如何生成每个作者自己的页面，并且上面有他们发表的文章和简介。
我们需要使用Collections收藏，它类似于posts，只是内容不需要按日期分组。
### Configuration
建立一个收藏需要告诉Jekyll。Jekyll的配置在bolg目录下一个名为_config.yml的文件中进行。
在blog目录下创建_config.yml文件，并写入以下内容:
![IMAGE](resources/CBA897EB685310576E189C0FC7244670.jpg =256x118)
重新加载配置需要在终端使用`Ctrl+C`结束Jekyll服务，再使用`bundle exec jekyll serve`重启服务。
### Add authors添加作者
文档(集合中的项目)位于站点根目录下名为_*collection_name*的文件夹中。在本例中，为_authors。
在blog文件夹中创建_authors文件夹。并为每个作者创建介绍文件。
![IMAGE](resources/5D4A5773949AB96E289044E3FE82CFB4.jpg =704x498)
### Staff page
接下来我们添加作者列表页面。列出该网站上的所有作者。Jekyll在site.authors上提供了这个集合。
在blog文件夹中创建staff.html并且遍历site.authors输出所有作者。staff.html的内容为:
![IMAGE](resources/C4FBC39309F77FF6CF40AF162B0A03CF.jpg =512x296)
由于内容是Markdown,所有需要markdownify过滤器运行它，当在布局中使用\{\{ content \}\}时，它会自动设置。
当然也需要修改导航。
修改_data文件夹中的navigation.yml为:
![IMAGE](resources/A8ED1FB987B972D9D43D1060C8E5F46D.jpg =373x198)

### Output a page
默认情况下，收藏不会为文档输出页面。在这个例子中，我们希望每个作者都有自己的页面，因此我们调整收藏配置。打开blog目录下的_config.yml修改为:
![IMAGE](resources/287D1D53AA0AF00AAB1B9C34EBA1F3BF.jpg =345x131)
重新启动Jekyll，使配置更改生效。可以使用author.url链接到输出的页面。
修改blog文件夹下的staff.html为:
![IMAGE](resources/6A6B9752BF70DB2ADE70634E40D0711D.jpg =564x323)
就像文章一样，需要为作者创建一个布局。
在_layouts文件夹下创建一个author.html为:
![IMAGE](resources/1A0547DE5E85664ADA10F822F0EA1D6E.jpg =339x161)
修改blog目录下的staff.html使用author.html布局
![IMAGE](resources/3C9DA2B7C01DA0FFEFD795DC69FBE856.jpg =515x311)

### Front matter defaults
我们在上面修改blog文件夹下的staff.html使用author.html布局之后。就像我们之前修改的那样。但是这些都是重复的工作。我们真正想要的是文章的布局使用文章的，作者的布局使用作者的。其它的一切使用默认。
可是使用blog文件夹下的_config.yml中的front matter default前置事项默认值来实现这一点。可以设置默认应用的范围，然后设置想要的默认前端内容。
修改_config.yml文件为:
![IMAGE](resources/87034E8B2CAA38F033D57885FCA92487.jpg =560x348)
现在可以从所有页面和文章的前置内容中删除布局。然后重启Jekyll。

### List author’s postsPermalink
让我们列出一个作者在他们的页面上发表的文章。为此，您需要将作者short_name与后作者匹配。您可以使用它按作者筛选帖子。
在_layouts/author.html中迭代这个过滤过的列表，输出作者的帖子:

### Link to authors page
这些帖子都有作者的引用，所以让我们把它链接到作者的页面。你可以在_layouts/post.html中使用类似的过滤技术来做到这一点:
![IMAGE](resources/1574A9A23AE36CC52FB97C2EF17C1698.jpg =606x279)

## 10.Deployment
### Gemfile
在站点中添加Gemfile，它确保了jekyll和gem的版本在不同的环境中保持一致。文件名必须为Gemfile,不能有任何扩展名。可以通过以下创建
![IMAGE](resources/5AB83E3CF45F56D356E041A45ADD6DA2.jpg =598x119)
bundler安装gem并创建一个Gemfile.lock锁定当前gem版本，以便将来安装bundle。如果你想要更新你的gem版本，你可以运行bundle update。
在使用Gemfile时，您将运行带有bundle exec前缀的jekyll serve等命令。完整的命令是:
![IMAGE](resources/18C05DACD2EED3589427D2C57B9ED3DE.jpg =619x171)

### Plugins
Jekyll插件允许您创建特定于站点的自定义生成内容。有很多可用的插件，你甚至可以自己编写。

有三个官方插件几乎在任何Jekyll网站上都很有用:

jekyll-sitemap -创建一个站点地图文件，以帮助搜索引擎索引内容
jekyll-feed -为你的帖子创建一个RSS提要
jekyll-seo-tag -添加元标签来帮助SEO
要使用这些文件，首先需要将它们添加到Gemfile中。如果你把它们放在jekyll_plugins组中，它们会自动被要求进入Jekyll:
![IMAGE](resources/99B4D12208CCB93BD53C3DC2BFA28931.jpg =681x267)
然后修改添加以下内容到_config.yml:
![IMAGE](resources/3631585105193B5E7310AFE95FF1C7A5.jpg =391x415)
现在使用`bundle update`安装它们。
Jekyll-sitemap不需要任何设置，它会在构建时创建你的站点地图。

对于jekyll-feed和jekyll-seo-tag，你需要在_layouts/default.html中添加标签:
![IMAGE](resources/175D948311CC99BA7700D89734E2E287.jpg =521x296)
重新启动Jekyll

### Environments
有时您可能希望在生产中输出一些东西，而不是在开发中输出。分析脚本是最常见的例子。

为此，您可以使用环境。您可以在运行命令时使用JEKYLL_ENV环境变量来设置环境。例如:
![IMAGE](resources/76D277909DEE25C54A22F87868E9CC83.jpg =683x95)
默认情况下，JEKYLL_ENV是development。JEKYLL_ENV可以通过jekyll.environment以liquid提供。所以为了只在生产环境中输出分析脚本，你需要执行以下步骤:
![IMAGE](resources/E36C5FEC3B2DF64EB90F97C7083886E8.jpg =517x99)
### Deployment
最后一步是将站点放到生产服务器上。最基本的方法是运行一个产品版本:
![IMAGE](resources/9E0BA08F1A97AFD854983B81AF6840E8.jpg =675x96)
然后将_site的内容复制到服务器。

---

1.markdown文章怎么生成网页
2.markdown引用的资源怎么处理
3.文章生成网页的布局
4.文章怎么分类
5.文章怎么导航

推荐使用rvm管理ruby版本，否则使用系统默认的/usr/bin/ruby会导致很多权限问题，不建议。