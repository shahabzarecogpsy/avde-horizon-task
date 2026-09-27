function avde_draw_history(ds,L,cfg,p,history)
% Persistent monetary evidence. Total visible rows indicate horizon:
% 4 forced + 1 free row in H1; 4 forced + 6 free rows in H6.
% Timeout rows use -Inf sentinel and are displayed as an em dash.
if p.horizon==0; totalRows=4; elseif p.horizon<=1; totalRows=L.historyRowsShort; else; totalRows=L.historyRowsLong; end
observedRows=size(history,1); Screen('TextSize',ds.win,cfg.runtime.font.history);
for row=1:totalRows
    y=L.historyTop+(row-1)*L.historyRowH;
    for source={'A','B'}
        s=source{1}; col=double(s=='B')+1; if strcmp(s,p.leftSource); x=L.leftCenterX; else; x=L.rightCenterX; end
        rect=CenterRectOnPointd([0 0 L.historyCellW L.historyCellH],x,y);
        Screen('FillRect',ds.win,cfg.display.historyFill,rect); Screen('FrameRect',ds.win,[28 30 34],rect,max(1,cfg.runtime.lineWidth-1));
        if row<=observedRows
            val=history(row,col);
            if isinf(val) && val<0; str='-'; color=[105 108 114];
            elseif isnan(val); str='XX'; color=[105 108 114];
            else; str=sprintf('%d',round(val)); color=cfg.display.historyText; end
            DrawFormattedText(ds.win,str,'center','center',color,[],[],[],[],[],rect);
        end
    end
end
end
