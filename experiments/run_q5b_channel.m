function summary = run_q5b_channel(transmitterDataPath, outputDir)
%RUN_Q5B_CHANNEL Generate Q5(B) channel cases, figures and saved data.
%   SUMMARY = RUN_Q5B_CHANNEL() loads results/transmitter_data.mat from
%   this repository and writes into results/Q5B. Optional absolute paths
%   select another transmitter MAT file and output directory.
%   This runner measures channel powers; it does not compute BER or PER.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(transmitterDataPath)
    transmitterDataPath = fullfile(repoRoot, 'results', ...
        'transmitter_data.mat');
end
if nargin < 2 || isempty(outputDir)
    outputDir = fullfile(repoRoot, 'results', 'Q5B');
end
if ~isfile(transmitterDataPath)
    error('run_q5b_channel:Input', 'Missing transmitter MAT file: %s', ...
        transmitterDataPath);
end
data = load(transmitterDataPath);
required = {'signals','tones','Mvalues','Fs','Rs','fc','spacing'};
for n = 1:numel(required)
    if ~isfield(data, required{n})
        error('run_q5b_channel:Input', 'MAT file lacks %s.', required{n});
    end
end
if ~isequal(data.Mvalues, [4 8]) || numel(data.signals) ~= 2 || ...
        numel(data.tones) ~= 2 || data.Fs ~= 24000 || data.Rs ~= 300 || ...
        data.spacing ~= 300 || data.Fs/data.Rs ~= 80
    error('run_q5b_channel:Input', ...
        'Transmitter metadata does not match the Q5(A) baseline.');
end
for q = 1:2
    expectedTones = data.fc + ((0:data.Mvalues(q)-1) ...
        -(data.Mvalues(q)-1)/2)*data.spacing;
    if ~isequal(data.tones{q}, expectedTones) || ...
            ~isvector(data.signals{q}) || ...
            mod(numel(data.signals{q}), data.Fs/data.Rs) ~= 0
        error('run_q5b_channel:Input', ...
            'Signal or tone metadata is inconsistent for M=%d.', ...
            data.Mvalues(q));
    end
end

sourcePath = fullfile(repoRoot, 'src');
oldPath = path;
addpath(sourcePath);
restorePath = onCleanup(@() path(oldPath)); %#ok<NASGU>
if ~isfolder(outputDir)
    mkdir(outputDir);
end

ebn0Values = 0:2:14;
jsrValues = [-10 0 10];
baseSeed = 3128;
cases = struct([]);
records = struct([]);
representative = zeros(2,4); % no jammer, on tone, between, outside
caseId = 0;

for q = 1:2
    M = data.Mvalues(q);
    tx = data.signals{q};
    placementNames = {'none','on_tone','between_tones','outside_bank'};
    placementHz = [NaN, data.tones{q}(M/2), data.fc, ...
        max(data.tones{q})+data.spacing];
    for e = 1:numel(ebn0Values)
        for scenario = 1:10 % baseline plus 3 JSRs x 3 placements
            caseId = caseId + 1;
            params = struct('Fs',data.Fs, 'Rs',data.Rs, 'M',M, ...
                'EbN0dB',ebn0Values(e), 'seed',baseSeed+caseId);
            if scenario == 1
                placement = 1;
                params.JSRdB = -Inf;
            else
                placement = mod(scenario-2,3)+2;
                jsrIndex = floor((scenario-2)/3)+1;
                params.JSRdB = jsrValues(jsrIndex);
                params.jammerHz = placementHz(placement);
            end
            [rx, components, meta] = apply_channel(tx, params);
            cases(caseId).params = params; %#ok<AGROW>
            cases(caseId).rx = rx;
            cases(caseId).noise = components.noise;
            cases(caseId).jammer = components.jammer;
            cases(caseId).meta = meta;
            records(caseId).caseId = caseId; %#ok<AGROW>
            records(caseId).M = M;
            records(caseId).EbN0dB = params.EbN0dB;
            records(caseId).JSRdB = params.JSRdB;
            records(caseId).placement = placementNames{placement};
            records(caseId).jammerHz = placementHz(placement);
            records(caseId).seed = params.seed;
            records(caseId).signalPower = meta.signalPower;
            records(caseId).targetNoisePower = meta.targetNoisePower;
            records(caseId).measuredNoisePower = meta.measuredNoisePower;
            records(caseId).targetJammerPower = meta.targetJammerPower;
            records(caseId).measuredJammerPower = meta.measuredJammerPower;
            records(caseId).measuredJSRdB = meta.measuredJSRdB;
            if params.EbN0dB == 6 && ...
                    (scenario == 1 || params.JSRdB == 0)
                representative(q,placement) = caseId;
            end
        end
    end
end

summary = struct2table(records);
config = struct('sourceMAT', transmitterDataPath, ...
    'EbN0dB', ebn0Values, 'JSRdB', jsrValues, ...
    'baseSeed', baseSeed, 'Mvalues', data.Mvalues, ...
    'placementRule', ['none; on tone at lower center tone; between ' ...
    'center tones; one spacing above highest tone'], ...
    'representativeEbN0dB', 6, 'representativeJSRdB', 0);
save(fullfile(outputDir, 'Q5B_channel_cases.mat'), ...
    'cases', 'summary', 'config', '-v7.3');
writetable(summary, fullfile(outputDir, 'Q5B_channel_summary.csv'));

for q = 1:2
    M = data.Mvalues(q);
    tx = data.signals{q};
    make_waveform_figure(tx, cases, representative(q,:), data.Fs, ...
        data.Fs/data.Rs, M, outputDir);
    make_spectrum_figure(cases, representative(q,:), data.Fs, ...
        data.tones{q}, M, outputDir);
end
fprintf('Saved %d channel cases and Q5(B) figures in %s\n', ...
    numel(cases), outputDir);
end

function make_waveform_figure(tx, cases, indices, Fs, Ns, M, outputDir)
labels = {'No jammer','On tone','Between tones','Outside tone bank'};
sampleCount = min(3*Ns, numel(tx));
timeMs = (0:sampleCount-1)*1000/Fs;
fig = figure('Visible','off');
for p = 1:4
    subplot(4,1,p);
    plot(timeMs, tx(1:sampleCount), 'Color',[0.65 0.65 0.65]);
    hold on;
    plot(timeMs, cases(indices(p)).rx(1:sampleCount), 'b');
    hold off; grid on;
    ylabel('Amplitude');
    title(sprintf('%d-FSK: %s, E_b/N_0=6 dB', M, labels{p}));
    if p == 1
        legend('Clean TX','Received');
    end
end
xlabel('Time (ms)');
print(fig, fullfile(outputDir, sprintf('Q5B_%dFSK_received_waveforms.png',M)), ...
    '-dpng','-r200');
close(fig);
end

function make_spectrum_figure(cases, indices, Fs, tones, M, outputDir)
labels = {'No jammer','On tone','Between tones','Outside tone bank'};
fig = figure('Visible','off');
for p = 1:4
    rx = cases(indices(p)).rx;
    fftLength = 2^nextpow2(numel(rx));
    spectrum = fft(rx, fftLength);
    psd = abs(spectrum(1:fftLength/2+1)).^2/(Fs*numel(rx));
    psd(2:end-1) = 2*psd(2:end-1);
    freq = (0:fftLength/2)*Fs/fftLength;
    subplot(4,1,p);
    plot(freq, 10*log10(psd+realmin)); grid on;
    xlim([max(0,min(tones)-900), min(Fs/2,max(tones)+900)]);
    if isfinite(cases(indices(p)).meta.jammerHz)
        hold on;
        verticalRange = ylim;
        jammerHz = cases(indices(p)).meta.jammerHz;
        plot([jammerHz jammerHz], verticalRange, 'r--');
        hold off;
    end
    ylabel('dB/Hz');
    title(sprintf('%d-FSK received PSD: %s', M, labels{p}));
end
xlabel('Frequency (Hz)');
print(fig, fullfile(outputDir, sprintf('Q5B_%dFSK_received_spectra.png',M)), ...
    '-dpng','-r200');
close(fig);
end
