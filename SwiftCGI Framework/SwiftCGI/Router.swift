//
//  Router.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 3/1/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

public struct RoutePattern {
    let route: String
    let method: HttpMethod
    
    init(route: String, forMethod method: HttpMethod) {
        self.route = route
        self.method = method
    }
}
extension RoutePattern : Hashable {
    public var hashValue: Int {
        return (self.route + self.method.rawValue).hashValue
    }
}

public func ==(lhs: RoutePattern, rhs: RoutePattern) -> Bool {
    return lhs.method == rhs.method && lhs.route == rhs.route
}

public class Router {
    
    private var _routes: [(routePattern:RoutePattern, handler:RequestHandler)] = []
    
    public init() {}
    
    public func mapRoute(pattern: String, toController controller: Any) {
        if let method = controller as? Getable {
            self.mapRoute(pattern, forMethod: HttpMethod.Get, toAction: method.get)
        }
        if let method = controller as? Putable {
            self.mapRoute(pattern, forMethod: HttpMethod.Put, toAction: method.put)
        }
        if let method = controller as? Patchable {
            self.mapRoute(pattern, forMethod: HttpMethod.Patch, toAction: method.patch)
        }
        if let method = controller as? Deletable {
            self.mapRoute(pattern, forMethod: HttpMethod.Delete, toAction: method.delete)
        }
        if let method = controller as? Postable {
            self.mapRoute(pattern, forMethod: HttpMethod.Post, toAction: method.post)
        }
    }
    
    public func mapRoute(var pattern: String, forMethod method: HttpMethod, toAction action: RequestHandler) {
        // trim the trailing "/"
        if pattern[pattern.endIndex.predecessor()] == "/" {
            pattern = pattern[pattern.startIndex..<pattern.endIndex.predecessor()]
        }
        
        let routePattern = RoutePattern(route: pattern, forMethod: method)
        _routes.append(routePattern: routePattern, handler: action)
    }
    
    func routeRequest(request: WebRequest) -> RequestHandler? {
        for (pattern, handler) in _routes where pattern.method == request.httpRequest.method  {
            if pattern.route == request.httpRequest.path {
                return handler
            }
        }
        
        return nil
    }
}
