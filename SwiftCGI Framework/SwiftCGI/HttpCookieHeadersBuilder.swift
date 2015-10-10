//
//  HttpCookieHeadersBuilder.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

struct HttpCookieHeadersBuilder {
    
    func build(cookies: [String:String]) -> [String] {
        return cookies.map { (key, value) in
            "Set-Cookie: \(key)=\(value)"
        }
    }
    
}
