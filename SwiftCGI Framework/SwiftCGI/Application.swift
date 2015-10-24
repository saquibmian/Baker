//
//  Application.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-11.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public class Application : HttpRequestReceiverDelegate {
    public let host: String
    public let port: UInt16
    private let _httpRequestProcessor: HttpRequestProcessor
    private let _router: Router
    private let _requestReciever: HttpRequestReceiver
    
    internal init(host: String, port: UInt16, requestRouter: Router, configureRouter: Router -> Void) {
        self.host = host
        self.port = port
        self._router = requestRouter
        
        self._httpRequestProcessor = HttpRequestProcessor(withRouter: _router)
        self._requestReciever = FastCGIServer(port: self.port)

        self._requestReciever.delegate = self
        
        configureRouter(self._router)
    }
    
    public convenience init(host: String = "localhost", port: UInt16, configureRouter: Router -> Void ) {
        self.init(host: host, port:port, requestRouter: Router(), configureRouter: configureRouter )
    }
    
    public func start() throws {
        try self._requestReciever.start()
    }
    
    public func use(handler: RequestHandler) {
        _httpRequestProcessor.addHandler(handler)
    }
    
    /// MARK: HttpRequestReceiverDelegate conformance
    
    public func server(didReceiveHttpRequest httpRequest: HttpRequest) {
        _httpRequestProcessor.processHttpRequest(httpRequest)
    }
    
    
}