% QUESTION 5A: 4-FSK and 8-FSK transmitter. Click Run in MATLAB.
clear; clc; close all;

%% 1. Input data and settings
numbers = {'240953668','240953568','240953138','240953634'};
payloadText = strjoin(numbers, '|'); % | separates the four numbers
payloadBytes = uint8(payloadText);  % ASCII code for each character
Rs = 300;       % symbols per second
Ts = 1/Rs;      % seconds per symbol
spacing = 1/Ts; % tone spacing: 300 Hz, orthogonal over Ts
fc = 3000;      % center frequency (change this if required)
Fs = 24000;     % samples per second
Ns = Fs/Rs;     % samples per symbol: 80

%% 2. Packet = preamble + length + payload + CRC
preamble = uint8([165 90]); % hexadecimal A5 5A
lengthByte = uint8(numel(payloadBytes));
checkBytes = [lengthByte payloadBytes];

% CRC-16/CCITT-FALSE over the length and payload bytes.
% Initial value FFFF; polynomial 1021; no final XOR.
crc = uint16(65535);
for n = 1:numel(checkBytes)
    crc = bitxor(crc, bitshift(uint16(checkBytes(n)), 8));
    for b = 1:8
        if bitget(crc, 16) == 1
            crc = bitxor(bitshift(crc, 1), uint16(hex2dec('1021')));
        else
            crc = bitshift(crc, 1);
        end
    end
end
crcHigh = uint8(bitshift(crc, -8));
crcLow = uint8(bitand(crc, uint16(255)));
frameBytes = [preamble checkBytes crcHigh crcLow];

% Change every packet byte into 8 bits, most significant bit first.
frameBits = zeros(1, 8*numel(frameBytes));
position = 1;
for n = 1:numel(frameBytes)
    for bitNumber = 8:-1:1
        frameBits(position) = bitget(frameBytes(n), bitNumber);
        position = position + 1;
    end
end
fprintf('Payload: %s\n', payloadText);
fprintf('Payload = %d bytes; frame = %d bits; CRC = %s (hex)\n\n', ...
    numel(payloadBytes), numel(frameBits), dec2hex(crc,4));

%% 3. Make the 4-FSK and 8-FSK waveforms from the same packet
Mvalues = [4 8];
signals = cell(1,2);  % signals{1}: 4-FSK; signals{2}: 8-FSK
tones = cell(1,2);
symbolTones = cell(1,2);
paddingBits = zeros(1,2);

for q = 1:2
    M = Mvalues(q);
    k = log2(M);                      % 4-FSK: 2 bits; 8-FSK: 3 bits
    paddingBits(q) = mod(-numel(frameBits), k);
    bits = [frameBits zeros(1, paddingBits(q))];
    numberOfSymbols = numel(bits)/k;
    tones{q} = fc + ((0:M-1) - (M-1)/2)*spacing;
    symbolTones{q} = zeros(1, numberOfSymbols);
    signals{q} = zeros(1, numberOfSymbols*Ns);
    oneSymbolTime = (0:Ns-1)/Fs;

    for s = 1:numberOfSymbols
        bitGroup = bits((s-1)*k + (1:k));
        toneIndex = 0;
        for j = 1:k
            toneIndex = 2*toneIndex + bitGroup(j);
        end
        frequency = tones{q}(toneIndex+1); % MATLAB indexing starts at 1
        symbolTones{q}(s) = frequency;
        places = (s-1)*Ns + (1:Ns);
        signals{q}(places) = sin(2*pi*frequency*oneSymbolTime);
    end

    grossBitRate = Rs*k;
    toneSpan = (M-1)*spacing;
    approxBandwidth = toneSpan + 2/Ts; % approximate main-lobe span
    fprintf('%d-FSK tones (Hz): %s\n', M, num2str(tones{q}));
    fprintf('Rs = %.0f symbols/s; gross bit rate = %.0f bits/s\n', ...
        Rs, grossBitRate);
    fprintf('Tone span = %.0f Hz; approximate bandwidth = %.0f Hz\n', ...
        toneSpan, approxBandwidth);
    fprintf('Symbols = %d; padding = %d bits; time = %.4f s\n\n', ...
        numberOfSymbols, paddingBits(q), numberOfSymbols*Ts);
end

%% 4. Plot the tone allocation
figure(1);
for q = 1:2
    subplot(2,1,q);
    stem(0:Mvalues(q)-1, tones{q}, 'filled'); grid on;
    xlabel('Tone index'); ylabel('Frequency (Hz)');
    title(sprintf('%d-FSK tone allocation', Mvalues(q)));
end
print(figure(1), 'Fig1_Tone_Allocation.png', '-dpng', '-r200');

%% 5. Plot the first three symbols of each waveform
figure(2);
for q = 1:2
    firstSamples = 3*Ns;
    timeMs = (0:firstSamples-1)*1000/Fs;
    subplot(2,1,q);
    plot(timeMs, signals{q}(1:firstSamples)); grid on;
    xlabel('Time (ms)'); ylabel('Amplitude');
    title(sprintf('%d-FSK waveform: first three symbols', Mvalues(q)));
    hold on;
    verticalRange = ylim;
    plot([1000*Ts 1000*Ts], verticalRange, 'r--', 'LineWidth', 1.2);
    plot([2000*Ts 2000*Ts], verticalRange, 'r--', 'LineWidth', 1.2);
    hold off;
end
print(figure(2), 'Fig2_Transmit_Waveform.png', '-dpng', '-r200');

%% 6. Plot a power spectral density estimate using an FFT
figure(3);
for q = 1:2
    x = signals{q};
    fftLength = 2^nextpow2(numel(x));
    spectrum = fft(x, fftLength);
    powerDensity = abs(spectrum(1:fftLength/2+1)).^2/(Fs*numel(x));
    powerDensity(2:end-1) = 2*powerDensity(2:end-1);
    frequencyAxis = (0:fftLength/2)*Fs/fftLength;
    subplot(2,1,q);
    plot(frequencyAxis, 10*log10(powerDensity+realmin)); grid on;
    xlim([1000 5000]);
    xlabel('Frequency (Hz)'); ylabel('PSD estimate (dB/Hz)');
    title(sprintf('%d-FSK power spectral density', Mvalues(q)));
end
print(figure(3), 'Fig3_Power_Spectral_Density.png', '-dpng', '-r200');

%% 7. Save the clean signals for the group members doing B and C
save('transmitter_data.mat', 'signals', 'tones', 'symbolTones', ...
    'frameBits', 'frameBytes', 'payloadText', 'crc', 'Mvalues', ...
    'paddingBits', 'Rs', 'Fs', 'Ts', 'fc', 'spacing');
disp('Finished. Three figures and transmitter_data.mat are in Current Folder.');
