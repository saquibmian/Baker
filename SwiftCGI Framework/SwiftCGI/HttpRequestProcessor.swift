//
//  HttpRequestProcessor.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-11.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

internal class HttpRequestProcessor {
    
    internal let _router: Router
    private var _preware: [RequestPrewareHandler] = []
    private var _middleware: [RequestMiddlewareHandler] = []
    private var _postware: [RequestPostwareHandler] = []
    
    internal init(withRouter router: Router) {
        _router = router
    }
    
    func processHttpRequest(httpRequest: HttpRequest ) {
        do {
            let webRequest = WrappedHttpRequest(request: httpRequest, forMatchingRoute: nil)
            for handler in _preware {
                try handler(webRequest)
            }
            
            if let requestHandler = _router.routeRequest(webRequest) {
                webRequest.matchedRoute = requestHandler.routePattern
                let response = requestHandler.handler(webRequest)
                for handler in _middleware {
                    try handler(webRequest, response)
                }
                
                let responseWriter = HttpResponseSerializer()
                if let responseData = responseWriter.serialize(response: try response.render()) {
                    httpRequest._fastCgiRequest.writeResponseData(responseData, toStream: FCGIOutputStream.Stdout)
                }
                
                for handler in _postware {
                    try handler(webRequest, response)
                }
            } else {
                let response = HttpResponse(status: HttpStatusCode.NotFound, content: HttpContent(contentType: HttpContentType.TextPlain, string: "Not found! Booooo :( ") )
                
                let responseWriter = HttpResponseSerializer()
                if let responseData = responseWriter.serialize(response: response) {
                    httpRequest._fastCgiRequest.writeResponseData(responseData, toStream: FCGIOutputStream.Stdout)
                }
                
            }
        } catch {
            let response = try! JsonResponse(model: ["error":"none"], statusCode: HttpStatusCode.InternalServerError)!.render()
            
            let responseWriter = HttpResponseSerializer()
            if let responseData = responseWriter.serialize(response: response) {
                httpRequest._fastCgiRequest.writeResponseData(responseData, toStream: FCGIOutputStream.Stdout)
            }
        }
    }
    
    // MARK: Pre/middle/postware registration
    
    internal func registerPrewareHandler(handler: RequestPrewareHandler) {
        _preware.append(handler)
    }
    
    internal func registerMiddlewareHandler(handler: RequestMiddlewareHandler) {
        _middleware.append(handler)
    }
    
    internal func registerPostwareHandler(handler: RequestPostwareHandler) {
        _postware.append(handler)
    }
    
}
