//
//  Request.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

public class HttpRequest {

    internal let _requestContext: InternalRequestContext!
    internal let _params: [String:String]!
    internal var _customProperties: [String:Any]!
    
    public var method: HttpMethod!
    public var url: String!
    public var headers: [String:String]!
    public var body: NSData?
    public var cookies: [String:String]?

    internal init?(fromFastCgiRequest request: FCGIRequest, withRequestContext context: InternalRequestContext ) {
        guard let methodString = request.params["REQUEST_METHOD"] else {
            _requestContext = nil
            _params = nil
            return nil
        }
        guard let url = request.params["REQUEST_URI"] else {
            _requestContext = nil
            _params = nil
            return nil
        }
        guard let method = HttpMethod(rawValue: methodString.uppercaseString) else {
            // TODO: the HEAD method doesn't show up in the params, so we come here
            _requestContext = nil
            _params = nil
            return nil
        }
        
        self._requestContext = context
        self._params = request.params
        
        self.url = url
        self.method = method
        self.body = request.stdIn
        self.headers = request.headers
        
        self._customProperties = [:]
        
        if let cookieString = _params["HTTP_COOKIE"] {
            cookies = [:]
            for cookie in cookieString.componentsSeparatedByString("; ") {
                let cookieDef = cookie.componentsSeparatedByString("=")
                cookies![cookieDef[0]] = cookieDef[1]
            }
        }
    }
    
    public func customValue(forKey key: String) -> Any? {
        if let prop = _customProperties[key] {
            return prop
        }
        
        return nil
    }
    
    public func setCustomValue(value: Any, forKey key: String) {
        _customProperties[key] = value
    }
    
}

// MARK: Convenience properties

extension HttpRequest {
    public var queryString: String? {
        let splitPath = self.url.componentsSeparatedByString("?")
        if splitPath.count == 2 {
            return splitPath.last!
        }
        return nil
    }
    
    public var queryParameters: [String:String]? {
        var toParse = self.url
        guard let index = toParse.rangeOfString(RouteCharacter.QueryStringStart) else {
            return nil
        }
        toParse = toParse.substringFromIndex(index.startIndex.successor())

        var toReturn = [String:String]()
        for kvp in toParse.componentsSeparatedByString(RouteCharacter.QueryStringSeparator) {
            if kvp.hasPrefix(RouteCharacter.QueryStringParameterSeparator) {
                continue // skip malformed
            }
            
            let pair = kvp.componentsSeparatedByString(RouteCharacter.QueryStringParameterSeparator)
            let key = pair[0]
            let value = pair.count == 2 ? pair[1] : ""
            
            toReturn[key] = value.urlDecodedString
        }

        return toReturn
    }
    
    public var contentType: String {
        return self.headers[HttpHeader.ContentType]!
    }
    
    public var contentLenth: UInt {
        return UInt(self.headers[HttpHeader.ContentLength]!)!
    }
}

