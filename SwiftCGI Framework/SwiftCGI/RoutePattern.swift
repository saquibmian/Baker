//
//  RoutePattern.swift
//  SwiftCGI
//
//  Created by Saquib Mian on 2015-10-10.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

let RouteComponentSeparator = "/"

struct RouteCharacter {
    static let Separator = "/"
    static let QueryStringStart = "?"
    static let QueryStringSeparator = "&"
    static let QueryStringParameterSeparator = "="
    static let ParameterPrefix = ":"
    static let Wildcard = "*"
}

internal protocol RouteMatchable {
    var route: String { get }
    var method: HttpMethod { get }
    
}

public struct RoutePattern {
    let route: String
    let method: HttpMethod
    internal let components: [String]
    
    init(route: String, forMethod method: HttpMethod) {
        self.route = route
        self.method = method
        
        self.components = self.route
            .componentsSeparatedByString(RouteComponentSeparator)
            .filter { !$0.isEmpty }
    }
}
extension RoutePattern : Hashable {
    public var hashValue: Int {
        return (self.route + self.method.rawValue).hashValue
    }
}

public func ==(lhs: RoutePattern, rhs: RoutePattern) -> Bool {
    return lhs.method == rhs.method && lhs.route == rhs.route
}

private extension String {
    
    var urlDecodedString: String {
        return self.stringByReplacingOccurrencesOfString("+", withString: " ").stringByRemovingPercentEncoding!
    }
    
    var queryParameters: [String:String]? {
        var toReturn: [String:String]!
        
        var toParse = self
        if let index = toParse.rangeOfString(RouteCharacter.QueryStringStart) {
            toParse = toParse.substringFromIndex(index.startIndex)
        }
        
        toReturn = [String:String]()
        for kvp in toParse.componentsSeparatedByString(RouteCharacter.QueryStringSeparator) {
            if kvp.hasPrefix(RouteCharacter.QueryStringParameterSeparator) {
                continue // skip malformed
            }
            
            let pair = kvp.componentsSeparatedByString(RouteCharacter.QueryStringParameterSeparator)
            let key = pair[0]
            let value = pair.count == 2 ? pair[1] : ""
            
            toReturn[key] = value.urlDecodedString
        }
        
        return toReturn
    }
}

extension RoutePattern {
    func match(url: String) -> MatchedRoute? {
        var parameters = url.queryParameters ?? [:]
        var wildcards: [String]? = nil
        
        let urlComponents = url
            .componentsSeparatedByString(RouteCharacter.QueryStringStart)
            .first!
            .componentsSeparatedByString(RouteCharacter.Separator)
            .filter { !$0.isEmpty }
        
        let componentCountEqual = self.components.count == urlComponents.count
        let routeContainsWildcard = self.route.containsString(RouteCharacter.Wildcard)
        guard componentCountEqual || routeContainsWildcard else {
            return nil
        }
        
        var componentIndex = 0
        for patternComponent in self.components {
            var urlComponent: String!
            if componentIndex < urlComponents.count {
                urlComponent = urlComponents[componentIndex]
            } else if patternComponent == RouteCharacter.Wildcard {
                urlComponent = urlComponents.last
            } else {
                return nil
            }
            
            if patternComponent.hasPrefix(RouteCharacter.ParameterPrefix) {
                let variableName = patternComponent.substringFromIndex(patternComponent.startIndex.successor())
                let variableValue = urlComponent.urlDecodedString
                
                if !variableName.isEmpty && !variableValue.isEmpty {
                    parameters[variableName] = variableValue
                }
            } else if patternComponent == RouteCharacter.Wildcard {
                let from = componentIndex
                let to = urlComponents.count-1
                
                if from > to {
                    continue;
                }
                
                wildcards = urlComponents[from...to].map { $0 } // silly...need to map from slice to array
            } else if patternComponent != urlComponent {
                return nil
            }
            ++componentIndex
        }
        
        return MatchedRoute(route: self, withParameters: parameters, andWildcards: wildcards)
    }
}

public struct MatchedRoute {
    public let route: RoutePattern
    public let parameters: [String:String]
    public let wildcards: [String]?
    
    init(route: RoutePattern, withParameters parameters: [String:String], andWildcards wildcards: [String]?) {
        self.route = route
        self.parameters = parameters
        self.wildcards = wildcards
    }
}
