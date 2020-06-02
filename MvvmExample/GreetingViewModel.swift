import RxSwift
import RxCocoa

final class GreetingViewModel : ViewModelType {

    struct Input {
        let name: Driver<String>
        let sayHelloButtonTap: Signal<Void>
    }

    struct Output {
        var greetingText: Driver<String>
        var catIsVisible: Driver<Bool>
    }

    func _subscribe(input: Input, propagate: (Output) -> Disposable) -> Disposable {

        let output = Output(
            greetingText: input.sayHelloButtonTap
                .withLatestFrom(input.name)
                .map { "Hello, \($0)!" }
                .asDriver(onErrorDriveWith: .never()
            ),
            catIsVisible: input.sayHelloButtonTap
                .map { true }
                .startWith(false)
                .asDriver(onErrorDriveWith: .never()
            )
        )

        return Disposables.create(
            propagate(output),
            subscribeOnSomeEvent()
        )
    }

    private func subscribeOnSomeEvent() -> Disposable {
        Disposables.create()
    }

    deinit {
        print("GreetingViewModel destroyed")
    }
}

/* alternative subscription */
extension GreetingViewModel {
    /* Where should I put `additionalSubscription`? */

    func getOutput(for input: Input) -> Output {
        let output = Output(
            greetingText: input.sayHelloButtonTap
                .withLatestFrom(input.name)
                .map { "Hello, \($0)!" }
                .asDriver(onErrorDriveWith: .never()
            ),
            catIsVisible: input.sayHelloButtonTap
                .map { true }
                .startWith(false)
                .asDriver(onErrorDriveWith: .never()
            )
        )

        let additionalSubscription = subscribeOnSomeEvent()
        /*
         Where should I put `additionalSubscription`?

         1) Return tuple?
         ```
         func getOutput(for input: Input) -> (Output, Disposable)
         ```

         Cons: VM binding code will become more sophisticated.

         2) return `Disposable` inside Output?
         ```
         struct Output {
            ...
            let additionalSubscriptions: Disposable
         }
         ```
         Cons: It is easy to forget add this disposable to disposeBag

         3) Add `disposeBag` inside ViewModel to store `additionalSubscription`?
         Cons: 2 places become responsible for subscription storing – View and ViewModel.

         4) Somehow inject calling `subscribeOnSomeEvent()` in output drivers
         ```
         output.greetingText = output.greetingText
             .withSubscription { [weak self] in self?.subscribeOnSomeEvent() }
             .asDriver(onErrorDriveWith: .never())
         ```
         see extension ObservableConvertibleType below.
         It is dirty way to perform subscription.
         
         */

        return output
    }
}

/*
extension ObservableConvertibleType {
    func withSubscription(_ subscribe: @escaping () -> Disposable?) -> Observable<Element> {
        Observable<Element>.create { observer in
            Disposables.create([subscribe(), self.asObservable().subscribe(observer)].compactMap { $0 })
        }
    }
}
*/
