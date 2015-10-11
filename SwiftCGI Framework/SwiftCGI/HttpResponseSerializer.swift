//
//  HttpResponseSerializer.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

internal struct HttpResponseSerializer {
    
    private let HTTPNewline = "\r\n"
    private let HTTPTerminator = "\r\n\r\n"
    
    private let primaryEncoding = NSUTF8StringEncoding
    
    func serialize(response response: HttpResponse) -> NSData? {
        var headers = [String]()
        
        headers.append("HTTP/1.1 \(response.status.rawValue) \(response.status.description)")
        
        headers.append("Status: \(response.status.rawValue) \(response.status.description)") // neccesary for fastcgi
        if let content = response.content {
            headers.append("Content-Type: \(content.contentType); charset=utf-8") // TODO charset not need for non-text content types
            headers.append("Content-Length: \(content.contentLength)")
        }
        for header in response.headers.keys {
            headers.append("\(header): \(response.headers[header])")
        }
        if let cookies = response.cookies {
            let cookieHeaderBuilder = HttpCookieHeadersBuilder()
            for header in cookieHeaderBuilder.build(cookies) {
                headers.append(header)
            }
        }
        
        headers.append(HTTPNewline)
        
        let responseString: String = {
            if let data = response.content, let body = data.dataAsString {
                return headers.joinWithSeparator(HTTPNewline) + body
            }
            return headers.joinWithSeparator(HTTPNewline)
        }()
        
        return responseString.dataUsingEncoding(primaryEncoding)
    }
}