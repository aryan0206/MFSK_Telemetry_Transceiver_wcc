function [stream, truth, geometry] = q5c_guarded_stream(data, q, trialId)
%Q5C_GUARDED_STREAM Assemble unchanged packet with deterministic guard symbols.
arguments
    data (1,1) struct
    q (1,1) double {mustBeMember(q,[1 2])}
    trialId (1,1) double {mustBeInteger,mustBePositive}
end
seed=3000000+10000*q+trialId;
random=RandStream('mt19937ar','Seed',seed);
prefix=randi(random,[0 8]);
suffix=randi(random,[0 4]);
M=data.Mvalues(q);
ns=data.Fs/data.Rs;
indices=randi(random,M,1,prefix+suffix);
tt=(0:ns-1)'/data.Fs;
guards=sin(2*pi*tt*data.tones{q}(indices));
prefixWave=reshape(guards(:,1:prefix),1,[]);
suffixWave=reshape(guards(:,prefix+1:end),1,[]);
stream=[prefixWave data.signals{q} suffixWave];
truth=struct('frameStartBit',prefix*log2(M)+1, ...
    'payloadBits',data.frameBits(25:end-16), ...
    'payloadBytes',uint8(data.payloadText));
geometry=struct('seed',seed,'prefixSymbols',prefix,'suffixSymbols',suffix);
end
