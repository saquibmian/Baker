//
//  SessionManagement.swift
//  SwiftCGI Sessions
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

import SwiftCGI

public typealias SessionID = String
public typealias SessionData = [String: String]


// MARK: Protocol that session managers must conform to

public protocol SessionManager {
    func getDataForSessionID(sessionID: SessionID) -> SessionData?
    func setData(data: SessionData, forSessionID sessionID: SessionID)
    static func sharedInstance() -> SessionManager
}


public class RequestSessionManager<T: SessionManager> {
    let sessionID: SessionID
    let sessionManager: SessionManager
    
    public init?(request: WebRequest) {
        self.sessionManager = T.sharedInstance()
        
        if let id = request.sessionID {
            sessionID = id
        } else {
            sessionID = ""  // Silly compiler; the initializer failed... *shrug*
            return nil
        }
    }
    
    public func getData() -> SessionData? {
        return sessionManager.getDataForSessionID(sessionID)
    }
    
    public func setData(data: SessionData) {
        sessionManager.setData(data, forSessionID: sessionID)
    }
}

// MARK: Can't get much more basic than this; session data is sent to /dev/null

public class NilSessionManager: SessionManager {
    public func getDataForSessionID(sessionID: SessionID) -> SessionData? {
        return nil
    }
    
    public func setData(data: SessionData, forSessionID sessionID: SessionID) {
        // Do nothing
    }
    
    public class func sharedInstance() -> SessionManager {
        struct Static {
            static let instance = NilSessionManager()
        }
        return Static.instance
    }
}


// MARK: Basic, transient in-memory session support; great for quick testing

public class TransientMemorySessionManager: SessionManager {
    private var sessionData: [String: SessionData] = [:]
    
    public func getDataForSessionID(sessionID: SessionID) -> SessionData? {
        return sessionData[sessionID]
    }
    
    public func setData(data: SessionData, forSessionID sessionID: SessionID) {
        sessionData[sessionID] = data
    }
    
    public class func sharedInstance() -> SessionManager {
        struct Static {
            static let instance = TransientMemorySessionManager()
        }
        return Static.instance
    }
}
