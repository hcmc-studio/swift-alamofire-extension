//
//  ContinuousFetchContext.swift
//
//
//  Created by Ji-Hwan Kim on 10/18/23.
//

import Foundation
import SwiftProtocolExtension

public actor ContinuousFetchContext<VO: ValueObject, Delegate: ContinuousFetchContextDelegate> where Delegate.VO == VO {
    let request: Request
    var hasMoreContents: Bool
    var isFetching: Bool
    var pageIndex: Int
    nonisolated let delegate: Delegate
    
    public init(request: Request, delegate: Delegate) {
        self.request = request
        self.hasMoreContents = true
        self.isFetching = false
        self.pageIndex = 0
        self.delegate = delegate
    }
    
    public func fetch() async throws {
        if isFetching || !hasMoreContents {
            return
        }
        if !(try await delegate.contextWillFetch()) {
            return
        }
        
        isFetching = true
        defer { isFetching = false }
        
        do {
            let pageSize = try await delegate.contextPageSize()
            let new = try await delegate.context(fetch: pageIndex)
            let hasMoreContents = pageSize == new.count
            self.hasMoreContents = hasMoreContents
            self.pageIndex += 1
            await MainActor.run { delegate.context(fetchSucceed: new, isLast: !hasMoreContents) }
        } catch let error {
            if await MainActor.run(body: { delegate.context(fetchFailed: error) }) {
                throw error
            }
        }
    }
}

public protocol ContinuousFetchContextDelegate {
    associatedtype VO: ValueObject
    
    /// 요청을 시작할 때 호출됩니다. `False`를 반환하여 요청을 시작하지 않을 수 있습니다. 기본 반환은 `true`입니다.
    func contextWillFetch() async throws -> Bool
    
    /// 한 요청 당 객체의 수를 반환합니다.
    func contextPageSize() async throws -> Int
    
    /// 요청을 수행합니다.
    func context(fetch pageIndex: Int) async throws -> [VO]
    
    /// 요청을 성공했을 때 호출됩니다. 마지막 요청일 때 `isLast`에 `True`가 전달됩니다. MainActor에서 수행됩니다.
    func context(fetchSucceed new: [VO], isLast: Bool)
    
    /// 요청을 실패했을 때 호출됩니다. `True`를 반환하면 `error`를 `throw`합니다. MainActor에서 수행됩니다.
    func context(fetchFailed error: Error) -> Bool
}

extension ContinuousFetchContextDelegate {
    public func contextWillFetch() async throws -> Bool { true }
    
    public func context(fetchSucceed new: [VO], isLast: Bool) {}
    
    public func context(fetchFailed error: Error) -> Bool { true }
}
