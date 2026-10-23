function metrics = evaluate_telemetry_trial(decodedBits, frame, truth)
%EVALUATE_TELEMETRY_TRIAL Ground-truth scoring, kept outside receiver logic.
arguments
    decodedBits {mustBeNumeric,mustBeReal,mustBeFinite}
    frame (1,1) struct
    truth (1,1) struct
end
assert(isvector(decodedBits) && all(decodedBits(:)==0 | decodedBits(:)==1), ...
    'q5c:Bits','Expected a binary detected-bit vector.');
decodedBits=double(decodedBits(:).');
truth.payloadBits=double(truth.payloadBits(:).');
validateattributes(truth.frameStartBit,{'numeric'}, ...
    {'scalar','integer','positive'});
payloadStart=truth.frameStartBit+24;
payloadEnd=payloadStart+numel(truth.payloadBits)-1;
assert(payloadEnd<=numel(decodedBits),'q5c:Truth','Payload outside received bits.');
accepted=strcmp(frame.status,'ok') && frame.crcOK;
correct=accepted && frame.startBit==truth.frameStartBit && ...
    isequal(frame.payloadBytes(:).',truth.payloadBytes(:).');
metrics=struct('bitErrors',sum(decodedBits(payloadStart:payloadEnd)~=truth.payloadBits), ...
    'payloadBits',numel(truth.payloadBits),'packetError',~correct, ...
    'acquisitionFailure',ismember(frame.status,{'no_preamble','truncated'}), ...
    'crcRejected',strcmp(frame.status,'crc_failed'), ...
    'undetectedError',accepted && ~correct);
end
