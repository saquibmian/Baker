//
//  HttpRequestProcessor.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-11.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public protocol RequestHandler {
    func didReceiveRequest(request: HttpRequest) -> HttpResponse?
    
    func willSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute?)
    
    func didSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute?)
}

internal class HttpRequestProcessor {
    
    private let _router: Router
    private let _responseWriter = HttpResponseSerializer()
    private var _handlers: [RequestHandler] = []
    
    internal init(withRouter router: Router) {
        _router = router
    }
    
    func processHttpRequest(request: HttpRequest) {
        let connection = request._requestContext.connection
        var response: HttpResponse!
        var matchedRoute: MatchedRoute? = nil
        
        for handler in _handlers {
            if let formedResponse = handler.didReceiveRequest(request) {
                response = formedResponse
                break
            }
        }
        
        // Route request if we don't have one yet
        if response == nil {
            if let requestHandler = _router.routeRequest(request) {
                matchedRoute = requestHandler.routePattern
                response = requestHandler.handler(request, matchedRoute!)
            } else {
                response = HttpResponse(status: HttpStatusCode.NotFound, content: TextContent("Not found! Booooo :( ")! )
            }
        }
        
        for handler in _handlers.reverse() {
            handler.willSendResponse(response, forRequest: request, andRoute: matchedRoute)
        }
        
        connection.sendResponse(response, forRequest: request)
        
        for handler in _handlers.reverse() {
            handler.didSendResponse(response, forRequest: request, andRoute: matchedRoute)
        }
    }
    
    internal func addHandler(handler: RequestHandler) {
        _handlers.append(handler)
    }
    
}
