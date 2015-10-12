//
//  BodyParser.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-12.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

public class BodyParser : Handler {
    internal static let BodyParserKey = "body-parser-body"
    
    public func didReceiveRequest(request: HttpRequest) {
        if let contentType = request.headers[HttpHeader.ContentType] {
            guard contentType == HttpContentType.ApplicationJSON else {
                // continue
                return
            }
            
            if let data = request.body {
                do {
                    let object = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                    request.customBody = object;
                } catch {
                    //abort request
                }
            }
        }
    }
    public func willSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute) {
        if let contentType = request.headers[HttpHeader.ContentType] {
            guard contentType == HttpContentType.ApplicationJSON else {
                // continue
                return
            }
            
            if let body = request.customBody as? AnyObject, let content = JsonContent(model: body) {
                    response.setContent(to: content)
            } else {
                //abort request
            }
        }
    }
    
    public func didSendResponse(response: HttpResponse, forRequest request: HttpRequest, andRoute route: MatchedRoute) { }
    
}

extension HttpRequest {
    var customBody: Any? {
        get {
            guard let parsedBody = self.customPropertyForKey(BodyParser.BodyParserKey) else {
                return nil
            }
            return parsedBody
        }
        set(value) {
            self.setCustomValue(value, forKey: BodyParser.BodyParserKey)
        }
    }
}

extension HttpResponse {
    var customBody: Any? {
        get {
            guard let parsedBody = self.customPropertyForKey(BodyParser.BodyParserKey) else {
                return nil
            }
            return parsedBody
        }
        set(value) {
            self.setCustomValue(value, forKey: BodyParser.BodyParserKey)
        }
    }
}
