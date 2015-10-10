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
    
    private var _routes: [(routePattern:RoutePattern, handler:() -> RequestHandler)] = []
    
    public init() {}
    
    public func mapRoute(pattern: String, toController controller: () -> Any) {
        let instantiatedController = controller()

        if let _ = instantiatedController as? Getable {
            let action = { (controller() as! Getable).get }
            self.mapRoute(pattern, forMethod: HttpMethod.Get, toAction: action)
        }
        if let _ = instantiatedController as? Putable {
            let action = { (controller() as! Putable).put }
            self.mapRoute(pattern, forMethod: HttpMethod.Put, toAction: action)
        }
        if let _ = instantiatedController as? Patchable {
            let action = { (controller() as! Patchable).patch }
            self.mapRoute(pattern, forMethod: HttpMethod.Patch, toAction: action)
        }
        if let _ = instantiatedController as? Deletable {
            let action = { (controller() as! Deletable).delete }
            self.mapRoute(pattern, forMethod: HttpMethod.Delete, toAction: action)
        }
        if let _ = instantiatedController as? Postable {
            let action = { (controller() as! Postable).post }
            self.mapRoute(pattern, forMethod: HttpMethod.Post, toAction: action)
        }
    }
    
    public func mapRoute(pattern: String, forMethod method: HttpMethod, toAction action: RequestHandler) {
        self.mapRoute(pattern, forMethod: method, toAction: { return action })
    }
    
    func mapRoute(var pattern: String, forMethod method: HttpMethod, toAction action: () -> RequestHandler) {
        // trim the trailing "/"
        if pattern[pattern.endIndex.predecessor()] == "/" {
            pattern = pattern[pattern.startIndex..<pattern.endIndex.predecessor()]
        }
        
        let routePattern = RoutePattern(route: pattern, forMethod: method)
        _routes.append(routePattern: routePattern, handler: action)
        
        print("Registered route: \(routePattern.method.rawValue) \(routePattern.route)")
    }
    
    func routeRequest(request: WebRequest) -> RequestHandler? {
        for (pattern, handler) in _routes where pattern.method == request.httpRequest.method  {
            if pattern.route == request.httpRequest.path {
                return handler()
            }
        }
        
        return nil
    }
}
