# Homebrew(brew)
![IMAGE](resources/38E6ED467C4EFB25CF3C07CCB9BDA67D.jpg =570x371)
Mac平台的包管理工具
# RVM(rvm)
![IMAGE](resources/DE2B18AC8D30BDA763764A9B8EEC5A22.jpg =570x371)
rvm是ruby的版本管理工具。推荐使用rvm管理ruby版本。因为mac自带的ruby在一个系统权限的目录下。当使用系统自带的ruby时候，当需要在ruby目录下添加文件或删除时候，会存在很多权限的问题，有的甚至使用sudo也无法解决。所以建议采用rvm安装一个新的ruby在/usr/local/bin目录下面。并使用rvm切换使用新安装的ruby。原来的系统自带的ruby不需要管它。
# Ruby(ruby)
![IMAGE](resources/8C7BE19A0E4699AE05C98A3461790953.jpg =570x371)
解释性面向对象的脚本语言
# RubyGems(gem)
![IMAGE](resources/74E1C7554AB50B073FBA435B60174FB2.jpg =570x371)
gem是一个ruby的包管理器,当安装ruby时，就已经下载了gem。可以在ruby的上级目录中看到。
# Bundler(bundle)
![IMAGE](resources/9FFE8CCCF62A5F76362155F2913951B5.jpg =570x371)
ruby的依赖管理。同样的在安装ruby是就已经下载了，同样可在ruby的上级目录中看到。



#一些问题
* 我们执行的脚本的命令到底是来自哪里，按什么路径查找的？
  我们就拿自带的工具Homebrew举例。首先查找的路径是,在终端输入`echo $PATH`
  ![IMAGE](resources/C1855FC8E2038173A10E21B948CFC9B2.jpg =565x67)
  可以看到路径是以冒号分割开，逐个路径查找，先查找`/usr/local/bin`，再查找`/usr/bin`等。
  如果没有找到就会报错,比如随便写一个不存在的命令`mybrew`回车执行
  ![IMAGE](resources/213BFFD1FDF1C1137C91D33D95AF5AC2.jpg =336x47)
  会报没有找到命令。
  那么有没有直接查看执行命令路径的命令哪。也是有的。比如查看brew的路径`which brew`
![IMAGE](resources/361C4B56EE921CBE18DDBAF748FD540E.jpg =365x50)
这也和我们刚刚输出的`$PATH`对应上了。
那我们刚刚采用的`echo`和`which`又是哪里的命令那。
![IMAGE](resources/25224005129009A8DC0C9DF7A8B06944.jpg =365x74)
使用`which`命令可以看到，它们都属于shell的内置命令。关于shell的信息可以自行查找。
那么现在命令就很清晰了，一类是shell内置的命令，比如`echo`,`which`等。还有一类是可执行文件，放在我们执行时要查找的路径下面。比如存放在`/usr/local/bin`路径下的可执行文件brew。


* mac自带的包管理工具Homebrew
  这个系统自带工具一般不存在什么问题。可以通过`brew --version`查看版本。通过`brew --help`查看有哪些命令。通过`man brew`来查看Homebrew的文档。

* 安装rvm来管理ruby版本 为什么不使用系统自带的ruby
 为什么要安装rvm管理ruby版本，不使用系统自带的ruby.因为系统自带的ruby在
![IMAGE](resources/A5E452F6C0B1BFF8E84065489DCA6ED4.jpg =380x48)
通过`ls -l /usr/bin/ruby`查看文件的详细信息可以看到。
![IMAGE](resources/C9AA7F8DA8F2FD8D77507A88752C53F7.jpg =444x46)
第一个字符"-"表示文件类型是普通类型。而接下来的"r-x"分别表示文件拥有者，文件属于的用户组，以及授予其它用户的权限。r代表读，w代表写，x代表执行。
那么可以看到/usr/bin/ruby文件。第一个r-x表示这个文件的拥有者只有读和执行的权限;同理第二个r-x表示这个文件所属的用户组也只有读和执行的权限;同理第三个r-x表示，这个文件授予其它用户也只有读和执行的权限。可以看到连文件拥有者也无法修改这个文件。如果使用系统的ruby来配置一些工程时，需要修改的时候，就会产生权限问题导致配置错误。
实际上使用sudo命令也无法修改。具体可以通过`man sudo`来查看这个命令的含义。
所以这里要使用rvm来装另外一个有修改权限的目录下的ruby来配置一些工程，防止需要修改目录文件的时候产生一些权限问题导致的失败。