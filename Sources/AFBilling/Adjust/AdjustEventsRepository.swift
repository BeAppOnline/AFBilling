//
//  AdjustEventsRepository.swift
//  VPN Guard
//
//  Created by Smart Mobile Tech on 5/12/20.
//  Copyright © 2020 beApp. All rights reserved.
//

import Foundation
import StoreKit

public protocol AdjustEventsRepository {
    func sendSuccessEvent(transaction: SKPaymentTransaction)
    func sendFailureEvent(transaction: SKPaymentTransaction, error: Error?)
    func sendRestoreSuccessEvent(transaction: SKPaymentTransaction)
}
