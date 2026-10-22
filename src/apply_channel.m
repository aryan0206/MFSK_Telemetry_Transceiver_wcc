function [rx, components, meta] = apply_channel(tx, params)
%APPLY_CHANNEL Add real passband AWGN and an optional single-tone jammer.
%   [RX, COMPONENTS, META] = APPLY_CHANNEL(TX, PARAMS) accepts a real,
%   nonzero row or column waveform and preserves its size in all outputs.
%
%   Required PARAMS fields:
%     Fs           sampling frequency in Hz
%     Rs           FSK symbol rate in symbols/s
%     M            FSK order (4 or 8)
%     EbN0dB       desired Eb/N0 in dB, or +Inf for no AWGN
%     JSRdB        jammer-to-signal power ratio in dB, or -Inf for no jammer
%     seed         nonnegative integer seed for a private MT19937 stream
%   When JSRdB is finite, jammerHz is also required. Optional
%   jammerPhaseRad fixes the phase; otherwise it is drawn from the stream.
%
%   The real passband convention uses average clean-signal power Ps and
%   gross mapped-bit rate Rb = Rs*log2(M): Eb = Ps/Rb,
%   N0 = Eb/10^(EbN0dB/10), and sample noise variance = N0*Fs/2.
%   This includes preamble, CRC and padding in the gross rate. The actual
%   finite-record noise power is reported separately from its target.
%   JSR = 10*log10(Pj/Ps), with Pj measured over the finite jammer vector.

validateattributes(tx, {'numeric'}, {'vector','real','finite','nonempty'}, ...
    mfilename, 'tx', 1);
tx = double(tx);
if ~isstruct(params) || ~isscalar(params)
    error('apply_channel:Params', 'params must be a scalar struct.');
end
required = {'Fs','Rs','M','EbN0dB','JSRdB','seed'};
for n = 1:numel(required)
    if ~isfield(params, required{n})
        error('apply_channel:MissingField', 'Missing params.%s.', required{n});
    end
end
validateattributes(params.Fs, {'numeric'}, ...
    {'scalar','real','finite','positive'}, mfilename, 'params.Fs');
validateattributes(params.Rs, {'numeric'}, ...
    {'scalar','real','finite','positive'}, mfilename, 'params.Rs');
validateattributes(params.M, {'numeric'}, ...
    {'scalar','real','finite','integer'}, mfilename, 'params.M');
if ~ismember(params.M, [4 8])
    error('apply_channel:Modulation', 'M must be 4 or 8.');
end
samplesPerSymbol = params.Fs/params.Rs;
if abs(samplesPerSymbol-round(samplesPerSymbol)) > 1e-10
    error('apply_channel:Timing', 'Fs/Rs must be an integer.');
end
validateattributes(params.seed, {'numeric'}, ...
    {'scalar','real','finite','integer','>=',0,'<=',4294967295}, ...
    mfilename, 'params.seed');
if ~isnumeric(params.EbN0dB) || ~isscalar(params.EbN0dB) || ...
        ~isreal(params.EbN0dB) || isnan(params.EbN0dB) || ...
        (isinf(params.EbN0dB) && params.EbN0dB < 0)
    error('apply_channel:EbN0', 'EbN0dB must be finite or +Inf.');
end
if ~isnumeric(params.JSRdB) || ~isscalar(params.JSRdB) || ...
        ~isreal(params.JSRdB) || isnan(params.JSRdB) || ...
        (isinf(params.JSRdB) && params.JSRdB > 0)
    error('apply_channel:JSR', 'JSRdB must be finite or -Inf.');
end

jammerEnabled = isfinite(params.JSRdB);
jammerHz = NaN;
if jammerEnabled
    if ~isfield(params, 'jammerHz')
        error('apply_channel:MissingField', 'Finite JSRdB requires jammerHz.');
    end
    validateattributes(params.jammerHz, {'numeric'}, ...
        {'scalar','real','finite','>',0,'<',params.Fs/2}, ...
        mfilename, 'params.jammerHz');
    jammerHz = double(params.jammerHz);
end
if isfield(params, 'jammerPhaseRad')
    validateattributes(params.jammerPhaseRad, {'numeric'}, ...
        {'scalar','real','finite'}, mfilename, 'params.jammerPhaseRad');
end

signalPower = mean(tx(:).^2);
if signalPower <= 0
    error('apply_channel:ZeroSignal', 'tx must have nonzero average power.');
end
bitsPerSymbol = log2(double(params.M));
grossBitRate = double(params.Rs)*bitsPerSymbol;
bitEnergy = signalPower/grossBitRate;
stream = RandStream('mt19937ar', 'Seed', double(params.seed));

if isinf(params.EbN0dB)
    noiseVariance = 0;
    noise = zeros(size(tx));
else
    N0 = bitEnergy/10^(double(params.EbN0dB)/10);
    noiseVariance = N0*double(params.Fs)/2;
    if ~isfinite(noiseVariance)
        error('apply_channel:NoisePower', 'Requested noise power is not finite.');
    end
    noise = sqrt(noiseVariance)*randn(stream, size(tx));
end

jammer = zeros(size(tx));
jammerPhaseRad = NaN;
targetJammerPower = 0;
if jammerEnabled
    if isfield(params, 'jammerPhaseRad')
        jammerPhaseRad = double(params.jammerPhaseRad);
    else
        jammerPhaseRad = 2*pi*rand(stream);
    end
    sampleIndex = reshape(0:numel(tx)-1, size(tx));
    unitJammer = sin(2*pi*jammerHz*sampleIndex/double(params.Fs) ...
        + jammerPhaseRad);
    unitPower = mean(unitJammer(:).^2);
    if unitPower <= 0
        error('apply_channel:JammerPower', 'Jammer has zero sampled power.');
    end
    targetJammerPower = signalPower*10^(double(params.JSRdB)/10);
    if ~isfinite(targetJammerPower)
        error('apply_channel:JammerPower', 'Requested jammer power is not finite.');
    end
    jammer = sqrt(targetJammerPower/unitPower)*unitJammer;
end

rx = tx + noise + jammer;
components = struct('noise', noise, 'jammer', jammer);
measuredNoisePower = mean(noise(:).^2);
measuredJammerPower = mean(jammer(:).^2);
meta = struct();
meta.Fs = double(params.Fs);
meta.Rs = double(params.Rs);
meta.M = double(params.M);
meta.samplesPerSymbol = round(samplesPerSymbol);
meta.bitsPerSymbol = bitsPerSymbol;
meta.grossBitRate = grossBitRate;
meta.sampleCount = numel(tx);
meta.seed = double(params.seed);
meta.signalPower = signalPower;
meta.bitEnergy = bitEnergy;
meta.EbN0dB = double(params.EbN0dB);
meta.targetNoisePower = noiseVariance;
meta.measuredNoisePower = measuredNoisePower;
meta.JSRdB = double(params.JSRdB);
meta.jammerHz = jammerHz;
meta.jammerPhaseRad = jammerPhaseRad;
meta.targetJammerPower = targetJammerPower;
meta.measuredJammerPower = measuredJammerPower;
if measuredNoisePower > 0
    meta.measuredEbN0dB = 10*log10(bitEnergy*double(params.Fs) ...
        /(2*measuredNoisePower));
else
    meta.measuredEbN0dB = Inf;
end
if measuredJammerPower > 0
    meta.measuredJSRdB = 10*log10(measuredJammerPower/signalPower);
else
    meta.measuredJSRdB = -Inf;
end
end
