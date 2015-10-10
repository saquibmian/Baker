//
//  Router.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 3/1/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

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


// MARK: Controller stuffs
public protocol Getable {
    func get( request: WebRequest ) -> WebResponse
}
public protocol Putable {
    func put( request: WebRequest ) -> WebResponse
}
public protocol Patchable {
    func patch( request: WebRequest ) -> WebResponse
}
public protocol Deletable {
    func delete( request: WebRequest ) -> WebResponse
}
public protocol Postable {
    func post( request: WebRequest ) -> WebResponse
}

public protocol WebController : Getable, Putable, Patchable, Deletable, Postable {}

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

public class BetterRouter {
    
    private var _routes: [(routePattern:RoutePattern, handler:BetterRequestHandler)] = []
    
    func mapRoute(pattern: String, toController controller: WebController) {
        self.mapRoute(pattern, toActionMethod: controller as Getable)
        self.mapRoute(pattern, toActionMethod: controller as Putable)
        self.mapRoute(pattern, toActionMethod: controller as Patchable)
        self.mapRoute(pattern, toActionMethod: controller as Deletable)
        self.mapRoute(pattern, toActionMethod: controller as Postable)
    }
    
    func mapRoute(pattern: String, toActionMethod action: Getable) {
        let routePattern = pattern
        let method = HttpMethod.Get
        let handler: BetterRequestHandler = { req in return action.get(req) }
        
        self.mapRoute(routePattern, forMethod: method, toAction: handler)
    }
    
    func mapRoute(pattern: String, toActionMethod action: Putable) {
        let routePattern = pattern
        let method = HttpMethod.Put
        let handler: BetterRequestHandler = { req in return action.put(req) }
        
        self.mapRoute(routePattern, forMethod: method, toAction: handler)
    }
    
    func mapRoute(pattern: String, toActionMethod action: Postable) {
        let routePattern = pattern
        let method = HttpMethod.Post
        let handler: BetterRequestHandler = { req in return action.post(req) }
        
        self.mapRoute(routePattern, forMethod: method, toAction: handler)
    }
    
    func mapRoute(pattern: String, toActionMethod action: Patchable) {
        let routePattern = pattern
        let method = HttpMethod.Patch
        let handler: BetterRequestHandler = { req in return action.patch(req) }
        
        self.mapRoute(routePattern, forMethod: method, toAction: handler)
    }
    
    func mapRoute(pattern: String, toActionMethod action: Deletable) {
        let routePattern = pattern
        let method = HttpMethod.Delete
        let handler: BetterRequestHandler = { req in return action.delete(req) }
        
        self.mapRoute(routePattern, forMethod: method, toAction: handler)
    }
    
    func mapRoute(pattern: String, forMethod method: HttpMethod, toAction action: BetterRequestHandler) {
        let routePattern = RoutePattern(route: pattern, forMethod: method)
        _routes.append(routePattern: routePattern, handler: action)
    }
    
    func routeRequest(request: WebRequest) -> BetterRequestHandler? {
        for (pattern, handler) in _routes where pattern.method == request.httpRequest.method  {
            if pattern.route == request.httpRequest.path {
                return handler
            }
        }
        
        return nil
    }
}

public class Router {
    private var subrouters: [Router] = []
    private let path: String
    private let wildcard: Bool
    private let handler: RequestHandler?
    
    public init(path: String, handleWildcardChildren wildcard: Bool, withHandler handler: RequestHandler?) {
        self.path = path
        self.wildcard = wildcard
        self.handler = handler
    }
    
    public func attachRouter(subrouter: Router) {
        subrouters.append(subrouter)
    }
    
    public func route(path: String) -> RequestHandler? {
        // TODO: Seems a bit kludgey... Functional, but kludgey...
        let components = (path as NSString).pathComponents.filter { return $0 != "/" }
        
        print("In router \(path) and looking for path with components: \(components)")
        
        if components.count > 0 {
            if components.count > 1 {
                // Match on sub-routers first
                let subPath = Array<String>(components[1..<components.count]).joinWithSeparator("/")
                for subrouter in subrouters {
                    if let subhandler = subrouter.route(subPath) {
                        return subhandler
                    }
                }
            }
            
            if self.path == components.first && (components.count == 1 || self.wildcard) {
                return handler
            }
        }
        
        return nil
    }
}