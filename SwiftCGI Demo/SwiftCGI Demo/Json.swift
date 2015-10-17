//
//  Json
//  SwiftCGI Demo
//
//  Created by Ian Wagner on 3/16/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import SwiftCGI

struct JsonController : Getable, Postable, Patchable {
    
    var currentRequest: HttpRequest!
    var matchedRoute: MatchedRoute!
    
    init() {}
    
    internal func get() -> HttpResponse {
        var model: [String:AnyObject] = ["hello":"myfriend"]
        var temp: [String:String]
        
        temp = [:]
        for (key,value) in self.matchedRoute.parameters {
            temp[key] = value
        }
        model["route-parameters"] = temp

        temp = [:]
        if let qp = self.currentRequest.queryParameters {
            for (key,value) in qp {
                temp[key] = value
            }
        }
        model["query-parameters"] = temp
        
        return json(model)
    }

    internal func post() -> HttpResponse {
        var model: [String:AnyObject] = ["hello":"myfriend"]
        var temp: [String:String]
        
        temp = [:]
        for (key,value) in self.matchedRoute.parameters {
            temp[key] = value
        }
        model["route-parameters"] = temp

        if let cookies = self.currentRequest.cookies {
            temp = [:]
            for (key,value) in cookies {
                temp[key] = value
            }
            model["cookies"] = temp
        }
        
        temp = [:]
        if let qp = self.currentRequest.queryParameters {
            for (key,value) in qp {
                temp[key] = value
            }
        }
        model["query-parameters"] = temp

        if let body = self.currentRequest.body {
            if let body = String(data: body, encoding: NSUTF8StringEncoding) {
                temp = [:]
                temp["data"] = body
                temp["content-type"] = self.currentRequest.contentType
                temp["content-length"] = "\(self.currentRequest.contentLenth)"
                model["content"] = temp
            }
        }
        
        return json(model)
    }

    internal func patch() -> HttpResponse {
        var model = ["hello":"myfriend"]
        
        if let qp = self.currentRequest.queryParameters {
            for (key,value) in qp {
                model[key] = value
            }
        }
        
        return json(model)
    }

}
