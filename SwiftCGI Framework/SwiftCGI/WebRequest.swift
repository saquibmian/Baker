//
//  WebRequest.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public struct HttpContent {
    public let contentType: String
    public let contentLength: UInt
    public let data: NSData
    
    var dataAsString: String? {
        return String(data: self.data, encoding: NSUTF8StringEncoding)
    }
    
    public init(contentType: String, contentLength: UInt, data: NSData) {
        self.contentLength = contentLength
        self.contentType = contentType
        self.data = data
    }
    
    public init(contentType: String, string: String) {
        self.contentType = contentType
        self.data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        self.contentLength = UInt(self.data.length)
    }
}

public protocol WebRequest {
    var method: HttpMethod { get set }
    var url: String  { get set }
    var content: HttpContent?  { get set }
    var cookies: [String:String]  { get set }
    var queryString: String?  { get set }
    var queryParameters: [String:String]?  { get set }
    var headers: [String:String]  { get set }
    
    var httpRequest: HttpRequest { get }
    var matchedRoute: MatchedRoute! { get }
}

internal class WrappedHttpRequest : WebRequest {
    internal var method: HttpMethod
    internal var url: String
    internal var content: HttpContent?
    internal var cookies: [String:String]
    internal var queryString: String?
    internal var queryParameters: [String:String]?
    internal var headers: [String:String]
    
    internal let httpRequest: HttpRequest
    internal var matchedRoute: MatchedRoute!
    
    internal init(request: HttpRequest, forMatchingRoute matchedRoute: MatchedRoute?) {
        self.httpRequest = request
        self.matchedRoute = matchedRoute
        
        self.method = request.method
        self.url = request.url
        self.cookies = request._fastCgiRequest.cookies ?? [:]
        self.headers = request.headers
        
        if let queryString = request._fastCgiRequest.queryString {
            if queryString != "" {
                self.queryString = queryString
            }
        }
        if let queryString = self.queryString {
            self.queryParameters = [:]
            for item in queryString.componentsSeparatedByString("&") {
                let itemDef = item.componentsSeparatedByString("=")
                self.queryParameters![itemDef[0]] = itemDef[1]
            }
        }

        if let body = request.body,
            let contentType = self.headers[HttpHeader.ContentType],
            let contentLength = self.headers[HttpHeader.ContentLength],
            let parsedContentLength = UInt(contentLength) {
                self.content = HttpContent(contentType: contentType, contentLength: parsedContentLength, data: body)
        }
    }
}

//extension WebRequest {
//    
//    public var routeParameters: [String:String] {
//        var toReturn = [String:String]()
//        
//        let urlComponents = self.url.componentsSeparatedByString("/")
//        let routeComponents = self.matchedRoute?.route.componentsSeparatedByString("/")
//        
//        // TODO: move route parameters to RoutePattern class
//        for (index, routeComponent) in routeComponents!.enumerate() {
//            if let colonIndex = routeComponent.rangeOfString(":")?.startIndex {
//                if colonIndex == routeComponent.startIndex { // ":" at starting
//                toReturn[routeComponent[colonIndex..<routeComponent.endIndex]] = urlComponents[index]
//            }
//        }
//        
//        var index = 0
//        for urlComponent in url.componentsSeparatedByString("/") {
//            
//            if urlComponent.rangeOfString(":")?.startIndex == self.url.startIndex {
//                /// TODO: implement the route parameters
//                // get matched route and find corresponding value
//            }
//            
//            ++index
//            }
//        }
//        
//        return toReturn
//    }
//    
//}
