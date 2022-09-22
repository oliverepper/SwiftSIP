//
//  SIPController.mm
//  
//
//  Created by Oliver Epper on 22.08.22.
//

#import "SIPController.h"
#import "Account.h"
#import "Call.h"

#include <pjsua2.hpp>
#include <pjsua.h>
#include <pjsua-lib/pjsua_internal.h>


@interface SIPController ()

@property Account *account;

@end

@implementation SIPController

std::vector<Call *> calls;

- (instancetype)initWithUserAgent:(NSString *)userAgent
{
    if ( self = [super init]) {
        new pj::Endpoint();
        pj::Endpoint::instance().libCreate();

        pj::EpConfig cfg;
        cfg.uaConfig.userAgent = [[userAgent copy] cStringUsingEncoding:NSUTF8StringEncoding];

        pj::Endpoint::instance().libInit(cfg);
        return self;
    }
    return nil;
}

- (instancetype)init
{
    return [self initWithUserAgent:@"PJSUA2 for 🖥 and 📱"];
}

- (void)dealloc
{
    pj::Endpoint::instance().libDestroy();
}

- (void)createTransportWithType:(pjsip_transport_type_e)type andPort:(int)port
{
    pj::TransportConfig cfg;
    cfg.port = port;
    pj::Endpoint::instance().transportCreate(type, cfg);
}

- (void)createAccountOnServer:(NSString *)servername forUser:(NSString *)user withPassword:(PasswordFunction)passwordFunction
{
    SIPController *object(self);
    self.account = new Account(object);
    pj::AccountConfig cfg;
    cfg.mediaConfig.srtpUse = PJMEDIA_SRTP_OPTIONAL;
    cfg.idUri = [[NSString stringWithFormat:@"%@<sip:%@@%@>", user, user, servername] UTF8String];
    pj::AuthCredInfo credInfo;
    credInfo.realm = "*";
    credInfo.username = [user UTF8String];
    credInfo.data = [passwordFunction() UTF8String];
    cfg.sipConfig.authCreds.push_back(credInfo);
    cfg.regConfig.registrarUri = [[NSString stringWithFormat:@"sip:%@;transport=TLS", servername] UTF8String];

    self.account->create(cfg, true);

    // FIXME: delete
    [self dumpAccount];
}

- (void)libStart
{
    pj::Endpoint::instance().libStart();
}

- (void)onIncomingCall:(int)callId
{
    calls.push_back(new Call(self, *self.account, callId));
    if (self.onIncomingCallCallback)
        self.onIncomingCallCallback(callId);
}

- (void)onCallState:(int)callId state:(pjsip_inv_state)state
{
    if (self.onCallStateCallback)
        self.onCallStateCallback(callId, state);
}

- (void)answerCall
{
    if (auto call = calls.back()) {
        pj::CallOpParam prm;
        prm.statusCode = PJSIP_SC_OK;
        call->answer(prm);
    }
}

- (void)hangupCall
{
    if (!calls.empty()) {
        auto call = calls.back();
        pj::CallOpParam prm;
        prm.statusCode = PJSIP_SC_DECLINE;
        call->hangup(prm);
        calls.pop_back();
    }
}

- (BOOL)callNumber:(NSString *)number onServer:(NSString *)server error:(NSError *__autoreleasing  _Nullable *)error
{
    BOOL success = YES;
    auto call = new Call(self, *self.account);
    pj::CallOpParam prm{true};
    try {
        call->makeCall([[NSString stringWithFormat:@"<sips:%@@%@>", number, server] UTF8String], prm);
        calls.push_back(call);
    } catch (pj::Error &pjError) {
        if (error) {
            NSString *domain = [[NSString alloc] initWithUTF8String:pjError.title.c_str()];
            NSString *desc = NSLocalizedString(([[NSString alloc] initWithUTF8String:pjError.reason.c_str()]), @"");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };

            *error = [NSError errorWithDomain:domain
                                         code:pjError.status
                                     userInfo:userInfo];
        }
        success = NO;
    }

    return success;
}

- (void)dumpAccount
{
    auto info = self.account->getInfo();
    NSLog(@"Account: %s", info.uri.c_str());
}

- (void)testAudio
{
    pj::AudioMedia& playback_dev_media = pj::Endpoint::instance().audDevManager().getPlaybackDevMedia();
    pj::AudioMedia& capture_dev_media = pj::Endpoint::instance().audDevManager().getCaptureDevMedia();

    capture_dev_media.startTransmit(playback_dev_media);
    capture_dev_media.adjustTxLevel(1.0);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        capture_dev_media.stopTransmit(playback_dev_media);
    });
}

- (void)dumpCodecs
{
    pjsua_codec_info c[32];
    unsigned i, count = PJ_ARRAY_SIZE(c);
    pj_status_t status = pjsua_enum_codecs(c, &count);

    for (int i=0; i < count; ++i) {
        printf("Codec: %s\n", pj_strbuf(&c[i].codec_id));
    }

    /* TODO: configure Opus Codec
    pj::CodecOpusConfig opus_cfg = pj::Endpoint::instance().getCodecOpusConfig();
    printf("bitrate: %d\n", opus_cfg.bit_rate);
    printf("complexity: %d\n", opus_cfg.complexity);
    printf("channel_cnt: %d\n", opus_cfg.channel_cnt);
    printf("sample_rate: %d\n", opus_cfg.sample_rate);
    printf("cbr: %d\n", opus_cfg.cbr);

    opus_cfg.channel_cnt = 1;
    opus_cfg.complexity = 8;
    opus_cfg.sample_rate = 16000;
    pj::Endpoint::instance().setCodecOpusConfig(opus_cfg);
    */
}

@end
