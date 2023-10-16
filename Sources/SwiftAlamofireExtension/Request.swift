//
//  Request.swift
//
//
//  Created by Ji-Hwan Kim on 10/13/23.
//

import Foundation
import Alamofire
import SwiftProtocolExtension
import SwiftTypeExtension
import Algorithms

public class Request: NSObject {
    let baseUrl: String
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    let print: Bool
    var cookies = [String : String?]()
    let session = Session()
    let defaultHeaders: HTTPHeaders
    let printer: (String) -> Void
    
    public init(
        baseUrl: String,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        defaultHeaders: HTTPHeaders? = nil,
        print: Bool,
        printer: @escaping (String) -> Void = { message in Swift.print(message) }
    ) {
        self.baseUrl = baseUrl
        self.encoder = encoder
        self.decoder = decoder
        self.defaultHeaders = defaultHeaders ?? [:]
        self.print = print
        self.printer = printer
    }
    
    func print(message: String) {
        if print {
            printer(message)
        }
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
        var body = [String : any Codable]()
        
        init(request: Request, path: String, method: HTTPMethod) {
            self.request = request
            self.path = path
            self.method = method
        }
    }
}

extension Request.Builder {
    /// 요청 URL에 포함되는 인자를 추가합니다.
    public func add(param name: String, value: String?) -> Request.Builder {
        if var present = param[name] {
            present.append(value)
        } else {
            param[name] = [value]
        }
        
        return self
    }
    
    /// 요청 URL에 포함되는 인자를 추가합니다.
    /// 같은 이름을 갖는 여러 값을 추가할 때 사용합니다.
    public func add<Values>(param name: String, values: Values) -> Request.Builder where Values: Sequence, Values.Element == String? {
        var present = param[name] ?? []
        present.append(contentsOf: values)
        param[name] = present
        
        return self
    }
    
    /// 요청 헤더를 추가합니다.
    /// `Cookie`를 지정할 경우 저장된 쿠키가 무시됩니다.
    public func set(header name: String, value: String) -> Request.Builder {
        header[name] = value
        return self
    }
    
    /// 요청 본문을 지정합니다.
    /// `POST`, `PUT`, `PATCH`를 제외한 요청일 때 무시됩니다.
    /// ``set(body:value:)``에서 지정한 내용을 무시합니다.
    public func set(body: (any DataTransferObject)?) -> Request.Builder {
        dto = body
        return self
    }
    
    /// 요청 본문을 추가합니다.
    /// `POST`, `PUT`, `PATCH`를 제외한 요청일 때 무시됩니다.
    public func set(body name: String, value: any Codable) -> Request.Builder {
        body[name] = value
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
                return try createParameters(dto: dto)
            } else if !body.isEmpty {
                return body
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    private func createParameters(dto: any DataTransferObject) throws -> Parameters {
        let encodedDTO = try request.encoder.encode(dto)
        
        return try JSONSerialization.jsonObject(with: encodedDTO) as! [String : Any]
    }
    
    private func createHeaders() -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        
        for (_, value) in request.defaultHeaders.enumerated() {
            headers.add(value)
        }
        
        let cookies = createCookies()
        if !cookies.isEmpty {
            headers.add(name: "Cookie", value: cookies)
        }
        
        for (name, value) in header {
            headers.add(name: name, value: value)
        }
        
        return headers
    }
    
    private func createCookies() -> String {
        var cookies = [String]()
        for (name, value) in request.cookies {
            if let value = value {
                cookies.append("\(name)=\(value)")
            } else {
                cookies.append(name)
            }
        }
        
        return cookies.joined(separator: "; ")
    }
    
    func createRequest() throws -> DataRequest {
        let url = createUrl()
        let parameters = try createParameters()
        let headers = createHeaders()
        request.print(message: ">> \(method.rawValue) \(url): headers=\(headers), body=\(parameters.describe())")
        
        return request.session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
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
        let response = await task.response
        let data = try await task.value
        if let cookies = response.response?.headers["Set-Cookie"] {
            update(cookies: cookies)
        }
        if let response = response.response {
            if 200..<300 ~= response.statusCode {
                throw try builder.request.decoder.decode(ErrorResponse.self, from: data)
            }
        }
        
        try printResponse(response, data)
        
        return data
    }
    
    private func update(cookies: String) {
        for cookie in cookies.split(separator: ";") {
            let splitIndex = cookie.firstIndex(of: "=")
            if let splitIndex = splitIndex {
                let name = String(cookie[cookie.startIndex..<splitIndex])
                let value = String(cookie[cookie.index(splitIndex, offsetBy: 1)..<cookie.endIndex])
                builder.request.cookies[name] = value
                builder.request.print(message: "Cookie updated. name=\(name), value=\(value)")
            } else {
                let name = String(cookie)
                builder.request.cookies[name] = nil
                builder.request.print(message: "Cookie updated. name=\(name), value=nil")
            }
        }
    }
    
    private func printResponse(_ response: DataResponse<Data, AFError>, _ data: Data) throws {
        let method = builder.method.rawValue
        let url = response.request?.url?.absoluteString ?? "<unidentified>"
        let headers = (response.response?.headers).describe()
        let body = String(data: data, encoding: .utf8).describe()
        builder.request.print(message: "<< \(method) \(url): headers=\(headers), body=\(body)")
    }
    
    private func decode<Result: Decodable>(data: Data) throws -> Result {
        return try builder.request.decoder.decode(Result.self, from: data)
    }
    
    public func object<Result: Decodable>() async throws -> ObjectResponse<Result> {
        let data = try await fetch()
        
        return try decode(data: data)
    }
    
    public func array<Result: Decodable>() async throws -> ArrayResponse<Result> {
        let data = try await fetch()
        
        return try decode(data: data)
    }
    
    @discardableResult
    public func empty() async throws -> SwiftProtocolExtension.EmptyResponse {
        let data = try await fetch()
        
        return try decode(data: data)
    }
    
    public func error() async throws -> ErrorResponse {
        let data = try await fetch()
        
        return try decode(data: data)
    }
}
