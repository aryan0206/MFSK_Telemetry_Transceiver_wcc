function tests = test_apply_channel
%TEST_APPLY_CHANNEL Function-based MATLAB test suite for Q5(B).
tests = functiontests(localfunctions);
end

function testChannelBehavior(~)
repoRoot = fileparts(fileparts(mfilename('fullpath')));
sourcePath = fullfile(repoRoot, 'src');
oldPath = path;
addpath(sourcePath);
restorePath = onCleanup(@() path(oldPath)); %#ok<NASGU>

Fs = 24000;
Rs = 300;
Ns = Fs/Rs;
sampleIndex = 0:(1000*Ns-1);
tx = sin(2*pi*2550*sampleIndex/Fs);
globalRngBefore = rng;

for M = [4 8]
    params = struct('Fs',Fs, 'Rs',Rs, 'M',M, ...
        'EbN0dB',10, 'JSRdB',0, 'jammerHz',3000, ...
        'jammerPhaseRad',0, 'seed',31415+M);
    [rx, c, meta] = apply_channel(tx, params);
    [rxAgain, cAgain, metaAgain] = apply_channel(tx, params);
    assert(isequal(rx, rxAgain) && isequal(c, cAgain) ...
        && isequal(meta, metaAgain), 'Same seed must reproduce all outputs.');
    assert(isequal(size(rx), size(tx)) && ...
        isequal(size(c.noise), size(tx)) && ...
        isequal(size(c.jammer), size(tx)), 'Waveform size changed.');
    assert(max(abs(rx-tx-c.noise-c.jammer)) < 1e-12, ...
        'Received vector does not equal its components.');
    assert(abs(meta.measuredJSRdB-params.JSRdB) < 1e-10, ...
        'Finite-record JSR calibration failed.');
    expectedNoisePower = mean(tx.^2)*Fs ...
        /(2*Rs*log2(M)*10^(params.EbN0dB/10));
    assert(abs(meta.targetNoisePower/expectedNoisePower-1) < 1e-12, ...
        'Eb/N0-to-sample-noise calibration failed.');
    assert(abs(meta.measuredNoisePower/meta.targetNoisePower-1) < 0.03, ...
        'AWGN sample power differs materially from the target.');
    assert(abs(meta.grossBitRate-Rs*log2(M)) < 1e-12, ...
        'Gross bit rate metadata is inconsistent.');
    params.seed = params.seed+1;
    rxOtherSeed = apply_channel(tx, params);
    assert(~isequal(rx, rxOtherSeed), ...
        'Different seeds unexpectedly reproduced the same waveform.');
end
assert(isequal(rng, globalRngBefore), ...
    'Channel must not change MATLAB global random state.');

params = struct('Fs',Fs, 'Rs',Rs, 'M',4, ...
    'EbN0dB',Inf, 'JSRdB',-Inf, 'seed',1);
[cleanRx, cleanC, cleanMeta] = apply_channel(tx.', params);
assert(isequal(cleanRx, tx.') && ...
    all(cleanC.noise == 0) && all(cleanC.jammer == 0) && ...
    isinf(cleanMeta.measuredEbN0dB) && ...
    isinf(cleanMeta.measuredJSRdB), ...
    'No-impairment mode must pass through a column waveform exactly.');

matPath = fullfile(repoRoot, 'results', 'transmitter_data.mat');
if isfile(matPath)
    data = load(matPath, 'signals', 'Mvalues', 'Fs', 'Rs');
    assert(isequal(data.Mvalues, [4 8]) && data.Fs == Fs && data.Rs == Rs, ...
        'Transmitter MAT metadata differs from the Q5(A) baseline.');
    for q = 1:2
        params.M = data.Mvalues(q);
        actualRx = apply_channel(data.signals{q}, params);
        assert(isequal(actualRx, double(data.signals{q})), ...
            'Channel failed clean pass-through of Q5(A) waveform.');
    end
end
end
