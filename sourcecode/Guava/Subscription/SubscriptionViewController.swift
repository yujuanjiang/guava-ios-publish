//
//  SubscriptionViewController.swift
//  Guava
//
//  Created by Paras on 05/01/24.
//  Copyright © 2024 Bold Era. All rights reserved.
//

import UIKit
import MBProgressHUD

class SubscriptionViewController: UIViewController {

    @IBOutlet weak var btnMonth: UIButton!
    @IBOutlet weak var btnYear: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func didTapRestoreButton(_ sender: UIButton) {
       // self.loadingLoader.alpha = 1\
        self.showHUD()
        SubscriptionManager.shared.restorePurchases { success, message in
            if success {
                if message == "Restore Success with information" {
                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                    self.navigationController?.pushViewController(vc, animated: true)
                } else if message == "Nothing to Restore" {
                    self.showAlertWithOkButton(title: "Message", message: message)
                } else {
                    let alertMessage = UserDefaults.standard.getsubscribedStatusMessage()
                    self.showAlertWithOkButton(title: "Message", message: alertMessage)
                }
                self.dismissHUD(isAnimated: true)
            } else {
                self.dismissHUD(isAnimated: true)
                self.showAlertWithOkButton(title: "Message", message: "Restore Failed Try Again")
            }
        }
    }
    
    @IBAction func didTapMonthButton(_ sender: UIButton) {
        self.showHUD()
        SubscriptionManager.shared.purchasePlan(subscriptionId: SubscriptionManager.shared.monthlySubscriptionId, atomically: true) { bool in
            if bool {
                self.dismissHUD(isAnimated: true)
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                self.dismissHUD(isAnimated: true)
            }
        }
    }
    
    @IBAction func didTapYearButton(_ sender: UIButton) {
        self.showHUD()
        SubscriptionManager.shared.purchasePlan(subscriptionId: SubscriptionManager.shared.yearlySubscriptionId, atomically: true) { bool in
            if bool {
                self.dismissHUD(isAnimated: true)
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                self.dismissHUD(isAnimated: true)
            }
        }
    }
    
    @IBAction func didTapSubscriptionInfoButton(_ sender: UIButton) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "SubscriptionInfoViewController") as! SubscriptionInfoViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
extension SubscriptionViewController {
    func setUI() {
        self.btnMonth.layer.cornerRadius = 5.0
        self.btnYear.layer.cornerRadius = 5.0
    }
    func showAlertWithOkButton(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension UIViewController {

    func showHUD(progressLabel: String = ""){
        DispatchQueue.main.async{
            let progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
            progressHUD.label.text = progressLabel
        }
    }

    func dismissHUD(isAnimated:Bool) {
        DispatchQueue.main.async{
            MBProgressHUD.hide(for: self.view, animated: isAnimated)
        }
    }
}
