//
//  Root.swift
//  SwiftCGI Demo
//
//  Created by Ian Wagner on 3/16/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import SwiftCGI
import SwiftCGISessions

let rootHandler: ActionMethod = { request, route in
    var extraGreeting = ""
    if let sessionManager = request.getSessionManager() as RequestSessionManager<TransientMemorySessionManager>? {
        var sessionData: SessionData = sessionManager.getData() ?? [:]
        
        if sessionData["visited"] == "true" {
            extraGreeting = " again"
        } else {
            sessionData["visited"] = "true"
        }
        
        sessionManager.setData(sessionData)
    }
    
    return HttpResponse(status: HttpStatusCode.OK, content: TextContent("안녕하세요\(extraGreeting), Swifter! The time is now \(NSDate())")! )
}