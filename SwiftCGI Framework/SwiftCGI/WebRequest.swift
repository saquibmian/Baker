//
//  WebRequest.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public protocol WebRequest {
    var routeParameters: [String:String] { get }
    var httpRequest: HttpRequest { get }
}

extension HttpRequest : WebRequest {
    public var routeParameters: [String:String] {
        var toReturn = [String:String]()
        
        var index = 0
        for routeKey in path.componentsSeparatedByString("/") {
            
            if routeKey.rangeOfString(":")?.startIndex == self.path.startIndex {
                /// TODO: implement the route parameters
                // get matched route and find corresponding value
            }
            
            ++index
        }
        
        return toReturn
    }
    
    public var httpRequest: HttpRequest { return self }
}
