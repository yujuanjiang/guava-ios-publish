//
//  SubscriptionHelper.swift
//  Guava
//
//  Created by Paras on 07/01/24.
//  Copyright © 2024 Bold Era. All rights reserved.
//

import Foundation

class SubscriptionHelper {
    
}
enum UserDefaultsKeys: String {
    case isSubscribe
    case subscribedStatusMessage
}
extension UserDefaults {
    func subscribe(value: Bool) {
        set(value, forKey: UserDefaultsKeys.isSubscribe.rawValue)
    }
    func getSubscription() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.isSubscribe.rawValue)
    }
    func setSubscribedStatusMessage(value: String) {
        set(value, forKey: UserDefaultsKeys.subscribedStatusMessage.rawValue)
    }
    func getsubscribedStatusMessage() -> String {
        return string(forKey: UserDefaultsKeys.subscribedStatusMessage.rawValue) ?? ""
    }
}
