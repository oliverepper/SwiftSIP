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

#include <iostream>
#include <thread>


@interface SIPController ()

@property Account *account;
@property pj::ToneGenerator *toneGenerator;
@property std::vector<Call *> calls;

@end

@implementation SIPController

- (instancetype)initWithUserAgent:(NSString *)userAgent
{
    if ( self = [super init]) {
        new pj::Endpoint();
        pj::Endpoint::instance().libCreate();

        pj::EpConfig cfg;
        cfg.uaConfig.userAgent = [[userAgent copy] cStringUsingEncoding:NSUTF8StringEncoding];

        pj::Endpoint::instance().libInit(cfg);

        self.toneGenerator = new pj::ToneGenerator{};
        self.toneGenerator->createToneGenerator();
        self.toneGenerator->startTransmit(pj::Endpoint::instance().audDevManager().getPlaybackDevMedia());

        [self configureOpusWithChannelCount:1 complexity:8 andSampleRate:16000];
        
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
    self.toneGenerator->stop();
    self.toneGenerator->stopTransmit(pj::Endpoint::instance().audDevManager().getPlaybackDevMedia());
    delete self.toneGenerator;
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
    _calls.emplace_back(new Call{self, *self.account, callId});
    if (self.onIncomingCallCallback)
        self.onIncomingCallCallback(callId);
}

- (void)onCallState:(int)callId state:(pjsip_inv_state)state
{
    if (self.onCallStateCallback)
        self.onCallStateCallback(callId, state);
}

- (BOOL)callNumber:(NSString *)number onServer:(NSString *)server error:(NSError *__autoreleasing  _Nullable *)error
{
    BOOL success = YES;
    auto call = new Call{self, *self.account};
    pj::CallOpParam prm{true};
    prm.opt.videoCount = 0;
    try {
        // FIXME: create call and call.makeCall
        call->makeCall([[NSString stringWithFormat:@"<sips:%@@%@>", number, server] UTF8String], prm);
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

    _calls.push_back(call);
    [self dumpCalls];

    return success;
}

- (void)answerCallWithId:(int)callId
{
    const auto& it = std::find_if(_calls.begin(), _calls.end(), [&callId](const Call *call_ptr) {
        return call_ptr->getId() == callId;
    });
    if (it != _calls.end()) {
        pj::CallOpParam prm;
        prm.statusCode = PJSIP_SC_OK;
        (*it)->answer(prm);
    }
}

- (void)hangupCallWithId:(int)callId
{
    const auto& it = std::find_if(_calls.begin(), _calls.end(), [&callId](const Call *call_ptr) {
        return call_ptr->getId() == callId;
    });
    if (it != _calls.end()) {
        pj::CallOpParam prm;
        prm.statusCode = PJSIP_SC_DECLINE;
        (*it)->hangup(prm);
        _calls.erase(it);
    }
    NSLog(@"@@@@@ -> %lu", _calls.size());
}

- (void)playDTMF:(NSString *)DTMFDigits
{
    std::string tones = std::string{[DTMFDigits cStringUsingEncoding:NSUTF8StringEncoding]};

    // play the tones into the conf bridge via toneGenerator
    std::vector<pj::ToneDigit> digits;

    for (const char c : tones) {
        pj::ToneDigit digit{};
        digit.digit = c;
        digit.on_msec = 100;
        digit.off_msec = 20;
        digit.volume = 5000;
        digits.push_back(digit);
    }

    self.toneGenerator->playDigits(digits);

    // FIXME: play DTMF in calls
    for (auto& c : _calls) c->dialDtmf(tones);
}

- (void)dumpAccount
{
    auto info = self.account->getInfo();
    NSLog(@"Account: %s", info.uri.c_str());
}

- (void)configureOpusWithChannelCount:(int) channelCount complexity:(int)complexity andSampleRate:(int)sampleRate
{
    pj::CodecOpusConfig opusCfg = pj::Endpoint::instance().getCodecOpusConfig();
    opusCfg.channel_cnt = channelCount;
    opusCfg.complexity = complexity;
    opusCfg.sample_rate = sampleRate;
    pj::Endpoint::instance().setCodecOpusConfig(opusCfg);
}

- (void)testAudio:(int)forSeconds
{
    pj::AudioMedia& playback_dev_media = pj::Endpoint::instance().audDevManager().getPlaybackDevMedia();
    pj::AudioMedia& capture_dev_media = pj::Endpoint::instance().audDevManager().getCaptureDevMedia();

    capture_dev_media.startTransmit(playback_dev_media);
    capture_dev_media.adjustTxLevel(1.0);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(forSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        capture_dev_media.stopTransmit(playback_dev_media);
    });
}

+ (void)dumpAudioDevices
{
    int count = pjmedia_aud_dev_count();
    NSLog(@"Found %d audio devices", count);
    for (pjmedia_aud_dev_index idx = 0; idx < count; ++idx) {
        pjmedia_aud_dev_info info;
        pjmedia_aud_dev_get_info(idx, &info);
        NSLog(@"%d - %s (ins: %d, outs: %d)", idx, info.name, info.input_count, info.output_count);
    }
}

+ (void)dumpCodecs
{
    pjsua_codec_info c[32];
    unsigned i, count = PJ_ARRAY_SIZE(c);
    pj_status_t status = pjsua_enum_codecs(c, &count);

    for (int i=0; i < count; ++i) {
        printf("Codec: %s\n", pj_strbuf(&c[i].codec_id));
    }
}

- (void)dumpCalls
{
    for(const auto& c : _calls) {
        NSLog(@"@@@@@ Call id: %d", c->getId());
    }
}

@end
