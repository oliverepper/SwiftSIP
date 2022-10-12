import Foundation

extension pjsip_inv_state: CustomStringConvertible {
    public var description: String {
        switch self {
        case PJSIP_INV_STATE_NULL: return "NULL"
        case PJSIP_INV_STATE_CALLING: return "CALLING"
        case PJSIP_INV_STATE_INCOMING: return "INCOMING"
        case PJSIP_INV_STATE_EARLY: return "EARLY"
        case PJSIP_INV_STATE_CONNECTING: return "CONNECTING"
        case PJSIP_INV_STATE_CONFIRMED: return "CONFIRMED"
        case PJSIP_INV_STATE_DISCONNECTED: return "DISCONNECTED"
        default:
            fatalError("Please add missing value to the switch statement in \(#fileID) \(#function)")
        }
    }
}

extension pj_str_t: CustomStringConvertible {
    public var description: String {
        UnsafeBufferPointer(start: self.ptr, count: self.slen).withMemoryRebound(to: UInt8.self) {
            return String(decoding: $0, as: UTF8.self)
        }
    }
}

extension pj_sys_info: CustomStringConvertible {
    public var description: String {
        self.info.description
    }
}
