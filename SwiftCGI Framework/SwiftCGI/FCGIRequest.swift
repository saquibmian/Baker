//
//  Request.swift
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

let FCGIRecordHeaderLength: UInt = 8
let FCGITimeout: NSTimeInterval = 5

// TODO: this should probably be a struct...
internal class FCGIRequest {
    let record: BeginRequestRecord
    let keepConnection: Bool
    
    internal var params: [String: String] = [:]
    
    internal let socket: GCDAsyncSocket
    internal var streamData: NSMutableData?
    
    init(record: BeginRequestRecord, fromSocket: GCDAsyncSocket) {
        self.record = record
        self.socket = fromSocket
        keepConnection = record.flags?.contains(.KeepConnection) ?? false
    }
    
    func writeResponseData(data: NSData, toStream stream: FCGIOutputStream) -> Bool {
        guard let streamType = FCGIRecordType(rawValue: stream.rawValue) else {
            NSLog("ERROR: invalid stream type")
            return false
        }
        
        let remainingData = data.mutableCopy() as! NSMutableData
        while remainingData.length > 0 {
            let chunk = remainingData.subdataWithRange(NSMakeRange(0, min(remainingData.length, 65535)))
            let outRecord = ByteStreamRecord(version: record.version, requestID: record.requestID, contentLength: UInt16(chunk.length), paddingLength: 0)
            outRecord.setRawData(chunk)
            
            outRecord.type = streamType
            socket.writeData(outRecord.fcgiPacketData, withTimeout: FCGITimeout, tag: 0)
            
            // Remove the data we just sent from the buffer
            remainingData.replaceBytesInRange(NSMakeRange(0, chunk.length), withBytes: nil, length: 0)
        }
        
        let termRecord = ByteStreamRecord(version: record.version, requestID: record.requestID, contentLength: 0, paddingLength: 0)
        termRecord.type = streamType
        socket.writeData(termRecord.fcgiPacketData, withTimeout: FCGITimeout, tag: 0)
        
        return true
    }
    
    // FCGI-specific implementation
    private func finishWithProtocolStatus(protocolStatus: FCGIProtocolStatus, andApplicationStatus applicationStatus: FCGIApplicationStatus) -> Bool {
        let outRecord = EndRequestRecord(version: record.version, requestID: record.requestID, paddingLength: 0, protocolStatus: protocolStatus, applicationStatus: applicationStatus)
        socket.writeData(outRecord.fcgiPacketData, withTimeout: 5, tag: 0)
        
        if keepConnection {
            socket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
        } else {
            socket.disconnectAfterWriting()
        }
        
        return true
    }
    
    
    internal var path: String {
        if var uri = params["REQUEST_URI"] {
            if let queryStringStart = uri.rangeOfString("?") {
                uri = uri[uri.startIndex..<queryStringStart.startIndex]
            }
            
            // trim the trailing "/"
            if uri[uri.endIndex.predecessor()] == "/" {
                uri = uri[uri.startIndex..<uri.endIndex.predecessor()]
            }
            
            return uri
        }
        
        fatalError("Encountered request that was missing a path")
    }
    
    internal var queryString: String? {
        if let queryString = params["QUERY_STRING"] {
            if queryString != "" {
                return queryString
            }
        }
        return nil
    }
    
    internal func finish() {
        finishWithProtocolStatus(.RequestComplete, andApplicationStatus: 0)
    }
    
    // TODO: move this one level up
    internal var cookies: [String: String]? {
        if let cookieString = params["HTTP_COOKIE"] {
            var result: [String: String] = [:]
            for cookie in cookieString.componentsSeparatedByString("; ") {
                let cookieDef = cookie.componentsSeparatedByString("=")
                result[cookieDef[0]] = cookieDef[1]
            }
            return result
        }
        return nil
    }
    
    // TODO: move this one level up
    internal var queryParameters: [String: String]? {
        if let queryString = self.queryString {
            var result: [String: String] = [:]
            for item in queryString.componentsSeparatedByString("&") {
                let itemDef = item.componentsSeparatedByString("=")
                result[itemDef[0]] = itemDef[1]
            }
            return result
        }
        return nil
    }
    
}
