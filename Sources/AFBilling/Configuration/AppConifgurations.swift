//
//  AppConfigurations.swift
//  VPN Guard
//
//  Created by Ali Fakih on 3/5/20.
//  Copyright © 2020 beApp. All rights reserved.
//

import Foundation

final class AppConfiguration {
    
    lazy var iTunesURL: String = {
        #if DEBUG
        guard let verifyReceiptURl = Bundle.main.object(forInfoDictionaryKey: "DEBUGiTunesURL") as? String else {
            fatalError("most provide a debug url for iTunes")
        }
        return verifyReceiptURl
        #elseif TESTFLIGHT
        guard let verifyReceiptURl = Bundle.main.object(forInfoDictionaryKey: "DEBUGiTunesURL") as? String else {
                   fatalError("most provide a url for iTunes")
        }
        return verifyReceiptURl
        #else
        guard let verifyReceiptURl = Bundle.main.object(forInfoDictionaryKey: "iTunesURL") as? String else {
                          fatalError("most provide a url for iTunes")
               }
        return verifyReceiptURl
        #endif
    }()
    
    lazy var sharedSecretKey: String = {
        guard let secretKey = Bundle.main.object(forInfoDictionaryKey: "SharedSecretKey") as? String else {
            fatalError("provide shared secret key")
        }
        print(secretKey)
        return secretKey
    }()
}
