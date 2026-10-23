function [bits, diagnostics] = mfsk_detect(rx, detector)
%MFSK_DETECT Detect complete, aligned real-passband symbols; return row bits.
arguments
    rx {mustBeNumeric,mustBeReal,mustBeFinite}
    detector (1,1) struct
end
assert(isvector(rx) && ~isempty(rx), 'q5c:Waveform','rx must be a nonempty vector.');
ns = detector.samplesPerSymbol;
assert(mod(numel(rx),ns)==0,'q5c:IncompleteSymbol','Incomplete symbol block.');
blocks = reshape(double(rx),ns,[]);
scores = abs(blocks.'*detector.reference).^2;
[~, indices] = max(scores,[],2);
k = detector.bitsPerSymbol;
% Power-of-two division gives exact fixed-width mapping without strings.
bitRows = mod(floor((indices-1)./(2.^(k-1:-1:0))),2);
bits = reshape(double(bitRows.'),1,[]);
if nargout>1
    diagnostics = struct('toneIndices',indices,'scores',scores);
end
end
