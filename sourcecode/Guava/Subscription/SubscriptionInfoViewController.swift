//
//  SubscriptionInfoViewController.swift
//  Guava
//
//  Created by Paras on 26/01/24.
//  Copyright © 2024 Bold Era. All rights reserved.
//

import UIKit

class SubscriptionInfoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnTapPrivacyPolicy(_ sender: UIButton) {
        guard let url = URL(string: "http://bolderai.com/privacy-policy") else {
             return
        }

        if UIApplication.shared.canOpenURL(url) {
             UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func btnTapTermCondition(_ sender: UIButton) {
        guard let url = URL(string: "http://bolderai.com/term-conditions") else {
             return
        }

        if UIApplication.shared.canOpenURL(url) {
             UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
