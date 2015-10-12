//
//  Json
//  SwiftCGI Demo
//
//  Created by Ian Wagner on 3/16/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import SwiftCGI

let jsonRootHandler: RequestHandlerOld = { request in
    var model = ["hello":"myfriend"]
    
    if let qp = request.queryParameters {
        for (key,value) in qp {
            model[key] = value
        }
    }

    return HttpResponse(status: HttpStatusCode.OK, content: JsonContent(model: model )!)
}

struct JsonController : Getable, Postable, Patchable {
    
    internal func get(request: HttpRequest) -> HttpResponse {
        var model: [String:AnyObject] = ["hello":"myfriend"]
        var temp: [String:String]
        
//        temp = [:]
//        for (key,value) in request.matchedRoute.parameters {
//            temp[key] = value
//        }
//        model["route-parameters"] = temp
//
//        temp = [:]
//        for (key,value) in request.parameters {
//            temp[key] = value
//        }
//        model["parameters"] = temp

        temp = [:]
        if let qp = request.queryParameters {
            for (key,value) in qp {
                temp[key] = value
            }
        }
        model["query-parameters"] = temp
        
        return HttpResponse(status: HttpStatusCode.OK, content: JsonContent(model: model )!)
    }

    internal func post(request: HttpRequest) -> HttpResponse {
        var model: [String:AnyObject] = ["hello":"myfriend"]
        var temp: [String:String]
        
//        temp = [:]
//        for (key,value) in request.matchedRoute.parameters {
//            temp[key] = value
//        }
//        model["route-parameters"] = temp
//        
//        temp = [:]
//        for (key,value) in request.parameters {
//            temp[key] = value
//        }
//        model["parameters"] = temp

        if let cookies = request.cookies {
            temp = [:]
            for (key,value) in cookies {
                temp[key] = value
            }
            model["cookies"] = temp
        }
        
        temp = [:]
        if let qp = request.queryParameters {
            for (key,value) in qp {
                temp[key] = value
            }
        }
        model["query-parameters"] = temp

        if let body = request.body {
            if let body = String(data: body, encoding: NSUTF8StringEncoding) {
                temp = [:]
                temp["data"] = body
                temp["content-type"] = request.contentType
                temp["content-length"] = "\(request.contentLenth)"
                model["content"] = temp
            }
        }
        
        let toReturn = HttpResponse(status: HttpStatusCode.OK, content: JsonContent(model: model )!)
        
        return toReturn
    }

    internal func patch(request: HttpRequest) -> HttpResponse {
        var model = ["hello":"myfriend"]
        
        if let qp = request.queryParameters {
            for (key,value) in qp {
                model[key] = value
            }
        }
        
        return HttpResponse(status: HttpStatusCode.OK, content: JsonContent(model: model )!)
    }

}