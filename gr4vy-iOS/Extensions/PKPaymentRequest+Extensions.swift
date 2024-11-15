//
//  PKPaymentRequest+Extensions.swift
//  gr4vy-ios
//
//  Created by Arthur Tristan Ramos on 5/17/24.
//

import Foundation
import PassKit

extension PKPaymentRequest {
    
    // MARK: This displays "Pay $(APPLE_ACCOUNT_ENTITY_NAME) in Apple Pay payment sheet. To have this properly working, pass your Apple Account/Entity name as `merchantAccountId` in your `Gr4vySetup` argument.
    
    func modifiedSessionForApplePay(gr4vySetup: Gr4vySetup, message: Gr4vyMessage) -> PKPaymentRequest? {
        let payload = message.payload
        return Gr4vyUtility.handleAppleStartSession(from: payload,
                                                    merchantId: gr4vySetup.applePayMerchantId ?? "",
                                                    merchantName: gr4vySetup.applePayMerchantId ?? "")
    }
}
