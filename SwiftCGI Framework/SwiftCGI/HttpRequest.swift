//
//  Request.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

public struct HttpRequest {

    internal let _fastCgiRequest: FCGIRequest
    
    public var method: HttpMethod
    public var path: String
    public var body: NSData?
    public var cookies: [String:String]
    public var queryParameters: [String:String]
    public var headers: [String:String]
    
    internal init?(fromFastCgiRequest request: FCGIRequest ) {
        _fastCgiRequest = request
        
        let methodString = _fastCgiRequest.params["REQUEST_METHOD"]!
        if let parsedMethod = HttpMethod(rawValue: methodString.uppercaseString) {
            method = parsedMethod
        } else {
            // TODO the HEAD method doesn't show up in the params, so we come here
            return nil
        }
        
        path = _fastCgiRequest.path
        body = _fastCgiRequest.streamData
        headers = _fastCgiRequest.params
        cookies = _fastCgiRequest.cookies ?? [:]
        queryParameters = _fastCgiRequest.queryParameters ?? [:]
        headers = [:]
        
        buildHeaders()
    }
    
    private mutating func buildHeaders() {
        for key in _fastCgiRequest.params.keys {
            if let range = key.rangeOfString("HTTP_") where range.startIndex == key.startIndex {
                let keyToInsert = key[range.endIndex..<key.endIndex]
                        .stringByReplacingOccurrencesOfString("_", withString: "-")
                        .capitalizedString
                
                headers[keyToInsert] = _fastCgiRequest.params[key]
            }
        }
    }
    
}