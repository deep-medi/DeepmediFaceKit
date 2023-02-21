//
//  SubObject.swift
//  DeepmediFaceKit
//
//  Created by Demian on 2023/02/13.
//

import Foundation
import Alamofire

public class Service: NSObject {
    let header = Header()
    public override init() {
        super.init()
    }
    
    public func makeSignature(method: Header.method, uri: String, secretKey: String, apiKey: String) -> HTTPHeaders {
        return self.header.v2Header(method: method, uri: uri, secretKey: secretKey, apiKey: apiKey)
    }
}
