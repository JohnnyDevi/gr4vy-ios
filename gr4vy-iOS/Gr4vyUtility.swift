//
//  Gr4vyUtility.swift
//  gr4vy-iOS
//
//  Created by Gr4vy
//

import Foundation
import PassKit

struct Gr4vyUtility {
    
    static func getInitialURL(from setup: Gr4vySetup) -> URLRequest? {
        let urlString = "https://embed.\(setup.instance).gr4vy.app/mobile.html?channel=123"
        guard let url = URL(string: urlString) else {
            return nil
        }
        return URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
    }
    
    static func generateUpdateOptions(from setup: Gr4vySetup) -> String {
        var optionalData: String = ""
        
        if let externalIdentifier = setup.externalIdentifier {
            optionalData = optionalData + ", externalIdentifier: '\(externalIdentifier)'"
        }
        
        if let store = setup.store {
            optionalData = optionalData + ", store: '\(store)'"
        }
        
        if let display = setup.display {
            optionalData = optionalData + ", display: '\(display)'"
        }
        
        if let intent = setup.intent {
            optionalData = optionalData + ", intent: '\(intent)'"
        }
        
        if let metadata = setup.metadata {
            var metadataString = ", metadata: {"
            for (index, key) in Array(metadata.keys).sorted().enumerated() {
                guard key != "" else {
                    continue
                }
                let ending = index + 1 == metadata.count ? "" : ", "
                let value = metadata[key]!
                metadataString = metadataString + "\(key): '\(value)'" + ending
            }
            metadataString = metadataString + "}"
            optionalData = optionalData + metadataString
        }
        
        if let paymentSource = setup.paymentSource {
            optionalData = optionalData + ", paymentSource: '\(paymentSource.rawValue)'"
        }
        
        if let cartItems = setup.cartItems {
            var cartItemsString = ", cartItems: ["
            for (index, item) in cartItems.enumerated() {
                let ending = index + 1 == cartItems.count ? "" : ", "
                cartItemsString = cartItemsString + "{name: '\(item.name)', quantity: \(item.quantity), unitAmount: \(item.unitAmount)}" + ending
            }
            cartItemsString = cartItemsString + "]"
            optionalData = optionalData + cartItemsString
        }
        
        if let buyerId = setup.buyerId {
            optionalData = optionalData + ", buyerId: '\(buyerId)'"
        }
        
        if deviceSupportsApplePay() {
            optionalData = optionalData + ", supportedApplePayVersion: 5"
        }
        
        if let theme = setup.theme {
            optionalData = optionalData + ", theme: \(theme.toString())"
        }
        
        if let buyerExternalIdentifier = setup.buyerExternalIdentifier {
            optionalData = optionalData + ", buyerExternalIdentifier: '\(buyerExternalIdentifier)'"
        }
        
        if let locale = setup.locale {
            optionalData = optionalData + ", locale: '\(locale)'"
        }
    
        if let statementDescriptor = setup.statementDescriptor {
            optionalData = optionalData + ", statementDescriptor: \(statementDescriptor.toString())"
        }
        
        if let requireSecurityCode = setup.requireSecurityCode {
            optionalData = optionalData + ", requireSecurityCode: '\(requireSecurityCode.description)'"
        }
        
        if let shippingDetailsId = setup.shippingDetailsId {
            optionalData = optionalData + ", shippingDetailsId: '\(shippingDetailsId)'"
        }
        
        let content =
        "window.postMessage({ type: 'updateOptions', data: { apiHost: 'api.\(setup.instance).gr4vy.app', apiUrl: 'https://api.\(setup.instance).gr4vy.app', token: '\(setup.token)', amount: \(setup.amount), country: '\(setup.country)', currency: '\(setup.currency)'"
        +
        optionalData
        +
        "},})"
        
        return content
    }
    
    static func generateAppleCompleteSession() -> String {
        return "window.postMessage({ type: 'appleCompleteSession'})"
    }
    
    static func generateAppleCancelSession() -> String {
        return "window.postMessage({ type: 'appleCancelSession'})"
    }
    
    static func generateApprovalCancelled() -> String {
        return "window.postMessage({ type: 'approvalCancelled'})"
    }
    
    static func handleApprovalUrl(from payload: [String: Any]) -> URL? {
        guard let urlString = payload["data"] as? String else {
            return nil
        }
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
    
    static func handleTransactionCreated(from payload: [String: Any]) -> Gr4vyEvent {
        
        guard let data = payload["data"] as? [String: Any], let status = data["status"] as? String else {
            return .generalError("Gr4vy Error: Pop up transaction created failed.")
        }
        
        switch status {
            // Success statuses
        case "capture_succeeded", "capture_pending", "authorization_succeeded", "authorization_pending":
            guard let transactionID = data["id"] as? String else {
                return .generalError("Gr4vy Error: transaction success has failed, no transactionID and/or paymentMethodID found")
            }
            return .transactionCreated(transactionID: transactionID, status: status, paymentMethodID: data["paymentMethodID"] as? String)
            
            // Failure statuses
        case "capture_declined", "authorization_failed":
            guard let transactionID = data["id"] as? String else {
                return .generalError("Gr4vy Error: transaction failed, no transactionID and/or paymentMethodID found")
            }
            return .transactionFailed(transactionID: transactionID, status: status, paymentMethodID: data["paymentMethodID"] as? String)
        default:
            guard let transactionID = data["id"] as? String else {
                return .generalError("Gr4vy Error: transaction failed, no transactionID and/or paymentMethodID found")
            }
            return .transactionFailed(transactionID: transactionID, status: status, paymentMethodID: data["paymentMethodID"] as? String)
        }
    }
    
    static func handleTransactionUpdated(from payload: [String: Any]) -> String? {
        guard let passOnMessage = try? JSONSerialization.data(withJSONObject: payload, options: .withoutEscapingSlashes), let message = String(data: passOnMessage, encoding: .utf8) else {
            return nil
        }
        
        return "window.postMessage(\(message.replacingOccurrences(of: "\"", with: "\"")))"
    }
    
    static func handlePaymentSelected(from payload: [String: Any]) -> Gr4vyEvent? {
        guard let data = payload["data"] as? [String: String],
              let method = data["method"],
              let mode = data["mode"] else {
            return nil
        }
        
        return .paymentMethodSelected(id: data["id"], method: method, mode: mode)
    }
    
    static func generateApplePayAuthorized(from payment: PKPayment) -> String {
        let token = payment.token.paymentData.prettyPrintedJSONString!.replacingOccurrences(of: "\n", with: "")
        let content =
        "window.postMessage({ type: 'applePayAuthorized', data: { 'payment_data': \(token) } })"
        return content
    }
    
    static func handleAppleStartSession(from payload: [String: Any], merchantId: String) -> PKPaymentRequest? {
        guard let data = payload["data"] as? [String: Any],
              let _ = data["supportedNetworks"] as? [String],
              let countryCode = data["countryCode"] as? String,
              let currencyCode = data["currencyCode"] as? String,
              let total = data["total"] as? [String: Any],
              let value = total["label"] as? String,
              let amount = total["amount"] as? String else {
            return nil
        }
        
        let paymentItem = PKPaymentSummaryItem.init(label: value, amount: NSDecimalNumber(string: amount))
        
        let paymentNetworks = [
            PKPaymentNetwork.amex,
            PKPaymentNetwork.cartesBancaires,
            PKPaymentNetwork.discover,
            PKPaymentNetwork.eftpos,
            PKPaymentNetwork.electron,
            PKPaymentNetwork.elo,
            PKPaymentNetwork.interac,
            PKPaymentNetwork.JCB,
            PKPaymentNetwork.mada,
            PKPaymentNetwork.maestro,
            PKPaymentNetwork.masterCard,
            PKPaymentNetwork.privateLabel,
            PKPaymentNetwork.visa,
            PKPaymentNetwork.vPay
        ]
        
        guard deviceSupportsApplePay(paymentNetworks: paymentNetworks) else {
            return nil
        }
        
        let request = PKPaymentRequest()
        request.currencyCode = currencyCode
        request.countryCode = countryCode
        request.merchantCapabilities = PKMerchantCapability.capability3DS
        request.merchantIdentifier = merchantId
        request.supportedNetworks = paymentNetworks
        request.paymentSummaryItems = [paymentItem]
        return request
        
    }
    
    static func deviceSupportsApplePay(paymentNetworks: [PKPaymentNetwork] = [PKPaymentNetwork.amex,
                                                                              PKPaymentNetwork.cartesBancaires,
                                                                              PKPaymentNetwork.discover,
                                                                              PKPaymentNetwork.eftpos,
                                                                              PKPaymentNetwork.electron,
                                                                              PKPaymentNetwork.elo,
                                                                              PKPaymentNetwork.interac,
                                                                              PKPaymentNetwork.JCB,
                                                                              PKPaymentNetwork.mada,
                                                                              PKPaymentNetwork.maestro,
                                                                              PKPaymentNetwork.masterCard,
                                                                              PKPaymentNetwork.privateLabel,
                                                                              PKPaymentNetwork.visa,
                                                                              PKPaymentNetwork.vPay]) -> Bool {
        return PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks)
        
    }
}
