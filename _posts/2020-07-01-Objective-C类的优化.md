---
layout: post
title: 类的优化
subtitle: 类的优化思考
categories: 类优化
tags: [ISA,优化]
---
## 类的优化
在上一篇文章中我们梳理了对象，类，元类，根元类的关系。
我们现在来看看Objective-C为了提高内存和方法调用的速度做了哪些优化。
首先让我们先回忆一下类的结构
![IMAGE](/assets/images/resources/05CAB12B5370C8DBB6C10A0D0EDB9B9E.jpg)
主要看一下**ISA**,**cache**,**bits**


### ISA
ISA是objc_class继承自objc_object的成员变量
![IMAGE](/assets/images/resources/2EEB1616B13ADD4CAC63AFF245AE0BE4.jpg)
它的实际类型是**isa_t**
![IMAGE](/assets/images/resources/1B74570C48B1E0D9A1EFB63E6E944B08.jpg)

**isa_t**这个联合体其它的类型要么表示一个类指针,要么是一个无符号的long类型的8字节的值。主要还是看**ISA_BITFIELD**这个宏定义的位域表示的意义。
![IMAGE](/assets/images/resources/149FD2EC3CAEEDDD557A438BCC6230C2.jpg)
使用结构体定义，并且在每个类型后面添加冒号和数字表示，使用几个二进制位来存储对应的数据。比如一个字节是8位，那么我们可以使用位域来存储8个二进制位的数字，当然每个数字就只能是0或1了。因为一个二进制位只能表示0和1两个数字。
这里根据不同的cpu架构分为arm64和x86_64。前者一般是真机，后者是代表模拟器。我们这里就采用真机arm64的定义来说明。
1. nonpointer  
根据名称就知道这个字段代表了是不是一个指针，如果为1则不是一个指针，即开启了isa优化。为0则是一个指针。
2. has_assoc 
标明对象是否有关联对象
3. has_cxx_dtor
表明对象是否有c++析构函数
4. shiftcls
存储类指针的值。
5. magic
用于调试器判断当前对象是否是真的对象
6. weakly_referencde
用于表示该对象是否被弱引用过
7. deallocating
对象是否正在被释放
8. has_sidetable_rc
是否使用了sidetable来存储引用计数
9. extra_rc
对象存储引用计数的值，当引用计数超出最大能存储的值时，借用sidetable来共同存储。

#### 为什么能对isa进行优化?
1. 因为现在的手机，电脑的cpu大部分都是64位的系统，同样的采用的指针大小也是8个字节64位的寻址能力，但是8个字节实际上的寻址空间范围为0~2^64-1即2^34个G大小的内存。远远超出了现在设备的内存大小。于是可以只用指针中的一部分二进制位表示真正的地址。其它的位数用来存储其它信息。比如在arm64架构下，isa指针就仅仅只用了33位来保存真正的地址位置。
2. 现在对地址的使用都会进行内存对齐，一般是进行8字节的内存对齐，那么考虑一个问题，凡是指向这些内存对齐的指针，它们都是8的倍数。那么这些指针的地址的低三位一定都为0。这3个位置就可以用来存储其它的信息。在开启了isa指针优化的指针中。这3位就分别用来存储**nonpointer**，**has_assoc**，**has_cxx_dtor**这3个标志位。

### cache
![IMAGE](/assets/images/resources/0E8BC533DE0C799E1704DA274A1CE1E1.jpg)
![IMAGE](/assets/images/resources/02C7EC6552EC0279230C5F16DE74DBF1.jpg)
如果不对方法做缓存，我们知道Objective-C的方法调用是通过在类中存储的方法列表中查找的。每次调用都去查找就会很慢，于是通过使用cache将方法缓存，查找方法时先查找缓存。同时当使用的容量大于最大容量四分之三时，对cache进行扩容，扩容大小为原来容量大小的2倍。
#### 为什么查找cache比查找方法列表快?
因为cache采用哈希表存储。能够通过key直接找到缓存的方法指针
#### 为什么类中存储的方法列表不设计成哈希表?
因为哈希表中的key是不允许重复的。但实际上方法列表中可以存储同名的方法。比如通过分类添加已经存在的方法。虽然看起来是覆盖了原来方法。实际上是将分类的方法添加到了方法列表之前。调用的时候先找到了分类的方法。


### bits
![IMAGE](/assets/images/resources/E222D01EE7870F8D4188F6485E3147C7.jpg)
可以看到bits仅仅只是简简单单的做了一个位与操作，就转换为了一个指向class_rw_t结构体的指针。
#### class_rw_t
![IMAGE](/assets/images/resources/9DA94FBEC3A2BEA0038A29C42B213DD7.jpg)
可以看到class_rw_t中有标志位，版本，class_ro_t类型的指针ro，以及方法列表，属性列表，协议列表等。

#### class_ro_t
![IMAGE](/assets/images/resources/31F7B4A804EA5AB0ADE162D3BDD52A27.jpg)
class_ro_t的结构中也含有方法列表，属性列表，协议列表等，但是前面都含有base。

#### 为什么区分**class_rw_t**和**class_ro_t**?
首先，其中的ro表示只读，rw表示可读可写。
在iOS中内存可以分为Clean memory和Dirty memory。
干净的内存在加载之后就不会再修改。class_ro_t就是干净的内存，因为它是只读的。
脏内存是那些在程序运行期间会被修改的内存。类结构一旦被使用，就会被弄脏，因为运行时将新数据写入其中。
脏内存比干净的内存昂贵的多，因为只要程序运行，它就必须一直存在。
干净的内存是可以被回收的，为其它的程序腾出空间。因为如果你需要它的时候，系统总是可以从磁盘重新加载。macOS能够交换内存。但在iOS中脏内存特别昂贵，因为iOS不可以交换内存。能保持干净的内存越多越好，通过分离出不更改的数据，允许大部分类数据作为干净的内存保存。
越多的内存是干净的内存越好。
通过将不会改变的数据分离出来，使得大部分的类数据能够作为干净的内存存储。

#### Tagged pointer
本质上一个指针所占的8字节实际上还有很多空余不会使用的位置，为了节省内存，将一些所占位置不大的对象的值直接存放在存储指针的内存中。
比如在arm64位中一个指针`0x00000001003041e0`
![IMAGE](/assets/images/resources/5275C5FBA5E7FC19BCDB1AE8F9630BF8.jpg)
最低的3个bit位总是为0，因为内存对齐的原因。对象的内存地址必须是这指针大小的倍数地址。即对象的地址始终是8的倍数，那么低3位必然全为0。
高位的前几个字节也总是零，因为地址空间是有限的，比如iphone14的内存是6GB。但是实际上2的40次方就可以表示2^40次方个字节(byte)，也就是1024个G的内存大小。现在的手机或者电脑的内存还远远没有达到1024个G那么大。而指针的8个字节，可以表示2^64次方个字节的大小。所以实际存贮指针的高位的前几个字节也总是零。
于是我们可以取一个地址，改变其中一个始终为0的位(bit)，并将其改为1.这将告诉我们这不是一个常规的指针，然后我们可以将其它所有位赋值为其它含有。这就是标记指针。
这样一些小的值就可以直接存储在特殊的指针中，不需要在为其开辟单独的内存，并用常规指针指向它。

#### 引用:
https://www.wwdcnotes.com/notes/wwdc20/10163/
