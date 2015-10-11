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

/*
typedef struct {
unsigned char version;
unsigned char type;
unsigned char requestIdB1;
unsigned char requestIdB0;
unsigned char contentLengthB1;
unsigned char contentLengthB0;
unsigned char paddingLength;
unsigned char reserved;
} FCGI_Header;
*/

internal protocol NewFCGIRecord {
    var header: FCGIHeader { get }
}

internal protocol FCGIIncomingRecordType : NewFCGIRecord {
    mutating func receiveData(data: NSData)
}

internal protocol FCGIOutgoingRecordType : NewFCGIRecord {
    func data() -> NSData
}
extension FCGIOutgoingRecordType {
    public func headerData() -> NSData {
        var bytes = [UInt8](count: 8, repeatedValue: 0)
        bytes[0] = self.header.version.rawValue
        bytes[1] = UInt8(self.header.type.rawValue)
        
        let (msb, lsb) = self.header.requestId.decomposeBigEndian()
        bytes[2] = msb
        bytes[3] = lsb
        
        let bigEndianContentLength = CFSwapInt16HostToBig(self.header.contentLength)
        bytes[4] = UInt8(bigEndianContentLength & 0xFF) // MSB
        bytes[5] = UInt8(bigEndianContentLength >> 8)   // LSB
        
        bytes[6] = self.header.paddingLength
        
        return NSData(bytes: &bytes, length: 8)
    }
}

struct FastCGIConstants {
    let Timeout: NSTimeInterval = 5 // seconds
}

internal struct FCGIHeader {
    static let Size: UInt = 8
    
    let version: FCGIVersion
    let type: FCGIRecordType
    let requestId: UInt16
    let contentLength: UInt16
    let paddingLength: UInt8
    
    init(version: FCGIVersion, type: FCGIRecordType, requestId: UInt16, contentLength: UInt16, paddingLength: UInt8) {
        self.version = version
        self.type = type
        self.requestId = requestId
        self.contentLength = contentLength
        self.paddingLength = paddingLength
    }
    
    init?(withData data: NSData) {
        guard data.length == Int(FCGIHeader.Size) else {
            return nil
        }
        guard let version = FCGIVersion(rawValue: data.readUInt8(atIndex: 0)) else {
            return nil
        }
        guard version == FCGIVersion.Version1 else {
            print("ERROR: Can't respond to FastCGI version \(version)")
            return nil
        }
        guard let type = FCGIRecordType(rawValue: data.readUInt8(atIndex: 1)) else {
            return nil
        }
        
        self.version = version
        self.type = type
        self.requestId = data.readUInt16FromNetworkOrder(atIndex: 2)
        self.contentLength = data.readUInt16FromNetworkOrder(atIndex: 4)
        self.paddingLength = data.readUInt8(atIndex: 6)
    }
    
    func asIncomingRecord() -> FCGIIncomingRecordType? {
        switch self.type {
        case .BeginRequest:
            return FCGIBeginRequest(header: self)
        case .Params:
            return FCGIParamsRequest(header: self)
        case .Stdin:
            return FCGIStdInRequest(header: self)
        default:
            return nil
        }
    }
}

struct FCGIBeginRequest : FCGIIncomingRecordType {
    static let Size: UInt = 16
    
    let header: FCGIHeader
    var role: FCGIRequestRole?
    var flags: FCGIRequestFlags?
    
    init?(header: FCGIHeader) {
        self.header = header
    }
    
    mutating func receiveData(data: NSData) {
        self.role = FCGIRequestRole(rawValue: data.readUInt16FromNetworkOrder(atIndex: 0))
        self.flags = FCGIRequestFlags(rawValue: data.readUInt8(atIndex: 2) )
    }
}

struct FCGIEndRequest : NewFCGIRecord {
    static let Size: UInt = 16
    
    let header: FCGIHeader
    let applicationStatus: UInt32
    let protocolStatus: FCGIProtocolStatus
}

struct FCGIStdInRequest : FCGIIncomingRecordType {
    let header: FCGIHeader
    var content: NSData?
    
    init?(header: FCGIHeader) {
        self.header = header
    }
    
    internal mutating func receiveData(data: NSData) {
        self.content = data.subdataWithRange(NSMakeRange(0, Int(header.contentLength)))
    }
}

struct FCGIStdOutRequest : FCGIOutgoingRecordType {
    let header: FCGIHeader
    var content: NSData
    
    init?(header: FCGIHeader, content: NSData) {
        self.header = header
        self.content = content
    }
    
    internal func data() -> NSData {
        let result = self.headerData().mutableCopy() as! NSMutableData
        result.appendData(content)
        return result
    }
}

struct FCGIParamsRequest : FCGIIncomingRecordType {
    let header: FCGIHeader
    var params: [String:String]?
    
    init?(header: FCGIHeader) {
        self.header = header
    }

    internal mutating func receiveData(data: NSData) {
        var paramData: [String: String] = [:]
        
        //Remove Padding
        let unpaddedData = data.subdataWithRange(NSMakeRange(0, Int(header.contentLength))).mutableCopy() as! NSMutableData
        while unpaddedData.length > 0 {
            var pos0 = 0, pos1 = 0, pos4 = 0
            
            var keyLengthB3 = 0, keyLengthB2 = 0, keyLengthB1 = 0, keyLengthB0 = 0
            
            var valueLengthB3 = 0, valueLengthB2 = 0, valueLengthB1 = 0, valueLengthB0 = 0
            
            var keyLength = 0, valueLength = 0
            
            unpaddedData.getBytes(&pos0, range: NSMakeRange(0, 1))
            unpaddedData.getBytes(&pos1, range: NSMakeRange(1, 1))
            unpaddedData.getBytes(&pos4, range: NSMakeRange(4, 1))
            
            if pos0 >> 7 == 0 {
                keyLength = pos0
                // NameValuePair11 or 14
                if pos1 >> 7 == 0 {
                    //NameValuePair11
                    valueLength = pos1
                    unpaddedData.replaceBytesInRange(NSMakeRange(0,2), withBytes: nil, length: 0)
                } else {
                    //NameValuePair14
                    unpaddedData.getBytes(&valueLengthB3, range: NSMakeRange(1, 1))
                    unpaddedData.getBytes(&valueLengthB2, range: NSMakeRange(2, 1))
                    unpaddedData.getBytes(&valueLengthB1, range: NSMakeRange(3, 1))
                    unpaddedData.getBytes(&valueLengthB0, range: NSMakeRange(4, 1))
                    
                    valueLength = ((valueLengthB3 & 0x7f) << 24) + (valueLengthB2 << 16) + (valueLengthB1 << 8) + valueLengthB0
                    unpaddedData.replaceBytesInRange(NSMakeRange(0,5), withBytes: nil, length: 0)
                }
            } else {
                // NameValuePair41 or 44
                unpaddedData.getBytes(&keyLengthB3, range: NSMakeRange(0, 1))
                unpaddedData.getBytes(&keyLengthB2, range: NSMakeRange(1, 1))
                unpaddedData.getBytes(&keyLengthB1, range: NSMakeRange(2, 1))
                unpaddedData.getBytes(&keyLengthB0, range: NSMakeRange(3, 1))
                keyLength = ((keyLengthB3 & 0x7f) << 24) + (keyLengthB2 << 16) + (keyLengthB1 << 8) + keyLengthB0
                
                if (pos4 >> 7 == 0) {
                    //NameValuePair41
                    valueLength = pos4
                    unpaddedData.replaceBytesInRange(NSMakeRange(0,5), withBytes: nil, length: 0)
                } else {
                    //NameValuePair44
                    unpaddedData.getBytes(&valueLengthB3, range: NSMakeRange(4, 1))
                    unpaddedData.getBytes(&valueLengthB2, range: NSMakeRange(5, 1))
                    unpaddedData.getBytes(&valueLengthB1, range: NSMakeRange(6, 1))
                    unpaddedData.getBytes(&valueLengthB0, range: NSMakeRange(7, 1))
                    valueLength = ((valueLengthB3 & 0x7f) << 24) + (valueLengthB2 << 16) + (valueLengthB1 << 8) + valueLengthB0
                    unpaddedData.replaceBytesInRange(NSMakeRange(0,8), withBytes: nil, length: 0)
                    
                }
            }
            
            let key = NSString(data: unpaddedData.subdataWithRange(NSMakeRange(0,keyLength)), encoding: NSUTF8StringEncoding)
            unpaddedData.replaceBytesInRange(NSMakeRange(0,keyLength), withBytes: nil, length: 0)
            
            let value = NSString(data: unpaddedData.subdataWithRange(NSMakeRange(0,valueLength)), encoding: NSUTF8StringEncoding)
            unpaddedData.replaceBytesInRange(NSMakeRange(0,valueLength), withBytes: nil, length: 0)
            
            if let key = key as? String, value = value as? String {
                paramData[key] = value
            } else {
                fatalError("Unable to decode key or value from content")  // non-decodable value
            }
        }
        
        if paramData.count > 0 {
            self.params = paramData
        }
    }
}

let FCGITimeout: NSTimeInterval = 5

// TODO: this should probably be a struct...
internal class FCGIRequest {
    internal let version: FCGIVersion
    internal let requestId: UInt16
    internal let keepConnection: Bool
    internal let socket: GCDAsyncSocket
    
    internal var params: [String: String] = [:]
    internal var stdIn: NSMutableData?
    internal var stdOut: NSMutableData?
        
    init(header: FCGIHeader, fromSocket: GCDAsyncSocket, withFlags flags: FCGIRequestFlags) {
        self.version = header.version
        self.requestId = header.requestId
        self.socket = fromSocket
        keepConnection = flags.contains(.KeepConnection)
    }
    
    func writeResponseData(data: NSData, toStream stream: FCGIOutputStream) -> Bool {
        let remainingData = data.mutableCopy() as! NSMutableData
        while remainingData.length > 0 {
            let chunk = remainingData.subdataWithRange(NSMakeRange(0, min(remainingData.length, 65535)))
            let header = FCGIHeader(version: FCGIVersion.Version1, type: FCGIRecordType.Stdout, requestId: self.requestId, contentLength: UInt16(chunk.length), paddingLength: 0)
            let record = FCGIStdOutRequest(header: header, content: chunk)
            
            socket.writeData(record?.data(), withTimeout: FCGITimeout, tag: 0)
            
            // Remove the data we just sent from the buffer
            remainingData.replaceBytesInRange(NSMakeRange(0, chunk.length), withBytes: nil, length: 0)
        }
        
        let emptyData = NSData()
        let header = FCGIHeader(version: FCGIVersion.Version1, type: FCGIRecordType.Stdout, requestId: self.requestId, contentLength: UInt16(emptyData.length), paddingLength: 0)
        let record = FCGIStdOutRequest(header: header, content: emptyData)

        socket.writeData(record?.data(), withTimeout: FCGITimeout, tag: 0)
        
        return true
    }
    
    // FCGI-specific implementation
    private func finishWithProtocolStatus(protocolStatus: FCGIProtocolStatus, andApplicationStatus applicationStatus: FCGIApplicationStatus) -> Bool {
        let outRecord = EndRequestRecord(version: self.version, requestID: self.requestId, paddingLength: 0, protocolStatus: protocolStatus, applicationStatus: applicationStatus)
        socket.writeData(outRecord.fcgiPacketData, withTimeout: 5, tag: 0)
        
        if keepConnection {
            socket.readDataToLength(FCGIHeader.Size, withTimeout: FCGITimeout, tag: FCGISocketState.AwaitingHeaderTag.rawValue)
        } else {
            socket.disconnectAfterWriting()
        }
        
        return true
    }
    
    internal func finish() {
        finishWithProtocolStatus(.RequestComplete, andApplicationStatus: 0)
    }
    
    
    
}

extension FCGIRequest {
    /// include the query string
    internal var path: String {
        if var uri = params["REQUEST_URI"] {
            return uri
        }
        
        fatalError("Encountered request that was missing a path")
    }
    
    internal var queryString: String? {
        return params["QUERY_STRING"]
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
