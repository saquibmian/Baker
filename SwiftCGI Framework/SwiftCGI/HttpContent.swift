//
//  WebRequest.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public protocol HttpContent {
    var contentType: String { get }
    var data: NSData { get }
}

extension HttpResponse {
    public func setContent(to content: HttpContent) {
        self.contentType = content.contentType
        self.contentLenth = UInt(content.data.length)
        self.body = content.data
    }
}

extension HttpRequest {
    public func setContent(to content: HttpContent) {
        self.contentType = content.contentType
        self.contentLenth = UInt(content.data.length)
        self.body = content.data
    }
}

public struct TextContent : HttpContent {
    public let contentType: String = HttpContentType.TextPlain
    public let data: NSData
    
    public init?(_ model: String) {
        guard let data = model.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        self.data = data
    }
    
}
