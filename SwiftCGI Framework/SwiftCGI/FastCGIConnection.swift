//
//  FastCGIConnection.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-12.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

internal class InternalRequestContext {
    internal let version: FCGIVersion
    internal let requestId: UInt16
    internal let keepConnectionOpen: Bool
    internal let connection: FastCGIConnection
    
    init(version: FCGIVersion, requestId: UInt16, keepConnectionOpen: Bool, connection: FastCGIConnection) {
        self.version = version
        self.requestId = requestId
        self.connection = connection
        self.keepConnectionOpen = keepConnectionOpen
    }
}

internal class FastCGIConnection : NSObject, GCDAsyncSocketDelegate {
    enum ConnectionState: Int {
        case AwaitingHeader = 0
        case AwaitingContentAndPadding = 1
    }
    
    let manager: ConnectionManager
    let socket: GCDAsyncSocket
    
    private var _incomingHttpRequests: [UInt16:FCGIRequest] = [:]
    // the protocol only sends one whole record at a time
    private var _incomingFCGIRecord: FCGIIncomingRecordType?
    
    init(connectionForSocket socket: GCDAsyncSocket, withManager manager: ConnectionManager) {
        self.socket = socket
        self.manager = manager
        
        super.init()
        
        let queue = dispatch_queue_create("SocketAcceptQueue-\(self.socket.connectedPort)", DISPATCH_QUEUE_SERIAL)
        self.socket.setDelegate(self, delegateQueue: queue)
        
        readNextRecordHeader()
    }
    
    // MARK: FastCGI record processing
    
    private func readNextRecordHeader() {
        socket.readDataToLength(FCGIHeader.Size, withTimeout: FCGITimeout, tag: ConnectionState.AwaitingHeader.rawValue)
    }
    
    private func readContent(ofLength length: UInt) {
        socket.readDataToLength(length, withTimeout: FCGITimeout, tag: ConnectionState.AwaitingContentAndPadding.rawValue)
    }
    
    private func handleIncomingRecord(record: FCGIIncomingRecordType, fromSocket socket: GCDAsyncSocket) {
        switch record {
        case let record as FCGIBeginRequest:
            processRecord(record)
        case let record as FCGIParamsRequest:
            processRecord(record)
        case let record as FCGIStdInRequest:
            processRecord(record)
        default:
            fatalError("unreachable")
        }
    }
    
    private func processRecord(record: FCGIBeginRequest) {
        print("Recieved a BEGIN request (#\(record.header.requestId)) on port \(socket.connectedPort)")
        
        let request = FCGIRequest(header: record.header, fromSocket: socket, withFlags: record.flags!)
        _incomingHttpRequests[record.header.requestId] = request
    }
    
    private func processRecord(record: FCGIParamsRequest) {
        print("Recieved a PARAMS request (#\(record.header.requestId)) on port \(socket.connectedPort)")
        
        guard let request = _incomingHttpRequests[record.header.requestId] else {
            print("WARNING: handleRecord called for invalid requestID")
            return
        }
        if let params = record.params {
            for key in params.keys {
                request.params[key] = params[key]
            }
        }
    }
    
    private func processRecord(record: FCGIStdInRequest) {
        print("Recieved a STREAM request (#\(record.header.requestId)) on port \(socket.connectedPort)")
        
        guard let request = _incomingHttpRequests[record.header.requestId] else {
            print("WARNING: handleRecord called for invalid requestID")
            return
        }
        if let data = record.content {
            if request.stdIn == nil {
                request.stdIn = NSMutableData(capacity: 65536)
            }
            request.stdIn!.appendData(data)
        } else if let httpRequest = HttpRequest(fromFastCgiRequest: request, withRequestContext: InternalRequestContext(version: request.version, requestId: request.requestId, keepConnectionOpen: request.keepConnectionOpen, connection: self)) {
            
            // send rquest off to be processed TODO: in other thread
            self.manager.connection(self, didReceiveHttpRequest: httpRequest)
            
            //TODO: _recordContext[socket] = nil
            _incomingHttpRequests.removeValueForKey(record.header.requestId)
        }
    }
    
    // MARK: GCDAsyncDelegate methods
    
    internal func socketDidDisconnect(sock: GCDAsyncSocket?, withError err: NSError!) {
        self.manager.connectionDidClose(self)
    }
    
    internal func socket(socket: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        guard let state = ConnectionState(rawValue: tag) else {
            print("ERROR: Unknown socket state \(tag)")
            socket.disconnect()
            return
        }
        
        switch state {
        case .AwaitingHeader:
            guard let header = FCGIHeader(withData: data) else {
                print("ERROR: Unable to construct request record")
                socket.disconnect()
                return
            }
            guard let record = header.asIncomingRecord() else {
                print("ERROR: Unable to construct request receivable record. You've sent me an incorrect message.")
                socket.disconnect()
                return
            }
            if header.contentLength == 0 {
                handleIncomingRecord(record, fromSocket: socket)
                readNextRecordHeader()
            } else {
                _incomingFCGIRecord = record
                readContent(ofLength: UInt(record.header.contentLength) + UInt(record.header.paddingLength ))
            }
        case .AwaitingContentAndPadding:
            if var record = _incomingFCGIRecord {
                record.receiveData(data)
                handleIncomingRecord(record, fromSocket: socket)
                readNextRecordHeader()
            } else {
                print("ERROR: state AwaitingContentAndPadding unexpectedly")
                return
            }
        }
    }
    
    // MARK -- Response methods
    
    internal func sendResponse(response: HttpResponse, forRequest request: HttpRequest) {
        let context = request._requestContext
        let responseWriter = HttpResponseSerializer()
        
        guard let responseData = responseWriter.serialize(response: response) else {
            print("ERROR: Unable to build response data!")
            return
        }
        
        let socket = context.connection.socket
        let requestId = context.requestId
        let keepConnection = context.keepConnectionOpen
        
        var sent = 0
        while responseData.length > sent {
            let chunk = responseData.subdataWithRange(NSMakeRange(sent, min(responseData.length - sent, 65535)))
            let header = FCGIHeader(version: FCGIVersion.Version1, type: FCGIRecordType.Stdout, requestId: requestId, contentLength: UInt16(chunk.length), paddingLength: 0)
            let record = FCGIStdOutRequest(header: header, content: chunk)
            
            self.socket.writeData(record.data(), withTimeout: FCGITimeout, tag: 0)
            
            sent += chunk.length
        }
        
        let emptyData = NSData()
        let header = FCGIHeader(version: FCGIVersion.Version1, type: FCGIRecordType.Stdout, requestId: requestId, contentLength: UInt16(emptyData.length), paddingLength: 0)
        let record = FCGIStdOutRequest(header: header, content: emptyData)
        
        socket.writeData(record.data(), withTimeout: FCGITimeout, tag: 0)
        
        let header2 = FCGIHeader(version: FCGIVersion.Version1, type: FCGIRecordType.Stdout, requestId: requestId, contentLength: UInt16(FCGIEndRequest.Size-FCGIHeader.Size), paddingLength: 0)
        let record2 = FCGIEndRequest(header: header2, protocolStatus: FCGIProtocolStatus.RequestComplete, applicationStatus: 0)
        
        socket.writeData(record2.data(), withTimeout: 5, tag: 0)
        
        if !keepConnection {
            socket.disconnectAfterWriting()
        }
    }
}
