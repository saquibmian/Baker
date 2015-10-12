//
//  JsonResponse.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

//public struct JsonResponse : HttpResponse {
//    
//    private let _model: AnyObject
//    private let _statusCode: HttpStatusCode
//    private let _contentType: String = HttpContentType.ApplicationJSON
//    
//    public init?(model: AnyObject) {
//        self.init(model: model, statusCode: HttpStatusCode.OK)
//    }
//    
//    public init?(model: AnyObject, statusCode: HttpStatusCode ) {
//        if !NSJSONSerialization.isValidJSONObject(model) {
//            return nil
//        }
//        
//        _model = model
//        _statusCode = statusCode
//    }
//    
//    public func render() throws -> HttpResponse {
//        let data = try NSJSONSerialization.dataWithJSONObject(_model, options: NSJSONWritingOptions.PrettyPrinted)
//        let json = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
//        let content = HttpContent(contentType: _contentType, string: json)
//        return HttpResponse(status: _statusCode, content: content)
//    }
//}

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