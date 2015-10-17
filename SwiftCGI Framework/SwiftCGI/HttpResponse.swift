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

public class HttpResponse {
    
    public var status: HttpStatusCode
    public var headers: [String:String] = [:]
    public var cookies: [String:String]?
    public var body: NSData?
    
    internal var _customProperties: [String:Any]
    
    // MARK: Init
    public init(status: HttpStatusCode) {
        self.status = status
        _customProperties = [:]
    }

    public init(status: HttpStatusCode, content: HttpContent) {
        self.status = status
        _customProperties = [:]

        self.setContent(to: content)
    }
    
    public func setValue(value: String, forHeader header: String ) {
        if header == HttpHeader.ContentLength {
            // TODO throw error
        }
        if header == HttpHeader.ContentType {
            // TODO throw error
        }
        headers[header] = value
    }
    
    public func setValue(value: String, forCookie key: String) {
        if cookies == nil {
            cookies = [:]
        }
        
        cookies![key] = value
    }
    
    public func customPropertyForKey(key: String) -> Any? {
        if let prop = _customProperties[key] {
            return prop
        }
        
        return nil
    }
    
    public func setCustomValue(value: Any, forKey key: String) {
        _customProperties[key] = value
    }

}

extension HttpResponse {
    public var contentType: String? {
        get {
            return self.headers[HttpHeader.ContentType]
        }
        set(value) {
            self.headers[HttpHeader.ContentType] = value!
        }
    }
    
    public var contentLenth: UInt? {
        get {
            guard let rawContentLength = self.headers[HttpHeader.ContentLength] else {
                return nil
            }
            return UInt(rawContentLength)
        }
        set(value) {
            self.headers[HttpHeader.ContentLength] = "\(value!)"
        }
    }
}

