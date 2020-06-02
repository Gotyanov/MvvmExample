//
//  ViewController.swift
//  MvvmExample
//
//  Created by Aleksey Gotyanov on 02.06.2020.
//  Copyright © 2020 aleksey.gotyanov. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ViewController: UIViewController {

    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Input your name"
        return textField
    }()

    private let sayHelloButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Say hello", for: .normal)
        return button
    }()

    private let catLabel: UILabel = {
        let label = UILabel()
        label.text = "🐈"
        label.font = UIFont.systemFont(ofSize: 72)
        return label
    }()

    private let greetingLabel = UILabel()

    // required by ViewModelSubscriptionOwnerType
    var viewModelSubscriptionDisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setUpLayout()
    }

    private func setUpLayout() {

        let stackView = UIStackView(arrangedSubviews: [nameTextField, sayHelloButton, greetingLabel])
        stackView.axis = .vertical
        stackView.spacing = UIStackView.spacingUseSystem

        view.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalTo(view.layoutMarginsGuide)
        }

        view.addSubview(catLabel)
        catLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(stackView.snp.top)
            make.centerX.equalToSuperview()
        }
    }

}

extension ViewController : ViewModelSubscriptionOwnerType { }

extension ViewController : ViewModelSubscriberType {
    /* compare with bind2
     `bind` method do not use `disposed(by:)`.
     @Subscription function builder combines Disposable-s into single Disposable that is result for propagate function.
     This Disposable is combined with other subscriptions and returned as a result of `subscribe(input:)`.

     The function is short and clear. Also, it doesn't contain any assignment operator.
     */
    func bind(viewModel: GreetingViewModel) -> Disposable {
        viewModel.subscribe(input: getViewModelInput()) { output in
            output.greetingText.drive(greetingLabel.rx.text)
            output.catIsVisible.map(!).drive(catLabel.rx.isHidden)
        }
    }

    private func getViewModelInput() -> ViewModel.Input {
        .init(
            name: nameTextField.rx.text.orEmpty.asDriver(),
            sayHelloButtonTap: sayHelloButton.rx.tap.asSignal()
        )
    }
}

extension ViewController {
    func bind2(viewModel: GreetingViewModel) {
        let output = viewModel.getOutput(for: getViewModelInput())
        viewModelSubscriptionDisposeBag = DisposeBag()
        output.greetingText.drive(greetingLabel.rx.text).disposed(by: viewModelSubscriptionDisposeBag)
        output.catIsVisible.map(!).drive(catLabel.rx.isHidden).disposed(by: viewModelSubscriptionDisposeBag)

        /*
         the code have 2 problems:
         1) It has more text so it harder to read. Especially because of using `disposed(by:)`
         2) It requires proper order of operations – `viewModelSubscriptionDisposeBag = DisposeBag()` should be placed before subscriptions.

         In RxSwift 6 will be added convenience method for DisposeBag. It will help to remove `.disposed(by:)`. The code can be rewritten as:
         ```
         let output = viewModel.getOutput(for: getViewModelInput())

         viewModelSubscriptionDisposeBag = DisposeBag {
            output.greetingText.drive(greetingLabel.rx.text)
            output.catIsVisible.map(!).drive(catLabel.rx.isHidden)
         }
         ```

         The new code looks better, but it has a subtle problem if a view has replaceable VM (cells, for example) – subsciptions are performed when previous subscriptions still alive.
         It can introduce bugs, that are not easy to find. `viewModelSubscriptionDisposeBag` should be destroyed before performing subscriptions.
         Correct code will be:
         ```
         let output = viewModel.getOutput(for: getViewModelInput())

         viewModelSubscriptionDisposeBag = DisposeBag()

         viewModelSubscriptionDisposeBag = DisposeBag {
            output.greetingText.drive(greetingLabel.rx.text)
            output.catIsVisible.map(!).drive(catLabel.rx.isHidden)
         }
         ```

         It is easy to forget to add `viewModelSubscriptionDisposeBag = DisposeBag()` to prevent possible bugs. Also it looks not obvious.

         `bind(viewModel:)` doesn't have this problem – see BindingSubscriptionOwnerType.performSubscription
         */
    }
}
