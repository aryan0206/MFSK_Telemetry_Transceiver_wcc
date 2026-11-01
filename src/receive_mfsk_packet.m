function out = receive_mfsk_packet(rx, cfg)
%RECEIVE_MFSK_PACKET Noncoherent tone detection and framed packet recovery.
% Assumes known Fs, Rs, tone bank, and sample timing (full-symbol prefix OK).
% Searches the detected bit stream for A5 5A at symbol-aligned starts.
required = {'Fs','Rs','M','tones'};
for i = 1:numel(required)
    if ~isfield(cfg,required{i}), error('receive_mfsk_packet:Config','Missing %s',required{i}); end
end
validateattributes(rx,{'numeric'},{'vector','real','finite','nonempty'});
Ns = cfg.Fs/cfg.Rs;
if Ns ~= round(Ns) || ~ismember(cfg.M,[4 8]) || numel(cfg.tones) ~= cfg.M
    error('receive_mfsk_packet:Config','Invalid symbol timing or tone bank');
end
Ns = round(Ns); k = log2(cfg.M);
count = floor(numel(rx)/Ns);
samples = reshape(double(rx(1:count*Ns)),Ns,count);
t = (0:Ns-1)'/cfg.Fs;
scores = zeros(cfg.M,count);
for tone = 1:cfg.M
    c = cos(2*pi*cfg.tones(tone)*t);
    s = sin(2*pi*cfg.tones(tone)*t);
    scores(tone,:) = (c'*samples).^2 + (s'*samples).^2;
end
[~,decisions] = max(scores,[],1);
values = uint16(decisions-1);
bits = zeros(1,count*k);
for j = 1:k
    bits(j:k:end) = bitget(values,k-j+1);
end
out = struct('bits',bits,'symbolDecisions',decisions,'scores',scores, ...
    'syncFound',false,'crcValid',false,'packetValid',false, ...
    'frameStartSymbol',NaN,'length',NaN,'payloadBytes',uint8([]), ...
    'payloadText','');
sync = [1 0 1 0 0 1 0 1 0 1 0 1 1 0 1 0];
for startSymbol = 1:count
    first = (startSymbol-1)*k+1;
    if first+23 > numel(bits) || ~isequal(bits(first:first+15),sync)
        continue
    end
    out.syncFound = true;
    out.frameStartSymbol = startSymbol;
    lengthByte = bits_to_bytes(bits(first+16:first+23));
    nPayload = double(lengthByte);
    endBit = first + 8*(2+1+nPayload+2)-1;
    if endBit > numel(bits)
        continue
    end
    packet = bits_to_bytes(bits(first:endBit));
    check = crc16_ccitt_false(packet(3:end-2));
    receivedCrc = bitor(bitshift(uint16(packet(end-1)),8),uint16(packet(end)));
    out.length = nPayload;
    out.payloadBytes = packet(4:end-2);
    out.payloadText = char(out.payloadBytes);
    out.crcValid = check == receivedCrc;
    out.packetValid = out.crcValid;
    if out.packetValid, return; end
end
end

function bytes = bits_to_bytes(bits)
bits = reshape(bits,8,[])';
bytes = uint8(bits * (2.^(7:-1:0))');
bytes = bytes';
end
