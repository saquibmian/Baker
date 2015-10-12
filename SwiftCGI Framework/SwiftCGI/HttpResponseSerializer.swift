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
        
        for header in response.headers.keys {
            if header == HttpHeader.ContentLength {
                continue
            }
            if header == HttpHeader.ContentType {
                continue
            }
            headers.append("\(header): \(response.headers[header]!)")
        }
        
        if let cookies = response.cookies {
            let cookieHeaderBuilder = HttpCookieHeadersBuilder()
            for header in cookieHeaderBuilder.build(cookies) {
                headers.append(header)
            }
        }
        
        if let _ = response.body {
            headers.append("Content-Type: \(response.contentType); charset=utf-8") // TODO charset not need for non-text content types
            headers.append("Content-Length: \(response.contentLenth)")
        }

        headers.append(HTTPNewline)
        
        let responseString: String = {
            if let data = response.body, let body = String(data: data, encoding: NSUTF8StringEncoding) {
                return headers.joinWithSeparator(HTTPNewline) + body
            }
            return headers.joinWithSeparator(HTTPNewline)
        }()
        
        return responseString.dataUsingEncoding(primaryEncoding)
    }
}