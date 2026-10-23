function protocol = q5c_protocol()
%Q5C_PROTOCOL Public frame convention; contains no reference payload or offset.
protocol=struct('preambleBits',reshape(dec2bin([165;90],8).'-'0',1,[]), ...
    'maxPreambleErrors',2);
end
