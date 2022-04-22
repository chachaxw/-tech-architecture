# Flutter技术架构(Flutter Architecture)

Flutter技术架构研究和学习，Flutter technology architecture study and learn

## Flutter技术架构概览

![Architectural diagram](images/archdiagram.png)

* Embedder是一个嵌入层，即把Flutter嵌入到各个平台上去，这里做的主要工作包括渲染Surface设置，线程设置，以及插件等。 从这里可以看出，Flutter的平台相关层很低，平台(如iOS)只是提供一个画布，剩余的所有渲染相关的逻辑都在Flutter内部，这就使得它具有了很好的跨端一致性
* Engine 是Flutter的核心，它主要是用C++编写的，并支持所有Flutter应用程序所必需的原语。每当需要绘制新界面时，引擎负责对合成场景进行栅格化。它提供了Flutter核心API的低级实现，包括图形（通过Skia），文本布局，文件和网络I / O，可访问性支持，插件架构以及Dart运行时和编译工具链
* Framework使用dart实现，包括Material Design风格的Widget, Cupertino(针对iOS)风格的Widgets，文本/图片/按钮等基础Widgets，渲染，动画，手势等。此部分的核心代码是: flutter仓库下的flutter package，以及flutter/engine仓库下的io, async, ui(dart:ui库提供了Flutter框架和引擎之间的接口)等package

## Flutter编译产物

![Flutter Artifact](images/flutter_artifact.png)

## Flutter引擎启动

![Flutter Engine](images/flutter_engine_startup.png)

### 引擎启动过程

* FlutterApplication.java的onCreate方法完成初始化配置，加载引擎libflutter.so文件，注册JNI([Java Native Interface，Java本地接口](https://zh.wikipedia.org/wiki/Java本地接口))方法
* FlutterActivity.java的onCreate过程，通过Flutter JNI的AttachJNI方法来初始化引擎Engine、Dart虚拟机、isolate线程、taskRunner等对象。再经过层层处理最终调用main.dart中的`main()`方法，执行`runApp(Widget app)`来处理整个Dart业务代码

### Flutter引擎中的TaskRunner

#### TaskRunner原理

Flutter引擎启动过程中，会创建UI线程，GPU线程和IO线程，Flutter引擎会为这些线程依次创建MessageLoop对象，启动后处于epoll_wait等待状态。

![both queues](images/both-queues.png)

Flutter任务队列分为event queue(事件队列)和microtask queue(微任务队列)，事件队列包含所有的外部事件，如Flutter引擎和Dart虚拟机的事件以及Future。Dart层执行 scheduleMicrotask() 所产生的属于Microtask微任务。
从上面的流程图可以看出，当main()执行完了之后，事件循环就开始工作。首先，它会以FIFO的顺序，执行所有的微任务。然后事件队列的第一项任务第一项出队并开始处理。然后重复该循环：执行所有的微任务，然后处理事件队列的下一项。

#### 四个TaskRunner

![task runner](images/task_runner.png)

* Platform Task Runner: 运行在Android或者iOS的主线程，尽管阻塞该线程并不会影响Flutter渲染管道，平台线程建议不要执行耗时操作；否则可能出发watchdog来结束该应用。比如Android、iOS都是使用平台线程来传递用户输入事件，一旦平台线程被阻塞则会引起手势事件丢失
* UI Task Runner: 运行在ui线程，比如`1.ui`，用于引擎执行root isolate中的所有Dart代码，执行渲染与处理vsync信号，将widget转换生成Layer Tree。除了渲染之外，还有处理Native Plugins消息、Timers、Microtasks等工作
* GPU Task Runner: 运行在gpu线程，比如`1.gpu`，用于将Layer Tree转换为具体GPU指令，执行设备GPU相关的skia调用，转换相应平台的绘制方式，比如OpenGL, vulkan, metal等。每一帧的绘制需要UI Runner和GPU Runner配合完成，任何一个环节延迟都可能导致掉帧
![GPU Task Runner](images/gpu_runner.jpg)
* IO Task Runner: 运行在io线程，比如`1.io`，前3个Task Runner都不允许执行耗时操作，该Runner用于将图片从磁盘读取出来，解压转换为GPU可识别的格式后，再上传给GPU线程。为了能访问GPU，IO Runner跟GPU Runner的Context在同一个ShareGroup。比如ui.image通过异步调用让IO Runner来异步加载图片，该线程不能执行其他耗时操作，否则可能会影响图片加载的性能

#### Dart虚拟机工作

Flutter引擎启动会创建Dart虚拟机以及Root Isolate。DartVM自身也拥有自己的Isolate，完全由虚拟机自己管理，Flutter引擎无法直接访问。Dart的UI相关操作，是由Root Isolate通过Dart的C++调用，或者是发送消息通知的方式，将UI渲染相关的任务提交到UIRunner执行，这样就可以跟Flutter引擎相关模块进行交互。

> 什么是Isolate?
> Isolate是Dart平台对线程的实现方案，但和普通Thread不同的是，Isolate拥有独立的内存，
> Isolate由线程和独立内存构成。正是由于isolate线程之间的内存不共享，
> 所以Isolate线程之间并不存在资源抢夺的问题，所以也不需要锁。

![Dart VM](images/isolate_heap.png)

#### Flutter Widget

StatelessWidget：内部没有保存状态，UI界面创建后不会发生改变

StatefulWidget：内部有保存状态，当状态发生改变，调用setState()方法会触发StatefulWidget的UI更新，对于自定义继承自StatefulWidget的子类，必须要重写createState()方法

![Flutter Widget](images/widget_arch.png)

[Flutter组件渲染和布局原理](https://flutter.dev/docs/resources/architectural-overview#rendering-and-layout)

#### Platform Channels

![Flutter Platform Channels](images/platform_channels.png)

Flutter提供了Platform Channels来允许开发者调用安卓和iOS原生代码，是一个用于Dart代码和原生应用程序之间进行通信的简单机制。通过创建一个通用的Channel（通道），你可以在原生代码（例如Swift，Kotlin）和Dart之间直接发送和接收消息。Dart的（例如Map）数据类型会经过序列化为标准格式，然后反序列化为Kotlin（例如HashMap）或 Swift（例如Dictionary）的等效表示形式。

[Flutter Platform Channels官方解读](https://flutter.dev/docs/resources/architectural-overview#platform-channels)

## 🔭 学习更多

* [Flutter通用开发模板](https://github.com/chachaxw/flutter_common_template)
* [Flutter 跨平台演进及架构开篇](http://gityuan.com/flutter/)
* [深入理解Flutter多线程](https://juejin.cn/post/6844903831478730759)
* [为追求高性能，我必须告诉你Flutter引擎线程的事实](https://zhuanlan.zhihu.com/p/38026271)
* [Flutter architecture overview](https://flutter.dev/docs/resources/architectural-overview)
* [The Event Loop and Dart](https://web.archive.org/web/20170704074724/https://webdev.dartlang.org/articles/performance/event-loop)
* [Flutter Architecture Samples](https://fluttersamples.com)
