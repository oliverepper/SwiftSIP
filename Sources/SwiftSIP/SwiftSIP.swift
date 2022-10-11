import Combine
@_exported import Controller

public struct SwiftSIP {
    public private(set) var controller = SIPController(userAgent: "✌️")
    private var incomingCallSubject = PassthroughSubject<Int32, Never>()
    private var callSubject = PassthroughSubject<(callId: Int32, state: pjsip_inv_state), Never>()

    public init() {
        setup()
    }

    private func setup() {
        controller.onIncomingCallCallback = { callId in
            incomingCallSubject.send(callId)
        }

        controller.onCallStateCallback = { (callId, state) in
            callSubject.send((callId, state))
        }
    }

    public func incomingCalls() -> AnyPublisher<Int32, Never> {
        incomingCallSubject.eraseToAnyPublisher()
    }

    public func callState() -> AnyPublisher<(callId: Int32, state: pjsip_inv_state), Never> {
        callSubject.eraseToAnyPublisher()
    }
}

