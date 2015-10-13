//
//  Logger.swift
//  SwiftCGI Demo
//
//  Created by Saquib Mian on 2015-10-12.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import SwiftCGI

internal struct Logger : RequestHandler {
    private static let ResponseTimeKey = "response-time-key"
    
    func didReceiveRequest(request: HttpRequest) -> HttpResponse? {
        request.setCustomValue(NSDate(), forKey: Logger.ResponseTimeKey)
        return nil
    }
    
    func willSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute?) {
        // do nothing
    }
    
    func didSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute?) {
        if let property = request.customValue(forKey: Logger.ResponseTimeKey), let startedAt = property as? NSDate {
            let durationMilliseconds = Int(startedAt.timeIntervalSinceNow) * -1000
            let method = request.method.rawValue.uppercaseString
            
            print("\(method) \(request.url) \(durationMilliseconds)ms")
        }
    }
}