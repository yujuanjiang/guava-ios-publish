//
//  SubscriptionManager.swift
//  Guava
//
//  Created by Paras on 07/01/24.
//  Copyright © 2024 Bold Era. All rights reserved.
//

import Foundation
import SwiftyStoreKit

class SubscriptionManager {
    static let shared = SubscriptionManager()
    
    let monthlySubscriptionId = "com.guava.ai.product.monthly_subscription"
    let yearlySubscriptionId = "com.guava.ai.product.yearly_subscription"
    let sharedSecretKey = "a95c834114314acaafe099e20cedbf77"
}
extension SubscriptionManager {
    func purchasePlan(subscriptionId: String, atomically: Bool, completion: @escaping (Bool) -> Void) {
        
        SwiftyStoreKit.purchaseProduct(subscriptionId, atomically: atomically) { result in
            switch result {
            case .success(let purchase):
                let downloads = purchase.transaction.downloads
                
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                }

                // isSubscribed = true
                print("Subscription Product ID:", purchase.productId)
                
                 // UserDefaults.standard.setSubscriptionProductID(value: purchase.productId)
                // UserDefaults.standard.setSubscribedKey(value: true)
            
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
                #if DEBUG
                let service = AppleReceiptValidator.VerifyReceiptURLType.sandbox
                #else
                let service = AppleReceiptValidator.VerifyReceiptURLType.production
                #endif
                
                let appleValidator = AppleReceiptValidator(service: service, sharedSecret: self.sharedSecretKey)
                SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
                    if case .success(let receipt) = result {
                        let purchaseResult = SwiftyStoreKit.verifySubscription(
                            ofType: .autoRenewable,
                            productId: purchase.productId,
                            inReceipt: receipt)
                        
                        switch purchaseResult {
                        case .purchased(let expiryDate, let receiptItems):
                            print("Product is valid until \(expiryDate)")
                            print("Is Trial Period:", receiptItems.first?.isTrialPeriod)
                            print("Receipt Items",receiptItems)
                            // print("Receipt Items",receiptItems.first?.transactionId)
                            // UserDefaults.standard.setTransactionId(value: receiptItems.first?.transactionId ?? "")
                        case .expired(let expiryDate, let receiptItems):
                            print("Product is expired since \(expiryDate)")
                            print("Receipt Items",receiptItems)
                        case .notPurchased:
                            print("This product has never been purchased")
                        }
                        completion(true) // Call completion with true for successful purchase
                        
                    } else {
                        completion(false)
                        // receipt verification error
                    }
                }
            case .error(let error):
                // Handle purchase error if needed
                print("Purchase error: \(error)")
                completion(false)
                // Call completion with false for failed purchase
            case .deferred(purchase: let purchase):
                // Handle purchase error if needed
                print("Purchase error: \(purchase)")
                completion(false)
                // Call completion with false for failed purchase
            }
        }
    }
}
// MARK: - Restore Purchases
extension SubscriptionManager {
    /**Restore Purchases if user has already subscribed*/
    func restorePurchases(completion: @escaping(Bool,String) -> Void) {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            print(results)
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed: \(results.restoreFailedPurchases)")
                completion(false, "Restore Failed")
            }
            else if results.restoredPurchases.count > 0 {
                print("Restore Success: \(results.restoredPurchases)")
                self.verifySubscriptions { success in
                    completion(success, "Restore Success with information")
                }
            }
            else {
                print("Nothing to Restore")
                completion(false, "Nothing to Restore")
            }
        }
    }
}
// MARK: - Verify Subscriptions
extension SubscriptionManager {
    /**Verify subscription that user's subscription has expired or not*/
    func verifySubscriptions(completion:@escaping (Bool) -> () ) {
        
        verifyReceipt { result in
            
            switch result {
            case .success(let receipt):
                let productIds = Set([self.monthlySubscriptionId, self.yearlySubscriptionId])
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(productIds: productIds, inReceipt: receipt)
                print(purchaseResult)
                switch purchaseResult {
                case .purchased(let expiryDate, let receiptItems):
                    print("Product is valid until \(expiryDate)")
                    print("Receipt Items",receiptItems)
                   // receiptItems.first means last purchased subscription reciept
                    if let item = receiptItems.first {
                        if #available(iOS 15.0, *) {
                            self.handleIsSubscribed(item: item, onMessage: { msg in
                                
                            })
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                    completion(true)
                case .expired(let expiryDate, let receiptItems):
                    print("Product is expired since \(expiryDate)")
                    print("Receipt Items",receiptItems)
                    
                       if let item = receiptItems.first {
                           if #available(iOS 15.0, *) {
                               self.handleSubscriptionExpired(item: item, onMessage: { msg in
                                   
                               })
                           } else {
                               // Fallback on earlier versions
                           }
                       }

                    completion(false)
                case .notPurchased:
                    print("This product has never been purchased")
                    completion(false)
                }
            case .error:
                completion(false)
            }
        }
    }

    /**Returns the latest reciept**/
    func verifyReceipt(completion: @escaping (VerifyReceiptResult) -> Void) {
        let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: sharedSecretKey)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { receipt in
            print(receipt)
            completion(receipt)
        }
    }
}
extension SubscriptionManager {
    /**If subscription has expired**/
    @available(iOS 15.0, *)
    func handleSubscriptionExpired(item: ReceiptItem, onMessage: (String)-> Void) {
        UserDefaults.standard.subscribe(value: false)
        /* isSubscribed = false
        UserDefaults.standard.setSubscribedKey(value: false)
        UserDefaults.standard.setSubscriptionProductID(value: item.productId)
        UserDefaults.standard.setSubscriptionLastPurchasedDate(value: item.purchaseDate)
        UserDefaults.standard.setSubscriptionFirstPurchasedDate(value: item.originalPurchaseDate)
        UserDefaults.standard.setSubscriptionExpirationDate(value: item.subscriptionExpirationDate ?? Date()) */
        
        let message = "Your subscription has expired. Do please renew to keep enjoying Guava"
        UserDefaults.standard.setSubscribedStatusMessage(value: message)
        onMessage(message)
    }
    
    /**If subscription has already purchased**/
    @available(iOS 15.0, *)
    func handleIsSubscribed(item: ReceiptItem, onMessage: (String)-> Void) {
        UserDefaults.standard.subscribe(value: true)
       /* isSubscribed = true
        UserDefaults.standard.setSubscribedKey(value: true)
        UserDefaults.standard.setSubscriptionProductID(value: item.productId)
        UserDefaults.standard.setSubscriptionLastPurchasedDate(value: item.purchaseDate)
        UserDefaults.standard.setSubscriptionFirstPurchasedDate(value: item.originalPurchaseDate)
        UserDefaults.standard.setSubscriptionExpirationDate(value: item.subscriptionExpirationDate ?? Date()) */
        let message = "Thank you for subscribing to Weekly Package. Your subscription started on \(item.purchaseDate) and is currently active. Your next billing date is \((item.subscriptionExpirationDate ?? Date()).formatted()), at which point your subscription will automatically renew. If you have any questions or concerns about your subscription, please don't hesitate to contact our support team. Thank you for being a valued subscriber!"
        UserDefaults.standard.setSubscribedStatusMessage(value: message)
        onMessage(message)
    }
}
