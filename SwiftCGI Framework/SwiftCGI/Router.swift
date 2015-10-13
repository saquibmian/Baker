//
//  Router.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 3/1/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

public class Router : _RouteMatchable {
    
    private var _routes: [(routePattern:_RouteMatchable, handlerBuilder:() -> RequestHandlerOld)] = []
    
    public let route: String
    let routeComponents: [String]

    public init() {
        route = RouteCharacter.Separator
        routeComponents = []
    }
    
    internal init(forRoute route: String) {
        self.route = route
        self.routeComponents = self.route
            .componentsSeparatedByString(RouteComponentSeparator)
            .filter { !$0.isEmpty }
    }
    
    // controller will be instantiated once, after that it'll be per request
    public func mapController<T: WebController>(pattern: String, ofType: T.Type) {
        if let controller = ofType as? Getable.Type {
            let action:  RequestHandlerOld = { req, route in
                let controller = controller.init(withRequest: req, foRoute: route)
                return controller.get()
            }
            self.mapRoute(pattern, forMethod: HttpMethod.Get, toAction: action)
        }
        if let controller = ofType as? Putable.Type {
            let action:  RequestHandlerOld = { req, route in
                let controller = controller.init(withRequest: req, foRoute: route)
                return controller.put()
            }
            self.mapRoute(pattern, forMethod: HttpMethod.Put, toAction: action)
        }
        if let controller = ofType as? Postable.Type {
            let action:  RequestHandlerOld = { req, route in
                let controller = controller.init(withRequest: req, foRoute: route)
                return controller.post()
            }
            self.mapRoute(pattern, forMethod: HttpMethod.Post, toAction: action)
        }
        if let controller = ofType as? Patchable.Type {
            let action:  RequestHandlerOld = { req, route in
                let controller = controller.init(withRequest: req, foRoute: route)
                return controller.patch()
            }
            self.mapRoute(pattern, forMethod: HttpMethod.Patch, toAction: action)
        }
        if let controller = ofType as? Deletable.Type {
            let action:  RequestHandlerOld = { req, route in
                let controller = controller.init(withRequest: req, foRoute: route)
                return controller.delete()
            }
            self.mapRoute(pattern, forMethod: HttpMethod.Delete, toAction: action)
        }
    }
    
    public func mapRoute(pattern: String, forMethod method: HttpMethod, toAction action: RequestHandlerOld) {
        self.mapRoute(pattern, forMethod: method, toAction: { return action })
    }
    
    func mapRoute(pattern: String, forMethod method: HttpMethod, toAction action: () -> RequestHandlerOld) {
        let joinedPattern = RouteCharacter.Separator + (self.route + RouteCharacter.Separator + pattern)
            .componentsSeparatedByString(RouteCharacter.Separator)
            .filter { !$0.isEmpty && $0 != RouteCharacter.Wildcard }
            .joinWithSeparator(RouteCharacter.Separator)
        
        let routePattern: _RouteMatchable = RoutePattern(route: joinedPattern, forMethod: method)
        _routes.append(routePattern: routePattern, handlerBuilder: action)
        
        print("Registered route: \(method.rawValue) \(routePattern.route)")
    }
    
    public func createNestedRouter(atBaseRoute route: String) -> Router {
        var joinedPattern = RouteCharacter.Separator + (self.route + RouteCharacter.Separator + route)
            .componentsSeparatedByString(RouteCharacter.Separator)
            .filter { !$0.isEmpty && $0 != RouteCharacter.Wildcard }
            .joinWithSeparator(RouteCharacter.Separator)
        joinedPattern += RouteCharacter.Separator + RouteCharacter.Wildcard
        
        let nestedRouter = Router(forRoute: joinedPattern)
        let handler: () -> RequestHandlerOld = { return { req in
            // this handler should never be explicitly invoked
            return HttpResponse(status: HttpStatusCode.InternalServerError)
        } }
        
        _routes.append(routePattern: (nestedRouter as _RouteMatchable), handlerBuilder: handler)
        
        return nestedRouter
    }
    
    func routeRequest(request: HttpRequest) -> (routePattern:MatchedRoute, handler:RequestHandlerOld)? {
        print("In Router at path: \(self.route)")
        for (pattern, handlerBuilder) in _routes {
            if var match = pattern.match(request.url, forMethod: request.method) {
                var handler = handlerBuilder()
                
                // handle nested routers
                while let router = match.target as? Router {
                    // avoid double testing
                    if router.route != self.route {
                        if let intermediaryMatch = router.routeRequest(request) {
                            match = intermediaryMatch.routePattern
                            handler = intermediaryMatch.handler
                        } else {
                            return nil
                        }
                    }
                }
                
                return (match,handler)
            }
        }
        
        return nil
    }
    
    // MARK: RouteMatchable conformance
    
    func respondsToMethod(method: HttpMethod) -> Bool {
        return true
    }
}

internal struct RoutePattern : _RouteMatchable {
    let route: String
    internal let method: HttpMethod
    internal let routeComponents: [String]
    
    init(route: String, forMethod method: HttpMethod) {
        self.route = route
        self.method = method
        
        self.routeComponents = self.route
            .componentsSeparatedByString(RouteComponentSeparator)
            .filter { !$0.isEmpty }
    }
    
    internal func respondsToMethod(method: HttpMethod) -> Bool {
        return self.method == method
    }
}

//internal struct ControllerRoutePattern : _RouteMatchable {
//    let route: String
//    internal let controllerBuilder: () -> WebController
//    internal let routeComponents: [String]
//    
//    init(route: String, withBuilder builder: () -> WebController) {
//        self.route = route
//        self.controllerBuilder = builder
//        
//        self.routeComponents = self.route
//            .componentsSeparatedByString(RouteComponentSeparator)
//            .filter { !$0.isEmpty }
//    }
//    
//    internal func respondsToMethod(method: HttpMethod) -> Bool {
//        if let _ = controllerBuilder as? (() -> Getable) {
//                return method == HttpMethod.Get
//        }
//        return false
//    }
//}

