//
//  WebRequest.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public protocol HttpContent {
    var contentType: String { get }
    var data: NSData { get }
}

extension HttpContent {
    var dataAsString: String? {
        return String(data: self.data, encoding: NSUTF8StringEncoding)
    }
}

extension HttpResponse {
    public func setContent(to content: HttpContent) {
        self.headers[HttpHeader.ContentType] = content.contentType
        self.headers[HttpHeader.ContentLength] = "\(content.data.length)"
        self.body = content.data
    }
}

extension HttpRequest {
    public func setContent(to content: HttpContent) {
        self.headers[HttpHeader.ContentType] = content.contentType
        self.headers[HttpHeader.ContentLength] = "\(content.data.length)"
        self.body = content.data
    }
}

public struct TextContent : HttpContent {
    public let contentType: String = HttpContentType.TextPlain
    public let data: NSData
    
    public init?(_ model: String) {
        guard let data = model.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        self.data = data
    }
    
}

//
//public protocol WebRequest {
//    var method: HttpMethod { get set }
//    var url: String  { get set }
//    var content: HttpContent?  { get set }
//    var cookies: [String:String]  { get set }
//    var queryString: String?  { get set }
//    var queryParameters: [String:String]?  { get set }
//    var headers: [String:String]  { get set }
//    
//    var parameters: [String:String]  { get }
//    var httpRequest: HttpRequest { get }
//    var matchedRoute: MatchedRoute! { get }
//}
//
//extension WebRequest {
//    public var parameters: [String:String] {
//        var model: [String:String] = [:]
//        
//        if self.matchedRoute.parameters.count > 0 {
//            for (key,value) in self.matchedRoute.parameters {
//                model[key] = value
//            }
//        }
//        if let qp = self.queryParameters {
//            for (key,value) in qp {
//                model[key] = value
//            }
//        }
//        
//        return model
//    }
//}
//
//internal class WrappedHttpRequest : WebRequest {
//    internal var method: HttpMethod
//    internal var url: String
//    internal var content: HttpContent?
//    internal var cookies: [String:String]
//    internal var queryString: String?
//    internal var queryParameters: [String:String]?
//    internal var headers: [String:String]
//    
//    internal let httpRequest: HttpRequest
//    internal var matchedRoute: MatchedRoute!
//    
//    internal init(request: HttpRequest, forMatchingRoute matchedRoute: MatchedRoute?) {
//        self.httpRequest = request
//        self.matchedRoute = matchedRoute
//        
//        self.method = request.method
//        self.url = request.url
//        self.cookies = request.cookies ?? [:]
//        self.headers = request.headers
//        
//        let splitPath = self.url.componentsSeparatedByString("?")
//        if splitPath.count == 2 {
//            self.queryString = splitPath.last
//        }
//        if let queryString = self.queryString {
//            self.queryParameters = [:]
//            for item in queryString.componentsSeparatedByString("&") {
//                let itemDef = item.componentsSeparatedByString("=")
//                self.queryParameters![itemDef[0]] = itemDef[1]
//            }
//        }
//
//        if let body = request.body,
//            let contentType = self.headers[HttpHeader.ContentType],
//            let contentLength = self.headers[HttpHeader.ContentLength],
//            let parsedContentLength = UInt(contentLength) {
//                self.content = HttpContent(contentType: contentType, contentLength: parsedContentLength, data: body)
//        }
//    }
//}

