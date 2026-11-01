function summary = run_q5_end_to_end(trialsPerCase)
%RUN_Q5_END_TO_END Receiver-decision payload BER and packet error rate.
% Uses the checked-in Q5(A) MAT waveform and a fixed, recorded seed plan.
if nargin < 1, trialsPerCase = 1000; end
validateattributes(trialsPerCase,{'numeric'},{'scalar','integer','positive'});
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
data = load(fullfile(root,'results','transmitter_data.mat'));
assert(isequal(data.Mvalues,[4 8]) && data.Fs == 24000 && data.Rs == 300);
assert(numel(data.frameBits) == 352 && numel(data.payloadText) == 39);
assert(isequal(data.frameBytes(1:3),uint8([165 90 39])));
assert(crc16_ccitt_false(data.frameBytes(3:end-2)) == data.crc);
outDir = fullfile(root,'results','Q5_end_to_end');
if ~isfolder(outDir), mkdir(outDir); end
ebValues = 0:2:14;
jsrValues = [-10 0 10];
rows = struct([]);
caseId = 0;
for q = 1:2
    M = data.Mvalues(q); k = log2(M);
    tx = data.signals{q};
    cfg = struct('Fs',data.Fs,'Rs',data.Rs,'M',M,'tones',data.tones{q});
    placements = {'none','on_tone','between_tones','outside_bank'};
    frequencies = [NaN,data.tones{q}(M/2),data.fc,max(data.tones{q})+data.spacing];
    for e = 1:numel(ebValues)
        for scenario = 1:10
            caseId = caseId+1;
            if scenario == 1
                p = 1; jsr = -Inf;
            else
                p = mod(scenario-2,3)+2;
                jsr = jsrValues(floor((scenario-2)/3)+1);
            end
            bitErrors = 0; packetErrors = 0; crcPasses = 0; syncPasses = 0;
            for trial = 1:trialsPerCase
                seed = 100000 + (caseId-1)*trialsPerCase + trial;
                params = struct('Fs',data.Fs,'Rs',data.Rs,'M',M, ...
                    'EbN0dB',ebValues(e),'JSRdB',jsr,'seed',seed);
                if isfinite(jsr), params.jammerHz = frequencies(p); end
                rx = apply_channel(tx,params);
                decoded = receive_mfsk_packet(rx,cfg);
                % The simulation knows the transmitted sample alignment. BER
                % compares payload decisions at that alignment, even if
                % autonomous frame acquisition fails. PER includes that failure.
                payloadRange = 25:(24+8*numel(data.payloadText));
                bitErrors = bitErrors + sum(decoded.bits(payloadRange) ...
                    ~= data.frameBits(payloadRange));
                syncPasses = syncPasses + decoded.syncFound;
                crcPasses = crcPasses + decoded.crcValid;
                valid = decoded.packetValid && decoded.length == 39 ...
                    && isequal(decoded.payloadBytes,data.frameBytes(4:end-2));
                packetErrors = packetErrors + ~valid;
            end
            rows(caseId).caseId = caseId; %#ok<AGROW>
            rows(caseId).M = M;
            rows(caseId).EbN0dB = ebValues(e);
            rows(caseId).JSRdB = jsr;
            rows(caseId).placement = placements{p};
            rows(caseId).jammerHz = frequencies(p);
            rows(caseId).trials = trialsPerCase;
            rows(caseId).firstSeed = 100000+(caseId-1)*trialsPerCase+1;
            rows(caseId).lastSeed = 100000+caseId*trialsPerCase;
            rows(caseId).bitErrors = bitErrors;
            rows(caseId).payloadBits = trialsPerCase*8*numel(data.payloadText);
            rows(caseId).BER = bitErrors/rows(caseId).payloadBits;
            rows(caseId).packetErrors = packetErrors;
            rows(caseId).PER = packetErrors/trialsPerCase;
            rows(caseId).syncPasses = syncPasses;
            rows(caseId).crcPasses = crcPasses;
        end
    end
end
summary = struct2table(rows);
writetable(summary,fullfile(outDir,'end_to_end_summary.csv'));
config = struct('trialsPerCase',trialsPerCase,'EbN0dB',ebValues, ...
    'JSRdB',jsrValues,'seedRule','100000+(caseId-1)*trialsPerCase+trial', ...
    'BERDefinition','payload tone decisions at true simulation alignment', ...
    'PERDefinition','failed sync, CRC, length, or payload comparison');
save(fullfile(outDir,'end_to_end_results.mat'),'summary','config');
for metric = {'BER','PER'}
    fig = figure('Visible','off'); hold on;
    for q = 1:2
        M = data.Mvalues(q);
        baseline = summary.M == M & strcmp(summary.placement,'none');
        plot(summary.EbN0dB(baseline),summary.(metric{1})(baseline), ...
            '-o','DisplayName',sprintf('%d-FSK AWGN',M));
        jammed = summary.M == M & summary.JSRdB == 0 ...
            & strcmp(summary.placement,'on_tone');
        plot(summary.EbN0dB(jammed),summary.(metric{1})(jammed), ...
            '--s','DisplayName',sprintf('%d-FSK on-tone JSR 0 dB',M));
    end
    grid on; xlabel('E_b/N_0 (dB)'); ylabel(metric{1});
    ylim([0 1]); legend('Location','best');
    title(sprintf('Receiver %s (%d trials per condition)',metric{1},trialsPerCase));
    print(fig,fullfile(outDir,[metric{1} '_vs_EbN0.png']),'-dpng','-r200');
    close(fig);
end
fig = figure('Visible','off');
for q = 1:2
    subplot(1,2,q); hold on;
    M = data.Mvalues(q);
    names = {'on_tone','between_tones','outside_bank'};
    for p = 1:3
        pick = summary.M == M & summary.JSRdB == 0 ...
            & strcmp(summary.placement,names{p});
        plot(summary.EbN0dB(pick),summary.PER(pick),'-o', ...
            'DisplayName',strrep(names{p},'_',' '));
    end
    grid on; ylim([0 1]); xlabel('E_b/N_0 (dB)'); ylabel('PER');
    title(sprintf('%d-FSK, JSR 0 dB',M)); legend('Location','best');
end
print(fig,fullfile(outDir,'PER_by_placement_JSR0.png'),'-dpng','-r200');
close(fig);
fig = figure('Visible','off');
for q = 1:2
    subplot(1,2,q); hold on;
    M = data.Mvalues(q);
    for p = 1:3
        pick = summary.M == M & summary.EbN0dB == 8 ...
            & strcmp(summary.placement,names{p});
        plot(summary.JSRdB(pick),summary.BER(pick),'-o', ...
            'DisplayName',strrep(names{p},'_',' '));
    end
    grid on; xlabel('JSR (dB)'); ylabel('BER'); ylim([0 1]);
    title(sprintf('%d-FSK, E_b/N_0 8 dB',M)); legend('Location','best');
end
print(fig,fullfile(outDir,'BER_by_JSR_EbN0_8.png'),'-dpng','-r200');
close(fig);
fprintf('Saved %d conditions, %d trials each to %s\n',height(summary),trialsPerCase,outDir);
end
