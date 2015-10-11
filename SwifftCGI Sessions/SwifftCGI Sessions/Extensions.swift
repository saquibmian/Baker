//
//  Extensions.swift
//  SwifftCGI Sessions
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

import Foundation
import SwiftCGI


let SessionIDCookieName = "sessionid"

// Extension to implement session handling properties on Request
public extension WebRequest {
    public var sessionID: String? {
        get {
            return cookies[SessionIDCookieName]
        }
        set(id) {
            self.cookies[SessionIDCookieName] = id
        }
    }
    
    public func getSessionManager<T: SessionManager>() -> RequestSessionManager<T>? {
        return RequestSessionManager<T>(request: self)
    }
}


// Define a handler function to modify the response accordingly
public func sessionMiddlewareHandler(var request: WebRequest, let response: WebResponse) throws {
    // Add the session cookie if necessary
    if request.sessionID == nil {
        request.sessionID = NSUUID().UUIDString
    }
    
    var httpResponse = try response.render()
    if let sessionID = request.sessionID {
        httpResponse.setValue("\(sessionID); Max-Age=86400", forCookie: SessionIDCookieName)
    }
}
