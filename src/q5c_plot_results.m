function q5c_plot_results(summary, outputDir, frames)
%Q5C_PLOT_RESULTS Export BER/PER evidence without inventing nonzero BER values.
arguments
    summary table
    outputDir (1,:) char
    frames (1,1) double {mustBePositive}
end
zeroRows=summary(summary.bitErrors==0,:);
writetable(zeroRows,fullfile(outputDir,'zero_error_observations.csv'));
placements={'none','on_tone','between_tones','outside_bank'};
labels={'AWGN only','On tone','Between tones','Outside tone bank'};
for M=[4 8]
    for metric={'BER','PER'}
        name=metric{1};
        fig=figure('Visible','off','Color','w','Position',[50 50 1200 850]);
        theme(fig,'light');
        cleanup=onCleanup(@() close(fig));
        layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
        for p=1:4
            ax=nexttile(layout);
            hold(ax,'on'); grid(ax,'on');
            ax.ColorOrder=[0 0.35 0.7; 0.85 0.325 0.098; 0.15 0.5 0.25];
            lineStyles={'-o','--s',':^'};
            if strcmp(name,'BER'), set(ax,'YScale','log'); end
            jsrs=[-10 0 10];
            if p==1, jsrs=-Inf; end
            zerosText={};
            for j=1:numel(jsrs)
                row=summary(summary.M==M & strcmp(summary.placement,placements{p}) ...
                    & summary.JSRdB==jsrs(j),:);
                row=sortrows(row,'EbN0dB');
                values=row.(name);
                if isempty(values), continue; end
                legendText=sprintf('JSR %+g dB',jsrs(j));
                if p==1, legendText='No jammer'; end
                if strcmp(name,'BER')
                    zero=row.EbN0dB(values==0);
                    values(values==0)=NaN;
                    if ~isempty(zero)
                        zerosText{end+1}=sprintf('%s: zero errors at %s dB', ...
                            legendText,strtrim(sprintf('%g ',zero))); %#ok<AGROW>
                    end
                    plot(ax,row.EbN0dB,values,lineStyles{j},'DisplayName',legendText,'LineWidth',1.2);
                else
                    errorbar(ax,row.EbN0dB,values,values-row.PERlower95, ...
                        row.PERupper95-values,lineStyles{j},'DisplayName',legendText,'LineWidth',1.2);
                end
            end
            xlabel(ax,'E_b/N_0 (dB)');
            if strcmp(name,'BER')
                ylabel(ax,'Raw payload BER');
                ylim(ax,[1/(312*frames) 1]);
                if ~isempty(zerosText)
                    text(ax,0.02,0.03,strjoin(zerosText,newline),'Units','normalized', ...
                        'FontSize',8,'VerticalAlignment','bottom','Interpreter','none');
                end
            else
                ylabel(ax,'End-to-end PER (95% Wilson intervals)');
                ylim(ax,[0 1]);
            end
            title(ax,labels{p});
            xlim(ax,[0 14]); xticks(ax,0:2:14);
            legend(ax,'Location','northoutside','Orientation','horizontal','FontSize',8);
        end
        title(layout,sprintf('%d-FSK %s | %d frames and %d payload bits per point', ...
            M,name,frames,312*frames));
        if strcmp(name,'BER')
            subtitle(layout,'Gross transmitted-bit Eb/N0; known evaluation alignment. Zero-error BER points omitted on log axes and listed in-panel / CSV.');
        else
            subtitle(layout,'Includes acquisition failures, CRC rejections and accepted-but-incorrect packets.');
        end
        exportgraphics(fig,fullfile(outputDir,sprintf('%s_%dFSK.png',name,M)),'Resolution',180);
        savefig(fig,fullfile(outputDir,sprintf('%s_%dFSK.fig',name,M)));
    end
end
end
