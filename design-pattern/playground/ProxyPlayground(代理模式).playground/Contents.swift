import UIKit

var greeting = "Hello, Proxy Pattern playground"

//:
//: ## 代理模式
//:
//: 代理模式是一种结构型设计模式，让你能够提供对象的替代品或其占位符。代理控制着对于原对象的访问，并允许在将请求提交给对象前后进行一些处理。
//:
//: ![代理模式](solution.png)
//: 代理将自己伪装成数据库对象，可在客户端或实际数据库对象不知情的情况下处理延迟初始化和缓存查询结果的工作。
//:
//: ## 代理模式结构
//:
//: ![代理模式](structure.png)
//:
//: 1. 服务接口（Service Interface）声明了服务接口。代理必须遵循该接口才能伪装成服务对象。
//: 2. 服务（Service）类提供了一些实用的业务逻辑。
//: 3. 代理（Proxy）类包含一个指向服务对象的引用成员变量。代理完成其任务（例如延迟初始化、记录日志、访问控制和缓存等）
//:    后会将请求传递给服务对象。通常情况下，代理会对其服务对象的整个生命周期进行管理。
//: 4. 客户端（Client）能通过同一接口与服务或代理进行交互，所以你可在一切需要服务对象的代码中使用代理。
//:
//: ## 代理模式适合应用场景
//:
//: 1. 延迟初始化（虚拟代理）。如果你有一个偶尔使用的重量级服务对象，一直保持该对象运行会消耗系统资源时，可使用代理模式。
//:    无需在程序启动时就创建该对象， 可将对象的初始化延迟到真正有需要的时候。
//: 2. 访问控制（保护代理）。如果你只希望特定客户端使用服务对象，这里的对象可以是操作系统中非常重要的部分，
//:    而客户端则是各种已启动的程序 （包括恶意程序），此时可使用代理模式。代理可仅在客户端凭据满足要求时将请求传递给服务对象。
//: 3. 本地执行远程服务（远程代理）。适用于服务对象位于远程服务器上的情形。
//:    在这种情形中，代理通过网络传递客户端请求，负责处理所有与网络相关的复杂细节。
//: 4. 记录日志请求（日志记录代理）。适用于当你需要保存对于服务对象的请求历史记录时。
//:    代理可以在向服务传递请求前进行记录。
//: 5. 缓存请求结果（缓存代理）。适用于需要缓存客户请求结果并对缓存生命周期进行管理时，特别是当返回结果的体积非常大时。
//:    代理可对重复请求所需的相同结果进行缓存，还可使用请求参数作为索引缓存的键值。
//: 6. 智能引用。可在没有客户端使用某个重量级对象时立即销毁该对象。
//:    代理会将所有获取了指向服务对象或其结果的客户端记录在案。代理会时不时地遍历各个客户端，
//:    检查它们是否仍在运行。如果相应的客户端列表为空，代理就会销毁该服务对象，释放底层系统资源。
//:    代理还可以记录客户端是否修改了服务对象。 其他客户端还可以复用未修改的对象。
//:
//: ## 实现方式
//:
//: 1. 如果没有现成的服务接口，就需要创建一个接口来实现代理和服务对象的可交换性。从服务类中抽取接口并非总是可行的，
//:    因为你需要对服务的所有客户端进行修改，让它们使用接口。备选计划是将代理作为服务类的子类，这样代理就能继承服务的所有接口了。
//: 2. 创建代理类，其中必须包含一个存储指向服务的引用的成员变量。通常情况下，代理负责创建服务并对其整个生命周期进行管理。
//:    在一些特殊情况下 客户端会通过构造函数将服务传递给代理。
//: 3. 根据需求实现代理方法。在大部分情况下，代理在完成一些任务后应将工作委派给服务对象。
//: 4. 可以考虑新建一个构建方法来判断客户端可获取的是代理还是实际服务。你可以在代理类中创建一个简单的静态方法，也可以创建一个完整的工厂方法。
//: 5. 可以考虑为服务对象实现延迟初始化。
//:
//: ## 代理模式优缺点
//:
//: ### 优点
//: 1. 可以在客户端毫无察觉的情况下控制服务对象。
//: 2. 如果客户端对服务对象的生命周期没有特殊要求，可以对生命周期进行管理。
//: 3. 即使服务对象还未准备好或不存在，代理也可以正常工作。
//: 4. 开闭原则。可以在不对服务或客户端做出修改的情况下创建新代理。
//:
//: ### 缺点
//:
//: 1. 代码可能会变得复杂，因为需要新建许多类。
//: 2. 服务响应可能会延迟。
//:

import XCTest

/// The Subject interface declares common operations for both RealSubject and the Proxy. As long as the
/// client works with RealSubject using this interface, you'll be able to pass it a proxy instead of a real subject.
protocol Subject {
    
    func request()
}

/// The RealSubject contains some core business logic. Usually, RealSubjects are capable of doing some useful work
/// Which may also be very slow or sensitive e.g. correcting input data. A Proxy can solve these issues without any
/// changes to the RealSubject's code.
class RealSubject: Subject {
    
    func request() {
        print("RealSubject: Handling request.")
    }
}

/// The Proxy has an interface identical to the RealSubject.
class Proxy: Subject {
    
    private var realSubject: RealSubject
    
    /// The Proxy maintains a reference to an object of the RealSubject class.
    /// It can be either lazy-loaded or passed to the Proxy by the client.
    init (_ realSubject: RealSubject) {
        self.realSubject = realSubject
    }
    
    /// The most common applications of the Proxy pattern are lazy loading, caching, controlling the access, logging, etc.
    /// A Proxy can perform one of these things and then, depending on the result, pass the execution to the same method
    /// in a linked RealSubject object.
    func request() {
        
        if (checkAccess()) {
            realSubject.request()
            logAccess()
        }
    }
    
    private func checkAccess() -> Bool {

        /// Some real checks should go here.
        print("Proxy: Checking access prior to firing a real request.")

        return true
    }

    private func logAccess() {
        print("Proxy: Logging the time of request.")
    }
}

/// The client code is supposed to work with all objects (both subjects and
/// proxies) via the Subject interface in order to support both real subjects
/// and proxies. In real life, however, clients mostly work with their real
/// subjects directly. In this case, to implement the pattern more easily, you
/// can extend your proxy from the real subject's class.
class Client {
    // ...
    static func clientCode(subject: Subject) {
        // ...
        print(subject.request())
        // ...
    }
    // ...
}

/// Let's see how it all works together.
class ProxyConceptual: XCTestCase {

    func test() {
        print("Client: Executing the client code with a real subject:")
        
        let realSubject = RealSubject()
        Client.clientCode(subject: realSubject)

        print("\nClient: Executing the same client code with a proxy:")

        let proxy = Proxy(realSubject)
        Client.clientCode(subject: proxy)
    }
}

let proxy = ProxyConceptual()

proxy.test()

// Output result
// Client: Executing the client code with a real subject:
// RealSubject: Handling request.
//
// Client: Executing the same client code with a proxy:
// Proxy: Checking access prior to firing a real request.
// RealSubject: Handling request.
// Proxy: Logging the time of request.
