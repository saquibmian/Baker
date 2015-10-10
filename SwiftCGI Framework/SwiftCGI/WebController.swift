//
//  WebController.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public protocol Getable {
    func get( request: WebRequest ) -> WebResponse
}
public protocol Putable {
    func put( request: WebRequest ) -> WebResponse
}
public protocol Patchable {
    func patch( request: WebRequest ) -> WebResponse
}
public protocol Deletable {
    func delete( request: WebRequest ) -> WebResponse
}
public protocol Postable {
    func post( request: WebRequest ) -> WebResponse
}

public protocol WebController : Getable, Putable, Patchable, Deletable, Postable {}