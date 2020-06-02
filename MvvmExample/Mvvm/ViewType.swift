import UIKit
import RxSwift
import RxCocoa

public protocol ViewType: class {
    var viewIsLoaded: Observable<Bool> { get }
}

extension UIView: ViewType {
    public var viewIsLoaded: Observable<Bool> {
        return .just(true)
    }
}

extension UIViewController: ViewType {
    public var viewIsLoaded: Observable<Bool> {
        return Observable.deferred { [weak self] in
            guard let self = self else { return .just(false) }
            guard self.viewIfLoaded == nil else { return .just(true) }

            return self.rx.methodInvoked(#selector(UIViewController.viewDidLoad)).map { _ in true }
        }
    }
}
