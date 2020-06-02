import RxSwift

public protocol ViewModelSubscriberType {
    associatedtype ViewModel: AnyObject
    
    func bind(viewModel: ViewModel) -> Disposable
}

public extension ViewModelSubscriberType where Self: ViewType, Self: BindingSubscriptionOwnerType {
    #warning("[1]")
    /*
     VM binding starts here.
     `ViewModelSubscriberType` is used to describe View that have VM.
     But to make binding `View` is not have to be `ViewModelSubscriberType`.
     View only needs to have `bind(viewModel: ViewModel) -> Disposable` method.
    */
    func bindAndStore(_ viewModel: ViewModel) {
        bindAndStore(viewModel, binding: Self.bind)
    }
}

public extension ViewType where Self: BindingSubscriptionOwnerType {
    #warning("[2]")
    /*
     `bindAndStore(_:binding:)` not depends on `ViewModelSubscriberType` so it is possible to add to View different types of ViewModels
     */
    func bindAndStore<ViewModel: AnyObject>(
        _ viewModel: ViewModel,
        /*
         The type of the next argument looks scary.
         The function that receives view and returns function that takes ViewModel and returns Disposable.
         Can simple `(ViewModel) -> Disposable` be used here? Yes, it is possible.
         The correct usage of this function will be:
         `bindAndStore(viewModel, binding: { [weak self] viewModel in self?.bind(viewModel) ?? Disposables.create() })`
         We should capture `self` weakly to prevent retain cycle – `binding` function captured inside closure.
         But smart user can write "bindAndStore(viewModel, binding: self.bind)" or just "bindAndStore(viewModel, binding: bind)".
         To deny a user of opportunity retain `self` through functions, function type should be (Self, ViewModel) -> Disposable or (Self) -> (ViewModel) -> Disposable. The latest one was selected because it can be specified via View type.
         */
        binding: @escaping (Self) -> (ViewModel) -> Disposable
    ) {
        /*
         The logic of this method is quite tricky.

         The `performSubscription` creates new DisposeBag, then pass it to `BindingSubscriptionOwnerType.setSubscription`.
         `setSubscription` must replace existing DisposeBag to new one in order to destroy existing subscriptions. It is important for View with replaceable VM.
         Then it pass new DisposeBag to closure.
         */
        performSubscription { disposeBag in
            /*
             Good VM – is VM that doesn't have state:) So after binding it can be safety destroyed.
             It this example VM is "good", try to remove the following line and remove "weak" before viewModel in the capture list.
             In the console output you will see "GreetingViewModel destroyed", but program should work without problems.

             But sometimes VM have a state. VM captures `self` weakly to have access to state and do not create retain cycle.
             Someone should have a reference to VM. The next line binds VM lifetime to `disposeBag` that live until View is deallocated or View is bound to other VM.
             */
            Disposables.retain(instance: viewModel).disposed(by: disposeBag)

            /*
             if View is loaded – subscription should be performed immediately, if not – after loading.
             This is important for UIViewController-s, because before `viewDidLoad` some views can be nil.
             */
            let viewLoaded = viewIsLoaded.filter { $0 }.take(1)

            viewLoaded
                /*
                 "unowned self" – `self` owns `disposeBag`. If `self` is destroyed so `disposeBag` also should be destroyed and then the subscription will be destroyed, so `onNext` won't be called. It is safe to use "unsafe" here.

                 "weak viewModel" – we can use strong reference here. But consider the case when View is bound multiple times to different VM-s before while it is not loaded:
                 ```
                 viewController.bindAndStore(viewModel1)
                 viewController.bindAndStore(viewModel2)
                 viewController.bindAndStore(viewModel3)
                 viewController.loadViewIfNeeded()
                 ```

                 Every `bindAndStore` make subscribtion on `viewLoaded`. If we will use strong reference on viewModel then `viewModel1` and `viewModel2` will be live until `viewController.loadViewIfNeeded()`. But they are not needed – binding should be created only for `viewModel3`. We use "weak" here because we don't want to keep unnecessary VMs.

                 `disposeBag` has reference to VM, View has reference to `disposeBag`, so latest viewModel will not be nil.

                 "weak disposeBag" – View keep reference only on latest `disposeBag`. If `disposeBag` is nil it means that View was bound to new VM, so one DisposeBag was replaced on another one and old one was deallocated. This is helps to provide "bind with latest ViewModel" strategy.

                 */
                .subscribe(onNext: { [unowned self, weak viewModel, weak disposeBag] _ in
                    guard let viewModel = viewModel, let disposeBag = disposeBag else { return }

                    binding(self)(viewModel).disposed(by: disposeBag)
                })
                .disposed(by: disposeBag)
        }
    }
}
