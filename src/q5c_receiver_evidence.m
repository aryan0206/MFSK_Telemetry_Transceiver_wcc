function q5c_receiver_evidence(bits, diagnostics, frame, truth, protocol, M, outputDir)
%Q5C_RECEIVER_EVIDENCE Plot actual preamble search and representative energies.
arguments
    bits (1,:) double
    diagnostics (1,1) struct
    frame (1,1) struct
    truth (1,1) struct
    protocol (1,1) struct
    M (1,1) double
    outputDir (1,:) char
end
fig=figure('Visible','off','Color','w','Position',[50 50 1000 700]);
theme(fig,'light');
cleanup=onCleanup(@() close(fig));
layout=tiledlayout(fig,2,1,'TileSpacing','compact');
ax=nexttile(layout);
distance=(16-conv(2*bits-1,fliplr(2*protocol.preambleBits-1),'valid'))/2;
plot(ax,1:numel(distance),distance); grid(ax,'on'); hold(ax,'on');
yline(ax,protocol.maxPreambleErrors,'--','Acceptance threshold');
xline(ax,frame.startBit,'r--');
xlabel(ax,'Candidate frame-start bit'); ylabel(ax,'Preamble bit mismatches');
title(ax,sprintf('Frame location: detected bit %d, true bit %d (evaluation only); CRC %04X passes', ...
    frame.startBit,truth.frameStartBit,frame.receivedCRC));
ax=nexttile(layout);
count=min(12,size(diagnostics.scores,1));
imagesc(ax,1:count,0:M-1,diagnostics.scores(1:count,:).');
set(ax,'YDir','normal'); colorbar(ax);
xlabel(ax,'Symbol index in received stream'); ylabel(ax,'Zero-based tone index');
title(ax,'Noncoherent tone correlation energies, clean guarded stream');
title(layout,sprintf('%d-FSK receiver evidence | known symbol timing',M));
exportgraphics(fig,fullfile(outputDir,sprintf('receiver_evidence_%dFSK.png',M)),'Resolution',180);
savefig(fig,fullfile(outputDir,sprintf('receiver_evidence_%dFSK.fig',M)));
end
