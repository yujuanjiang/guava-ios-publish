//
//  ViewController.swift
//
// Copyright 2023 (c) WebIntoApp.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Guava
//
// Created by Bold Era on 25/03/2023.
//
import WebKit
import UIKit
import AppTrackingTransparency
class FileDownloader {
    
    static func loadFileSync(url: URL, completion: @escaping (String?, Error?) -> Void) {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        } else if let dataFromURL = NSData(contentsOf: url) {
            if dataFromURL.write(to: destinationUrl, atomically: true) {
                print("file saved [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            } else {
                print("error saving file")
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(destinationUrl.path, error)
            }
        } else {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(destinationUrl.path, error)
        }
    }
    
    static func loadFileAsync(url: URL, completion: @escaping (String?, Error?) -> Void) {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        } else {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(with: request, completionHandler: { data, response, error in
                if error == nil {
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode == 200 {
                            if let data = data {
                                if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic) {
                                    completion(destinationUrl.path, error)
                                } else {
                                    completion(destinationUrl.path, error)
                                }
                            } else {
                                completion(destinationUrl.path, error)
                            }
                        }
                    }
                } else {
                    completion(destinationUrl.path, error)
                }
            })
            task.resume()
        }
    }
}
extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}
extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}
extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
}
extension UINavigationBar {
    func customNavigationBar() {
        self.tintColor = UIColor(rgb: 0xffffff)
        self.barTintColor = UIColor(rgb: 0x1a1a1a)
        self.isTranslucent = false
        self.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(rgb: 0xffffff)]
        self.setBackgroundImage(UIImage(), for: .default)
        self.shadowImage = UIImage()
    }
}
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIDocumentInteractionControllerDelegate, UIGestureRecognizerDelegate {
    var window: UIApplication!
    var statusBar: UIView!
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
            self.statusBar.isHidden = true
        } else {
            print("Portrait")
            self.statusBar.isHidden = false
        }
    }
    var webView: WKWebView!
    var webViewSplashScreen: WKWebView!
    var useSplashScreen: Bool = true
    var loadingError: Bool! = false
    let refreshControl = UIRefreshControl()
    @objc func reloadWebView(_ sender: UIRefreshControl) {
        if loadingError == true
        {
            loadingError = false
            self.LoadWebView()
        }
        else
        {
            webView.reload()
        }
        refreshControl.endRefreshing()
    }
    let progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override func loadView() {
        print("-loadView")
        super.loadView()
        navigationController?.navigationBar.barStyle = .black
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusBar = UIView(frame: window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
            statusBar.backgroundColor = UIColor(rgb: 0x303030)
            window?.addSubview(statusBar)
        } else {
            UIApplication.shared.statusBarView?.backgroundColor = UIColor(rgb: 0x303030)
            UIApplication.shared.statusBarStyle = .lightContent
        }
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webView, action: #selector(reloadWebView))
        let back = UIBarButtonItem(title: "Back", style: .plain, target: webView, action: #selector(self.webView!.goBack))
        self.navigationItem.rightBarButtonItem = refresh
        self.navigationItem.leftBarButtonItem = back
        self.navigationItem.title = "Guava"
        self.navigationController?.isNavigationBarHidden = false
        /*
         print("webView didFinish")
         let add = UIAction(title: "Add", image: UIImage(systemName: "plus")) { (action) in
         print("Add")
         }
         let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { (action) in
         print("Edit")
         }
         let delete = UIAction(title: "Delete", image: UIImage(systemName: "minus"), attributes: .destructive) { (action) in
         print("Delete")
         }
         let menu = UIMenu(title: "Menu", children: [add, edit, delete])
         let refresh = UIBarButtonItem(title: "Delete", image: UIImage(systemName: "minus"))
         refresh.menu = menu
         let back = UIBarButtonItem(title: "Back", style: .plain, target: webView, action: #selector(self.webView!.goBack))
         let customImageBarBtn1 = UIBarButtonItem(
         image: UIImage(named: "AppIcon"),
         style: .plain, target: self, action: #selector(self.webView!.goBack))
         self.navigationItem.title = "Guava"
         self.navigationItem.rightBarButtonItem = refresh
         self.navigationItem.leftBarButtonItem = customImageBarBtn1
         self.navigationController?.isNavigationBarHidden = false
         */
        self.webView = WKWebView(frame: self.view.frame)
        self.webViewSplashScreen = WKWebView(frame: self.view.frame)
    }
    @objc func backNavigationFunction(_ sender: UIScreenEdgePanGestureRecognizer) {
        let dX = sender.translation(in: view).x
        if sender.state == .ended {
            let fraction = abs(dX / view.bounds.width)
            if fraction >= 0.35 {
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let swipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(backNavigationFunction(_:)))
        swipeGesture.edges = .left
        swipeGesture.delegate = self
        view.addGestureRecognizer(swipeGesture)
        print("-viewDidLoad")
        if useSplashScreen == true {
            print("Load with splash screen")
            view = webViewSplashScreen
            let localFilePath = Bundle.main.url(forResource: "loading", withExtension: "html", subdirectory: "htmlapp/helpers")
            let request = NSURLRequest(url: localFilePath!)
            webViewSplashScreen.navigationDelegate = self
            webViewSplashScreen.uiDelegate = self
            webViewSplashScreen.load(request as URLRequest)
        }
        else {
            self.LoadWebView()
        }
        // NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.applicationDidBecomeActive()
    }
    
    func applicationDidBecomeActive() {
        print("active")
        if let run_first_exists = UserDefaults.standard.object(forKey: "first_run") {
            print("first_run is: \(run_first_exists)")
        } else {
            print("Send Install Info")
            if #available(iOS 14, *) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    ATTrackingManager.requestTrackingAuthorization { status in
                        if status == .authorized {
                            DispatchQueue.main.async { () -> Void in
                                let screen_width = Double(UIScreen.main.bounds.size.width * UIScreen.main.scale).removeZerosFromEnd()
                                let screen_height = Double(UIScreen.main.bounds.size.height * UIScreen.main.scale).removeZerosFromEnd()
                                let url = URL(string: "https://install.webintoapp.com/install/")!
                                var request = URLRequest(url: url)
                                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                                request.httpMethod = "POST"
                                let parameters: [String: String] = [
                                    "key": "oXlBOyfQGjCsXzCXjAsJcrHBrIsShkVM",
                                    "app_version": "1.0",
                                    "device": "iOS",
                                    "device_version": UIDevice.current.systemVersion, // ?? "UNKNOWN",
                                    "resolution": "\(screen_width)x\(screen_height)"
                                ]
                                print("ALL PARAMETERS = \(parameters)")
                                request.httpBody = parameters.percentEscaped().data(using: .utf8)
                                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                    guard let data = data,
                                          let response = response as? HTTPURLResponse,
                                          error == nil else {                                              // check for fundamental networking error
                                        print("error", error ?? "Unknown error")
                                        return
                                    }
                                    guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                                        print("statusCode should be 2xx, but is \(response.statusCode)")
                                        print("response = \(response)")
                                        return
                                    }
                                    let responseString = String(data: data, encoding: .utf8)
                                    print("responseString = \(String(describing: responseString))")
                                }
                                task.resume()
                                UserDefaults.standard.set("exists", forKey: "first_run")
                                print("Saved the first_run")
                            }
                        } else {
                            UserDefaults.standard.set("exists", forKey: "first_run")
                            print("Saved the first_run")
                        }
                    }
                })
            }
        }
    }
    
    private func setupProgressView() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        progressView.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(progressView)
        progressView.isHidden = true
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.0)
        ])
    }
    
    private func setupEstimatedProgressObserver() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.progressView.progress = Float(webView.estimatedProgress)
        }
    }
    
    private func setupWebview(url: URL) {
        let request = URLRequest(url: url)
        webView.navigationDelegate = self
        webView.load(request)
    }
    
    @objc func LoadWebView() {
        print("-LoadWebView")
        setupProgressView()
        setupEstimatedProgressObserver()
        refreshControl.addTarget(self, action: #selector(reloadWebView(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        let source: String = "var meta = document.createElement('meta');" +
        "meta.name = 'viewport';" +
        "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
        "var head = document.getElementsByTagName('head')[0];" +
        "head.appendChild(meta);"
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        let url    = URL(string: "http://ceciliajiangpa.pythonanywhere.com")!
        webView.load(URLRequest(url: url))
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if progressView.isHidden {
            progressView.isHidden = false
        }
        UIView.animate(withDuration: 0.33,
                       animations: {
            self.progressView.alpha = 1.0
        })
        print("didStartProvisionalNavigation - webView.url: \(String(describing: webView.url?.description))")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nserror = error as NSError
        if nserror.code != NSURLErrorCancelled {
            let localFilePath = Bundle.main.url(forResource: "error", withExtension: "html", subdirectory: "htmlapp/helpers")
            let request = NSURLRequest(url: localFilePath!)
            webView.load(request as URLRequest)
            loadingError = true
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let frame = navigationAction.targetFrame, frame.isMainFrame {
            return nil
        }
        webView.load(navigationAction.request)
        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if(webView == self.webViewSplashScreen) {
            print("webViewSplashScreen didFinish")
            self.LoadWebView()
        }
        if(webView == self.webView) {
            print("webView didFinish")
            view = webView
            UIView.animate(withDuration: 0.33,
                           animations: {
                self.progressView.alpha = 0.0
            },
                           completion: { isFinished in
                self.progressView.isHidden = isFinished
            })
        }
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        UINavigationBar.appearance().barTintColor = UIColor(rgb: 0x1a1a1a)
        UINavigationBar.appearance().tintColor = UIColor(rgb: 0x1a1a1a)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(rgb: 0x1a1a1a), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.bold)]
        return self
    }
    
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return view
    }
    
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return view.frame
    }
    
    func showFileWithPath(path: String) {
        let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
        if isFileFound == true {
            let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
            viewer.delegate = self
            viewer.presentPreview(animated: true)
        }
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        let fileextension = url?.pathExtension
        if(["zip", "7g", "pdf"].contains(fileextension!)) {
            decisionHandler(.cancel)
            let url = URL(string: (url!.absoluteURL.absoluteString))
            FileDownloader.loadFileAsync(url: url!) { (path, error) in
                print("File downloaded to : \(path!)")
                DispatchQueue.main.async { () -> Void in
                    self.showFileWithPath(path: path!)
                }
            }
        } else if ["tel", "sms", "facetime", "mailto", "whatsapp", "twitter", "twitterauth", "fb", "fbapi", "fbauth2", "fbshareextension", "fb-messenger-api", "viber", "wechat", "line", "instagram", "instagram-stories", "googlephotos"].contains(url?.scheme) {
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!)
            } else {
                print("Can't open url on this device")
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
