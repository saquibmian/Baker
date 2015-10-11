//
//  Router.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 3/1/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

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
    
    func mapRoute(pattern: String, forMethod method: HttpMethod, toAction action: () -> RequestHandler) {
        let routePattern = RoutePattern(route: pattern, forMethod: method)
        _routes.append(routePattern: routePattern, handler: action)
        
        print("Registered route: \(routePattern.method.rawValue) \(routePattern.route)")
    }
    
    func routeRequest(request: WebRequest) -> (routePattern:MatchedRoute, handler:RequestHandler)? {
        for (pattern, handler) in _routes where pattern.method == request.method  {
            if let match = pattern.match(request.url) {
                return (match,handler())
            }
        }
        
        return nil
    }
    
    public func createNestedRouter(var atBaseRoute route: String) -> Router {
        if !route.hasSuffix(RouteCharacter.Wildcard) {
            route = route + RouteCharacter.Wildcard
        }

        let nestedRouter = Router()
        
        
        
        
        return nestedRouter
    }
}
