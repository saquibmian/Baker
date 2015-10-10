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
    
    for (key,value) in request.httpRequest.queryParameters {
        model[key] = value
    }

    return JsonResponse(model: model )!
}

struct JsonController : Getable, Postable, Patchable {
    
    internal func get(request: WebRequest) -> WebResponse {
        var model = ["hello":"myfriend"]
        
        for (key,value) in request.httpRequest.queryParameters {
            model[key] = value
        }
        
        return JsonResponse(model: model )!
    }

    internal func post(request: WebRequest) -> WebResponse {
        var model = ["hello":"myfriend"]
        
        for (key,value) in request.httpRequest.queryParameters {
            model[key] = value
        }
        
        return JsonResponse(model: model )!
    }

    internal func patch(request: WebRequest) -> WebResponse {
        var model = ["hello":"myfriend"]
        
        for (key,value) in request.httpRequest.queryParameters {
            model[key] = value
        }
        
        return JsonResponse(model: model )!
    }

}