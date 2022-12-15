//
//  SIPController.h
//  
//
//  Created by Oliver Epper on 22.08.22.
//

#import <Foundation/Foundation.h>
#include <pjsua.h>

NS_ASSUME_NONNULL_BEGIN

@interface SIPController : NSObject

typedef void(^OnIncomingCallCallback)(int);
typedef void(^OnCallStateCallback)(int, pjsip_inv_state);

typedef NSString * _Nonnull(^PasswordFunction)(void);

@property OnIncomingCallCallback onIncomingCallCallback;
@property OnCallStateCallback onCallStateCallback;

- (instancetype)init;
- (instancetype)initWithUserAgent:(NSString* )userAgent NS_DESIGNATED_INITIALIZER;

- (void)createTransportWithType:(pjsip_transport_type_e)type andPort:(int)port;
- (void)createTransportUsingSRVLookupWithType:(pjsip_transport_type_e)type;
- (void)createAccountOnServer:(NSString *)servername forUser:(NSString *)user withPassword:(PasswordFunction)passwordFunction;
- (void)libStart;

- (void)onIncomingCall:(pjsua_call_id)callId;
- (void)onCallState:(pjsua_call_id)callId state:(pjsip_inv_state)state;

- (BOOL)callNumber:(NSString *)number onServer:(NSString *)server error:(NSError **)error;

- (void)answerCallWithId:(int)callId;
- (void)hangupCallWithId:(int)callId;

- (void)playDTMF:(NSString *)DTMFDigits;

- (void)testAudio:(int)forSeconds;

+ (void)dumpAudioDevices;

+ (void)dumpCodecs;

@end

NS_ASSUME_NONNULL_END

