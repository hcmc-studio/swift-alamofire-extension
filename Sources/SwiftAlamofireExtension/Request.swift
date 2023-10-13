//
//  Request.swift
//
//
//  Created by Ji-Hwan Kim on 10/13/23.
//

import Foundation
import Alamofire
import SwiftProtocolExtension
import Algorithms
import SwiftyJSON

public class Request: NSObject {
    let baseUrl: String
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    var cookies = [String]()
    
    public init(
        baseUrl: String,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseUrl = baseUrl
        self.encoder = encoder
        self.decoder = decoder
    }
}

extension Request {
    public func create(path: String, method: HTTPMethod) -> Request.Builder {
        .init(request: self, path: path, method: method)
    }
}

extension Request {
    public class Builder {
        let request: Request
        let path: String
        let method: HTTPMethod
        var header = [String : String]()
        var param = [String : [String?]]()
        var dto: (any DataTransferObject)? = nil
        var body = [String : any Decodable]()
        
        init(request: Request, path: String, method: HTTPMethod) {
            self.request = request
            self.path = path
            self.method = method
        }
    }
}

extension Request.Builder {
    public func add(param name: String, value: String?) -> Request.Builder {
        if var present = param[name] {
            present.append(value)
        } else {
            param[name] = [value]
        }
        
        return self
    }
    
    public func add<Values>(param name: String, values: Values) -> Request.Builder where Values: Sequence, Values.Element == String? {
        var present = param[name] ?? []
        present.append(contentsOf: values)
        param[name] = present
        
        return self
    }
    
    public func set(header name: String, value: String) -> Request.Builder {
        header[name] = value
        return self
    }
    
    public func set(body: (any DataTransferObject)?) -> Request.Builder {
        self.dto = body
        return self
    }
    
    public func async() -> AsynchronousRequest {
        .init(builder: self)
    }
    
    private func createUrl() -> String {
        let url = request.baseUrl + path
        if param.isEmpty {
            return url
        }
        
        var reduced = [String]()
        for (name, values) in param {
            var acc = [String]()
            for value in values {
                acc.append("\(name)=\(value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
            }
            
            reduced.append(acc.joined(separator: "&"))
        }
        
        return url + "?" + reduced.joined(separator: "&")
    }
    
    private func createParameters() throws -> Parameters? {
        switch method {
        case .post, .put, .patch:
            if let dto = dto {
                var parameters = Parameters()
                let json = (try JSON(data: try request.encoder.encode(dto)))
                for (key, value) in json {
                    parameters[key] = value
                }
                
                return parameters
            } else if !body.isEmpty {
                var parameters = Parameters()
                for (key, value) in body {
                    parameters[key] = value
                }
                
                return parameters
            } else {
                return nil
            }
        default:
            throw SwiftAlamofireExtensionLocalError.RequestBodyViolation
        }
    }
    
    private func createHeaders() -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "Cookie", value: request.cookies.joined(separator: "; "))
        for (name, value) in header {
            headers.add(name: name, value: value)
        }
        
        return headers
    }
    
    func createRequest() throws -> DataRequest {
        return Session().request(
            createUrl(),
            method: method,
            parameters: try createParameters(),
            encoding: JSONEncoding.default,
            headers: createHeaders()
        )
    }
}

public class AsynchronousRequest {
    private let builder: Request.Builder
    
    init(builder: Request.Builder) {
        self.builder = builder
    }
}

extension AsynchronousRequest {
    private func fetch() async throws -> Data {
        let request = try builder.createRequest()
        let task = request.serializingData()
        
        return try await task.value
    }
    
    private func decode<Result: Decodable>(data: Data) throws -> Result {
        try builder.request.decoder.decode(Result.self, from: data)
    }
    
    public func object<Result: Decodable>() async throws -> ObjectResponse<Result> {
        let data = try await fetch()
        
        return try decode(data: data)
    }
    
    public func array<Result: Decodable>() async throws -> ArrayResponse<Result> {
        let data = try await fetch()
        
        return try decode(data: data)
    }
    
    public func empty() async throws -> SwiftProtocolExtension.EmptyResponse {
        let data = try await fetch()
        
        return try decode(data: data)
    }
    
    public func error() async throws -> ErrorResponse {
        let data = try await fetch()
        
        return try decode(data: data)
    }
}
