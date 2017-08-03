//
//  WRIStoreKitDelegate.swift
//  Kimoji
//
//  Created by aramik on 2/23/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import StoreKit

public protocol WStoreKitDelegate {
    func WRIStoreKitRequestProductsFinished(_ productResponse:SKProductsResponse?, error:NSError?)
    func WRIStoreKitTransactionFinished(_ transaction:SKPaymentTransaction, productIdentifier:String)
    func WRIStoreKitTransactionFailed(_ transaction:SKPaymentTransaction, productIdentifier:String)
    func WRIStoreKitTransactionsRemoved(_ transactions: [SKPaymentTransaction])
    func WRIStoreKitRestoreFinished(_ queue:SKPaymentQueue, error:NSError?)
    func WRIStoreKitRestoreFailed()
}
