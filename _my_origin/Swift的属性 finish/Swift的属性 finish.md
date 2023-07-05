Swift属性分为存储属性和计算属性
存储属性存储常量或变量作为实例的一部分。由类和结构体提供。
计算属性则计算(而不是存储)一个值。由类，结构和枚举提供。
属性观察者
属性包装器重用

## 存储属性
存储属性可以通过关键字var设置为变量存储属性或者使用关键字let设置为常量存储属性。可以通过在定义时给存储属性设置默认值。也可以在初始化期间设置和修改存储属性的值。即使对于常量存储属性也是可以的。
```
struct FixedLengthRange {
    var firstValue: Int
    let length: Int
}
var rangeOfThreeItems = FixedLengthRange(firstValue: 0, length: 3)
// the range represents integer values 0, 1, and 2
rangeOfThreeItems.firstValue = 6
// the range now represents integer values 6, 7, and 8
```
在上面的例子中，FixedLengthRange的实例有一个变量存储属性firstValue和一个常量存储属性length。length在创建新的FixedLengthRange的实例的时候初始化。此后就不能在更改了，因为它是一个常量存储属性。

### 常量结构体实例的存储属性
如果你创建一个常量结构体实例，你就不能在修改它的属性了，尽管该属性被定义为变量存储属性。
```
let rangeOfFourItems = FixedLengthRange(firstValue: 0, length: 4)
// this range represents integer values 0, 1, 2, and 3
rangeOfFourItems.firstValue = 6
// this will report an error, even though firstValue is a variable property
```
因为使用let关键字将rangeOfFourItems声明为常量。所以firstValue属性不能再被修改了。尽管它是一个变量存储属性。
这种行为是由于结构体是值类型。当一个值类型的实例被标记为常量时，它的所有属性也被标记为常量。
对于类则不是这样，类是引用类型。如果将引用类型的实例赋值给常量，仍然可以更改该实例的变量属性。

### 惰性存储属性（懒加载存储属性）
惰性存储属性是一种属性，它的初始值直到第一次使用时才计算出来。通过在惰性存储属性声明之前编写惰性修饰符来指示惰性存储属性。
**注意：
必须始终将惰性属性声明为变量(使用var关键字)，因为在实例初始化完成之前，可能无法检索其初始值。常量属性在初始化完成之前必须始终有一个值，因此不能声明为惰性属性。**

当属性的初始值依赖于外部因素时，惰性属性是有用的，这些外部因素的值直到实例初始化完成后才知道。当属性的初始值需要进行复杂或计算开销较大的设置时，惰性属性也很有用，除非需要，否则不应该执行这些设置。

下面的示例使用lazy存储属性来避免复杂类的不必要初始化。这个例子定义了两个名为DataImporter和DataManager的类，它们都没有完整显示:
```
class DataImporter {
    /*
    DataImporter is a class to import data from an external file.
    The class is assumed to take a nontrivial amount of time to initialize.
    */
    var filename = "data.txt"
    // the DataImporter class would provide data importing functionality here
}


class DataManager {
    lazy var importer = DataImporter()
    var data: [String] = []
    // the DataManager class would provide data management functionality here
}


let manager = DataManager()
manager.data.append("Some data")
manager.data.append("Some more data")
// the DataImporter instance for the importer property hasn't yet been created
```
DataManager类有一个名为data的存储属性，该属性是用一个新的String值空数组初始化的。虽然没有显示它的其他功能，但这个DataManager类的目的是管理并提供对这个String数据数组的访问。

DataManager类的部分功能是从文件导入数据的能力。这个功能是由DataImporter类提供的，它被认为需要花费大量的时间来初始化。这可能是因为在初始化DataImporter实例时，DataImporter实例需要打开文件并将其内容读入内存。

因为DataManager实例可以在不从文件导入数据的情况下管理其数据，所以在创建DataManager本身时，DataManager并不创建新的DataManager实例。相反，在首次使用DataImporter实例时创建它更有意义。

因为它被标记为lazy修饰符，所以importer属性的DataImporter实例只在第一次访问importer属性时创建，比如当它的filename属性被查询时:
```
print(manager.importer.filename)
// the DataImporter instance for the importer property has now been created
// Prints "data.txt"
```
**注意：
如果一个带有lazy修饰符的属性被多个线程同时访问，并且该属性还没有被初始化，那么不能保证该属性只被初始化一次。**

### 存储属性和实例变量
如果你有Objective-C的经验，你可能知道它提供了两种方法来存储值和引用作为类实例的一部分。除了属性之外，您还可以使用实例变量作为存储在属性中的值的后备存储。
Swift将这些概念统一到一个属性声明中。Swift属性没有对应的实例变量，属性的后备存储也不能直接访问。这种方法避免了在不同上下文中如何访问该值的混淆，并将属性的声明简化为单个明确的语句。关于属性的所有信息——包括它的名称、类型和内存管理特征——作为类型定义的一部分定义在一个位置。

## 计算属性
除了存储属性之外，类、结构体和枚举还可以定义计算属性，这些属性实际上并不存储值。相反，它们提供了一个getter和一个可选的setter来间接地检索和设置其他属性和值。
```
struct Point {
    var x = 0.0, y = 0.0
}
struct Size {
    var width = 0.0, height = 0.0
}
struct Rect {
    var origin = Point()
    var size = Size()
    var center: Point {
        get {
            let centerX = origin.x + (size.width / 2)
            let centerY = origin.y + (size.height / 2)
            return Point(x: centerX, y: centerY)
        }
        set(newCenter) {
            origin.x = newCenter.x - (size.width / 2)
            origin.y = newCenter.y - (size.height / 2)
        }
    }
}
var square = Rect(origin: Point(x: 0.0, y: 0.0),
    size: Size(width: 10.0, height: 10.0))
let initialSquareCenter = square.center
// initialSquareCenter is at (5.0, 5.0)
square.center = Point(x: 15.0, y: 15.0)
print("square.origin is now at (\(square.origin.x), \(square.origin.y))")
// Prints "square.origin is now at (10.0, 10.0)"
```
这个例子定义了三个处理几何图形的结构:
Point封装了点的x坐标和y坐标。
Size封装了宽度和高度。
Rect通过一个原点和一个大小来定义一个矩形。
Rect结构还提供了一个名为center的计算属性。Rect的当前中心位置总是可以从其原点和大小确定，因此您不需要将中心点存储为显式的point值。相反，Rect为一个名为center的计算变量定义了一个自定义的getter和setter，使您能够像处理实际存储的属性一样处理矩形的中心。
上面的例子创建了一个名为square的Rect变量。square变量初始化为原点(0,0)，宽度和高度为10。
然后通过点语法(square.center)访问square变量的center属性，这将导致调用center的getter来检索当前属性值。getter实际上计算并返回一个新的Point来表示正方形的中心，而不是返回一个现有的值。getter正确地返回中心点(5,5)。
然后将center属性设置为新值(15,15)，设置center属性会调用center的setter，它会修改存储的origin属性的x和y值，并将正方形移动到新的位置。

### 简写的Setter声明
如果计算属性的setter没有为要设置的新值定义名称，则使用newValue的默认名称。下面是Rect结构的另一个版本，它利用了这种简写表示法:
```
struct AlternativeRect {
    var origin = Point()
    var size = Size()
    var center: Point {
        get {
            let centerX = origin.x + (size.width / 2)
            let centerY = origin.y + (size.height / 2)
            return Point(x: centerX, y: centerY)
        }
        set {
            origin.x = newValue.x - (size.width / 2)
            origin.y = newValue.y - (size.height / 2)
        }
    }
}
```
### 简写Getter声明
如果getter的整个主体是单个表达式，则getter隐式返回该表达式。下面是Rect结构的另一个版本，它利用了这种简写表示法和setter的简写表示法:
```
struct CompactRect {
    var origin = Point()
    var size = Size()
    var center: Point {
        get {
            Point(x: origin.x + (size.width / 2),
                  y: origin.y + (size.height / 2))
        }
        set {
            origin.x = newValue.x - (size.width / 2)
            origin.y = newValue.y - (size.height / 2)
        }
    }
}
```
### 只读计算属性
具有getter但没有setter的计算属性称为只读计算属性。只读计算属性总是返回一个值，并且可以通过点语法访问，但不能设置为不同的值。
 
**注意：
必须使用var关键字将计算属性(包括只读计算属性)声明为可变属性，因为它们的值不是固定的。let关键字仅用于常量属性，表明它们的值一旦作为实例初始化的一部分被设置，就不能被更改。**
你可以通过删除get关键字及其大括号来简化只读计算属性的声明:
```
struct Cuboid {
    var width = 0.0, height = 0.0, depth = 0.0
    var volume: Double {
        return width * height * depth
    }
}
let fourByFiveByTwo = Cuboid(width: 4.0, height: 5.0, depth: 2.0)
print("the volume of fourByFiveByTwo is \(fourByFiveByTwo.volume)")
// Prints "the volume of fourByFiveByTwo is 40.0"
```
这个例子定义了一个名为Cuboid的新结构，它表示一个具有宽度、高度和深度属性的3D矩形框。这个结构还有一个只读的计算属性，叫做volume，它计算并返回长方体的当前体积。设置体积是没有意义的，因为对于一个特定的体积值应该使用哪个宽度、高度和深度值是不明确的。尽管如此，对于一个Cuboid来说，提供一个只读的计算属性以使外部用户能够发现其当前计算的体积是很有用的。

## 属性观察者
属性观察者观察并响应属性值的变化。每次设置属性值时都会调用属性观察器，即使新值与属性的当前值相同。
可以在以下地方添加属性观察者:
* 定义存储属性时
* 继承存储属性时
* 继承计算属性时
对于继承属性，可以通过在子类中重写该属性来添加属性观察者。对于你定义的计算属性，请使用属性的setter来观察并响应值的更改，而不是尝试创建一个观察者。重写属性的描述见重写。你可以选择在属性上定义这两个观察者中的一个或两个:
* 将在存储值之前调用willSet
* 在存储新值后立即调用didSet
如果你实现了一个willSet观察者，它会将新的属性值作为一个常量参数传递给你。您可以为这个参数指定一个名称，作为willSet实现的一部分。如果您没有在实现中编写参数名称和括号，则可以使用默认参数名称newValue来提供该参数。
类似地，如果你实现一个didSet观察者，它会传递一个包含旧属性值的常量参数。可以为参数命名，也可以使用oldValue的默认参数名。如果你给一个属性在它自己的didSet观察者内赋值，你赋的新值会替换刚刚设置的那个值。
 
**注意：
超类属性的willSet和didSet观察者会在超类初始化器被调用后，在子类初始化器中设置属性时被调用。在超类初始化器被调用之前，在类设置自己的属性时不会调用它们。**
```
class StepCounter {
    var totalSteps: Int = 0 {
        willSet(newTotalSteps) {
            print("About to set totalSteps to \(newTotalSteps)")
        }
        didSet {
            if totalSteps > oldValue  {
                print("Added \(totalSteps - oldValue) steps")
            }
        }
    }
}
let stepCounter = StepCounter()
stepCounter.totalSteps = 200
// About to set totalSteps to 200
// Added 200 steps
stepCounter.totalSteps = 360
// About to set totalSteps to 360
// Added 160 steps
stepCounter.totalSteps = 896
// About to set totalSteps to 896
// Added 536 steps
```
StepCounter类声明了一个Int类型的totalSteps属性。这是一个带有willSet和didSet观察者的存储属性。
totalSteps的willSet和didSet观察者会在属性被赋新值时被调用。即使新值与当前值相同，也是如此。
本例的willSet观察者使用一个自定义参数名称newTotalSteps来表示即将到来的新值。在本例中，它只是打印出将要设置的值。
didSet观察者在totalSteps的值更新后被调用。它将totalSteps的新值与旧值进行比较。如果总步数增加，则打印一条消息，指示已执行了多少新步数。didSet观察者没有为旧值提供自定义参数名，而是使用了默认的oldValue名。

**注意：
如果你把一个带有观察者的属性作为输入输出参数传递给一个函数，那么willSet和didSet观察者总是会被调用。这是因为输入输出参数的拷贝模式:值总是在函数结束时写回属性。**

## 属性包装器
属性包装器在管理如何存储属性的代码和定义属性的代码之间添加了一层分离。例如，如果您有提供线程安全检查或将其底层数据存储在数据库中的属性，则必须在每个属性上编写该代码。使用属性包装器时，在定义包装器时编写一次管理代码，然后通过将该管理代码应用于多个属性来重用该管理代码。
要定义属性包装器，可以创建定义wrappedValue属性的结构、枚举或类。在下面的代码中，TwelveOrLess结构确保它包装的值总是包含一个小于或等于12的数字。如果你让它存储一个更大的数字，它会存储12。
```
@propertyWrapper
struct TwelveOrLess {
    private var number = 0
    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, 12) }
    }
}
```
setter确保新值小于或等于12,getter返回存储的值。
注意：
上面示例中的number声明将变量标记为私有，这确保number仅在TwelveOrLess的实现中使用。在其他地方编写的代码使用wrappedValue的getter和setter来访问值，而不能直接使用number。
通过将包装器的名称作为特性写在属性之前，可以将包装器应用于属性。下面是一个存储矩形的结构，它使用了TwelveOrLess属性包装器来确保它的尺寸总是小于等于12:
```
struct SmallRectangle {
    @TwelveOrLess var height: Int
    @TwelveOrLess var width: Int
}


var rectangle = SmallRectangle()
print(rectangle.height)
// Prints "0"


rectangle.height = 10
print(rectangle.height)
// Prints "10"


rectangle.height = 24
print(rectangle.height)
// Prints "12"
```
高度和宽度属性从TwelveOrLess的定义中获得初始值，该定义设置了TwelveOrLess的number值为0。TwelveOrLess中的setter将10视为有效值，因此将数字10存储在矩形中。高度照常进行。然而，24比TwelveOrLess允许的要大，所以尝试存储24最终会被替代设置为允许的最大值12。
将包装器应用于属性时，编译器将综合为包装器提供存储的代码和通过包装器提供对属性访问的代码。(属性包装器负责存储包装后的值，因此没有相应的合成代码。)您可以编写使用属性包装器行为的代码，而不需要利用特殊的属性语法。
```
struct SmallRectangle {
    private var _height = TwelveOrLess()
    private var _width = TwelveOrLess()
    var height: Int {
        get { return _height.wrappedValue }
        set { _height.wrappedValue = newValue }
    }
    var width: Int {
        get { return _width.wrappedValue }
        set { _width.wrappedValue = newValue }
    }
}
```
_height和_width属性存储属性包装器的一个实例，即TwelveOrLess。height和width的getter和setter包装为访问属性的wrappedValue

### 设置包装属性的初始值
上面示例中的代码通过在TwelveOrLess的定义中给number一个初始值来设置包装属性的初始值。使用此属性包装器的代码不能为由TwelveOrLess包装的属性指定不同的初始值——例如，SmallRectangle的定义不能给出高度或宽度的初始值。要支持设置初始值或其他自定义，属性包装器需要添加初始化器。下面是TwelveOrLess的扩展版本SmallNumber，它定义了设置包装值和最大值的初始化式:
```
@propertyWrapper
struct SmallNumber {
    private var maximum: Int
    private var number: Int


    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, maximum) }
    }


    init() {
        maximum = 12
        number = 0
    }
    init(wrappedValue: Int) {
        maximum = 12
        number = min(wrappedValue, maximum)
    }
    init(wrappedValue: Int, maximum: Int) {
        self.maximum = maximum
        number = min(wrappedValue, maximum)
    }
}
```
SmallNumber的定义包括三个初始化器——init()、init(wrappedValue:)和init(wrappedValue:maximum:)——下面的示例使用它们来设置包装值和最大值。当你将包装器应用到一个属性并且没有指定初始值时，Swift会使用init()初始化器来设置包装器。例如:
```
struct ZeroRectangle {
    @SmallNumber var height: Int
    @SmallNumber var width: Int
}


var zeroRectangle = ZeroRectangle()
print(zeroRectangle.height, zeroRectangle.width)
// Prints "0 0"
```
通过调用SmallNumber()来创建包含高度和宽度的SmallNumber实例。该初始化器中的代码设置初始包装值和初始最大值，使用默认值0和12。属性包装器仍然提供所有的初始值，就像前面在SmallRectangle中使用TwelveOrLess的示例一样。与该示例不同的是，SmallNumber还支持写入这些初始值，作为声明属性的一部分。当你为属性指定一个初始值时，Swift使用init(wrappedValue:)初始化器来设置包装器。例如:
```
struct UnitRectangle {
    @SmallNumber var height: Int = 1
    @SmallNumber var width: Int = 1
}


var unitRectangle = UnitRectangle()
print(unitRectangle.height, unitRectangle.width)
// Prints "1 1"
```
当您使用包装器在属性上写入=1时，这将被转换为对init(wrappedValue:)初始化器的调用。SmallNumber的包装高度和宽度的实例是通过调用SmallNumber(wrappedValue:1)来创建的。初始化器使用这里指定的包装值，它使用默认最大值12。
当你在自定义属性后面的圆括号中写入参数时，Swift会使用接受这些参数的初始化器来设置包装器。例如，如果你提供了一个初始值和一个最大值，Swift使用init(wrappedValue:maximum:)初始化器:
```
struct NarrowRectangle {
    @SmallNumber(wrappedValue: 2, maximum: 5) var height: Int
    @SmallNumber(wrappedValue: 3, maximum: 4) var width: Int
}


var narrowRectangle = NarrowRectangle()
print(narrowRectangle.height, narrowRectangle.width)
// Prints "2 3"


narrowRectangle.height = 100
narrowRectangle.width = 100
print(narrowRectangle.height, narrowRectangle.width)
// Prints "5 4"
```
通过调用SmallNumber(wrappedValue:2,maximum:5)创建包装高度的SmallNumber实例，通过调用SmallNumber(wrappedValue: 3, maximum: 4)创建包装宽度的实例。
通过向属性包装器包含参数，您可以在包装器中设置初始状态，或者在创建包装器时将其他选项传递给它。这种语法是使用属性包装器的最通用方法。你可以为属性提供任何你需要的参数，它们被传递给初始化器。
当包含属性包装器参数时，还可以使用赋值来指定初始值。Swift把赋值当作一个wrappedValue参数，并使用接受你包含的参数的初始化器。例如:
```
struct MixedRectangle {
    @SmallNumber var height: Int = 1
    @SmallNumber(maximum: 9) var width: Int = 2
}


var mixedRectangle = MixedRectangle()
print(mixedRectangle.height)
// Prints "1"


mixedRectangle.height = 20
print(mixedRectangle.height)
// Prints "12"
```
封装高度的SmallNumber实例是通过调用SmallNumber(wrappedValue:1)创建的，它使用默认最大值12。包装宽度的实例是通过调用SmallNumber(wrappedValue: 2, maximum: 9)创建的。
 
### 从属性包装器投射值
除了包装值之外，属性包装器还可以通过定义投影值来公开其他功能—例如，管理对数据库的访问的属性包装器可以在其投影值上公开flushDatabaseConnection()方法。投影值的名称与包装值相同，只是它以美元符号($)开头。因为您的代码不能定义以$开头的属性，所以投影值永远不会干扰您定义的属性。
在上面的SmallNumber示例中，如果尝试将属性设置为一个太大的数字，属性包装器会在存储该数字之前调整该数字。下面的代码将projectedValue属性添加到SmallNumber结构中，以跟踪属性包装器是否在存储新值之前调整了该属性的新值。
```
@propertyWrapper
struct SmallNumber {
    private var number: Int
    private(set) var projectedValue: Bool


    var wrappedValue: Int {
        get { return number }
        set {
            if newValue > 12 {
                number = 12
                projectedValue = true
            } else {
                number = newValue
                projectedValue = false
            }
        }
    }


    init() {
        self.number = 0
        self.projectedValue = false
    }
}
struct SomeStructure {
    @SmallNumber var someNumber: Int
}
var someStructure = SomeStructure()


someStructure.someNumber = 4
print(someStructure.$someNumber)
// Prints "false"


someStructure.someNumber = 55
print(someStructure.$someNumber)
// Prints "true"
```
使用someStructure.$someNumber访问包装器的投影值。在存储了像4这样的小值之后，someStructure.$someNumber为假。然而，在尝试存储一个太大的数字(比如55)后，投影值为真。
属性包装器可以返回任何类型的值作为其投影值。在本例中，属性包装器仅公开一条信息——数字是否被调整——因此它将布尔值作为其投影值公开。需要公开更多信息的包装器可以返回其他类型的实例，也可以返回self以将包装器的实例作为其投影值公开。
当您从属于类型的代码(如属性getter或实例方法)访问投影值时，可以省略self。在属性名之前，就像访问其他属性一样。以下示例中的代码引用包装器在height和width周围的投影值为$height和$width:
```
enum Size {
    case small, large
}


struct SizedRectangle {
    @SmallNumber var height: Int
    @SmallNumber var width: Int


    mutating func resize(to size: Size) -> Bool {
        switch size {
        case .small:
            height = 10
            width = 20
        case .large:
            height = 100
            width = 100
        }
        return $height || $width
    }
}
```
因为属性包装器语法只是带有getter和setter的属性的语法糖，所以访问height和width的行为与访问任何其他属性相同。例如，resize(to:)中的代码使用它们的属性包装器访问高度和宽度。如果调用resize(to: .large)， .large的开关情况将矩形的高度和宽度设置为100。包装器防止这些属性的值大于12，并将投影值设置为true，以记录它调整了它们的值的事实。在resize(to:)语句结束时，返回语句检查$height和$width，以确定属性包装器是否调整了高度或宽度。

## 全局变量和局部变量
上述用于计算和观察属性的功能也可用于全局变量和局部变量。全局变量是在任何函数、方法、闭包或类型上下文之外定义的变量。局部变量是在函数、方法或闭包上下文中定义的变量。
前面章节中遇到的全局变量和局部变量都是存储变量。与存储属性一样，存储变量为某种类型的值提供存储，并允许设置和检索该值。
但是，您也可以在全局或局部范围内定义计算变量和为存储变量定义观察器。计算变量计算它们的值，而不是存储它，它们的编写方式与计算属性相同。
 
**注意：
全局常量和变量总是以惰性方式计算，与惰性存储属性类似。与惰性存储属性不同，全局常量和变量不需要使用惰性修饰符进行标记。
局部常量和变量从不惰性计算。**
可以将属性包装器应用于本地存储的变量，但不能应用于全局变量或计算变量。例如，在下面的代码中，myNumber使用SmallNumber作为属性包装器。
```
func someFunction() {
    @SmallNumber var myNumber: Int = 0


    myNumber = 10
    // now myNumber is 10


    myNumber = 24
    // now myNumber is 12
}
```
与将SmallNumber应用于属性一样，将myNumber的值设置为10也是有效的。因为属性包装器不允许大于12的值，所以它将myNumber设置为12而不是24。
 
## 类型属性
实例属性是属于特定类型的实例的属性。每次创建该类型的新实例时，它都有自己的一组属性值，与任何其他实例分开。
您还可以定义属于类型本身的属性，而不属于该类型的任何一个实例。无论您创建了多少个该类型的实例，这些属性都只有一个副本。这些类型的属性被称为类型属性。
类型属性对于定义对特定类型的所有实例通用的值很有用，例如所有实例都可以使用的常量属性(如C中的静态常量)，或者存储对该类型的所有实例全局的值的变量属性(如C中的静态变量)。
存储类型属性可以是变量或常量。与计算实例属性一样，计算类型属性总是声明为变量属性。
 
**注意：
与存储实例属性不同，您必须始终为存储类型属性提供默认值。这是因为类型本身没有可以在初始化时将值赋给存储类型属性的初始化项。
存储类型属性在第一次访问时惰性初始化。它们保证只初始化一次，即使在多个线程同时访问时也是如此，而且它们不需要用lazy修饰符进行标记。**

### 类型属性语法
在C和Objective-C中，您可以将与类型关联的静态常量和变量定义为全局静态变量。然而，在Swift中，类型属性是作为类型定义的一部分写的，在类型的外部花括号中，每个类型属性都明确地限定在它支持的类型范围内。
使用static关键字定义类型属性。对于类类型的计算类型属性，您可以使用class关键字来允许子类覆盖父类的实现。下面的例子显示了存储和计算类型属性的语法:
```
struct SomeStructure {
    static var storedTypeProperty = "Some value."
    static var computedTypeProperty: Int {
        return 1
    }
}
enum SomeEnumeration {
    static var storedTypeProperty = "Some value."
    static var computedTypeProperty: Int {
        return 6
    }
}
class SomeClass {
    static var storedTypeProperty = "Some value."
    static var computedTypeProperty: Int {
        return 27
    }
    class var overrideableComputedTypeProperty: Int {
        return 107
    }
}
```
**注意：
上面的计算类型属性示例用于只读计算类型属性，但是您也可以使用与计算实例属性相同的语法定义读写计算类型属性。**

### 查询和设置类型属性
与实例属性一样，使用点语法查询和设置类型属性。但是，类型属性是在类型上查询和设置的，而不是在该类型的实例上。例如:
```
print(SomeStructure.storedTypeProperty)
// Prints "Some value."
SomeStructure.storedTypeProperty = "Another value."
print(SomeStructure.storedTypeProperty)
// Prints "Another value."
print(SomeEnumeration.computedTypeProperty)
// Prints "6"
print(SomeClass.computedTypeProperty)
// Prints "27"
```
 
 
参考:
https://docs.swift.org/swift-book/documentation/the-swift-programming-language/properties
https://medium.com/swift-india/lets-explore-properties-in-swift-ca4054516e8