//
//  AppDelegate.swift
//
//  Copyright (c) 2014, Ian Wagner
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that thefollowing conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

import Cocoa
import SwiftCGI
import SwiftCGISessions

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    
    var app: Application!
    
    private func mapRoutes(router: Router) {
        let root = router.createNestedRouter(atBaseRoute: "/root/")
        let rootRoot = root.createNestedRouter(atBaseRoute: "/root/")
        
        rootRoot.mapRoute("/root", forMethod: HttpMethod.Get, toAction: rootHandler)
        root.mapRoute("/test", forMethod: HttpMethod.Get) { req, route in
            return HttpResponse(status: HttpStatusCode.MovedPermanently)
        }
        rootRoot.mapRoute("/root/blog", forMethod: HttpMethod.Get, toAction: blogRootHandler)
        
        rootRoot.mapController("/root/json/:id/:woah", ofType: JsonController.self)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        app = Application(port: 9081, configureRouter: mapRoutes)
        
        app.use(Logger())
        app.use(Authorizer())
        
        do {
            try app.start()
            print("Started SwiftCGI server on port \(app.port)")
        } catch {
            print("Failed to start SwiftCGI server")
            exit(1)
        }
        
        statusItem.title = "SwiftCGI"   // TODO: Use a logo
        let menu = NSMenu()
        menu.addItemWithTitle("Stop Server", action: Selector("killServer:"), keyEquivalent: "")
        statusItem.menu = menu
    }

    func applicationWillTerminate(aNotification: NSNotification) { }

    func killServer(sender: AnyObject!) {
        NSApplication.sharedApplication().terminate(sender)
    }
    
}
