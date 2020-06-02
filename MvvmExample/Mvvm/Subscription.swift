import RxSwift

@_functionBuilder
public struct Subscription {
    public static func buildBlock(_ disposables: Disposable...) -> Disposable {
        Disposables.create(disposables)
    }

    public static func buildEither(first: Disposable) -> Disposable {
        first
    }

    public static func buildEither(second: Disposable) -> Disposable {
        second
    }
}
