function result = measure_occupied_bandwidth
%MEASURE_OCCUPIED_BANDWIDTH Equal-tail 99% positive-frequency FFT power span.
root = fileparts(fileparts(mfilename('fullpath')));
d = load(fullfile(root,'results','transmitter_data.mat'),'signals','Mvalues','Fs','Rs');
rows = struct([]);
for q = 1:numel(d.Mvalues)
    x = double(d.signals{q});
    N = 2^nextpow2(8*numel(x));
    X = fft(x,N);
    p = abs(X(1:N/2+1)).^2;
    p(2:end-1) = 2*p(2:end-1);
    cumulative = cumsum(p)/sum(p);
    f = (0:N/2)*d.Fs/N;
    lowerHz = f(find(cumulative >= 0.005,1));
    upperHz = f(find(cumulative >= 0.995,1));
    rows(q).M = d.Mvalues(q); %#ok<AGROW>
    rows(q).Rs = d.Rs;
    rows(q).grossBitRate = d.Rs*log2(d.Mvalues(q));
    rows(q).lowerHz = lowerHz;
    rows(q).upperHz = upperHz;
    rows(q).occupiedBandwidth99Hz = upperHz-lowerHz;
    rows(q).fftPoints = N;
end
result = struct2table(rows);
writetable(result,fullfile(root,'results','occupied_bandwidth_99pct.csv'));
disp(result);
end
