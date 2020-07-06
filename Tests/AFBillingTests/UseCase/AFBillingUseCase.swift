//
//  AFBillingUseCase.swift
//  
//
//  Created by Smart Mobile Tech on 7/6/20.
//

import Foundation
@testable import AFBilling

protocol AFBillingUseCase {
   func requestProduct(_ completion: @escaping ProductsRequestCompletionHandler)
    func buyProduct(_ product: ProductIdentifier)
    func isProductPurchased(_ productIdentifier: ProductIdentifier, completion: @escaping (Result<Bool, Error>) -> Void)
    func canMakePurchase(_ completion: @escaping(Result<Bool, Error>) -> Void)
    func restorePurchase()
    func receiptValidation(completion: @escaping ValidatePurchaseCompletion) -> Cancellable?
    func removeObserver()
    func registerObserver()
}


public class DefaultAFBillingUseCase {
    
    private var purchaseRepository: IAPRepository
    init(inAppRepository: IAPRepository) {
        self.purchaseRepository = inAppRepository
    }
}


extension DefaultAFBillingUseCase: AFBillingUseCase {
    public func registerObserver() {
        self.purchaseRepository.registerObserver()
    }
    
    public func removeObserver() {
        self.purchaseRepository.removeObserver()
    }
    
    public func requestProduct(_ completion: @escaping ProductsRequestCompletionHandler) {
        self.purchaseRepository.requestProduct(completion)
    }
    
    public func buyProduct(_ product: ProductIdentifier) {
        self.purchaseRepository.buyProduct(product)
    }
    
    public func isProductPurchased(_ productIdentifier: ProductIdentifier, completion: @escaping (Result<Bool, Error>) -> Void) {
        self.purchaseRepository.isProductPurchased(productIdentifier, completion: completion)
    }
    
    public func canMakePurchase(_ completion: @escaping (Result<Bool, Error>) -> Void) {
        self.purchaseRepository.canMakePurchase(completion)
    }
    
    public func restorePurchase() {
        self.purchaseRepository.restorePurchase()
    }
    
    public func receiptValidation(completion: @escaping ValidatePurchaseCompletion) -> Cancellable? {
        return self.purchaseRepository.receiptValidation(completion: completion)
    }
}

