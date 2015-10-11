//
//  Json
//  SwiftCGI Demo
//
//  Created by Ian Wagner on 3/16/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import SwiftCGI

let jsonRootHandler: RequestHandler = { request in
    var model = ["hello":"myfriend"]
    
    if let qp = request.queryParameters {
        for (key,value) in qp {
            model[key] = value
        }
    }

    return JsonResponse(model: model )!
}

struct JsonController : Getable, Postable, Patchable {
    
    internal func get(request: WebRequest) -> WebResponse {
        var model: [String:AnyObject] = ["hello":"myfriend"]
        var temp: [String:String]
        
        temp = [:]
        for (key,value) in request.matchedRoute.parameters {
            temp[key] = value
        }
        model["route-parameters"] = temp

        temp = [:]
        for (key,value) in request.parameters {
            temp[key] = value
        }
        model["parameters"] = temp

        temp = [:]
        if let qp = request.queryParameters {
            for (key,value) in qp {
                temp[key] = value
            }
        }
        model["query-parameters"] = temp
        
        return JsonResponse(model: model )!
    }

    internal func post(request: WebRequest) -> WebResponse {
        var model: [String:AnyObject] = ["hello":"myfriend"]
        var temp: [String:String]
        
        temp = [:]
        for (key,value) in request.matchedRoute.parameters {
            temp[key] = value
        }
        model["route-parameters"] = temp
        
        temp = [:]
        for (key,value) in request.parameters {
            temp[key] = value
        }
        model["parameters"] = temp

        temp = [:]
        for (key,value) in request.cookies {
            temp[key] = value
        }
        model["cookies"] = temp
        
        temp = [:]
        if let qp = request.queryParameters {
            for (key,value) in qp {
                temp[key] = value
            }
        }
        model["query-parameters"] = temp

        if let content = request.content {
            if let body = String(data: content.data, encoding: NSUTF8StringEncoding) {
                temp = [:]
                temp["data"] = body
                temp["content-type"] = content.contentType
                temp["content-length"] = "\(content.contentLength)"
                model["content"] = temp
            }
        }
        
        return JsonResponse(model: model )!
    }

    internal func patch(request: WebRequest) -> WebResponse {
        var model = ["hello":"myfriend"]
        
        if let qp = request.queryParameters {
            for (key,value) in qp {
                model[key] = value
            }
        }
        
        return JsonResponse(model: model )!
    }

}