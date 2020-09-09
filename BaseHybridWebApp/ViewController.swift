//
//  ViewController.swift
//  BaseHybridWebApp
//
//  Created by Colby Lim on 2020/09/09.
//  Copyright © 2020 Colby Lim. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    @IBOutlet weak var toolView: UIView!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var forwardBtn: UIButton!
    
    private lazy var webView: WKWebView = {
        let cf: WKWebViewConfiguration
        if let config = webConfig {
            cf = config
        } else {
            cf = WKWebViewConfiguration()
        }
        let webView = WKWebView(frame: .zero, configuration: cf)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0
//        progressView.tintColor = .systemBlue
        return progressView
    }()
    
    private var observers: [NSKeyValueObservation] = []
    
    var webConfig: WKWebViewConfiguration?
    var openLoadURL: URL?
    
    deinit {
        webView.stopLoading()
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
        
        removeObservers()
    }
    
    override func loadView() {
        super.loadView()
        
        setWebViewLayout()
        setProgressViewLayout()
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        addObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        webView.stopLoading()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        interactivePopGestureRecognizerEnabled(!self.webView.canGoBack)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        interactivePopGestureRecognizerEnabled(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if let url = openLoadURL {
            load(url)
        } else {
            load("https://www.naver.com")
        }
    }

    private func setProgressViewLayout() {
        view.addSubview(progressView)
        
        if #available(iOS 11.0, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                progressView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                progressView.topAnchor.constraint(equalTo: guide.topAnchor),
                progressView.heightAnchor.constraint(equalToConstant: 3)
            ])
        } else {
            NSLayoutConstraint.activate([
                progressView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                progressView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.bottomAnchor),
                progressView.heightAnchor.constraint(equalToConstant: 3)
            ])
        }
    }
    
    private func setWebViewLayout() {
        view.addSubview(webView)
        
        if #available(iOS 11.0, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                webView.topAnchor.constraint(equalTo: guide.topAnchor),
                webView.bottomAnchor.constraint(equalTo: toolView.topAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                webView.bottomAnchor.constraint(equalTo: toolView.topAnchor)
            ])
        }
    }
    
    private func addObservers() {
        observers.append(webView.observe(\.estimatedProgress, options: .new) { [weak self] (_, change) in
            guard let self = self else { return }
            let newValue = change.newValue ?? 0.0
            self.progressView.setProgress(Float(newValue), animated: false)
            if newValue == 1 {
                UIView.animate(withDuration: 0.5, animations: {
                    self.progressView.alpha = 0
                }) { (_) in
                    self.progressView.setProgress(0, animated: false)
                }
            } else {
                self.progressView.alpha = 1
            }
        })
        
        observers.append(webView.observe(\.isLoading, options: .new) { [weak self] (_, change) in
            guard let newValue = change.newValue else { return }
            if newValue == true {
                self?.loadDidStart()
            } else {
                self?.loadDidFinish()
            }
        })
        
        observers.append(webView.observe(\.url, options: .new) { [weak self] (webView, _) in
            guard let host = webView.url?.host else { return }
            self?.title = host
        })
    }
    
    private func removeObservers() {
        observers.forEach { $0.invalidate() }
        observers.removeAll()
    }
    
    private func loadDidStart() {
        let canGoBack = webView.canGoBack
        let canGoForward = webView.canGoForward
        
        backBtn.isEnabled = canGoBack
        forwardBtn.isEnabled = canGoForward
        
        interactivePopGestureRecognizerEnabled(!canGoBack)
    }
    
    private func loadDidFinish() {
        loadDidStart()
    }
    
    private func interactivePopGestureRecognizerEnabled(_ isEnabled: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = isEnabled
    }
    
    @IBAction func backBtnPressed(_ sender: UIButton) {
        webView.goBack()
    }
    
    @IBAction func forwardBtnPressed(_ sender: UIButton) {
        webView.goForward()
    }
    
    func load(_ urlPath: String?, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 0) {
        guard var urlPath = urlPath else { return }
        if urlPath.lowercased().hasPrefix("http") == false {
            urlPath = "http://\(urlPath)"
        }
        
        guard let url = URL(string: urlPath) else { return }
        load(url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
    }
    
    func load(_ url: URL?, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 0) {
        guard let url = url else { return }
        webView.load(URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval))
    }
}

// MARK: WKUIDelegate
extension ViewController: WKUIDelegate {
    
    // alert 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let ac = UIAlertController(title: "",
                                   message: message,
                                   preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "확인",
                                   style: .default) { (action) in
            completionHandler()
        })
        
        present(ac, animated: true, completion: nil)
    }
    
    //confirm 처리
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let ac = UIAlertController(title: "",
                                   message: message,
                                   preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "확인",
                                   style: .default) { (action) in
                                    completionHandler(true)
        })
        
        ac.addAction(UIAlertAction(title: "취소",
                                   style: .cancel) { (action) in
                                    completionHandler(false)
        })
        
        present(ac, animated: true, completion: nil)
    }
    
    // textField alert
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let ac = UIAlertController(title: "",
                                   message: prompt,
                                   preferredStyle: .alert)
        
        ac.addTextField { (textField) in
            textField.text = defaultText
        }
        ac.addAction(UIAlertAction(title: "확인", style: .default) { (_) in
            if let text = ac.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        })
        
        present(ac, animated: true, completion: nil)
    }
    
    // href="_blank" 처리
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "WebVC") as? ViewController {
                vc.openLoadURL = navigationAction.request.url
                vc.webConfig = configuration
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        return nil
    }
}

// MARK: WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    // 중복적으로 리로드 방지
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadDidStart()
    }
        
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadDidFinish()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadDidFinish()
    }
}
