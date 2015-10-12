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

let FCGITimeout: NSTimeInterval = 5

// TODO: this should probably be a struct...

//public protocol RequestContext {
//    var webRequest: WebRequest { get }
//    var webResponse: WebResponse { get set }
//}

//public class FCGIRequestContext : RequestContext{
//    public var webRequest: WebRequest
//    public var webResponse: WebResponse
//    
//    internal let version: FCGIVersion
//    internal let requestId: UInt16
//    internal let keepConnectionOpen: Bool
//    internal let socket: GCDAsyncSocket
//    
//    init(webRequest: WebRequest, webResponse: WebResponse, fcgiVersion version: FCGIVersion, fcgiRequestId requestId: UInt16, keepConnectionOpen: Bool, socket: GCDAsyncSocket) {
//        self.webRequest = webRequest
//        self.webResponse = webResponse
//        
//        self.version = version
//        self.requestId = requestId
//        self.socket = socket
//        self.keepConnectionOpen = keepConnectionOpen
//    }
//}



internal class FCGIRequest {
    internal let version: FCGIVersion
    internal let requestId: UInt16
    internal let keepConnectionOpen: Bool
    
    internal var params: [String: String] = [:]
    internal var stdIn: NSMutableData?
    
    init(header: FCGIHeader, fromSocket: GCDAsyncSocket, withFlags flags: FCGIRequestFlags) {
        self.version = header.version
        self.requestId = header.requestId
        keepConnectionOpen = flags.contains(.KeepConnection)
    }
    
    var headers: [String:String] {
        var toReturn = [String:String]()
        
        for (var key,value) in self.params {
            if let range = key.rangeOfString("HTTP_") where range.startIndex == key.startIndex {
                key = key[range.endIndex..<key.endIndex]
                    .stringByReplacingOccurrencesOfString("_", withString: "-")
                    .capitalizedString
                
                toReturn[key] = value
            }
        }
        
        return toReturn
    }
    
}


