//
//  LinkedinWebVC.swift
//  SoapBox
//
//  Created by Danish Khan on 05/07/21.
//

import UIKit
import WebKit
import SwiftyJSON

protocol LinkdinSuccessDelegate {
    func linkidinSuccessWith(name:String?,email:String?,image:String?,socialID:String?)
}

class LinkedinWebVC: UIViewController,UIWebViewDelegate {
    
 
    private var name:String?
    private var socialID:String?
    private var emailID:String?
    private var userImage:String?
    
    var userr:SocialUserData?
    var delegate:LinkdinSuccessDelegate?
    
    @IBOutlet weak var webView: WKWebView!
    
    let linkedInKey = "78c3wz5pjelrgz"
    let linkedInSecret = "u8D6GVaMzKtx7DWo"
    let authorizationEndPoint = "https://www.linkedin.com/oauth/v2/authorization"
    let accessTokenEndPoint = "https://www.linkedin.com/oauth/v2/accessToken"
    let callBackURL = "https://com.elsner.linkedin.oauth/oauth"
    
    var av = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        av = Loader.start(view: view)
        webView.navigationDelegate = self
        
//        if let linkedinToken = UserDefaultManager.sharedManager.objectForKey(key: Constants.UserDefaultKey.linkedinToken) as? String{
//            print(linkedinToken)
//            requestForEmailAddress(accessToken: linkedinToken) { (isSuccess, error) in
//                    self.socialID = linkedinToken
//                    self.av.removeFromSuperview()
//                    self.delegate?.linkidinSuccessWith(name: self.name, email: self.emailID, image: self.userImage, socialID: self.socialID)
//                    self.navigationController?.popViewController(animated: true)
//            }
//        }else{
            self.startAuthorization()
        //}
      
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func startAuthorization() {
        let responseType = "code"
        let redirectURL = callBackURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        print("URLL",redirectURL)
        
        let state = "linkedin\(Date().timeIntervalSince1970)"
        
        let scope = "r_liteprofile,r_emailaddress"
        
        var authorizationURL = "\(authorizationEndPoint)?"
        authorizationURL += "response_type=\(responseType)&"
        authorizationURL += "client_id=\(linkedInKey)&"
        authorizationURL += "redirect_uri=\(redirectURL)&"
        authorizationURL += "state=\(state)&"
        authorizationURL += "scope=\(scope)"
        
        
        // Create a URL request and load it in the web view.
        let url:URL = URL(string: authorizationURL)!
        let request = URLRequest(url: url)
        webView.load(request)
        
    }
  
    func logout(token:String){
        let revokeUrl = "https://www.linkedin.com/oauth/v2/revoke"
        //        let url = URL.init(string: revokeUrl)
        //        let request = URLRequest.init(url: url!)
        
        // Set the POST parameters.
        var postParams = "token=\(token)&"
        postParams += "client_id=\(linkedInKey)&"
        postParams += "client_secret=\(linkedInSecret)"
        
        
        // Convert the POST parameters into a NSData object.
        let postData = postParams.data(using: String.Encoding.utf8)
        // Initialize a mutable URL request object using the access token endpoint URL string.
        let request = NSMutableURLRequest(url: NSURL(string: revokeUrl)! as URL)
        
        
        // Indicate that we're about to make a POST request.
        request.httpMethod = "POST"
        
        // Set the HTTP body using the postData object created above.
        request.httpBody = postData
        // Add the required HTTP header field.
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        
        // Initialize a NSURLSession object.
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        
        let task:URLSessionDataTask = session.dataTask(with: request as URLRequest) { data, response, error in
            
            let statusCode = (response as! HTTPURLResponse).statusCode
            
            print("STATUS CODE:",statusCode)
            
            if statusCode == 200 {
                do{
                    self.av.removeFromSuperview()
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                    Logger.log("LogOut")
                }catch{
                    
                }
            }else{
                print(response)
            }
        }
        
        task.resume()
        
        //webView.load(request)
    }
    
    func requestForLiteProfile(accessToken:String,completion:@escaping (_ isSuccess: Bool, _ message: String) -> ()) {
        let targetURL =  "https://api.linkedin.com/v2/me"
        let url = URL.init(string: targetURL)
        var request = URLRequest.init(url: url!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession.init(configuration: .default)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            let statusCode = (response as! HTTPURLResponse).statusCode
            
            if statusCode == 200 {
                do {
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                    let json = JSON(dataDictionary)
                    print("JSON",json)
                    
                    DispatchQueue.main.async {
                        self.name = json["localizedFirstName"].stringValue + json["localizedLastName"].stringValue
                        self.userImage = json["profilePicture"]["displayImage"].stringValue
                        self.socialID = json["id"].stringValue
                        completion(true,"")
                    }
                }catch {
                    completion(false,"Could not load json into dictionory.")
                    Logger.log("Could not load json into dictionory.")
                }
            }
        }
        task.resume()
    }
    
    
    func requestForEmailAddress(accessToken:String,completion:@escaping (_ isSuccess: Bool, _ message: String) -> ()) {
        let targetURL =  "https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))"
        let url = URL.init(string: targetURL)
        var request = URLRequest.init(url: url!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession.init(configuration: .default)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            let statusCode = (response as! HTTPURLResponse).statusCode
            
            print("STATUS CODE",statusCode)
            
            if statusCode == 200 {
                do {
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                   
                    let json = JSON(dataDictionary)

                    print("JSON",json)
                    
                    let email = json["elements"][0]["handle~"]["emailAddress"].stringValue
                    print("EMAIL",email)
                    
                    self.emailID = email
                  
                    self.requestForLiteProfile(accessToken: accessToken){ (isSucces,msg) in
                       completion(isSucces,msg)
                    }
                }catch {
                    Logger.log("Could not load json into dictionory.")
                }
            }
            
        }
        task.resume()
    }
 
    
    func requestForAccessToken(authorizationCode: String,completion:@escaping (_ isSuccess: Bool, _ message: String) -> ()) {
        let grantType = "authorization_code"
        
        let redirectURL = callBackURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        
        // Set the POST parameters.
        var postParams = "grant_type=\(grantType)&"
        postParams += "code=\(authorizationCode)&"
        postParams += "redirect_uri=\(redirectURL)&"
        postParams += "client_id=\(linkedInKey)&"
        postParams += "client_secret=\(linkedInSecret)"
        
        
        // Convert the POST parameters into a NSData object.
        let postData = postParams.data(using: String.Encoding.utf8)
        // Initialize a mutable URL request object using the access token endpoint URL string.
        let request = NSMutableURLRequest(url: NSURL(string: accessTokenEndPoint)! as URL)
           
        
        // Indicate that we're about to make a POST request.
        request.httpMethod = "POST"
        
        // Set the HTTP body using the postData object created above.
        request.httpBody = postData
        // Add the required HTTP header field.
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        
        // Initialize a NSURLSession object.
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        
        let task:URLSessionDataTask = session.dataTask(with: request as URLRequest) { data, response, error in
           
            let statusCode = (response as! HTTPURLResponse).statusCode
            
            if statusCode == 200 {
                do{
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                    let accessToken = (dataDictionary as! [String:Any]) ["access_token"] as! String
                    
                    UserDefaultManager.sharedManager.addValue(object: accessToken, key: Constants.UserDefaultKey.linkedinToken)
                    print("Access Token ",accessToken)
                    
                    self.requestForEmailAddress(accessToken: accessToken){ (isSucces,msg) in
                        completion(isSucces,"")
                    }
                }catch{
                    completion(false,"")
                }
            }
        }
        
        task.resume()
    }
}



extension LinkedinWebVC: WKNavigationDelegate{
    
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error){
        print(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!){
        //        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        print("Strat to load")
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        //        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        /*
         Stop Loader
         */
        av.removeFromSuperview()
        print("finish to load")
    }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        Logger.log(#function)
        
        let request = navigationAction.request
        let url = request.url!
        
        if request.url?.host == "com.elsner.linkedin.oauth"{

            if url.absoluteString.range(of: "code") != nil{
                let urlParts = url.absoluteString.components(separatedBy: "?")
                let code = urlParts[1].components(separatedBy: "=")[1]
                av = Loader.start(view: view)
                requestForAccessToken(authorizationCode: code){ (isSuccess, message) in
                    if isSuccess{
                        self.av.removeFromSuperview()
                        self.delegate?.linkidinSuccessWith(name: self.name, email: self.emailID, image: self.userImage, socialID: self.socialID)
                        self.navigationController?.popViewController(animated: true)
                    }else{
                        self.av.removeFromSuperview()
                    }
                }
            }
            
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }
}
