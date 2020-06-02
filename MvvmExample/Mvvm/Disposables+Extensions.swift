import RxSwift

extension Disposables {
    static func retain(instance: AnyObject) -> Disposable {
        return RefStorageDisposable(instance: instance)
    }
}

private final class RefStorageDisposable: Disposable {
    var instance: AnyObject?

    init(instance: AnyObject) {
        self.instance = instance
    }

    func dispose() {
        instance = nil
    }
}
