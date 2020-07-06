//
//  DefaultAdjustEvent.swift
//  VPN Guard
//
//  Created by Smart Mobile Tech on 5/12/20.
//  Copyright © 2020 beApp. All rights reserved.
//

import Foundation
import Adjust
import StoreKit

final class DefaultAdjustEvent: AdjustEventsRepository {
    
    private var appConfiguration = AdjustConfigurations()
    //private var storageRepository: DataStorageRepository
    
    private var sendTaskOperation: OperationQueue? { willSet { sendTaskOperation?.cancelAllOperations() } }
    
//    init(storageRepository: DataStorageRepository) {
//        self.storageRepository = storageRepository
//        storageRepository.loadUser { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success(let user):
//                self.user = user
//                break
//            case .failure(_):
//                break
//            }
//        }
//    }
    
    func sendSuccessEvent(transaction: SKPaymentTransaction) {
        sendTaskOperation = OperationQueue()
        sendTaskOperation?.addOperation { [weak self] in
            guard let self = self else { return }
            Adjust.trackEvent(self.queryCallback(token: self.appConfiguration.eventSuccessToken, transaction: transaction))
        }
    }
    
    func sendFailureEvent(transaction: SKPaymentTransaction, error: Error?) {
        sendTaskOperation = OperationQueue()
        sendTaskOperation?.addOperation({ [weak self] in
            guard let self = self else { return }
            print( self.appConfiguration.eventFailureToken)
            Adjust.trackEvent(self.queryCallback(token: self.appConfiguration.eventFailureToken, transaction: transaction))
        })
    }
    
    func sendRestoreSuccessEvent(transaction: SKPaymentTransaction) {
        sendTaskOperation = OperationQueue()
        sendTaskOperation?.addOperation({ [weak self] in
            guard let self = self else { return }
            Adjust.trackEvent(self.queryCallback(token: self.appConfiguration.eventRestore, transaction: transaction))
        })
    }
    
    private func queryCallback(token: String, transaction: SKPaymentTransaction) -> ADJEvent? {
        let adjustEvent = ADJEvent(eventToken: token)
        switch transaction.transactionState {
        case .purchasing:
            break
        case .purchased:
            adjustEvent?.addCallbackParameter("eventValue", value: "ok")
            break
        case .failed:
            adjustEvent?.addCallbackParameter("eventValue", value: "failed")
            break
        case .restored:
            adjustEvent?.addCallbackParameter("eventValue", value: "Restored ok")
        case .deferred:
            break
        @unknown default:
            break
        }
        
        adjustEvent?.addCallbackParameter("inAppOriginalTransactionDate", value: transaction.original?.transactionDate?.string ?? "None")
        adjustEvent?.addCallbackParameter("inAppTransactionId", value: transaction.transactionIdentifier ?? "Not Provided")
        adjustEvent?.addCallbackParameter("inAppPassword", value: "")
        adjustEvent?.addCallbackParameter("inAppProductId", value: transaction.payment.productIdentifier)
        adjustEvent?.addCallbackParameter("inAppOriginalTransactionId", value: transaction.original?.transactionIdentifier ?? "Not provided")
        adjustEvent?.addCallbackParameter("inAppTransactionDate", value: transaction.transactionDate?.string ?? "Not Provided")
//        if let tempUser = user, tempUser.userDeeplink.isDeeplink {
//            adjustEvent?.addCallbackParameter("inAppDeeplink", value: tempUser.userDeeplink.url)
//        }
        return adjustEvent
    }
    
}

private extension Date {
    var string: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
    
    func days(between otherDate: Date) -> Int {
        let calendar = Calendar.current

        let startOfSelf = calendar.startOfDay(for: self)
        let startOfOther = calendar.startOfDay(for: otherDate)
        let components = calendar.dateComponents([.day], from: startOfSelf, to: startOfOther)

        return abs(components.day ?? 0)
    }
}
