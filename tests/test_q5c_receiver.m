function tests = test_q5c_receiver
%TEST_Q5C_RECEIVER Receiver, protocol, evaluator and experiment acceptance tests.
tests=functiontests(localfunctions);
end

function setupOnce(t)
root=fileparts(fileparts(mfilename('fullpath')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'src')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'experiments')));
t.TestData.root=root;
t.TestData.data=load(fullfile(root,'results','transmitter_data.mat'));
end

function testCRCReferenceVectors(t)
t.verifyEqual(crc16_ccitt_false(uint8('123456789')),uint16(hex2dec('29B1')));
d=t.TestData.data;
t.verifyEqual(crc16_ccitt_false(d.frameBytes(3:end-2)),uint16(hex2dec('A327')));
t.verifyError(@() crc16_ccitt_false([0 256]),'q5c:Bytes');
end

function testCleanBothModulations(t)
d=t.TestData.data;
for q=1:2
    detector=make_detector(d,q);
    bits=mfsk_detect(d.signals{q},detector);
    t.verifyEqual(bits,[d.frameBits zeros(1,d.paddingBits(q))]);
    t.verifyEqual(mfsk_detect(d.signals{q}.',detector),bits);
    frame=decode_telemetry_frame(bits,q5c_protocol());
    t.verifyTrue(frame.crcOK);
    t.verifyEqual(frame.payloadText,d.payloadText);
    t.verifyEqual(frame.startBit,1);
end
end

function testEveryToneAndMapping(t)
d=t.TestData.data;
for q=1:2
    detector=make_detector(d,q);
    wave=reshape(sin(2*pi*(0:79)'/d.Fs*d.tones{q}),1,[]);
    [bits,diagnostics]=mfsk_detect(wave,detector);
    t.verifyEqual(diagnostics.toneIndices,(1:d.Mvalues(q)).');
    t.verifyEqual(bits,reshape(dec2bin(0:d.Mvalues(q)-1,log2(d.Mvalues(q))).'-'0',1,[]));
end
end

function testPhaseInsensitiveDetection(t)
d=t.TestData.data;
for q=1:2
    detector=make_detector(d,q);
    expected=reshape(dec2bin(0:d.Mvalues(q)-1,log2(d.Mvalues(q))).'-'0',1,[]);
    for phase=[pi/3 pi/2 pi]
        wave=reshape(sin(2*pi*(0:79)'/d.Fs*d.tones{q}+phase),1,[]);
        t.verifyEqual(mfsk_detect(wave,detector),expected);
    end
end
end

function testInputValidation(t)
detector=make_detector(t.TestData.data,1);
t.verifyError(@() mfsk_detect(ones(3,3),detector),'q5c:Waveform');
t.verifyError(@() mfsk_detect(ones(1,81),detector),'q5c:IncompleteSymbol');
t.verifyError(@() mfsk_detect([NaN zeros(1,79)],detector),'MATLAB:validators:mustBeFinite');
t.verifyError(@() mfsk_detect([Inf zeros(1,79)],detector),'MATLAB:validators:mustBeFinite');
t.verifyError(@() decode_telemetry_frame([0 2 1],q5c_protocol()),'q5c:Bits');
t.verifyError(@() prepare_mfsk_detector(struct()),'q5c:Config');
end

function testGuardVariationAndRandomIsolation(t)
d=t.TestData.data;
before=rng;
prefixes=zeros(1,40);
for q=1:2
    detector=make_detector(d,q);
    for trial=1:40
        [tx,truth,geometry]=q5c_guarded_stream(d,q,trial);
        prefixes(trial)=geometry.prefixSymbols;
        bits=mfsk_detect(tx,detector);
        frame=decode_telemetry_frame(bits,q5c_protocol());
        result=evaluate_telemetry_trial(bits,frame,truth);
        t.verifyFalse(result.packetError);
        t.verifyEqual(frame.startBit,truth.frameStartBit);
    end
end
t.verifyGreaterThan(numel(unique(prefixes)),1);
t.verifyEqual(rng,before);
end

function testPreambleTolerance(t)
bits=t.TestData.data.frameBits;
bits([1 8])=1-bits([1 8]);
frame=decode_telemetry_frame(bits,q5c_protocol());
t.verifyTrue(frame.crcOK);
t.verifyEqual(frame.preambleErrors,2);
end

function testFalseCandidateBeforeValidFrame(t)
d=t.TestData.data;
falseFrame=d.frameBits;
falseFrame(25)=1-falseFrame(25);
frame=decode_telemetry_frame([falseFrame d.frameBits],q5c_protocol());
t.verifyTrue(frame.crcOK);
t.verifyEqual(frame.startBit,numel(falseFrame)+1);
end

function testCorruptionAndTruncation(t)
d=t.TestData.data;
p=q5c_protocol();
for offset=[25 numel(d.frameBits)]
    bits=d.frameBits; bits(offset)=1-bits(offset);
    frame=decode_telemetry_frame(bits,p);
    t.verifyFalse(frame.crcOK);
    t.verifyEqual(frame.status,'crc_failed');
end
frame=decode_telemetry_frame(zeros(1,60),p);
t.verifyEqual(frame.status,'no_preamble');
for stop=[18 40 351]
    frame=decode_telemetry_frame(d.frameBits(1:stop),p);
    t.verifyFalse(frame.crcOK);
    t.verifyEqual(frame.status,'truncated');
end
bits=d.frameBits;bits(17:24)=1;
frame=decode_telemetry_frame(bits,p);
t.verifyFalse(frame.crcOK);
t.verifyEqual(frame.status,'truncated');
end

function testMetricsCoverFailures(t)
d=t.TestData.data;
bits=d.frameBits;
truth=struct('frameStartBit',1,'payloadBits',bits(25:end-16),'payloadBytes',uint8(d.payloadText));
frame=decode_telemetry_frame(bits,q5c_protocol());
result=evaluate_telemetry_trial(bits,frame,truth);
t.verifyEqual(result.bitErrors,0);t.verifyFalse(result.packetError);
t.verifyEqual(evaluate_telemetry_trial(bits.',frame,truth),result);
bits(25)=1-bits(25);frame.status='no_preamble';frame.crcOK=false;
result=evaluate_telemetry_trial(bits,frame,truth);
t.verifyEqual(result.bitErrors,1);t.verifyTrue(result.acquisitionFailure);
t.verifyTrue(result.packetError);
frame.status='crc_failed';
result=evaluate_telemetry_trial(bits,frame,truth);
t.verifyTrue(result.crcRejected);
frame.status='ok';frame.crcOK=true;frame.payloadBytes(1)=0;
result=evaluate_telemetry_trial(bits,frame,truth);
t.verifyTrue(result.undetectedError);t.verifyTrue(result.packetError);
end

function testNoGroundTruthInReceiverConfig(t)
detector=make_detector(t.TestData.data,1);
t.verifyEqual(sort(fieldnames(q5c_protocol())),sort({'preambleBits';'maxPreambleErrors'}));
t.verifyFalse(any(ismember(fieldnames(detector),{'payloadText','payloadBytes','frameStartBit'})));
end

function testWilsonBounds(t)
t.verifyEqual(q5c_wilson_interval(0,1000),[0 0.003826758485555], 'AbsTol',1e-12);
b=q5c_wilson_interval(1000,1000);
t.verifyEqual(b,[1-0.003826758485555 1],'AbsTol',1e-12);
end

function testResumeAndConfigurationMismatch(t)
first=tempname;second=tempname;
t.addTeardown(@() remove_folder(first));t.addTeardown(@() remove_folder(second));
before=rng;
run_q5c_receiver('smoke',first,TrialCount=3,ConditionIds=[1 81],StopAfter=1,ExportFigures=false);
resumed=run_q5c_receiver('smoke',first,TrialCount=3,ConditionIds=[1 81],ExportFigures=false);
fresh=run_q5c_receiver('smoke',second,TrialCount=3,ConditionIds=[1 81],ExportFigures=false);
t.verifyTrue(isequaln(resumed,fresh));
a=load(fullfile(first,'trial_outcomes.mat'),'trialOutcomes');
b=load(fullfile(second,'trial_outcomes.mat'),'trialOutcomes');
t.verifyTrue(isequaln(a,b));t.verifyEqual(rng,before);
t.verifyError(@() run_q5c_receiver('smoke',first,TrialCount=4, ...
    ConditionIds=[1 81],ExportFigures=false),'q5c:CheckpointMismatch');
end

function detector=make_detector(d,q)
detector=prepare_mfsk_detector(struct('Fs',d.Fs,'Rs',d.Rs,'M',d.Mvalues(q),'tones',d.tones{q}));
end

function remove_folder(folder)
if isfolder(folder), rmdir(folder,'s'); end
end
