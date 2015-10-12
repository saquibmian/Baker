//
//  WebController.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public protocol Getable {
    func get( request: HttpRequest ) -> HttpResponse
}
public protocol Putable {
    func put( request: HttpRequest ) -> HttpResponse
}
public protocol Patchable {
    func patch( request: HttpRequest ) -> HttpResponse
}
public protocol Deletable {
    func delete( request: HttpRequest ) -> HttpResponse
}
public protocol Postable {
    func post( request: HttpRequest ) -> HttpResponse
}

public protocol WebController : Getable, Putable, Patchable, Deletable, Postable {}