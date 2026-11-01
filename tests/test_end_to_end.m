function tests = test_end_to_end
tests = functiontests(localfunctions);
end

function testCleanAndCorrupt(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
d = load(fullfile(root,'results','transmitter_data.mat'));
verifyEqual(testCase,numel(d.frameBytes),44);
verifyEqual(testCase,d.frameBytes(1:3),uint8([165 90 39]));
verifyEqual(testCase,crc16_ccitt_false(uint8('123456789')),uint16(hex2dec('29B1')));
verifyEqual(testCase,crc16_ccitt_false(d.frameBytes(3:end-2)),d.crc);
for q = 1:2
    M = d.Mvalues(q);
    cfg = struct('Fs',d.Fs,'Rs',d.Rs,'M',M,'tones',d.tones{q});
    params = struct('Fs',d.Fs,'Rs',d.Rs,'M',M, ...
        'EbN0dB',Inf,'JSRdB',-Inf,'seed',42);
    clean = receive_mfsk_packet(apply_channel(d.signals{q},params),cfg);
    verifyTrue(testCase,clean.packetValid);
    verifyEqual(testCase,clean.payloadBytes,d.frameBytes(4:end-2));
    verifyEqual(testCase,clean.bits(1:352),d.frameBits);
    prefixed = receive_mfsk_packet([zeros(1,80) d.signals{q}],cfg);
    verifyTrue(testCase,prefixed.packetValid);
    verifyEqual(testCase,prefixed.frameStartSymbol,2);
    altered = d.signals{q};
    symbol = ceil(40/log2(M));
    indices = (symbol-1)*80+(1:80);
    otherTone = d.tones{q}(find(d.tones{q} ~= d.symbolTones{q}(symbol),1));
    altered(indices) = sin(2*pi*otherTone*(0:79)/d.Fs);
    damaged = receive_mfsk_packet(altered,cfg);
    verifyFalse(testCase,damaged.packetValid);
end
end
