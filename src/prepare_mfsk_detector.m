function detector = prepare_mfsk_detector(config)
%PREPARE_MFSK_DETECTOR Validate settings and cache noncoherent references.
arguments
    config (1,1) struct
end
required = {'Fs','Rs','M','tones'};
assert(all(isfield(config,required)), 'q5c:Config', 'Missing detector settings.');
validateattributes(config.Fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(config.Rs,{'numeric'},{'scalar','real','finite','positive'});
assert(isscalar(config.M) && ismember(config.M,[4 8]), ...
    'q5c:Config','M must be 4 or 8.');
validateattributes(config.tones,{'numeric'},{'vector','real','finite','numel',config.M});
ns = config.Fs/config.Rs;
assert(abs(ns-round(ns))<1e-10, 'q5c:Config','Fs/Rs must be integral.');
tones = double(config.tones(:).');
assert(all(tones>0 & tones<config.Fs/2) && numel(unique(tones))==config.M, ...
    'q5c:Config','Tones must be distinct and strictly inside Nyquist.');
tt = (0:round(ns)-1)'/config.Fs;
detector = struct('Fs',config.Fs,'Rs',config.Rs,'M',config.M, ...
    'samplesPerSymbol',round(ns),'bitsPerSymbol',log2(config.M), ...
    'tones',tones,'reference',exp(-1i*2*pi*tt*tones));
end
