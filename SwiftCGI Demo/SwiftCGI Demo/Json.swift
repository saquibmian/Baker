//
//  Json
//  SwiftCGI Demo
//
//  Created by Ian Wagner on 3/16/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import SwiftCGI

let jsonRootHandler: RequestHandler = { request in
    return JsonResponse(model: ["hello":"myfriend"] )!
}
