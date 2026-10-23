function checksum = crc16_ccitt_false(bytes)
%CRC16_CCITT_FALSE CRC-16: poly 1021, init FFFF, nonreflected, xorout 0000.
arguments
    bytes {mustBeNumeric,mustBeReal,mustBeFinite}
end
assert((isvector(bytes) || isempty(bytes)) && all(bytes(:)>=0 & ...
    bytes(:)<=255 & bytes(:)==fix(bytes(:))), 'q5c:Bytes','Expected byte vector.');
% Immutable lookup cache, derived once from the polynomial (not payload data).
persistent lookup
if isempty(lookup)
    lookup = zeros(1,256,'uint16');
    for n=0:255
        value=bitshift(uint16(n),8);
        for b=1:8
            top=bitget(value,16);
            value=bitshift(value,1);
            if top, value=bitxor(value,uint16(4129)); end
        end
        lookup(n+1)=value;
    end
end
checksum=uint16(65535);
for value=uint8(bytes(:).')
    index=bitxor(bitshift(checksum,-8),uint16(value));
    checksum=bitxor(bitshift(checksum,8),lookup(double(index)+1));
end
end
