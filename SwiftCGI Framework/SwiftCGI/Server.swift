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


// MARK: Main server class

// NOTE: This class muse inherit from NSObject; otherwise the Obj-C code for
// GCDAsyncSocket will somehow not be able to store a reference to the delegate
// (it will remain nil and no error will be logged).

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

public class FCGIServer: NSObject, GCDAsyncSocketDelegate {

    public let port: UInt16
    internal var paramsAvailableHandler: (FCGIRequest -> Void)?
    
    private let _httpRequestProcessor: HttpRequestProcessor
    private let _router: Router
    
    private var _recordContext: [GCDAsyncSocket: FCGIRecord] = [:]
    private var _currentRequests: [String: FCGIRequest] = [:]
    private var _activeSockets: Set<GCDAsyncSocket> = []
    
    private let _delegateQueue: dispatch_queue_t
    private lazy var _listener: GCDAsyncSocket = {
        GCDAsyncSocket(delegate: self, delegateQueue: self._delegateQueue)
    }()

    // MARK: Init
    
    internal init(port: UInt16, requestRouter: Router) {
        self.port = port
        self._router = requestRouter
        self._httpRequestProcessor = HttpRequestProcessor(withRouter: _router)
        
        _delegateQueue = dispatch_queue_create("SocketAcceptQueue", DISPATCH_QUEUE_SERIAL)
    }
    
    public convenience init(port: UInt16, configureRouter: Router -> Void ) {
        self.init(port:port, requestRouter: Router() )
        
        configureRouter(self._router)
    }
    
    
    // MARK: Instance methods
    
    public func start() throws {
        try _listener.acceptOnPort(port)
    }
    
    func handleRecord(record: FCGIRecord, fromSocket socket: GCDAsyncSocket) {
        let globalRequestID = "\(record.requestID)-\(socket.connectedPort)"
        
        switch record {
        case let record as BeginRequestRecord:
            let request = FCGIRequest(record: record, fromSocket: socket)
            
            objc_sync_enter(_currentRequests)
            _currentRequests[globalRequestID] = request
            objc_sync_exit(_currentRequests)
            print("Recieved a BEGIN request: \(globalRequestID)")
            
            socket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
        case let record as ParamsRecord:
            objc_sync_enter(_currentRequests)
            guard let request = _currentRequests[globalRequestID] else {
                print("WARNING: handleRecord called for invalid requestID")
                return
            }
            objc_sync_exit(_currentRequests)
            print("Recieved a PARAMS request: \(globalRequestID)")

            guard let params = record.params else {
                // TODO: could possibly inject preware here
                paramsAvailableHandler?(request)
                // TODO: cleaner way to do this
                socket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
                return
            }
            
            for key in params.keys {
                request.params[key] = params[key]
            }
            
            socket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
        case let record as ByteStreamRecord:
            objc_sync_enter(_currentRequests)
            guard let request = _currentRequests[globalRequestID] else {
                print("WARNING: handleRecord called for invalid requestID")
                return
            }
            objc_sync_exit(_currentRequests)
            print("Recieved a STREAM request: \(globalRequestID)")
            
            if request.streamData == nil {
                request.streamData = NSMutableData(capacity: 65536)
            }
            
            if let recordData = record.rawData {
                request.streamData!.appendData(recordData)
            } else if let httpRequest = HttpRequest(fromFastCgiRequest: request) {
                _httpRequestProcessor.processHttpRequest(httpRequest)
            }
            
            request.finish()
            
            _recordContext[socket] = nil
            
            objc_sync_enter(_currentRequests)
            _currentRequests.removeValueForKey(globalRequestID)
            objc_sync_exit(_currentRequests)
        default:
            fatalError("ERROR: handleRecord called with an invalid FCGIRecord type")
        }
    }
    
    // MARK: Pre/middle/postware registration
    
    public func registerPrewareHandler(handler: RequestPrewareHandler) -> Void {
        _httpRequestProcessor.registerPrewareHandler(handler)
    }
    
    public func registerMiddlewareHandler(handler: RequestMiddlewareHandler) -> Void {
        _httpRequestProcessor.registerMiddlewareHandler(handler)
    }
    
    public func registerPostwareHandler(handler: RequestPostwareHandler) -> Void {
        _httpRequestProcessor.registerPostwareHandler(handler)
    }
    
    // MARK: GCDAsyncSocketDelegate conformance
    
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        _activeSockets.insert(newSocket)
        
        let acceptedSocketQueue = dispatch_queue_create("SocketAcceptQueue-\(newSocket.connectedPort)", DISPATCH_QUEUE_SERIAL)
        newSocket.delegateQueue = acceptedSocketQueue
        
        newSocket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket?, withError err: NSError!) {
        guard let sock = sock else {
            print("WARNING: nil sock disconnect")
            return
        }
            
        _recordContext[sock] = nil
        _activeSockets.remove(sock)
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        guard let socketTag = FCGISocketState(rawValue: tag) else {
            print("ERROR: Unknown socket tag")
            sock.disconnect()
            return
        }
        
        switch socketTag {
        case .AwaitingHeaderTag:
            guard let record = createRecordFromHeaderData(data) else {
                print("ERROR: Unable to construct request record")
                sock.disconnect()
                return
            }
            if record.contentLength == 0 {
                // No content; handle the message
                handleRecord(record, fromSocket: sock)
            } else {
                // Read additional content
                _recordContext[sock] = record
                sock.readDataToLength(UInt(record.contentLength) + UInt(record.paddingLength), withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingContentAndPaddingTag.rawValue)
            }
        case .AwaitingContentAndPaddingTag:
            guard let record = _recordContext[sock] else {
                print("ERROR: Case .AwaitingContentAndPaddingTag hit with no context")
                return
            }
            record.processContentData(data)
            handleRecord(record, fromSocket: sock)
        }
    }
}
