//
//  Blog.swift
//  SwiftCGI Demo
//
//  Created by Ian Wagner on 3/16/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import SwiftCGI

let blogRootHandler: RequestHandler = { request in
    var extraGreeting = ""
    
    return HttpResponse(status: HttpStatusCode.OK, content: HttpContent( contentType: HttpContentType.TextPlain, string: "Welcome to my blog!") )
}
