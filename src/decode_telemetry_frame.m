function frame = decode_telemetry_frame(bits, protocol)
%DECODE_TELEMETRY_FRAME Search preambles, parse length, and validate CRC.
arguments
    bits {mustBeNumeric,mustBeReal,mustBeFinite}
    protocol (1,1) struct
end
assert(isvector(bits) && all(bits(:)==0 | bits(:)==1), ...
    'q5c:Bits','Expected nonempty binary vector.');
bits=double(bits(:).');
preamble=protocol.preambleBits;
assert(isequal(size(preamble),[1 16]) && all(preamble==0 | preamble==1), ...
    'q5c:Protocol','Expected 16-bit binary preamble.');
validateattributes(protocol.maxPreambleErrors,{'numeric'}, ...
    {'scalar','integer','>=',0,'<=',16});
frame=empty_frame();
if numel(bits)<16, return; end
mismatch=(16-conv(2*bits-1,fliplr(2*preamble-1),'valid'))/2;
starts=find(mismatch<=protocol.maxPreambleErrors);
if isempty(starts), return; end
[~,order]=sortrows([mismatch(starts).' starts.'],[1 2]);
starts=starts(order);
frame.candidateCount=numel(starts);
frame.status='truncated';
frame.startBit=starts(1);
frame.preambleErrors=mismatch(starts(1));
haveComplete=false;
for start=starts
    if start+23>numel(bits), continue; end
    declared=bits_to_bytes(bits(start+16:start+23));
    last=start+16+8+8*double(declared)+16-1;
    if last>numel(bits), continue; end
    bytes=bits_to_bytes(bits(start+16:last));
    received=bitor(bitshift(uint16(bytes(end-1)),8),uint16(bytes(end)));
    calculated=crc16_ccitt_false(bytes(1:end-2));
    candidate=empty_frame();
    candidate.status='crc_failed';
    candidate.startBit=start;
    candidate.preambleErrors=mismatch(start);
    candidate.declaredLength=double(declared);
    candidate.payloadBytes=bytes(2:end-2);
    candidate.payloadText=char(candidate.payloadBytes);
    candidate.receivedCRC=received;
    candidate.calculatedCRC=calculated;
    candidate.crcOK=(received==calculated);
    candidate.candidateCount=numel(starts);
    if ~haveComplete
        frame=candidate;
        haveComplete=true;
    end
    if candidate.crcOK
        candidate.status='ok';
        frame=candidate;
        return;
    end
end
end

function bytes=bits_to_bytes(bits)
bytes=uint8(reshape(bits,8,[]).'*(2.^(7:-1:0)).').';
end

function frame=empty_frame()
frame=struct('status','no_preamble','startBit',NaN,'preambleErrors',NaN, ...
    'declaredLength',NaN,'payloadBytes',uint8([]),'payloadText','', ...
    'receivedCRC',uint16(0),'calculatedCRC',uint16(0), ...
    'crcOK',false,'candidateCount',0);
end
