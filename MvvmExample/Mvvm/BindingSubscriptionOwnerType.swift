import RxSwift
import Foundation
import UIKit

public protocol BindingSubscriptionOwnerType: class {
    /**
     should release old disposeBag and retain received disposeBag
    */
    func setSubscription(_ disposeBag: DisposeBag)
}

extension BindingSubscriptionOwnerType {
    public func performSubscription(_ subscribe: (DisposeBag) throws -> Void) rethrows {
        let disposeBag = DisposeBag()
        setSubscription(disposeBag)
        try subscribe(disposeBag)
    }
}

public protocol ViewModelSubscriptionOwnerType: BindingSubscriptionOwnerType {
    var viewModelSubscriptionDisposeBag: DisposeBag { get set }
}

extension ViewModelSubscriptionOwnerType {
    public func setSubscription(_ disposeBag: DisposeBag) {
        viewModelSubscriptionDisposeBag = disposeBag
    }
}

/* add conforming to BindingSubscriptionOwnerType for all UIViewController / UIView

extension BindingSubscriptionOwnerType where Self: NSObject {
    public func setSubscription(_ disposeBag: DisposeBag) {
        objc_setAssociatedObject(self, &AssociatedObjectKeys.viewModelSubscriptionDisposeBag, disposeBag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private struct AssociatedObjectKeys {
    static var viewModelSubscriptionDisposeBag = "viewModelSubscriptionDisposeBag"
}

extension UIViewController : BindingSubscriptionOwnerType { }
extension UIView : BindingSubscriptionOwnerType { }

 */
