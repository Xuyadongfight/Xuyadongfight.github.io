## 从isa_t结构引申出来的一系列问题
将isa类型isa_t改写一下
```
union isa_t {
    Class cls;
    uintptr_t bits;
    struct {
      uintptr_t nonpointer        : 1;                                        
      uintptr_t has_assoc         : 1;                                         
      uintptr_t has_cxx_dtor      : 1;                                         
      uintptr_t shiftcls          : 44; /*MACH_VM_MAX_ADDRESS 0x7fffffe00000*/ 
      uintptr_t magic             : 6;                                         
      uintptr_t weakly_referenced : 1;                                         
      uintptr_t deallocating      : 1;                                         
      uintptr_t has_sidetable_rc  : 1;                                         
      uintptr_t extra_rc          : 8
    }
};
```

### 1.从`nonpointer`看看普通指针和位域指针
![IMAGE](resources/BE7DC795C64C113359F1926258C45A7B.jpg =324x194)
**1. 普通指针**
就是isa_t中定义的Class类型的cls，它就是存储的类对象的地址。

**2. 位域指针**
![IMAGE](resources/B41A1A9789E7D7999B98178FBA3CCCB7.jpg =655x271)
宏定义ISA_BITFIELD就是位域指针。相比普通指针，它还利用位域存储了其它信息。优化了内存利用率。为什么要这样做。我们知道在64位cpu下，一个指针的大小是8个字节。即64位。而64位的指针大小的理论寻址大小为2的64次方-1个字节的大小。我们就粗略的认为是2的64次方个字节的大小。1024Byte=1KB,1024KB=1MB,1024MB=1GB。即2的30次方Byte = 1GB。而2的64次方能访问的内存大小是2的34次方GB。而我现在使用的电脑的内存大小仅仅只有16GB。
![IMAGE](resources/A8720AEAE1638B449DBF83D01F5C3DAA.jpg =586x346)
更别提手机的内存了，远远小于2的34次方GB。这就意味着8个字节存储的一个指针。64位中有很多位一直为0。因为根本没有那么大位置的内存分配。比如假设内存最大能做到2的40次方个字节，即1TB=1024G的内存大小。那么实际上存储指针的8个字节64位中，仅仅需要40位就能访问到设备上的所有内存了。还剩下存储数字高位的24位是固定一直为0的。那么就可以利用这些存储其它信息。又因为内存对齐的原因。申请到的内存地址一定是8字节对齐的。即内存的起始地址低位一定是0x0或者0x8。用二进制位表示即最低位的3位二进制位置一定都是0。那么这3位也可以用来存储其它信息。现在再看**ISA_BITFIELD**的定义。它的低地址3位分别用来存储**nonpointer**，**has_assoc**，**has_cxx_dtor**。高位分别用来存储**magic**，**weakly_referenced**，**deallocating**，**has_sidetable_rc**，**extra_rc**。而中间占用最多位的**shiftcls**才是真正则用来存储指针的。
位域各个字段的含义为：
```
      uintptr_t nonpointer        : 1;                                         \  //是否是一个指针
      uintptr_t has_assoc         : 1;                                         \  //是否有关联对象
      uintptr_t has_cxx_dtor      : 1;                                         \  //是否有C++析构方法
      uintptr_t shiftcls          : 44; /*MACH_VM_MAX_ADDRESS 0x7fffffe00000*/ \  //存储的指针
      uintptr_t magic             : 6;                                         \  //用于调试器判断当前对象是真的对象还是没有初始化的空间
      uintptr_t weakly_referenced : 1;                                         \ //对象被指向或者曾经指向一个 ARC 的弱变量
      uintptr_t deallocating      : 1;                                         \ //对象正在释放内存
      uintptr_t has_sidetable_rc  : 1;                                         \ //对象引用计数存储是否使用了sidetable
      uintptr_t extra_rc          : 8    //存储对象的引用计数
```
#### 扩展
**标记指针**
Tagged Pointer本质上已经不是一个指针地址，而是存储的数据的类型及数据本身的值。
因为在OC中一切皆对象，对于一些本身存储占用很小的内存的值。当在32位下一个指针使用4个字节时候还不突出，但当cpu的位数来到64位之后，比如原来存储一个NSNumber的实例对象需要存储isa及数值本身需要8个字节。来到64位之后，内存占用直接翻倍变为16个字节。为了优化这种内存占用于是有了Tagged Pointer。当然现在的版本已经对值进行了隐藏没法直接看出来了。

#### 总结
实际上不管是isa_t位域进行的优化还是tagged pointer的优化都是为了尽可能节约内存。isa_t是使得isa指针中尽可能存储更多的信息。而tagged pointer则已经不是一个对象了，它连isa都没有。

### 2.从`has_assoc`聊聊关联对象的实现
```
objc_setAssociatedObject(id _Nonnull object, const void * _Nonnull key,
                         id _Nullable value, objc_AssociationPolicy policy);

objc_getAssociatedObject(id _Nonnull object, const void * _Nonnull key);
                         
                      
```
**objc_setAssociatedObject方法**
![IMAGE](resources/5E77D6B5A18507CF02A357197AAB2BFF.jpg =740x718)

**AssociationsManager**
![IMAGE](resources/B9F35E835D4661E7A1B20FAD7883C201.jpg =548x219)

**AssociationsHashMap**
![IMAGE](resources/38DF2226D8AC9EB4F9B89E6351F6B3AF.jpg =815x154)

**ObjectAssociationMap**
![IMAGE](resources/58332F4AC8EC57A1D4672B50030275C2.jpg =822x118)

**ObjcAssociation**
![IMAGE](resources/129C7B9DCE77F29CE09FE23E0F1FAB8E.jpg =805x212)

通过runtime方法`objc_setAssociatedObject`和`objc_getAssociatedObject`设置关联对象。本质上是使用一个AssociationsManager来管理一个全局的AssociationsHashMap。而这个AssociationsHashMap的key和value又分别是上图中的`object`和一个ObjectAssociationMap哈希表。ObjectAssociationMap这个表的key和value又分别是上图中的`key`和一个ObjcAssociation对象，这个对象中存储了上图中的`value`和`policy`。

### 3.从`weakly_referenced`聊聊弱引用实现
弱引用的本质就是一个指向对象的指针，当这个对象被释放之后，需要将这个这个指针设为空，否则就会指向已经被释放的内存，成为悬垂指针。而weak就相当于下面的处理。唯一需要理解的就是为什么要传ptr的地址。因为方法的传参是传递的原值的复制样本，在方法里面修改参数实际上修改的是复制的样本，并没有修改原值。想要修改原值就要传递存储原值的内存地址。通过原值的内存地址来修改原值。
```
void test(){
    void* ptr = malloc(16);
    free(ptr);
    printf("%p\n",ptr);
    my_weak(&ptr);
    printf("%p\n",ptr);
}
void my_weak(void**ptr){
    *ptr = nil;
}
```
**1. 存储的问题**
显然当一个对象被弱引用的时候，我们需要先将弱引用的指针地址存储起来。当弱引用的对象释放的时候在将弱引用置为空。
**SideTables**又登场了
![IMAGE](resources/7D99BC0227ACE629B627700B119C657B.jpg =509x65)
SideTables是一张存储SideTable的全局表。在真机中拥有8张SideTable表，模拟器中拥有64张SideTable表。

**SideTable**
![IMAGE](resources/0EB7EB6875E427A934D76C7305FC9F4E.jpg =532x400)
从Sidetable中我们发现了weak_table。没错看名字就知道它是一张存储弱引用的表。

**weak_table**
![IMAGE](resources/9F1ADCCFFA2B1790451ACFE4CEE32A8D.jpg =308x111)
weak_table弱引用表中存储的是weak_entry_t。而这个weak_entry_t就是存储的对象和指向这个对象的弱引用地址。

**weak_entry_t**
![IMAGE](resources/F0A0BF6294192AD939C98B6EFA825D8E.jpg =632x567)
看看weak_entry_t最下面的初始化方法。两个参数`(objc_object *newReferent, objc_object **newReferrer)`，有没有想到我们写的简易的弱引用释放的方法中的`void*`和`void**`

**2. 释放的问题**
那么现在的问题就是什么时候调用weak方法将原来的指针改为nil。其实从上面代码已经看出来了，当原对象释放的时候将其置为空值。而原对象释放实际是调用了根类的rootDealloc方法。
![IMAGE](resources/AACA4C862B627214E1A53F66C25CEC36.jpg =462x294)
发现果然在释放时候有`weakly_referenced`的判断，如果有弱引用显然走后面的`object_dispose`方法。
**object_dispose**
![IMAGE](resources/B4C836D0FC62F079BD5A6CD3404F6350.jpg =276x171)

**objc_destructInstance**
![IMAGE](resources/DD1267B8269A66ECC1A9CAC2A63DBF40.jpg =450x248)

**clearDeallocating**
![IMAGE](resources/783D3EECD83E75A9ED8C24FFA4646020.jpg =590x248)

**clearDeallocating_slow**
![IMAGE](resources/CB950BDDCB181983C6B461C46F3B5444.jpg =579x262)
到这里我们终于看到了如果有`weakly_referenced`就会获取SideTable进行弱引用的设置。

**weak_clear_no_lock**
![IMAGE](resources/DD536967D9183D635D9856CFDBDB3BDA.jpg =724x713)
可以看到最后通过`objc_object **referrer`将`*referrer = nil;`设为nil。

### 4.从`deallocating`聊聊对象释放时做了什么工作
我们知道对象释放时会走`dealloc`方法，并且这个方法特殊的地方在两点。一是不能在方法里面使用对自身的弱引用，另外一个是不能调用父类的`dealloc`方法。
**1. 为什么不能使用自身的弱引用？**
![IMAGE](resources/37B6EFABF55EDF4E0A108AB6FE1E6173.jpg =836x743)
当调用dealloc方法时候，对象此时的状态已经是正在释放了。此时进行弱引用会抛出`_objc_fatal`的错误。

**2. 为什么不能调用父类的方法？**
当你实现dealloc方法时候，编译器实际上已经默认给你加上了根类的`rootDealloc`方法调用。并且是添加在dealloc方法的最后面，为什么会这样，因为在根类的dealloc方法中，已经将指针所指向的内存释放掉了。如果你自己进行根类的调用，我们一般将父类的调用写在方法的最开始，然而根类的dealloc恰恰相反。可能是怕我们写的有问题，编译器直接将父类的调用插入在dealloc方法末尾。实际上在MRC情况下，dealloc方法的使用是在方法的末尾添加`[super dealloc];`。

**3. dealloc方法做了什么？**
dealloc方法最终会调用根类的`rootDealloc`方法。
![IMAGE](resources/9972425ED508D6C529590B768A572895.jpg =460x317)
1.判断是否是tagged pointer，如果是标记指针，直接返回。
2.判断是否是nonpointer优化指针
3.判断有没有弱引用
4.判断有没有关联对象
4.判断有没有c++析构方法
5.判断有没有额外的sidetable引用计数

### 5.从`has_sidetable_rc`和`extra_rc`聊聊OC对象的内存管理
OC对象的内存管理采用的引用计数的方法。每个对象都有一个引用计数值。当一个对象被强引用的时候，引用计数的值就加一，当一个对象的引用计数值为0时就将对象释放。而对象存储引用计数的位置在两个地方。一个是isa_t优化指针中的`extra_rc`，当`extra_rc`不够存储时在采用`SideTable`存储。
![IMAGE](resources/95E5B3143DE1E9AB0810F5A6A3002E45.jpg =520x338)
从`rootRetainCount`方法中就能发现，获取一个对象的引用值就是获取`extra_rc`和`SideTable`中存储的值。

### 扩展
**联合体**
使用`union`声明的结构就是联合体。联合体和结构体的区别是，结构体当中每个成员变量都有各自的内存区域，而联合体中各个成员变量是公用同一块内存。那么显然一个联合体的长度等于其内部长度最大的成员的长度。一旦使用联合体其中的一个类型初始化之后，最好将其一直当做那个类型使用。比如一个联合体包含一个int类型（4字节）和一个double类型（8字节）两个成员。如果你将其当做double类型进行的初始化，那么最好使用的时候也将其当做double类型使用，虽然也可以当做int类型使用，但是当做int类型时，取值的时候就会仅仅用其中的4个字节。

**位域**
我们也看到这个联合体中有一个结构体类型，但与一般的结构体不同的是，结构体中每个成员的后面跟了一个冒号及数字，这其实就是结构体位域的用法。位域是一种特殊的结构体成员，允许我们按位对成员进行定义，指定其占用的位数。我们通常使用的内存单位为字节，一个字节占8位，通过使用位域我们可以定义一个字节大小，但是含有8个成员，每个成员占1位的结构体。
```
typedef struct{
    uintptr_t bit_0 : 1;
    uintptr_t bit_1 : 1;
    uintptr_t bit_2 : 1;
    uintptr_t bit_3 : 1;
    
    uintptr_t bit_4 : 1;
    uintptr_t bit_5 : 1;
    uintptr_t bit_6 : 1;
    uintptr_t bit_7 : 1;
}StructByte;
```
当然因为每个成员只占有一位的大小。所以每个成员变量也只能存储0或1
结合联合体和位域我们也可以有一些比较有趣的用法，比如快速获取一个字节中的某位二进制值。
```
#define Bits struct{ \
    uintptr_t bit_0 : 1; \
    uintptr_t bit_1 : 1; \
    uintptr_t bit_2 : 1; \
    uintptr_t bit_3 : 1; \
    uintptr_t bit_4 : 1; \
    uintptr_t bit_5 : 1; \
    uintptr_t bit_6 : 1; \
    uintptr_t bit_7 : 1; \
}

typedef union{
    char ptr;
    Bits;
}CharUnion;

```

## 参考
1. https://draveness.me/isa/
2. https://juejin.cn/post/6872655753174810631
3. https://blog.devtang.com/2014/05/30/understand-tagged-pointer/