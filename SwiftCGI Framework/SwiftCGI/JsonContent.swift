//
//  JsonResponse.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public struct JsonContent : HttpContent {
    public let contentType: String = HttpContentType.ApplicationJSON
    public let contentLength: UInt
    public let data: NSData

    public init?(model: AnyObject) {
        if !NSJSONSerialization.isValidJSONObject(model) {
            return nil
        }
        self.data = try! NSJSONSerialization.dataWithJSONObject(model, options: NSJSONWritingOptions(rawValue:0))
        self.contentLength = UInt(data.length)
    }
}

extension WebController {
    public func json(model: AnyObject) -> HttpResponse {
        let toReturn = HttpResponse(status: HttpStatusCode.OK, content: JsonContent(model: model )!)
        return toReturn
    }
    
    public func json(model: AnyObject, withStatusCode statusCode: HttpStatusCode) -> HttpResponse {
        let toReturn = HttpResponse(status: statusCode, content: JsonContent(model: model )!)
        return toReturn
    }
}
