//
//  HttpRequestProcessor.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-11.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

internal class HttpRequestProcessor {
    
    private let _router: Router
    private let _responseWriter = HttpResponseSerializer()
    
    private var _requestMiddleware: [RequestHandler] = []
    private var _responseMiddleware: [ResponseHandler] = []
    
    private var _preware: [RequestPrewareHandler] = []
    private var _middleware: [RequestMiddlewareHandler] = []
    private var _postware: [RequestPostwareHandler] = []
    
    internal init(withRouter router: Router) {
        _router = router
    }
    
    func processHttpRequest(request: HttpRequest) {
        let connection = request._requestContext.connection
        
        var response: HttpResponse
        let matchedRoute: MatchedRoute
        do {
            for handler in _requestMiddleware {
                handler.didReceiveRequest(request)
            }
            
            if let requestHandler = _router.routeRequest(request) {
                matchedRoute = requestHandler.routePattern
                response = requestHandler.handler(request)
                
                for handler in _responseMiddleware {
                    handler.willSendResponse(response, forRequest: request, andRoute: matchedRoute)
                    handler.didSendResponse(response, forRequest: request, andRoute: matchedRoute)
                }
            } else {
                response = HttpResponse(status: HttpStatusCode.NotFound, content: TextContent("Not found! Booooo :( ")! )
            }
        } catch {
            do {
                response = HttpResponse(status: HttpStatusCode.InternalServerError)
                if let json = JsonContent(model: ["error":"An error occured while building the response."]) {
                    response.setContent(to: json)
                }
            } catch {
                response = HttpResponse(status: HttpStatusCode.InternalServerError)
            }
        }

        connection.sendResponse(response, forRequest: request)
        
        for handler in _responseMiddleware {
            //handler.didSendResponse(response, forRequest: request, andRoute: matchedRoute)
        }
    }

    
//    func processHttpRequest(httpRequest: HttpRequest ) {
//        let connection = httpRequest._requestContext.connection
//        
//        var response: HttpResponse
//        do {
//            let webRequest = WrappedHttpRequest(request: httpRequest, forMatchingRoute: nil)
//            for handler in _preware {
//                try handler(webRequest)
//            }
//            
//            if let requestHandler = _router.routeRequest(webRequest) {
//                webRequest.matchedRoute = requestHandler.routePattern
//                let webResponse = requestHandler.handler(webRequest)
//                
//                for handler in _middleware {
//                    try handler(webRequest, webResponse)
//                }
//                response = try webResponse.render()
//                
//                
//                for handler in _postware {
//                    try handler(webRequest, response)
//                }
//            } else {
//                response = HttpResponse(status: HttpStatusCode.NotFound, content: HttpContent(contentType: HttpContentType.TextPlain, string: "Not found! Booooo :( ") )
//            }
//        } catch {
//            do {
//                response = try JsonResponse(model: ["error":"An error occured while building the response."], statusCode: HttpStatusCode.InternalServerError)!.render()
//            } catch {
//                response = HttpResponse(status: HttpStatusCode.InternalServerError)
//            }
//        }
//        connection.sendResponse(response, forRequest: httpRequest)
//    }
    
    internal func addHandler(handler: RequestHandler) {
        _requestMiddleware.append(handler)
    }
    
    internal func addHandler(handler: ResponseHandler) {
        _responseMiddleware.append(handler)
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
