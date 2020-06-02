import Foundation
import RxSwift

public protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    #warning("[3]")
    /*
     Why the function name starts from an underscore?
     Because we want to show to a user that it is not that he wants to use. The user should use "subscribe(input:propagate:)" from extension instead.

     The method from extension has @Subscription argument before propagate. It combines disposables into single result.
     Protocol can not require the usage of function builders for an argument. Instead every implementation of `ViewModelType` should add @Subscription before `propagate`.
     It easy to forget to add @Subscription.
     So we have 2 `subscribe` methods – `_subscribe` – must be implemented by ViewModel. And `subscribe` that will be used by Views.
     */
    func _subscribe(input: Input, propagate: (Output) -> Disposable) -> Disposable
}

public extension ViewModelType {
    #warning("why propagate?")
    /*
     What wrong with `getOutput(for input: Input) -> Output` or `transform(input: Input) -> Output`?
     These function names are lying. They say that they are "pure" functions that transform Input to Output.
     But quite often it is needed to perform some additional actions (side effects), some of them produce `Disposable`-s.
     And it is needed some way to handle these Disposables. Some solutions described inside `GreetingViewModel.getOutput`.

     `subscribe` explicitly returns subscriptions (Disposable that combines subscriptions on Output/Input and additional ones on services).
     And provides nice way to subscribe on Output for View using trailing closure.
     Next benefit is combining Disposables into one Disposable thanks to @Subscription. This saves us from having to use `.dispose(by:)` method.

     `subscribe` doesn't return `Output`. The purpose of this temporary struct is to provide binding. It won't be stored anywhere.
     */
    @inlinable
    func subscribe(input: Input, @Subscription propagate: (Output) -> Disposable) -> Disposable {
        _subscribe(input: input, propagate: propagate)
    }
}
