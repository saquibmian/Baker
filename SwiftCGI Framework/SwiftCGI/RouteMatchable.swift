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

public protocol RouteMatchable {
    var route: String { get }
}

internal protocol _RouteMatchable : RouteMatchable {
    var routeComponents: [String] { get }
    func respondsToMethod(method: HttpMethod) -> Bool
}

extension _RouteMatchable {
    func match(url: String, forMethod method: HttpMethod) -> MatchedRoute? {
        print("...attempting to match against \(self.route)")
        guard self.respondsToMethod(method) else {
            print("...route does not respond to \(method.rawValue.uppercaseString)")
            return nil
        }
        
        var parameters = [String:String]()
        var wildcards: [String]? = nil
        
        let urlComponents = url
            .componentsSeparatedByString(RouteCharacter.QueryStringStart)
            .first!
            .componentsSeparatedByString(RouteCharacter.Separator)
            .filter { !$0.isEmpty }
        
        let componentCountEqual = self.routeComponents.count == urlComponents.count
        let routeContainsWildcard = self.route.containsString(RouteCharacter.Wildcard)
        guard componentCountEqual || routeContainsWildcard else {
            return nil
        }
        
        var componentIndex = 0
        for patternComponent in self.routeComponents {
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
        
        print("matched against \(self.route)")
        return MatchedRoute(target: self, withParameters: parameters, andWildcards: wildcards)
    }
}

public struct MatchedRoute {
    public let target: RouteMatchable
    public let parameters: [String:String]
    public let wildcards: [String]?
    
    init(target: RouteMatchable, withParameters parameters: [String:String], andWildcards wildcards: [String]?) {
        self.target = target
        self.parameters = parameters
        self.wildcards = wildcards
    }
}

public extension String {
    
    var urlDecodedString: String {
        return self.stringByReplacingOccurrencesOfString("+", withString: " ").stringByRemovingPercentEncoding!
    }

}
