//
//  RxProperty.swift
//  RxProperty
//
//  Created by Yasuhiro Inami on 2017-03-11.
//  Copyright © 2017 Yasuhiro Inami. All rights reserved.
//

import RxSwift
import RxCocoa

/// A get-only `BehaviorRelay` that works similar to ReactiveSwift's `RxProperty`.
///
/// - Note:
/// From ver 0.3.0, this class will no longer send `.completed` when deallocated.
///
/// - SeeAlso:
///     https://github.com/ReactiveCocoa/ReactiveSwift/blob/1.1.0/Sources/Property.swift
///     https://github.com/ReactiveX/RxSwift/pull/1118 (unmerged)
public final class RxProperty<Element> {

    public typealias E = Element

    fileprivate let _behaviorRelay: BehaviorRelay<E>

    /// Gets current value.
    public var value: E {
        get {
            return _behaviorRelay.value
        }
    }

    /// Initializes with initial value.
    public init(_ value: E) {
        _behaviorRelay = BehaviorRelay(value: value)
    }

    /// Initializes with `BehaviorRelay`.
    public init(_ behaviorRelay: BehaviorRelay<E>) {
        _behaviorRelay = behaviorRelay
    }

    /// Initializes with `Variable` (DEPRECATED).
    @available(*, deprecated, message: "Use `init(_ behaviorRelay:)` instead. Note that `Variable` will not be captured.")
    public convenience init(capturing variable: Variable<E>) {
        self.init(variable)
    }

    /// Initializes with `Variable` (DEPRECATED).
    @available(*, deprecated, message: "Use `init(_ behaviorRelay:)` instead.")
    public convenience init(_ variable: Variable<E>) {
        self.init(initial: variable.value, then: variable.asObservable())
    }

    /// Initializes with `Observable` that must send at least one value synchronously.
    ///
    /// - Warning:
    /// If `unsafeObservable` fails sending at least one value synchronously,
    /// a fatal error would be raised.
    ///
    /// - Warning:
    /// If `unsafeObservable` sends multiple values synchronously,
    /// the last value will be treated as initial value of `RxProperty`.
    public convenience init(unsafeObservable: Observable<E>) {
        let observable = unsafeObservable.share(replay: 1, scope: .whileConnected)
        var initial: E? = nil

        let initialDisposable = observable
            .subscribe(onNext: { initial = $0 })

        guard let initial_ = initial else {
            fatalError("An unsafeObservable promised to send at least one value. Received none.")
        }

        self.init(initial: initial_, then: observable)

        initialDisposable.dispose()
    }

    /// Initializes with `initial` element and then `observable`.
    public init(initial: E, then observable: Observable<E>) {
        _behaviorRelay = BehaviorRelay(value: initial)

        _ = observable
            .bind(to: _behaviorRelay)
            // .disposed(by: disposeBag)    // Comment-Out: Don't dispose when `property` is deallocated
    }

    /// Observable that synchronously sends current element and then changed elements.
    /// This is same as `ReactiveSwift.Property<T>.producer`.
    public func asObservable() -> Observable<E> {
        return _behaviorRelay.asObservable()
    }

    /// Observable that only sends changed elements, ignoring current element.
    /// This is same as `ReactiveSwift.Property<T>.signal`.
    public var changed: Observable<E> {
        return asObservable().skip(1)
    }

}

/// This property wrapper allows to modify readonly property without decalring
/// additional BehaviourRelay for internal usage.
///
@propertyWrapper
final class ReadWrite<Element> {

    var wrappedValue: RxProperty<Element>

    init(wrappedValue: RxProperty<Element>) {
        self.wrappedValue = wrappedValue
    }
    
    var projectedValue: BehaviorRelay<Element> {
        return wrappedValue._behaviorRelay
    }
}
