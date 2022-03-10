//
//  ContentView.swift
//  CookieHelper
//
//  Created by Yutu on 2022/3/8.
//

import SwiftUI
import WKView
import SUEButtons
import WebKit
import Toaster
import ToastUI

struct ContentView: View {
    @State var isSheetPresented = false
    @State private var presentingClearToast: Bool = false
    @State private var presentingUploadDialog: Bool = false
    @State private var presentingCopyFailToast: Bool = false
    @State private var presentingCopySuccessToast: Bool = false
    @State private var remark: String = ""
    let yutuApi: String = "https://ck.howiehye.top/upload_cookie"
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                    .frame(width: 250.0, height: 10.0, alignment: .center)
                Image("CookieHelper")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200.0, height: 200.0, alignment: .center)
                    .clipShape(Circle())
                Divider()
                Button(action: {
                    isSheetPresented.toggle()
                }, label: {
                    Text("  获取Cookie  ")
                })
                    .buttonStyle(CapsuleButtonStyle())
                    .fixedSize()
                    .sheet(isPresented: $isSheetPresented, content: {
                        NavigationView {
                            // Present a webview with onNavigationAction and optional: allowedHosts, forbiddenHosts and credential
                            WebView(url: "https://m.jd.com"){
                                (onNavigationAction) in
                                switch onNavigationAction {
                                case .decidePolicy(let webView, let navigationAction, let policy):
                                    print("WebView -> \(String(describing: webView.url)) -> decidePolicy navigationAction: \(navigationAction)")
                                    switch policy {
                                    case .cancel:
                                        print("WebView -> \(String(describing: webView.url)) -> decidePolicy: .cancel")
                                        isSheetPresented = false
                                    case .allow:
                                        print("WebView -> \(String(describing: webView.url)) -> decidePolicy: .allow")
                                    case .download: break
                                        
                                    @unknown default:
                                        print("WebView -> \(String(describing: webView.url)) -> decidePolicy: @unknown default")
                                    }
                                    
                                case .didRecieveAuthChallenge(let webView, let challenge, let disposition, let credential):
                                    print("WebView -> \(String(describing: webView.url)) -> didRecieveAuthChallange challenge: \(challenge.protectionSpace.host)")
                                    print("WebView -> \(String(describing: webView.url)) -> didRecieveAuthChallange disposition: \(disposition.rawValue)")
                                    if let credential = credential {
                                        print("WebView -> \(String(describing: webView.url)) -> didRecieveAuthChallange credential: \(credential)")
                                    }
                                    
                                case .didStartProvisionalNavigation(let webView, let navigation):
                                    print("WebView -> \(String(describing: webView.url)) -> didStartProvisionalNavigation: \(navigation)")
                                case .didReceiveServerRedirectForProvisionalNavigation(let webView, let navigation):
                                    print("WebView -> \(String(describing: webView.url)) -> didReceiveServerRedirectForProvisionalNavigation: \(navigation)")
                                case .didCommit(let webView, let navigation):
                                    print("WebView -> \(String(describing: webView.url)) -> didCommit: \(navigation)")
                                case .didFinish(let webView, let navigation):
                                    print("WebView -> \(String(describing: webView.url)) -> didFinish: \(navigation)")
                                case .didFailProvisionalNavigation(let webView, let navigation, let error):
                                    print("WebView -> \(String(describing: webView.url)) -> didFailProvisionalNavigation: \(navigation)")
                                    print("WebView -> \(String(describing: webView.url)) -> didFailProvisionalNavigation: \(error)")
                                case .didFail(let webView, let navigation, let error):
                                    print("WebView -> \(String(describing: webView.url)) -> didFail: \(navigation)")
                                    print("WebView -> \(String(describing: webView.url)) -> didFail: \(error)")
                                }
                            }
                            
                        }
                    })
                Button("  复制Cookie  "){
                    var ptKey = ""
                    var ptPin = ""
                    
                    getCookies(){ data in
                        for (key, value) in data {
                            if key == "pt_key" {
                                ptKey = value as! String
                            }
                            if key == "pt_pin" {
                                ptPin = value as! String
                            }
                        }
                        if ptPin == "" || ptKey == "" {
                            presentingCopyFailToast = true
                        } else {
                            let jdCk = "pt_key=\(ptKey);pt_pin=\(ptPin);"
                            UIPasteboard.general.string = jdCk
                            presentingCopySuccessToast = true
                        }
                    }
                }
                .buttonStyle(CapsuleButtonStyle())
                .fixedSize()
                .toast(isPresented: $presentingCopyFailToast) {
                    ToastView{
                        VStack(spacing: 5) {
                            Text("你好像还没有登录吧!")
                                .padding(.bottom)
                                .multilineTextAlignment(.center)
                            Button("  朕知道了  "){
                                presentingCopyFailToast = false
                            }
                            .onTapGesture(perform: simpleFailed)
                            .buttonStyle(CapsuleButtonStyle())
                            .fixedSize()
                        }
                    }
                }
                .toast(isPresented: $presentingCopySuccessToast) {
                    ToastView{
                        VStack(spacing: 5) {
                            Text("Cookie 已复制到粘贴板!!!")
                                .padding(.bottom)
                                .multilineTextAlignment(.center)
                            Button("  朕知道了  "){
                                presentingCopySuccessToast = false
                            }
                            .buttonStyle(CapsuleButtonStyle())
                            .fixedSize()
                        }
                    }
                }
                
                Button("  上传Cookie  ") {
                    presentingUploadDialog = true
                }
                .buttonStyle(CapsuleButtonStyle())
                .fixedSize()
                .toast(isPresented: $presentingUploadDialog){
                    ToastView{
                        VStack(spacing: 5){
                            Text("  请输入备注信息:  ")
                                .padding(.bottom)
                                .multilineTextAlignment(.center)
                            TextField("备注:", text: $remark)
                                .padding(.bottom)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                                .fixedSize()
                            HStack(spacing: 20){
                                Button("  取消  "){
                                    presentingUploadDialog = false
                                }
                                Button("  确定  "){
                                    let urlApi = URL(string: yutuApi)
                                    var request = URLRequest(url: urlApi!)
                                    let session = URLSession.shared
                                    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                                    request.addValue("keep-alive", forHTTPHeaderField: "Connection")
                                    request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36", forHTTPHeaderField: "User-Agent")
                                    var ptKey = ""
                                    var ptPin = ""
                                    var msg = ""
                                    
                                    getCookies(){ data in
                                        for (key, value) in data {
                                            if key == "pt_key" {
                                                ptKey = value as! String
                                            }
                                            if key == "pt_pin" {
                                                ptPin = value as! String
                                            }
                                        }
                                        if ptPin == "" || ptKey == "" {
                                            ToastView.appearance().backgroundColor = .red
                                            ToastView.appearance().bottomOffsetPortrait = 100
                                            ToastView.appearance().font = UIFont.systemFont(ofSize: 20)
                                            let toast = Toast(text: "你还没有登录呢!!!", duration: Delay.long)
                                            presentingUploadDialog = false
                                            toast.show()
                                        } else {
                                            ToastView.appearance().backgroundColor = .red
                                            ToastView.appearance().bottomOffsetPortrait = 100
                                            ToastView.appearance().font = UIFont.systemFont(ofSize: 20)
                                            let toast = Toast(text: "正在上传!!!不要重复点击!!!", duration: Delay.long)

                                            toast.show()
                                            
                                            let param = ["pt_key": ptKey, "pt_pin": ptPin, "remark": remark]
                                            request.httpMethod = "POST"
                                            
                                            do {
                                                request.httpBody = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
                                            } catch _{
                                                ToastView.appearance().backgroundColor = .red
                                                ToastView.appearance().bottomOffsetPortrait = 100
                                                ToastView.appearance().font = UIFont.systemFont(ofSize: 20)
                                                let toast = Toast(text: "上传出错啦~~~手动复制吧!!!", duration: Delay.long)
                                                presentingUploadDialog = false
                                                toast.show()
                                            }
                                            let task = session.dataTask(with: request) { data, response, error in
                                                guard error == nil else {
                                                    return
                                                }
                                                guard let data = data else {
                                                    return
                                                }
                                                do {
                                                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]{
                                                        ToastView.appearance().backgroundColor = .gray
                                                        ToastView.appearance().bottomOffsetPortrait = 100
                                                        ToastView.appearance().font = UIFont.systemFont(ofSize: 20)
                                                        msg = json["message"] as! String
                                                        let toast = Toast(text: msg, duration: Delay.long)
                                                        presentingUploadDialog = false
                                                        toast.show()
                                                    }
                                                } catch _ {
                                                    ToastView.appearance().backgroundColor = .red
                                                    ToastView.appearance().bottomOffsetPortrait = 100
                                                    ToastView.appearance().font = UIFont.systemFont(ofSize: 20)
                                                    let toast = Toast(text: "上传出错啦~~~\n手动复制吧!!!", duration: Delay.long)
                                                    presentingUploadDialog = false
                                                    toast.show()
                                                }
                                            }
                                            task.resume()
                                        }
                                    }
                                }
                            }
                            .buttonStyle(CapsuleButtonStyle())
                            .fixedSize()
                        }
                    }
                }
                
                Button("  清除Cookie  "){
                    presentingClearToast = true
                }
                .buttonStyle(CapsuleButtonStyle())
                .fixedSize()
                .toast(isPresented: $presentingClearToast) {
                    ToastView{
                        VStack(spacing: 5) {
                            Text("清理登录状态成功~~~")
                                .padding(.bottom)
                                .multilineTextAlignment(.center)
                            Button("朕知道了"){
                                removeCookies()
                                ToastView.appearance().backgroundColor = .gray
                                ToastView.appearance().bottomOffsetPortrait = 100
                                ToastView.appearance().font = UIFont.systemFont(ofSize: 20)
                                let toast = Toast(text: "已经清理完成啦~~~\n重新登录吧!", duration: Delay.long)
                                toast.show()
                                presentingClearToast = false
                            }
                            .buttonStyle(CapsuleButtonStyle())
                            .fixedSize()
                        }
                    }
                }
                
                Button("  关            于  "){
                    ToastView.appearance().backgroundColor = .gray
                    ToastView.appearance().bottomOffsetPortrait = 100
                    ToastView.appearance().font = UIFont.systemFont(ofSize: 20)
                    let toast = Toast(text: "还没想到写啥东东?", duration: Delay.long)
                    toast.show()
                }
                .buttonStyle(CapsuleButtonStyle())
                .fixedSize()
                Spacer()
            }
            .navigationBarTitle("Cookies 小工具")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    private var httpCookieStore: WKHTTPCookieStore {
        return WKWebsiteDataStore.default().httpCookieStore
    }
    
    func getCookies(for domain: String? = nil, completion: @escaping ([String : Any])->()) {
        var cookieDict = [String: AnyObject]()
        httpCookieStore.getAllCookies{cookies in
            for cookie in cookies {
                if let domain = domain {
                    if cookie.domain.contains(domain){
                        cookieDict[cookie.name] = cookie.value as AnyObject?
                    }
                } else {
                    cookieDict[cookie.name] = cookie.value as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }
    
    func removeCookies(){
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date.init(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom, completionHandler: {
            print("清理完成!")
        })
    }
    
    func simpleFailed() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
