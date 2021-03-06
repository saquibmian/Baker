//
//  WebController.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public protocol Getable : WebController{
    func get() -> HttpResponse
}
public protocol Putable: WebController{
    func put() -> HttpResponse
}
public protocol Patchable : WebController{
    func patch() -> HttpResponse
}
public protocol Deletable : WebController{
    func delete() -> HttpResponse
}
public protocol Postable : WebController{
    func post() -> HttpResponse
}

public protocol WebController {
    var currentRequest: HttpRequest! { get set }
    var matchedRoute: MatchedRoute! { get set }
    
    init()
}
