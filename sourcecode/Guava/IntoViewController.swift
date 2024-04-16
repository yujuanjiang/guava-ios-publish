//
//  IntoViewController.swift
//  Guava
//
//  Created by Paras on 07/01/24.
//  Copyright © 2024 Bold Era. All rights reserved.
//

import UIKit

class IntoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.openViewController()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func openViewController() {
       let isSubscribe = UserDefaults.standard.getSubscription()
        if isSubscribe {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "SubscriptionViewController") as! SubscriptionViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
