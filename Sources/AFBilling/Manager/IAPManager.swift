//
//  IAPManager.swift
//  VPN Guard
//
//  Created by Ali Fakih on 4/1/20.
//  Copyright © 2020 beApp. All rights reserved.
//

import StoreKit

open class IAPManager: NSObject, InAppPurchaseBillingRepository {

    private let productIdentifiers: Set<ProductIdentifier>
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    private var loadedProducts: [SKProduct] = []
    private var boolTest: Bool = false
    private let defaultAdjustEvent: AdjustEventsRepository
    private var didFinishRequesting = false
    
    public init(productIds: Set<ProductIdentifier>, defaultAdjustEvent: AdjustEventsRepository) {
        self.defaultAdjustEvent = defaultAdjustEvent
        productIdentifiers = productIds
        for productIdentifier in productIds {
          let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
          if purchased {
            purchasedProductIdentifiers.insert(productIdentifier)
            print("Previously purchased: \(productIdentifier)")
          } else {
            print("Not purchased: \(productIdentifier)")
          }
        }
        super.init()
        SKPaymentQueue.default().add(self)
        //for transactionQueue in SKPaymentQueue.default().transactions {
            //SKPaymentQueue.default().finishTransaction(transactionQueue)
        //}
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    public func removeObserver() {
        SKPaymentQueue.default().remove(self)
        
    }
    
    public func registerObserver() {
       //SKPaymentQueue.default().add(self)
    }
}

extension IAPManager {
    public func requestProducts(_ completion: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completion
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func buyProduct(_ productIdentifier: ProductIdentifier) {
        boolTest = false
        let product = loadedProducts.filter { $0.productIdentifier == productIdentifier }
        for p in product {
            buyProduct(p)
        }
    }
    
    

    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public func canMakePayment() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchase() {
        boolTest = false
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        if productsRequestCompletionHandler != nil {
            productsRequestCompletionHandler?(.success(products))
        }
        clearRequestAndHandler()
        loadedProducts.removeAll()
        loadedProducts = products
        for p in products {
            if #available(iOS 12.0, *) {
                if #available(OSX 10.15, *) {
                    print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue) isDownloadable: \(p.isDownloadable), subscriptionGroupIdentifier: \(String(describing: p.subscriptionGroupIdentifier)), subscription Period Unit\(String(describing: p.subscriptionPeriod?.unit)), \(String(describing: p.subscriptionPeriod?.numberOfUnits))")
                } else {
                    // Fallback on earlier versions
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(.failure(error))
        clearRequestAndHandler()
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPManager {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            
            switch transaction.transactionState {
            case .purchasing:
               break
            case .purchased:
                complete(transaction: transaction)
                defaultAdjustEvent.sendSuccessEvent(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
                defaultAdjustEvent.sendFailureEvent(transaction: transaction, error: nil)
            case .restored:
                restore(transaction: transaction)
                defaultAdjustEvent.sendRestoreSuccessEvent(transaction: transaction)
            case .deferred:
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            @unknown default:
                break
            }
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        
        print("Transaction failed restored with error: \(error.localizedDescription)")
        for transaction in queue.transactions {
            defaultAdjustEvent.sendFailureEvent(transaction: transaction, error: error)
        }

    }
    
    
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
            
        print("Transaction restored \(queue.transactions.count)")
        if (queue.transactions.count == 0) {
            NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: "There's no subscription to restore")
        } else {
            for transaction in queue.transactions {
                switch transaction.transactionState {
                case .purchasing:
                   break
                case .purchased:
                    complete(transaction: transaction)
                    defaultAdjustEvent.sendSuccessEvent(transaction: transaction)
                case .failed:
                    fail(transaction: transaction)
                    defaultAdjustEvent.sendFailureEvent(transaction: transaction, error: nil)
                case .restored:
                    restore(transaction: transaction)
                    defaultAdjustEvent.sendRestoreSuccessEvent(transaction: transaction)
                case .deferred:
                    SKPaymentQueue.default().finishTransaction(transaction)
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
        let productIdentifier = transaction.payment.productIdentifier
        deliverPurchaseNotificationFor(transaction: transaction, identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")
        NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: transaction)
        if let transactionError = transaction.error as NSError?,
            let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {
            print("Transaction Error: \(localizedDescription)")
        }
      SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
       guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }

        print("restore... \(productIdentifier)")
        deliverPurchaseNotificationFor(transaction: transaction, identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        

     }
    
    private func deliverPurchaseNotificationFor(transaction: SKPaymentTransaction, identifier: ProductIdentifier) {
        if(!boolTest) {
            purchasedProductIdentifiers.insert( identifier)
            UserDefaults.standard.set(true, forKey: identifier)
            NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: transaction)
            boolTest = true
        }
    }
    
    public func refreshReceipt(completion: @escaping () -> Void) {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        request.start()
        sleep(arc4random() / 4)
        while !didFinishRequesting {
            print("waiting…")
        }
        print("request done…")
        completion()
    }
    
    
    public func requestDidFinish(_ request: SKRequest) {
        
    }
}

extension Notification.Name {
  static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
}
