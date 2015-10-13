//
//  Authorizer.swift
//  SwiftCGI Demo
//
//  Created by Saquib Mian on 2015-10-12.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import SwiftCGI

internal struct Authorizer : RequestHandler {
    func didReceiveRequest(request: HttpRequest) -> HttpResponse? {
        return nil
        //return HttpResponse(status: HttpStatusCode.Forbidden)
    }
    
    func willSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute?) {
        // do nothing
    }
    
    func didSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute?) {
        // do nothing
    }
}