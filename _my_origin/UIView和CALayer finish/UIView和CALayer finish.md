# UIView
在iOS当中，所有的视图都从一个叫做 UIVIew 的基类派生而来， UIView 可以 处理触摸事件，可以支持基于Core Graphics绘图，可以做仿射变换（例如旋转或 者缩放），或者简单的类似于滑动或者渐变的动画。

# CALayer
CALayer 类在概念上和 UIView 类似，同样也是一些被层级关系树管理的矩形 块，同样也可以包含一些内容（像图片，文本或者背景色），管理子图层的位置。 它们有一些方法和属性用来做动画和变换。和 UIView 最大的不同是 CALayer 不 处理用户的交互。
CALayer 并不清楚具体的响应链（iOS通过视图层级关系用来传送触摸事件的机 制），于是它并不能够响应事件，即使它提供了一些方法来判断是否一个触点在图层的范围之内

# UIView和CALayer的关系
每一个 UIview 都有一个 CALayer 实例的图层属性，也就是所谓的backing layer，视图的职责就是创建并管理这个图层，以确保当子视图在层级关系中添加或 者被移除的时候，他们关联的图层也同样对应在层级关系树当中有相同的操作。
实际上这些背后关联的图层才是真正用来在屏幕上显示和做动画， UIView 仅仅 是对它的一个封装，提供了一些iOS类似于处理触摸的具体功能，以及Core Animation底层方法的高级接口。

# 为什么要基于UIView和CALayer提供两个平行的层级关系
原因在于要做职责分离，这样也能避免 很多重复代码。在iOS和Mac OS两个平台上，事件和用户交互有很多地方的不同， 基于多点触控的用户界面和基于鼠标键盘有着本质的区别，这就是为什么iOS有 UIKit和 UIView ，但是Mac OS有AppKit和 NSView 的原因。他们功能上很相似， 但是在实现上有着显著的区别。
绘图，布局和动画，相比之下就是类似Mac笔记本和桌面系列一样应用于iPhone 和iPad触屏的概念。把这种功能的逻辑分开并应用到独立的Core Animation框架， 苹果就能够在iOS和Mac OS之间共享代码，使得对苹果自己的OS开发团队和第三 方开发者去开发两个平台的应用更加便捷。
实际上，这里并不是两个层级关系，而是四个，每一个都扮演不同的角色，除了 视图层级和图层树之外，还存在呈现树和渲染树。

# 图层的能力
一些简单的需求，可以通过UIView的高级API实现。但是简单意味着一些灵活上的缺陷。如果想在底层做一些改变，或者使用没有在UIView上实现的接口功能，除了使用CoreAnimation底层之外别无选择。
图层不能像视图那样处理触摸事件，那么图层能做哪些视图不能做的哪？
* 阴影，圆角，带颜色的边框
* 3D变换
* 非矩形范围
* 透明遮罩
* 多级非线性动画

# CALayer的一些基础属性

## contents属性
图层的寄宿图，虽然这个属性被定义为id类型，但实际上是一个CGImageRef,它是一个指向CGImage结构的指针。所以在赋值的时候需要使用`layer.contents = (__bridge id)image.CGImage;`bridge关键字转换。我们利用CALayer在一个普通的UIView中显示了一张图片。这不是一个UIImageView，它不是我们通常用来展示图片的方法。通过直接操作图层，我们使用了一些新的函数，使得UIView更加有趣了。

## contentsGravity
通常我们加载的图片不能刚好适应一个视图的大小。通常会被拉伸。在使用UIImageView的时候遇到这样的问题。解决方法就是把contentMode设置成更合适的。`view.contentMode = UIViewContentModeScaleAspectFit;`但实际上UIView大多数视觉相关的属性比如**contentMode**，对这些属性的操作其实是对对应图层的操作。
CALayer与**contentMode**对应的属性叫做**contentsGravity**，但是它是一个NSString类型，而不是对应UIKit部分中的枚举。**contentsGravity**可选吃常量值有以下一些:
* kCAGravityCenter
* kCAGravityTop
* kCAGravityBottom
* kCAGravityLeft
* kCAGravityRight
* kCAGravityTopLeft
* kCAGravityTopRight
* kCAGravityBottomLeft
* kCAGravityBottomRight
* kCAGravityResize
* kCAGravityResizeAspect
* kCAGravityResizeAspectFill

和 cotentMode 一样， contentsGravity 的目的是为了决定内容在图层的边界 中怎么对齐，我们将使用kCAGravityResizeAspect，它的效果等同于 UIViewContentModeScaleAspectFit， 同时它还能在图层中等比例拉伸以适应图层的边界。
`self.layerView.layer.contentsGravity = kCAGravityResizeAspect;`

## contentsScale
contentsScale 属性定义了寄宿图的像素尺寸和视图大小的比例，默认情况下它 是一个值为1.0的浮点数。contentsScale属性其实属于支持高分辨率（又称Hi-DPI或Retina）屏幕机制的 一部分。它用来判断在绘制图层的时候应该为寄宿图创建的空间大小，和需要显示 的图片的拉伸度（假设并没有设置 contentsGravity 属性）。UIView有一个类似 功能但是非常少用到的 contentScaleFactor属性。如果contentsScale设置为1.0，将会以每个点1个像素绘制图片，如果设置为 2.0，则会以每个点2个像素绘制图片，这就是我们熟知的Retina屏幕。这并不会对我们在使用kCAGravityResizeAspect时产生任何影响，因为它就是拉伸 图片以适应图层而已，根本不会考虑到分辨率问题。但是如果我们 把 contentsGravity 设置为kCAGravityCenter（这个值并不会拉伸图片），那将 会有很明显的变化。可以通过以下代码设置正确的**contentsScale**
`layer.contentsScale = [UIScreen mainScreen].scale;`

## contentsRect
CALayer的 contentsRect 属性允许我们在图层边框里显示寄宿图的一个子域。这 涉及到图片是如何显示和拉伸的，所以要比 contentsGravity 灵活多了 和 bounds ， frame 不同， contentsRect 不是按点来计算的，它使用了单位 坐标，单位坐标指定在0到1之间，是一个相对值（像素和点就是绝对值）。所以他 们是相对与寄宿图的尺寸的。iOS使用了以下的坐标系统：
* 点 —— 在iOS和Mac OS中最常见的坐标体系。点就像是虚拟的像素，也被称 作逻辑像素。在标准设备上，一个点就是一个像素，但是在Retina设备上，一 个点等于2*2个像素。iOS用点作为屏幕的坐标测算体系就是为了在Retina设备 和普通设备上能有一致的视觉效果。
* 像素 —— 物理像素坐标并不会用来屏幕布局，但是仍然与图片有相对关系。 UIImage是一个屏幕分辨率解决方案，所以指定点来度量大小。但是一些底层 的图片表示如CGImage就会使用像素，所以你要清楚在Retina设备和普通设备 上，他们表现出来了不同的大小。
* 单位 —— 对于与图片大小或是图层边界相关的显示，单位坐标是一个方便的 度量方式， 当大小改变的时候，也不需要再次调整。单位坐标在OpenGL这种 纹理坐标系统中用得很多，Core Animation中也用到了单位坐标。

默认的 contentsRect 是{0, 0, 1, 1}，这意味着整个寄宿图默认都是可见的，如果 我们指定一个小一点的矩形，图片就会被裁剪。

## contentsCenter
本章我们介绍的最后一个和内容有关的属性是 contentsCenter ，看名字你可能 会以为它可能跟图片的位置有关，不过这名字着实误导了 你。 contentsCenter 其实是一个CGRect，它定义了一个固定的边框和一个在图 层上可拉伸的区域。 改变 contentsCenter 的值并不会影响到寄宿图的显示，除 非这个图层的大小改变了，你才看得到效果。
![IMAGE](resources/E0574F20A1C2A4884D3DD7EBE727BF28.jpg =713x1061)

# Custom Drawing
给contents赋CGImage的值不是唯一设置寄宿图的方法。我们也可以直接用Core Graphics直接绘制寄宿图。能够通过继承UIView并实现`-drawRect:`方法来自定义绘制。
drawRect方法没有默认的实现，因为对UIView来说，寄宿图并不是必须的，它不在意那是单调的颜色还是一个图片的实例。如果UIView检测到drawRect方法被调用了，它就会为视图分配一个寄宿图，这个寄宿图的像素尺寸等于视图大小乘以contentsScale的值。
如果不需要寄宿图，就不要创建这个方法，这会造成CPU资源和内存的浪费，这也是苹果为什么建议：如果没有自定义绘制任务就不要在子类中写一个空的drawRect方法。
当视图在屏幕上出现的时候 -drawRect: 方法就会被自动调用。 - drawRect: 方法里面的代码利用Core Graphics去绘制一个寄宿图，然后内容就会 被缓存起来直到它需要被更新（通常是因为开发者调用了 -setNeedsDisplay 方 法，尽管影响到表现效果的属性值被更改时，一些视图类型会被自动重绘， 如 bounds 属性）。虽然 -drawRect: 方法是一个UIView方法，事实上都是底层 的CALayer安排了重绘工作和保存了因此产生的图片。
CALayer有一个可选的delegate属性，实现了CALayerDelegate协议，你只需要调用你想调用的方法，CALayer会帮你做剩下的.
当需要被重绘时，CALayer会请求它的代理给它一个寄宿图来显示。通过调用`(void)displayLayer:(CALayer *)layer;`来做到。如果代理想设置contents属性的话，它就可以这么做，不然没有别的方法可以调用了。如果代理不实现displayLayer方法。CALayer就会转而尝试调用`- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;`在调用这个方法之前，CALayer创建了一个合适尺寸的空寄宿图和一个CoreGraphics的绘制上下文环境，会绘制寄宿图做准备，他作为ctx参数传入。