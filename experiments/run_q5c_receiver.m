function summary = run_q5c_receiver(profile, outputDir, options)
%RUN_Q5C_RECEIVER Reproducible Q5(C) demonstrations and checkpointed BER/PER.
%   RUN_Q5C_RECEIVER('smoke') uses 20 frames/condition; 'final' uses 1000.
%   Optional TrialCount/ConditionIds/StopAfter/ExportFigures support bounded tests.
arguments
    profile (1,:) char {mustBeMember(profile,{'smoke','final'})} = 'smoke'
    outputDir (1,:) char = ''
    options.TrialCount (1,1) double {mustBeInteger,mustBeNonnegative} = 0
    options.ConditionIds (1,:) double {mustBeInteger,mustBePositive} = 1:160
    options.StopAfter (1,1) double {mustBePositive} = Inf
    options.ExportFigures (1,1) logical = true
end
repoRoot=fileparts(fileparts(mfilename('fullpath')));
oldPath=path;
cleanup=onCleanup(@() path(oldPath));
addpath(fullfile(repoRoot,'src'));
if isempty(outputDir), outputDir=fullfile(repoRoot,'results','Q5C',profile); end
assert(numel(unique(options.ConditionIds))==numel(options.ConditionIds) && ...
    all(options.ConditionIds<=160),'q5c:Conditions','Invalid condition selection.');
frames=20;
if strcmp(profile,'final'), frames=1000; end
if options.TrialCount>0, frames=options.TrialCount; end
assert(frames<=1000,'q5c:Trials','TrialCount must not exceed seed partition of 1000.');
config=make_config(repoRoot,profile,frames,options.ConditionIds);
fingerprint=sha256(uint8(unicode2native(jsonencode(config),'UTF-8')));
if ~isfolder(outputDir), mkdir(outputDir); end
manifestPath=fullfile(outputDir,'configuration.mat');
if isfile(manifestPath)
    prior=load(manifestPath,'fingerprint');
    assert(strcmp(prior.fingerprint,fingerprint),'q5c:CheckpointMismatch', ...
        'Configuration or source changed. Use a separate output directory.');
else
    save(manifestPath,'config','fingerprint');
end
checkpointDir=fullfile(outputDir,'checkpoints');
if ~isfolder(checkpointDir), mkdir(checkpointDir); end
data=load(fullfile(repoRoot,'results','transmitter_data.mat'));
validate_transmitter(data);
protocol=q5c_protocol();
detectors=cell(1,2);
for q=1:2
    detectors{q}=prepare_mfsk_detector(struct('Fs',data.Fs,'Rs',data.Rs, ...
        'M',data.Mvalues(q),'tones',data.tones{q}));
end
conditions=make_conditions(data);
run_demonstrations(data,detectors,protocol,outputDir,options.ExportFigures);
review_saved_cases(repoRoot,data,detectors,protocol,outputDir);
completed=0;
started=tic;
for id=options.ConditionIds
    checkpoint=fullfile(checkpointDir,sprintf('case_%03d.mat',id));
    if isfile(checkpoint)
        prior=load(checkpoint,'fingerprint','records','condition');
        assert(strcmp(prior.fingerprint,fingerprint) && ...
            isequaln(prior.condition,conditions(id)) && ...
            isequal(size(prior.records),[frames numel(config.trialColumns)]), ...
            'q5c:CheckpointMismatch','Checkpoint mismatch in case %d.',id);
    else
        condition=conditions(id);
        records=run_condition(data,detectors{condition.q},protocol,condition,frames);
        temporary=[checkpoint '.partial'];
        save(temporary,'fingerprint','condition','records','-mat');
        movefile(temporary,checkpoint);
    end
    completed=completed+1;
    if mod(completed,10)==0 || completed==1 || completed==numel(options.ConditionIds)
        fprintf('Q5C %s: condition %d/160, %d frames; elapsed %.1f s\n', ...
            profile,id,frames,toc(started));
    end
    if completed>=options.StopAfter, break; end
end
[summary,trialOutcomes]=collect_results(checkpointDir,conditions, ...
    options.ConditionIds,config.trialColumns,frames);
save(fullfile(outputDir,'trial_outcomes.mat'),'trialOutcomes','config','fingerprint');
writetable(summary,fullfile(outputDir,'summary.csv'));
save(fullfile(outputDir,'summary.mat'),'summary','config','fingerprint');
if options.ExportFigures
    q5c_plot_results(summary,outputDir,frames);
end
write_run_info(outputDir,summary,config,toc(started));
fprintf('Q5C %s complete: %d/%d conditions, %d frames.\n', ...
    profile,height(summary),numel(options.ConditionIds),sum(summary.frames));
end

function config=make_config(root,profile,frames,ids)
sourceList=[dir(fullfile(root,'src','*.m')); ...
    dir(fullfile(root,'experiments','run_q5c_receiver.m'))];
sourceHashes=struct();
for n=1:numel(sourceList)
    entry=sourceList(n);
    sourceHashes.(matlab.lang.makeValidName(entry.name))= ...
        file_hash(fullfile(entry.folder,entry.name));
end
[status,revision]=system(sprintf('git -C "%s" rev-parse HEAD',root));
if status~=0, revision='unavailable'; end
inputNames={'transmitter_data.mat',fullfile('Q5B','Q5B_channel_cases.mat')};
inputHashes=cellfun(@(f) file_hash(fullfile(root,'results',f)),inputNames, ...
    'UniformOutput',false);
config=struct('schemaVersion',1,'profile',profile,'framesPerCondition',frames, ...
    'conditionIds',ids,'matlabRelease',version('-release'), ...
    'matlabVersion',version,'sourceRevision',strtrim(revision), ...
    'sourceHashes',sourceHashes,'inputNames',{inputNames},'inputHashes',{inputHashes}, ...
    'protocol',q5c_protocol(),'EbN0dB',0:2:14,'JSRdB',[-10 0 10], ...
    'channelSeedRule','1000000+10000*conditionId+trialId', ...
    'guardSeedRule','3000000+10000*modulationIndex+trialId', ...
    'berDefinition','Raw payload BER; known evaluation alignment; all payload bits', ...
    'perDefinition','No CRC-valid frame at correct location with exact payload', ...
    'perInterval','Two-sided 95 percent Wilson', ...
    'timingAssumption','Known symbol timing and tones; unknown frame location', ...
    'trialColumns',{{'trialId','channelSeed','guardSeed','prefixSymbols', ...
    'suffixSymbols','bitErrors','packetError','acquisitionFailure', ...
    'crcRejected','undetectedError','crcOK','startBit','preambleErrors','declaredLength'}});
end

function validate_transmitter(d)
required={'Fs','Rs','Mvalues','signals','tones','frameBits','frameBytes', ...
    'paddingBits','payloadText','crc'};
assert(all(isfield(d,required)),'q5c:Transmitter','Missing transmitter metadata.');
assert(d.Fs==24000 && d.Rs==300 && isequal(d.Mvalues,[4 8]), ...
    'q5c:Transmitter','Unexpected transmitter baseline.');
assert(isequal(d.frameBytes(1:2),uint8([165 90])) && ...
    double(d.frameBytes(3))==numel(d.payloadText) && numel(d.payloadText)==39, ...
    'q5c:Transmitter','Unexpected packet header or payload length.');
assert(isequal(uint8(d.payloadText),d.frameBytes(4:end-2)), ...
    'q5c:Transmitter','Payload metadata mismatch.');
assert(crc16_ccitt_false(d.frameBytes(3:end-2))==d.crc && ...
    d.crc==uint16(hex2dec('A327')),'q5c:Transmitter','CRC reference mismatch.');
expected=reshape(dec2bin(d.frameBytes(:),8).'-'0',1,[]);
assert(isequal(expected,d.frameBits) && numel(expected)==352, ...
    'q5c:Transmitter','Frame bit order mismatch.');
for q=1:2
    k=log2(d.Mvalues(q));
    expectedTones=3000+((0:d.Mvalues(q)-1)-(d.Mvalues(q)-1)/2)*300;
    assert(isequal(d.tones{q},expectedTones) && ...
        d.paddingBits(q)==mod(-numel(expected),k) && ...
        numel(d.signals{q})==(numel(expected)+d.paddingBits(q))/k*80, ...
        'q5c:Transmitter','Waveform metadata mismatch.');
end
end

function conditions=make_conditions(d)
blank=struct('caseId',0,'q',0,'M',0,'EbN0dB',0,'JSRdB',0,'placement','', ...
    'jammerHz',NaN);
conditions=repmat(blank,1,160);
id=0;
jsrs=[-10 0 10];
labels={'none','on_tone','between_tones','outside_bank'};
for q=1:2
    M=d.Mvalues(q);
    hz=[NaN d.tones{q}(M/2) d.fc max(d.tones{q})+d.spacing];
    for eb=0:2:14
        for scenario=1:10
            id=id+1;
            placement=1; jsr=-Inf;
            if scenario>1
                placement=mod(scenario-2,3)+2;
                jsr=jsrs(floor((scenario-2)/3)+1);
            end
            conditions(id)=struct('caseId',id,'q',q,'M',M,'EbN0dB',eb, ...
                'JSRdB',jsr,'placement',labels{placement},'jammerHz',hz(placement));
        end
    end
end
end

function records=run_condition(data,detector,protocol,c,frames)
records=zeros(frames,14);
params=struct('Fs',data.Fs,'Rs',data.Rs,'M',c.M, ...
    'EbN0dB',c.EbN0dB,'JSRdB',c.JSRdB,'jammerHz',c.jammerHz,'seed',0);
for trial=1:frames
    [tx,truth,geometry]=q5c_guarded_stream(data,c.q,trial);
    params.seed=1000000+10000*c.caseId+trial;
    rx=apply_channel(tx,params);
    bits=mfsk_detect(rx,detector);
    frame=decode_telemetry_frame(bits,protocol);
    m=evaluate_telemetry_trial(bits,frame,truth);
    records(trial,:)=[trial params.seed geometry.seed geometry.prefixSymbols ...
        geometry.suffixSymbols m.bitErrors m.packetError m.acquisitionFailure ...
        m.crcRejected m.undetectedError frame.crcOK frame.startBit ...
        frame.preambleErrors frame.declaredLength];
end
end

function [summary,outcomes]=collect_results(folder,conditions,ids,columns,frames)
records=cell(1,numel(ids));
outcomes=repmat(struct('caseId',0,'records',[]),1,numel(ids));
count=0;
for id=ids
    filename=fullfile(folder,sprintf('case_%03d.mat',id));
    if ~isfile(filename), continue; end
    loaded=load(filename,'records');
    a=loaded.records;
    c=conditions(id);
    count=count+1;
    outcomes(count)=struct('caseId',id,'records',a);
    bounds=q5c_wilson_interval(sum(a(:,7)),frames);
    records{count}=struct('caseId',id,'M',c.M,'EbN0dB',c.EbN0dB, ...
        'JSRdB',c.JSRdB,'placement',c.placement,'jammerHz',c.jammerHz, ...
        'frames',frames,'payloadBits',frames*312,'bitErrors',sum(a(:,6)), ...
        'packetErrors',sum(a(:,7)),'BER',sum(a(:,6))/(frames*312), ...
        'PER',sum(a(:,7))/frames,'PERlower95',bounds(1),'PERupper95',bounds(2), ...
        'acquisitionFailures',sum(a(:,8)),'crcRejections',sum(a(:,9)), ...
        'undetectedErrors',sum(a(:,10)));
end
outcomes=outcomes(1:count);
summary=struct2table([records{1:count}]);
assert(numel(columns)==14,'q5c:Schema','Unexpected trial schema.');
end

function run_demonstrations(data,detectors,protocol,out,exportFigures)
fid=fopen(fullfile(out,'recovery_demonstration.txt'),'w');
assert(fid~=-1,'q5c:Output','Cannot open demonstration transcript.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'Q5(C): known symbol timing; frame position unknown to receiver.\n');
fprintf(fid,'CRC check 123456789: %s (expected 29B1)\n', ...
    dec2hex(crc16_ccitt_false(uint8('123456789')),4));
assert(crc16_ccitt_false(uint8('123456789'))==hex2dec('29B1'));
for q=1:2
    bits=mfsk_detect(data.signals{q},detectors{q});
    frame=decode_telemetry_frame(bits,protocol);
    assert(frame.crcOK && strcmp(frame.payloadText,data.payloadText));
    fprintf(fid,'\n%d-FSK clean: frame start=%d, CRC=%s, recovered=%s\n', ...
        data.Mvalues(q),frame.startBit,dec2hex(frame.receivedCRC,4),frame.payloadText);
    [tx,truth,geometry]=q5c_guarded_stream(data,q,1);
    [bits,diag]=mfsk_detect(tx,detectors{q});
    frame=decode_telemetry_frame(bits,protocol);
    metric=evaluate_telemetry_trial(bits,frame,truth);
    assert(~metric.packetError && metric.bitErrors==0);
    fprintf(fid,'Guarded: prefix=%d symbols, true start=%d, detected start=%d, CRC OK=%d\n', ...
        geometry.prefixSymbols,truth.frameStartBit,frame.startBit,frame.crcOK);
    corrupt=bits;
    corrupt(truth.frameStartBit+24)=1-corrupt(truth.frameStartBit+24);
    damaged=decode_telemetry_frame(corrupt,protocol);
    assert(~damaged.crcOK);
    fprintf(fid,'Intentional payload-bit corruption: status=%s, CRC OK=%d\n', ...
        damaged.status,damaged.crcOK);
    if exportFigures
        q5c_receiver_evidence(bits,diag,frame,truth,protocol,data.Mvalues(q),out);
    end
end
end

function review_saved_cases(root,data,detectors,protocol,out)
loaded=load(fullfile(root,'results','Q5B','Q5B_channel_cases.mat'),'cases');
rows=cell(1,numel(loaded.cases));
for id=1:numel(loaded.cases)
    c=loaded.cases(id);
    q=1+(c.meta.M==8);
    bits=mfsk_detect(c.rx,detectors{q});
    frame=decode_telemetry_frame(bits,protocol);
    truth=struct('frameStartBit',1,'payloadBits',data.frameBits(25:end-16), ...
        'payloadBytes',uint8(data.payloadText));
    m=evaluate_telemetry_trial(bits,frame,truth);
    rows{id}=struct('caseId',id,'M',c.meta.M,'EbN0dB',c.params.EbN0dB, ...
        'JSRdB',c.params.JSRdB,'bitErrors',m.bitErrors,'payloadBits',m.payloadBits, ...
        'packetError',m.packetError,'status',frame.status);
end
savedCaseDiagnostics=struct2table([rows{:}]);
writetable(savedCaseDiagnostics,fullfile(out,'saved_case_diagnostics.csv'));
end

function value=file_hash(filename)
fid=fopen(filename,'rb');
assert(fid~=-1,'q5c:Input','Cannot read %s.',filename);
cleanup=onCleanup(@() fclose(fid));
value=sha256(fread(fid,Inf,'*uint8'));
end

function value=sha256(bytes)
digest=java.security.MessageDigest.getInstance('SHA-256');
digest.update(bytes);
value=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end

function write_run_info(out,summary,config,seconds)
fid=fopen(fullfile(out,'run_info.txt'),'w');
assert(fid~=-1,'q5c:Output','Cannot open run info.');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'Profile: %s\nMATLAB: %s\nConditions completed: %d of %d\n', ...
    config.profile,config.matlabRelease,height(summary),numel(config.conditionIds));
fprintf(fid,'Frames: %d\nPayload bits evaluated: %d\nElapsed processing seconds: %.3f\n', ...
    sum(summary.frames),sum(summary.payloadBits),seconds);
fprintf(fid,'BER: %s\nPER: %s\n',config.berDefinition,config.perDefinition);
fprintf(fid,'PER intervals: %s\nTiming: %s\n',config.perInterval,config.timingAssumption);
fprintf(fid,'Checkpoints resume only with matching source and configuration hashes.\n');
end
