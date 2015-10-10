//
//  HTTPResponseHelpers.swift
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

public struct HttpResponse {
    
    public var status: HttpStatusCode
    public var contentType: String
    public var contentLength: Int { return body.utf8.count }
    public var cookies: [String:String]?
    public var headers: [String:String] = [:]
    public var body: String
    

    // MARK: Init
    public init(status: HttpStatusCode, contentType: String, body: String) {
        self.status = status
        self.body = body
        self.contentType = contentType
    }
    
    public init(body: String) {
        status = .OK
        self.body = body
        contentType = HttpContentType.TextPlain
    }
    
    public mutating func setValue(value: String, forHeader header: String ) {
        if header == HttpHeader.ContentLength {
            // TODO throw error
        }
        if header == HttpHeader.ContentType {
            // TODO throw error
        }
        headers[header] = value
    }
    
    public mutating func setValue(value: String, forCookie key: String) {
        if cookies == nil {
            cookies = [:]
        }
        
        cookies![key] = value
    }
    
}