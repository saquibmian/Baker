//
//  WebResponse.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

//public protocol HttpRequest {
//    func render() throws -> HttpResponse
//}
//
//extension HttpResponse : WebResponse {
//    public func render() -> HttpResponse {
//        return self
//    }
//}

//public extension WebResponse {
//    public static func notFound() -> WebResponse  {
//        return HttpResponse(status: HttpStatusCode.NotFound, contentType: HttpContentType.TextPlain, body: "Not found!")
//    }
//}