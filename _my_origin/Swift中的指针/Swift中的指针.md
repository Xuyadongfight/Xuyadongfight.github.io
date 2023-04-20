## 1.MemoryLayout

### size
```
//        MemoryLayout<T>.size //当是具体类型时
//        MemoryLayout.size(ofValue: instance) //当是一个实例时
        let size1 = MemoryLayout<Int>.size
        let size2 = MemoryLayout.size(ofValue: Int())
```
以字节为单位的连续的内存占用。
一个类型的大小不包含动态分配的或者行外存储(非连续的内存占用)。当T是类类型时，无论T有多少存储属性，size都是相同的。当使用不安全的指针为T的多个实例分配内存时，使用该类型的stride的倍数而不是size。

### alignment
```
        //        MemoryLayout<T>.alignment //当是具体类型时
        //        MemoryLayout.alignment(ofValue: instance) //当是一个实例时
        let alignment1 = MemoryLayout<Int>.alignment
        let alignment2 = MemoryLayout.alignment(ofValue: Int())
```
以字节为单位的T类型的默认内存对齐。
使用不安全指针分配内存时，使用内存对齐。这个值总是正的。

### stride
```
//        MemoryLayout<T>.stride //当是具体类型时
//        MemoryLayout.stride(ofValue: instance) //当是一个实例时
        let stride1 = MemoryLayout<Int>.stride
        let stride2 = MemoryLayout.stride(ofValue: Int())
```
当存储在连续内存中或存储在数组Array<T>中。一个T类型的实例的开始到下一个T类型的实例开始的字节数。也就是两个连续实例之间起点的间隔字节数。
这个值与`UnsafePointer<T>`实例增加时移动的字节数相同。T类型可能具有较低的最小对齐，以运行时性能换区空间的效率。这个值总是正的。

### MemoryLayout总结

* size的大小是**连续**的内存占用。当是类类型时候，无论类有多少存储属性。size都一样。

```
class ClassA{
}

class ClassB{
    var propertyInt : Int = 10
    var propertyString : String = "test"
   // var propertyClass : ClassB = ClassB()  //不要在一个类中定义一个类本身的初始化，否则会进入无限递归
    var propertyClass : ClassA = ClassA()
}
let sizeA = MemoryLayout<ClassA>.size
let sizeB = MemoryLayout<ClassB>.size
print("sizeA = \(sizeA),sizeB = \(sizeB)")
// sizeA = 8,sizeB = 8
```

* alignment是默认的内存对齐的大小，即存储每个类型的开始地址都是alignment的倍数。

```
        var classA = ClassA()
        var classB = ClassB()
        let alignmentA = MemoryLayout.alignment(ofValue: classA)
        let alignmentB = MemoryLayout.alignment(ofValue: classB)
        print("alignmentA = \(alignmentA),alignmentB = \(alignmentB)")
        
        withUnsafeMutablePointer(to: &classA) { pointerA in
            print("A start address = \(pointerA)")
        }
        withUnsafeMutablePointer(to: &classB) { pointerB in
            print("B start address = \(pointerB)")
        }
        // alignmentA = 8,alignmentB = 8
        // A start address = 0x00007ff7b78b2230
        // B start address = 0x00007ff7b78b2228
        
```
可以看到存储A和B的内存起始地址都是对齐值8的倍数


* stride表示的是当连续存储相同类型时，相邻两个类型的起始地址间隔是stride
其实stride就是size+内存对齐需要的字节


### 假设基础类型

```
MemoryLayout<Int>.size = 8
MemoryLayout<Int>.alignment = 8
MemoryLayout<Int>.stride = 8
```

那么实际存储Int类型值的是8个字节；Int类型的数据的起始地址要能被8整除。即起始地址是8的倍数；多个Int连续存储的时候，每个Int类型的起始地址之间间距为步幅8；

### 假设结构体类型布局
```
struct SampleStruct{
    let number:UInt32
    let flag : Bool
}
MemoryLayout<SampleStruct>.size = 5
MemoryLayout<SampleStruct>.alignment = 4
MemoryLayout<SampleStruct>.stride = 8
```

那么实际存储SampleStruct类型值的是5个字节；SampleStruct类型的数据的起始地址要能被4整除。即起始地址是4的倍数；多个SampleStruct连续存储的时候，每个SampleStruct类型的起始地址之间间距为步幅8；

### 推论

* size实际大小很简单，就是结构体中的类型的实际大小相加
* alignment也很简单，就是结构体中类型最大的size值
* stride实际上很容易根据size和alignment推导出来。同一类型的数据连续存储，那么他们之间的间隔肯定要大于等于实际大小size。就SampleStruct来说。就是stride肯定要大于等于5。又因为下一个SampleStruct类型的数据的起始地址要是4的倍数。那么显然大于5且是4的倍数的值为8。故stride的值为8。

## 2.指针类型

![IMAGE](resources/DB13C2A47528EE24802F865933CDE993.jpg =685x483)

## 3.使用

### 1.直接创建指针

```
class SwiftPointer {
    
    class func start(){
        let memLayoutInt = MemoryLayout<Int>.self
        let count = 2
        let byteCount = memLayoutInt.stride * count
        
        //raw pointer(匿名指针)
        do{
            print("raw pointer")
            let pointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: memLayoutInt.alignment)
            defer {
                pointer.deallocate()
            }
            
            pointer.storeBytes(of: 100, as: Int.self)
            pointer.advanced(by: memLayoutInt.stride).storeBytes(of: 1000, as: Int.self)
            let firstInt = pointer.load(as: Int.self)
            let secondInt = pointer.load(fromByteOffset: memLayoutInt.stride, as: Int.self)
            
            print("first = \(firstInt),second = \(secondInt)")
            
            let bufferPointer = UnsafeRawBufferPointer(start: pointer, count: byteCount)
            for (index,value) in bufferPointer.enumerated(){
                print("index = \(index), value = \(value)")
            }
        }

        //type pointer(类型指针)
        do{
            print("type pointer")
            let pointer = UnsafeMutablePointer<Int>.allocate(capacity: count)
            pointer.initialize(repeating: 0, count: count)
            defer {
                pointer.deinitialize(count: count)
                pointer.deallocate()
            }
            pointer.pointee = 100
            pointer.advanced(by: 1).pointee = 1000
            
            let firstInt = pointer.pointee
            let secondInt = pointer.advanced(by: 1).pointee
            print("first = \(firstInt),second = \(secondInt)")
            
            let bufferPointer = UnsafeBufferPointer(start: pointer, count: count)
            for (index,value) in bufferPointer.enumerated(){
                print("index = \(index), value = \(value)")
            }
        }
        
         // raw pointer convert to type pointer (匿名指针转换为类型指针)
        do{
            print("Converting raw pointers to typed pointers")
            
            let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: memLayoutInt.alignment)
            let typedPointer = rawPointer.bindMemory(to: Int.self, capacity: count)
            typedPointer.initialize(repeating: 0, count: count)
            defer{
                rawPointer.deallocate()
                typedPointer.deinitialize(count: count)
            }
            
            typedPointer.pointee = 100
            typedPointer.advanced(by: 1).pointee = 1000
            
            let bufferPointer = UnsafeBufferPointer(start: typedPointer, count: count)
            for (index,value) in bufferPointer.enumerated(){
                print("index = \(index), value = \(value)")
            }
        }
    }
}

```

### 2.获取变量的指针
```
        do{
            var int_value = 123456789
            print("Getting the pointer of an instance")
            //获取不可变指针
            withUnsafePointer(to: &int_value) { p in
                print(p,p.pointee)
            }
            print(int_value)
            
            //获取可变指针
            withUnsafeMutablePointer(to: &int_value) { mp in
                mp.pointee = 100
                print(mp,mp.pointee)
            }
            print(int_value)
            
            print("Getting the bytes of an instance")
            //获取变量的的每个字节的值
            withUnsafeBytes(of: &int_value) { bufferp in
                for (index,value) in bufferp.enumerated(){
                    print("index = \(index),value = \(value)")
                }
            }
            
        }
```

## 4.使用Swift指针需要注意
### 1.不要从withUnsafeBytes返回指针
```
        // Rule #1
        do {
          print("1. Don't return the pointer from withUnsafeBytes!")
          
          var int_value = 100
          
          let bytes = withUnsafeBytes(of: &int_value) { bytes in
            return bytes // strange bugs here we come ☠️☠️☠️
          }
          print("Horse is out of the barn!", bytes) // undefined!!!
        }
```

### 2.一次只绑定一种类型!
```
// Rule #2
do {
  print("2. Only bind to one type at a time!")
  
  let count = 3
  let stride = MemoryLayout<Int16>.stride
  let alignment = MemoryLayout<Int16>.alignment
  let byteCount = count * stride
  
  let pointer = UnsafeMutableRawPointer.allocate(
    byteCount: byteCount,
    alignment: alignment)
  
  let typedPointer1 = pointer.bindMemory(to: UInt16.self, capacity: count)
  
  // Breakin' the Law... Breakin' the Law (Undefined behavior)
  let typedPointer2 = pointer.bindMemory(to: Bool.self, capacity: count * 2)
  
  // If you must, do it this way:
  typedPointer1.withMemoryRebound(to: Bool.self, capacity: count * 2) {
    (boolPointer: UnsafeMutablePointer<Bool>) in
    print(boolPointer.pointee) // See Rule #1, don't return the pointer
  }
}
```

### 3.不要越界
```
// Rule #3... wait
do {
  print("3. Don't walk off the end... whoops!")
  
  let count = 3
  let stride = MemoryLayout<Int16>.stride
  let alignment = MemoryLayout<Int16>.alignment
  let byteCount =  count * stride
  
  let pointer = UnsafeMutableRawPointer.allocate(
    byteCount: byteCount,
    alignment: alignment)
  let bufferPointer = UnsafeRawBufferPointer(start: pointer, count: byteCount + 1) 
  // OMG +1????
  
  for byte in bufferPointer {
    print(byte) // pawing through memory like an animal
  }
}
```

## 5.几个具体例子
### 1.通过指针修改变量的值
```
    class func test(){
        var a = 10
        withUnsafeMutablePointer(to: &a) { pa in
            pa.pointee = 100
        }
        print(a)
    }
```
### 2.通过指针修改结构体的值
```
struct SampleStruct {
    var number : Int
    var flag : Bool
    mutating func headPointerOfStruct()->UnsafeMutableRawPointer{
        withUnsafeMutablePointer(to: &self){UnsafeMutableRawPointer($0)}
    }
}

func Test(){
    var temp = SampleStruct(number: 32, flag: false)
    print("raw temp = \(temp)")
    let rawPointer = temp.headPointerOfStruct()
    rawPointer.assumingMemoryBound(to: Int.self).pointee = 101
    rawPointer.advanced(by: MemoryLayout<Int>.stride).assumingMemoryBound(to: Bool.self).pointee = true
    print("new temp = \(temp)")
}
```
### 3.通过指针修改对象的值
```
class Human{
    var age : Int?
    var name : String?
    var nicknames : [String] = [String]()
    
    func headPointerOfStruct()->UnsafeMutableRawPointer{
        var temp = self
       return withUnsafeMutablePointer(to: &temp){UnsafeMutableRawPointer($0)}
    }
    func description() -> String {
        return "age = \(self.age ?? 0) , name = \(self.name ?? "") , nicknames = \(self.nicknames)"
    }
}

func Test_Class(){
    let temp = Human()
    temp.age = 10
    temp.name = "raw name"
    temp.nicknames = ["nick_a,nick_b"]
    print(temp.description())
    
    //获取对象的基础地址
    let base_class_pointer = temp.headPointerOfStruct().assumingMemoryBound(to: UnsafeMutableRawPointer.self).pointee

    //修改age
    let type_size = 8 //类型所占8字节(64位机器上)
    let refcount_size = 8 //引用计数占8字节
    let base_age = base_class_pointer.advanced(by: type_size).advanced(by: refcount_size).assumingMemoryBound(to: Optional<Int>.self)
    base_age.pointee? = 20
    
    //修改name
    let stride_age = MemoryLayout<Optional<Int>>.stride
    let base_name = UnsafeMutableRawPointer(base_age).advanced(by: stride_age).assumingMemoryBound(to: Optional<String>.self)
    base_name.pointee? = "new name"
    
    //修改nicknames
    let stride_name = MemoryLayout<Optional<String>>.stride
    let base_nicknames = UnsafeMutableRawPointer(base_name).advanced(by: stride_name).assumingMemoryBound(to: Array<String>.self)
    let newNicknames = ["new_nick_a,new_nick_b"]
    base_nicknames.pointee = newNicknames
    
    print(temp.description())
}

```
主要通过`UnsafeMutableRawPointer`将类型指针转为匿名指针，这样使用`advanced`移动时，每次移动的单位为一个字节。再通过`assumingMemoryBound`将匿名指针转换为类型指针。修改其指向的值。

## 6.总结
### 1.对于匿名指针（类型不确定指针）
匿名指针一般创建可修改的匿名指针,如果创建不可修改的匿名指针没什么意义。创建匿名指针，因为是匿名类型所以需要知道指针所指内存大小及存储内容时的对齐方法。使用`storeBytes`方法赋值，使用`load`方法读取值。可以使用`advanced`调整指针的位置。最后不要忘记释放内存。
**注意：因为是匿名指针，所以存储数据和读取数据时都需要指定类型，并且指针移动的基础单位是一个字节**
```
        do{
            let mPointer = UnsafeMutableRawPointer.allocate(byteCount: 4*2, alignment: 4)
            defer{
                mPointer.deallocate()
            }
            mPointer.storeBytes(of: 10, as: Int32.self)
//            mPointer.storeBytes(of: 20, toByteOffset: 4, as: Int32.self)
            mPointer.advanced(by: 4).storeBytes(of: 20, as: Int32.self)

            let res = mPointer.advanced(by: 4).load(as: Int32.self)
            print("res = ",res)
        }
```
### 2.对于类型指针（已知指针类型）
类型指针因为已经知道具体的类型，所以创建的时候只需要指定容量即可。实际所占字节的大小为`MemoryLayout<具体类型>.stride * count`。且因为知道具体类型，可以直接加i类似于数组下标进行偏移，而不需要计算真正偏移了多少个字节。
**注意：因为已经知道具体类型，所以存储数据和读取数据都是指定的类型，在进行指针的偏移的时候，使用的基础单位是`MemoryLayout<具体类型>.stride`**
```
        do{
            let intPointer = UnsafeMutablePointer<Int>.allocate(capacity: 4)
            defer{
                intPointer.deallocate()
            }
            for i in 0..<4 {
//                (intPointer + i).initialize(to: i)
//                intPointer.advanced(by: i).initialize(to: i)
                intPointer.advanced(by: i).pointee = i
            }
            for i in 0..<4{
                print(intPointer.advanced(by: i).pointee)
            }
        }
```

### 3.类型转换
可以使用`bindMemory`将匿名指针转换为类型指针。
```
        do{
            let mPointer = UnsafeMutableRawPointer.allocate(byteCount: 4*2, alignment: 4)
            
            defer{
                mPointer.deallocate()
            }
            mPointer.storeBytes(of: 10, as: Int32.self)
//            mPointer.storeBytes(of: 20, toByteOffset: 4, as: Int32.self)
            mPointer.advanced(by: 4).storeBytes(of: 20, as: Int32.self)

            let res = mPointer.advanced(by: 4).load(as: Int32.self)
            print("res = ",res)
            
            //转换为确定类型指针
            let newTypePointer = mPointer.bindMemory(to: Int32.self, capacity: 2)
            print(newTypePointer.pointee,newTypePointer.advanced(by: 1).pointee)
        }
```
**注意：转换为类型指针后，内存还是同一块，可以使用原来的匿名指针管理内存，也可以使用新的类型指针管理内存，但是不可以同时使用两种。因为实际上指向的是同一块内存。**

## 7.扩展
### OpaquePointer

不透明指针用于表示无法在Swift中表示的类型的C指针，例如不完整的结构类型。
当使用C库时，一些指针被导入为不透明指针，但其他指针被导入为unsafepointer<T>。差异可以在C头文件中找到。当一个结构体person在头文件中被完全定义后，任何指向它的指针都会被Swift导入为UnsafePointer<T>;。这意味着我们还可以对指针解引用，并通过调用指针上的pointee来查看其内容。例如，在下面的C头文件中，我们有关于person结构体的完整信息:
```
// sample.h
typedef struct person person;
struct person {
    int age;
    char *first_name;
};
void person_print(person*);
```
当我们从Swift中使用person_print时，它被导入为func person_print(_:UnsafeMutablePointer<person>!)。因为person在头文件中，所以我们也得到了person的构造函数，以及它的属性的访问器:
```
let p = person(age: 33, first_name: strdup("hello"))
print("person: \(p.age)")
free(p.first_name)
```
C中的另一个常见做法是保持结构定义不完整。例如，考虑这样一个头文件:
```
typedef struct account account;
void account_print(account*);
```
上面的头文件没有提供account结构的定义，只有一个typedef。该定义在实现文件中找到，在sample.m之外不可见:
```
// sample.m
struct account {
    int account_number;
    char *first_name;
};
```
因为account只在头文件中，所以它被称为不透明(或者有时:不完整)类型:从外部看，我们对它一无所知。
这意味着在Swift中我们不能获得它的初始化器，我们不能访问帐户的属性，等等。即使在account_print中，也没有提到帐户类型。它被导入为function account_print(_: OpaquePointer!)。不透明指针是Swift让你知道你在处理一个不透明指针的方式。

### Unmanaged

用来传播一个没有托管的引用对象的类型。当使用这个类型时，你需要部分的负责保持对象的存活。简单理解就是这个类型可以用来自己管理对象的内存。可以用来将对象转换为指针，或将指针转换为对象。并且可以进行内存管理。

#### 1.将对象转换为Unmanaged结构
```
class Test{
    var num = 10
    init(num:Int) {
        self.num = num
    }
    deinit {
        print("deinit \(self) \(self.num)")
    }
}

func Test_unmanaged1(){
    let instance = Test(num: 10)
    
    //将对象转为Unmanaged结构。并且unmanaged_auto不负责管理对象内存。还是由系统自动管理对象内存
    let unmanaged_auto = Unmanaged.passUnretained(instance)
    
    //将对象转为Unmanaged结构。由unmanaged_no_auto管理对象内存,要想正确释放对象内存需要调用release方法
    let unmanaged_no_auto = Unmanaged.passRetained(instance)
    /*
     本质上
     let unmanaged_no_auto = Unmanaged.passRetained(instance)
     等价于
         let unmanaged_auto = Unmanaged.passUnretained(instance)
         unmanaged_auto.retain()
     所以要想unmanaged_no_auto正确管理内存，需要它调用release方法
     unmanaged_no_auto.release()
     */
    unmanaged_no_auto.release()
}
```

#### 2.Unmanaged结构的内存管理

```
func Test_unmanaged2(){
    let instance = Test(num: 20)
    let unmanaged_no_auot = Unmanaged.passUnretained(instance)
    
    /*
     swift对象还是使用引用计数管理内存。当讲对象管理从自动管理移交到手动管理时候，retain,release必须成对出现
     */
    unmanaged_no_auot.retain()//
    unmanaged_no_auot.release()
}
```

#### 3.获取对象的指针

```
func Test_unmanaged3(){
    let instance = Test(num: 30)
    let unmanaged_no_auot = Unmanaged.passUnretained(instance)
    /*
     获取对象指针,因为并没有retain操作。所以只在方法内部使用指针。否则当方法结束，对象释放后，指针会指向已回收的内存
     */
    let pointer = unmanaged_no_auot.toOpaque()
    print(pointer)
}
```

#### 4.从Unmanaged结构获取对象

```
func Test_unmanaged4(){
    let instance = Test(num: 40)
    let unmanaged_no_auot = Unmanaged.passUnretained(instance)
    let instance_origin = unmanaged_no_auot.takeUnretainedValue()
    print(instance_origin)
}
```
#### 5.总结
我们可以这样理解。引用计数的内存管理需要retain和release达到一种平衡。即retain和release的数量要一样。编译器的自动管理内存和手动管理内存都有各自的平衡生态。当两种生态相互作用的时候，需要总的retain和release达到平衡。否则就会产生内存泄漏。而在自动管理内存转为手动管理内存或者手动管理内存转为自动管理内存的过程中都有各自相互影响或不影响的方法。

```
func Test_unmanaged5(){
    let instance = Test(num: 50)
    
    /*自动管理内存到手动管理内存*/
    //没有破坏管理内存平衡。等价于即没有retain也没有release
    let unmanaged_auto = Unmanaged.passUnretained(instance)
    
    //破坏了管理内存平衡。此时相当于主动给unmanaged_no_auto调用了一次retain方法。
    let unmanaged_no_auto = Unmanaged.passRetained(instance)
    
    
    /*手动管理内存到自动管理内存*/
    //没有破坏管理内存平衡。等价于即没有retain也没有release
    let instance_auto = unmanaged_auto.takeUnretainedValue()
    
    //破坏了管理内存的平衡，相当于主动给unmanaged_no_auto调用了一次release方法
    let instance_no_auto = unmanaged_no_auto.takeRetainedValue()

}
```

 

## 引用
**1.** https://www.kodeco.com/7181017-unsafe-swift-using-pointers-and-interacting-with-c
**2.** https://www.objc.io/blog/2018/01/30/opaque-vs-unsafe-pointers/