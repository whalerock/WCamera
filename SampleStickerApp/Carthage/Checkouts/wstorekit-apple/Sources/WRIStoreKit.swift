//
//  WRIStoreKit.swift
//  Kimoji
//
//  Created by aramik on 2/23/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import StoreKit
import WConfig

public class WStoreKit:NSObject {
    public static let manager = WStoreKit()
    public var delegate: WStoreKitDelegate?
    
    public var consoleLogs: Bool = false
    public var isProcessingTransaction: Bool = false

    public var appGroupIdentifier: String?
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    public func autoConfigure() {
        if let storeKitGroupId = WConfig.sharedInstance.get("storekit.appGroupIdentifier") as? String {
            self.appGroupIdentifier = storeKitGroupId
            log("StoreKit setup with \(storeKitGroupId)")
        }
    }
    
    public func requestProducts(productIDs:NSArray) {
        guard !isProcessingTransaction else {
            self.log("Already processing another transaction")
            return
        }
        if SKPaymentQueue.canMakePayments() {
            let productIdentifiers = NSSet(array: productIDs as [AnyObject])
            let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String> )
            productRequest.delegate = self
            productRequest.start()
            self.isProcessingTransaction = true
        }
        else {
            self.log("Cannot perform In App Purchases")
            let errInfo = NSDictionary()
            errInfo.setValue("WRIStoreKit Cannot perform In App Purchases", forKey: NSLocalizedDescriptionKey)
            self.delegate?.WRIStoreKitRequestProductsFinished(nil, error: NSError(domain: "WRIStoreKitError", code: 0, userInfo: errInfo as [NSObject : AnyObject]))
        }
    }
    
    public func purchaseProduct(product:SKProduct) {
        guard !isProcessingTransaction else {
            self.log("Already processing another transaction")
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func restorePurchases() {
        guard !isProcessingTransaction else {
            self.log("Already processing another transaction")
            return
        }
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public func didPurchase(_ productIdentifier:String) -> Bool {
        var userDefaults: UserDefaults?
        
        userDefaults = UserDefaults(suiteName: self.appGroupIdentifier)
        
        return userDefaults?.bool(forKey: "WRISK--\(productIdentifier.hashValue)") ?? false
    }
    
    fileprivate func saveProductStatusInPrefs(productIdentifier:String, purchaseSuccessful:Bool) {
        var userDefaults: UserDefaults?
        
        userDefaults = UserDefaults(suiteName: self.appGroupIdentifier)
        
        userDefaults?.set(purchaseSuccessful, forKey: "WRISK--\(productIdentifier.hashValue)")
        userDefaults?.synchronize()
        
    }
    
    
    private func log(_ message:String) {
        if consoleLogs {
            print("[WRIStoreKit]: ",message)
        }
    }
    
}

// MARK: StoreKit Delegates

extension WStoreKit: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        self.isProcessingTransaction = false
        self.delegate?.WRIStoreKitRequestProductsFinished(response, error: nil)
    }
}

extension WStoreKit: SKPaymentTransactionObserver {

    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                
                self.saveProductStatusInPrefs(productIdentifier: transaction.payment.productIdentifier, purchaseSuccessful: true)
                   self.delegate?.WRIStoreKitTransactionFinished(transaction, productIdentifier: transaction.payment.productIdentifier)
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                self.saveProductStatusInPrefs(productIdentifier: transaction.payment.productIdentifier, purchaseSuccessful: false)
                   self.delegate?.WRIStoreKitTransactionFailed(transaction, productIdentifier: transaction.payment.productIdentifier)
            default:
                return
            }
            
         
        }
        self.isProcessingTransaction = false
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        self.delegate?.WRIStoreKitRestoreFailed()
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        self.delegate?.WRIStoreKitTransactionsRemoved(transactions)
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        self.delegate?.WRIStoreKitRestoreFinished(queue, error: nil)
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        self.delegate?.WRIStoreKitRestoreFinished(queue, error: nil)
    }
}
