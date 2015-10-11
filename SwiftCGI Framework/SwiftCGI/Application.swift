//
//  Application.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-11.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public class Application : HttpRequestDelegate {
    public let port: UInt16
    private let _httpRequestProcessor: HttpRequestProcessor
    private let _router: Router
    private let _fcgi: FCGIServer
    
    internal init(port: UInt16, requestRouter: Router) {
        self.port = port
        self._router = requestRouter
        self._httpRequestProcessor = HttpRequestProcessor(withRouter: _router)
        
        self._fcgi = FCGIServer(port: self.port)
        self._fcgi.delegate = self
    }
    
    public convenience init(port: UInt16, configureRouter: Router -> Void ) {
        self.init(port:port, requestRouter: Router() )
        
        configureRouter(self._router)
    }
    
    public func start() throws {
        try self._fcgi.start()
    }
    
    public func registerPrewareHandler(handler: RequestPrewareHandler) -> Void {
        _httpRequestProcessor.registerPrewareHandler(handler)
    }
    
    public func registerMiddlewareHandler(handler: RequestMiddlewareHandler) -> Void {
        _httpRequestProcessor.registerMiddlewareHandler(handler)
    }
    
    public func registerPostwareHandler(handler: RequestPostwareHandler) -> Void {
        _httpRequestProcessor.registerPostwareHandler(handler)
    }
    
    /// MARK: HttpRequestDelegate conformance
    
    public func server(didReceiveHttpRequest httpRequest: HttpRequest) {
        _httpRequestProcessor.processHttpRequest(httpRequest)
    }
    
}