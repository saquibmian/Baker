//
//  Server.swift
//  SwiftCGI
//
//  Copyright (c) 2014, Ian Wagner
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that thefollowing conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

public protocol RequestHandler {
    func didReceiveRequest(request: HttpRequest)
}

public protocol ResponseHandler {
    func willSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute)
    func didSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute)
}

public protocol Handler : RequestHandler, ResponseHandler {}

public protocol HttpRequestDelegate {
    func server(didReceiveHttpRequest httpRequest: HttpRequest)
}

internal protocol ConnectionManager {
    func connection(connection: FastCGIConnection, didReceiveHttpRequest httpRequest: HttpRequest)
    func connection(connection: FastCGIConnection, willSendResponse response: HttpResponse, forRequest request: HttpRequest)
    func connection(connection: FastCGIConnection, didSendResponse response: HttpResponse, forRequest request: HttpRequest)
    func connectionDidClose(connection: FastCGIConnection)
}

// NOTE: This class muse inherit from NSObject; otherwise the Obj-C code for
// GCDAsyncSocket will somehow not be able to store a reference to the delegate
// (it will remain nil and no error will be logged).
internal class FCGIServer: NSObject, GCDAsyncSocketDelegate, ConnectionManager {

    private let _port: UInt16
    private let _timeout: NSTimeInterval = 5

    private var _activeConnections: Set<FastCGIConnection> = []
    
    private let _delegateQueue: dispatch_queue_t
    private lazy var _listener: GCDAsyncSocket = {
        GCDAsyncSocket(delegate: self, delegateQueue: self._delegateQueue)
    }()

    internal var delegate: HttpRequestDelegate!

    internal init(port: UInt16) {
        self._port = port
        _delegateQueue = dispatch_queue_create("SocketAcceptQueue", DISPATCH_QUEUE_SERIAL)
    }
    
    internal func start() throws {
        try _listener.acceptOnPort(_port)
    }
    
    func connection(connection: FastCGIConnection, didReceiveHttpRequest httpRequest: HttpRequest) {
        self.delegate.server(didReceiveHttpRequest: httpRequest)
    }
    func connection(connection: FastCGIConnection, willSendResponse response: HttpResponse, forRequest request: HttpRequest) {
        // TODO: currently httprequest delegate does everything...these will forward to that?
    }
    func connection(connection: FastCGIConnection, didSendResponse response: HttpResponse, forRequest request: HttpRequest) {
        
    }
    internal func socket(socket: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        let connection = FastCGIConnection(connectionForSocket: newSocket, withManager: self)
        _activeConnections.insert(connection)
    }
    
    func connectionDidClose(connection: FastCGIConnection) {
        _activeConnections.remove(connection)
    }

//    internal func client(didFinishBuildingResponse response: HttpResponse, forHttpRequest request: HttpRequest) {
//        request._fcgiContext.connection.sendResponse(httpResponse: response, forRequest: request)
//    }
}
