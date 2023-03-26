//
//  Gr4vyViewController.swift
//  gr4vy-iOS
//
//  Created by Gr4vy
//

import UIKit
import WebKit
import PassKit

public class Gr4vyViewController: UIViewController , WKNavigationDelegate {
    
    var delegate: Gr4vyInternalDelegate?
    var url: URLRequest!
    var applePayState: ApplePayState = .started
    var theme: Gr4vyTheme?
    
    private let postMessageHandler = "nativeapp"
    private var webView = WKWebView()
    
    deinit {
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: postMessageHandler)
        webView.navigationDelegate = nil
        webView.scrollView.delegate = nil
        webView = WKWebView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let theme = theme {
            if theme.navigationTextColor == nil && theme.navigationBackgroundColor == nil {
                return
            }
            
            self.edgesForExtendedLayout = []
            
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithDefaultBackground()
            if let navigationBackgroundColor = theme.navigationBackgroundColor {
                navigationBarAppearance.backgroundColor = navigationBackgroundColor
            }
            if let navigationTextColor = theme.navigationTextColor {
                navigationBarAppearance.titleTextAttributes = [.foregroundColor: navigationTextColor]
                navigationController?.navigationBar.tintColor = navigationTextColor
            }
            
            navigationController?.navigationBar.standardAppearance = navigationBarAppearance
            navigationController?.navigationBar.compactAppearance = navigationBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the view
        navigationItem.title = ""
        
        // Setup the back button
        let backBtn = UIBarButtonItem()
        let image = UIImage(named: "BackButton", in: Bundle(for: Gr4vy.self), compatibleWith: nil)
        backBtn.image = image
        backBtn.action = #selector(backTapped)
        backBtn.target = self
        navigationItem.leftBarButtonItem = backBtn
        
        // Setup the WebView
        setupWKWebViewConstraints()
        setupWKWebViewJavascriptHandler()
        
        // Load the URL
        webView.navigationDelegate = self
        webView.load(url)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.navigationDelegate = nil
        if #available(iOS 14.0, *) {
            webView.configuration.userContentController.removeAllScriptMessageHandlers()
        } else {
            // Fallback on earlier versions
            webView.configuration.userContentController.removeScriptMessageHandler(forName: postMessageHandler)
        }
    }
    
    func sendJavascriptMessage(_ message: String, completionHandler: @escaping ((Any?, Error?) -> Void)) {
        self.webView.evaluateJavaScript(message, completionHandler: completionHandler)
    }
    
    @objc private func backTapped(sender: UIButton) {
        if webView.canGoBack {
            webView.goBack()
        } else {
            delegate?.handleApprovalCancelled()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func setupWKWebViewConstraints() {
        webView.frame = view.bounds
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
    }
    
    private func setupWKWebViewJavascriptHandler() {
        webView.configuration.userContentController.add(self, name: postMessageHandler)
    }
}

extension Gr4vyViewController: WKScriptMessageHandler {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.title = webView.title
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        // Get message body
        guard let dict = message.body as? [String : Any] else {
            delegate?.error(message: "Gr4vy Information: No message body from webview")
            return
        }
        
        // Check the message name is "nativeapp"
        guard message.name == postMessageHandler else {
            delegate?.error(message: "Gr4vy Information: script handler name miss match")
            return
        }
        
        // Check for the type
        guard let type = dict["type"] as? String else {
            delegate?.error(message: "Gr4vy Error: No type in message body")
            return
        }
        
        delegate?.handle(message: Gr4vyMessage(type: type, payload: dict))
        
    }
}

extension Gr4vyViewController: PKPaymentAuthorizationViewControllerDelegate {
    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        if applePayState == .started {
            delegate?.handleAppleCancelSession()
        }
        dismiss(animated: true, completion: nil)
    }
    
    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        applePayState = .authorized
        delegate?.generateApplePayAuthorized(payment: payment)
        return completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
}

enum ApplePayState {
    case started
    case authorized
}
