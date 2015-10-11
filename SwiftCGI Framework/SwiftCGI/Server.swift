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

public protocol HttpRequestDelegate {
    func server(didReceiveHttpRequest httpRequest: HttpRequest)
}

// NOTE: This class muse inherit from NSObject; otherwise the Obj-C code for
// GCDAsyncSocket will somehow not be able to store a reference to the delegate
// (it will remain nil and no error will be logged).
internal class FCGIServer: NSObject, GCDAsyncSocketDelegate {

    private let _timeout: NSTimeInterval = 5
    private let _port: UInt16
    private var _recordContext: [GCDAsyncSocket: FCGIIncomingRecordType] = [:]
    private var _currentRequests: [String: FCGIRequest] = [:]
    private var _activeSockets: Set<GCDAsyncSocket> = []
    
    private let _delegateQueue: dispatch_queue_t
    private lazy var _listener: GCDAsyncSocket = {
        GCDAsyncSocket(delegate: self, delegateQueue: self._delegateQueue)
    }()

    internal var delegate: HttpRequestDelegate?

    internal init(port: UInt16) {
        self._port = port
        _delegateQueue = dispatch_queue_create("SocketAcceptQueue", DISPATCH_QUEUE_SERIAL)
    }
    
    internal func start() throws {
        try _listener.acceptOnPort(_port)
    }
    
    func handleIncomingRecord(record: FCGIIncomingRecordType, fromSocket socket: GCDAsyncSocket) {
        let globalRequestID = "\(record.header.requestId)-\(socket.connectedPort)"
        
        switch record {
        case let record as FCGIBeginRequest:
            let request = FCGIRequest(header: record.header, fromSocket: socket, withFlags: record.flags!)
            
            objc_sync_enter(_currentRequests)
            _currentRequests[globalRequestID] = request
            objc_sync_exit(_currentRequests)
            print("Recieved a BEGIN request (#\(record.header.requestId)) on port \(socket.connectedPort)")
            
            // read next request
            socket.readDataToLength(FCGIHeader.Size, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
        
        case let record as FCGIParamsRequest:
            objc_sync_enter(_currentRequests)
            guard let request = _currentRequests[globalRequestID] else {
                print("WARNING: handleRecord called for invalid requestID")
                return
            }
            objc_sync_exit(_currentRequests)
            print("Recieved a PARAMS request (#\(record.header.requestId)) on port \(socket.connectedPort)")
            
            if let params = record.params {
                for key in params.keys {
                    request.params[key] = params[key]
                }
            }
            socket.readDataToLength(FCGIHeader.Size, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
        
        case let record as FCGIStdInRequest:
            objc_sync_enter(_currentRequests)
            guard let request = _currentRequests[globalRequestID] else {
                print("WARNING: handleRecord called for invalid requestID")
                return
            }
            objc_sync_exit(_currentRequests)
            print("Recieved a STREAM request (#\(record.header.requestId)) on port \(socket.connectedPort)")
            
            if let data = record.content {
                if request.stdIn == nil {
                    request.stdIn = NSMutableData(capacity: 65536)
                }
                request.stdIn!.appendData(data)
            } else if let httpRequest = HttpRequest(fromFastCgiRequest: request) {
                self.delegate?.server(didReceiveHttpRequest: httpRequest)
                request.finish()
                
                _recordContext[socket] = nil
                objc_sync_enter(_currentRequests)
                _currentRequests.removeValueForKey(globalRequestID)
                objc_sync_exit(_currentRequests)
            }
            
            socket.readDataToLength(FCGIHeader.Size, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
        default:
            fatalError("unreachable")
        }

    }
    
    // MARK: GCDAsyncSocketDelegate conformance
    
    internal func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        _activeSockets.insert(newSocket)
        
        let acceptedSocketQueue = dispatch_queue_create("SocketAcceptQueue-\(newSocket.connectedPort)", DISPATCH_QUEUE_SERIAL)
        newSocket.delegateQueue = acceptedSocketQueue
        
        newSocket.readDataToLength(FCGIHeader.Size, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
    }
    
    internal func socketDidDisconnect(sock: GCDAsyncSocket?, withError err: NSError!) {
        guard let sock = sock else {
            print("WARNING: nil sock disconnect")
            return
        }
            
        _recordContext[sock] = nil
        _activeSockets.remove(sock)
    }
    
    internal func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        guard let socketTag = FCGISocketState(rawValue: tag) else {
            print("ERROR: Unknown socket tag")
            sock.disconnect()
            return
        }
        
        switch socketTag {
        case .AwaitingHeaderTag:
            guard let header = FCGIHeader(withData: data) else {
                print("ERROR: Unable to construct request record")
                sock.disconnect()
                return
            }
            guard let record = header.asIncomingRecord() else {
                print("ERROR: Unable to construct request receivable record. You've sent me an incorrect message.")
                sock.disconnect()
                return
            }
            if header.contentLength == 0 {
                handleIncomingRecord(record, fromSocket: sock)
            } else {
                // Read additional content
                _recordContext[sock] = record
                sock.readDataToLength(UInt(record.header.contentLength) + UInt(record.header.paddingLength), withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingContentAndPaddingTag.rawValue)
            }
        case .AwaitingContentAndPaddingTag:
            if var record = _recordContext[sock] {
                record.receiveData(data)
                handleIncomingRecord(record, fromSocket: sock)
            } else {
                print("ERROR: Case .AwaitingContentAndPaddingTag hit with no context")
                return
            }
        }
    }
}
