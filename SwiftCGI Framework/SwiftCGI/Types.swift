//
//  FCGITypes.swift
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

// MARK: Request/response lifecycle

//
// Preware:    Invoked BEFORE the request is handled or a response is generated.
//             Preware returns an (optionally modified) FCGIRequest; use preware
//             to modify the request before it is handled.
// Middleware: Invoked AFTER the request handler has been called, but before
//             the response is sent back to the client. Middleware allows you to
//             alter the response (usually by doing things like setting cookies).
// Postware:   Invoked AFTER the request has completed and the response has been
//             sent to the client.
//

// TODO: Make these Request instances generic once Swift sees the light and lets us do generic
// typeclasses

public typealias RequestHandler = WebRequest -> WebResponse

public typealias RequestPrewareHandler = WebRequest throws -> Void
public typealias RequestMiddlewareHandler = (WebRequest, WebResponse) throws -> Void
public typealias RequestPostwareHandler = (WebRequest, WebResponse) throws -> Void


// MARK: Low-level stuff

public typealias FCGIApplicationStatus = UInt32


public enum FCGIOutputStream: UInt8 {
    case Stdout = 6
}

public enum FCGIProtocolStatus: UInt8 {
    case RequestComplete = 0
    //case FCGI_CANT_MPX_CONN = 1
    //case Overloaded = 2
    case UnknownRole = 3
}


// MARK: Private types

typealias FCGIRequestID = UInt16
typealias FCGIContentLength = UInt16
typealias FCGIPaddingLength = UInt8
//typealias FCGIShortNameLength = UInt8
//typealias FCGILongNameLength = UInt32
//typealias FCGIShortValueLength = UInt8
//typealias FCGILongValueLength = UInt32


enum FCGIVersion: UInt8 {
    case Version1 = 1
}

enum FCGIRequestRole: UInt16 {
    case Responder = 1
}

enum FCGIRecordType: UInt8 {
    case BeginRequest = 1
    case EndRequest = 3
    case Params = 4
    case Stdin = 5
    case Stdout = 6
}

struct FCGIRequestFlags : OptionSetType {
    typealias RawValue = UInt8
    let rawValue: RawValue
    
    init(rawValue value: RawValue) {
        self.rawValue = value
    }
    
    static var allZeros = FCGIRequestFlags(rawValue: 0)
    static var None = FCGIRequestFlags(rawValue: 0)
    static var KeepConnection = FCGIRequestFlags(rawValue: 1 << 0)
}

enum FCGISocketState: Int {
    case AwaitingHeaderTag = 0
    case AwaitingContentAndPaddingTag
}
