//
//  SceneDelegate.swift
//  MvvmExample
//
//  Created by Aleksey Gotyanov on 02.06.2020.
//  Copyright © 2020 aleksey.gotyanov. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)

        let controller = ViewController()
        #warning("[0] Follow the warnings to read descriptions about VM binding!")
        controller.bindAndStore(GreetingViewModel()) // performs VM binding AFTER ViewController.view loading.

        /* controller.view is not loaded yet. If bind2 subscribes on a view that is not yet created (is nil) then will be a crash. The problem is actual for controllers like UITableViewController where tableView is nil until view loaded... */

        // controller.bind2(viewModel: GreetingViewModel())

        /* ... so invoked `bind2(viewModel:)` should be moved to `ViewController.viewDidLoad`? How VC will receive VM? – VC should store VM.
         controller.viewModel = GreetingViewModel() */

        window?.rootViewController = controller

        window?.makeKeyAndVisible()
    }

}

