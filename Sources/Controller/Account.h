//
//  Account.h
//  
//
//  Created by Oliver Epper on 22.08.22.
//

#ifndef Account_h
#define Account_h

#include <pjsua2.hpp>

class Account : public pj::Account {
public:
    Account(const SIPController *sipController) : _sipController{sipController} {}
    ~Account() {
        shutdown();
    }
    void onIncomingCall(pj::OnIncomingCallParam &prm) override {
        if (_sipController) [_sipController onIncomingCall:prm.callId];
    }
private:
    const SIPController *_sipController;
};

#endif /* Account_h */

