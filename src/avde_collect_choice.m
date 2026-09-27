function [choice, e] = avde_collect_choice(ds, L, cfg, p, history, requestedOnset, progress)
% Show the choice screen at its scheduled time and adjudicate LEFT/RIGHT presses
% by their KbQueue hardware timestamps (not by polling time):
%  * valid window: onset <= t <= deadline (deadline = onset + choiceHardTimeout);
%    presses stamped before onset are logged as anticipatory and ignored; presses
%    stamped after the deadline are ignored. After the deadline the queue is
%    drained for cfg.input.postDeadlineDrain (30 ms) so a press stamped just before the
%    deadline is never lost.
%  * near-simultaneous rule: presses of BOTH keys within simultaneousWindow of each
%    other are rejected even when they arrive in different polls: a candidate press
%    is accepted only after polling has continued past t + simultaneousWindow.
%  * keyHeldAtOnset is sampled immediately AFTER the onset flip.
%  * a held key never delays the screen (KbQueue registers new presses only).
%  * RT < fastRTFlag is flagged (fastResponse) but counts.
avde_draw_base(ds, L, cfg, p, history, '', progress); avde_draw_response_cues(ds, L, cfg);
avde_kb_flush(ds);
t = avde_scheduled_flip(ds, requestedOnset); onset = t.actualOnset;
[held,~,kc] = KbCheck(ds.keyboardDeviceIndex); held = logical(held) && (kc(ds.keys.left) || kc(ds.keys.right));
win = cfg.input.simultaneousWindow; deadline = onset + cfg.timing.choiceHardTimeout; drainUntil = deadline + cfg.input.postDeadlineDrain;
choice = struct('timeout',true,'rt',NaN,'side','','source','','responseTime',NaN);
e = struct('keyHeldAtOnset',held,'anticipatoryPress',false,'simultaneousPress',false,'invalidKeyCount',0, ...
    'leftPressTime',NaN,'rightPressTime',NaN);
buf = zeros(0,2);                                   % [timestamp side(1=L,2=R)] of in-window presses
auto = avde_autopilot();
if auto
    rt = 0.35 + 0.5*rand; if rand < 0.02; rt = Inf; end
    autoT = onset + rt; autoSide = 1 + (rand < 0.5); autoDone = false;
end
while true
    now = GetSecs;
    if auto
        pressed = false; fp = zeros(1,256); lp = fp;
        if ~autoDone && now >= autoT; pressed = true; autoDone = true; fp(ds.keys.left*(autoSide==1) + ds.keys.right*(autoSide==2)) = autoT; lp = fp; end
    else
        [pressed, fp, ~, lp] = avde_kb_check(ds);
    end
    if pressed
        if fp(ds.keys.escape) > 0; error('AVDE:UserAbort','Experiment aborted by ESCAPE.'); end
        other = fp > 0; other([ds.keys.left ds.keys.right ds.keys.escape]) = false;
        e.invalidKeyCount = e.invalidKeyCount + sum(other);
        for side = 1:2
            if side == 1; k = ds.keys.left; else; k = ds.keys.right; end
            ts = fp(k); if ts <= 0; continue; end
            if ts < onset
                e.anticipatoryPress = true;
                if lp(k) >= onset; ts = lp(k); else; continue; end   % a later press of the same key in the same poll
            end
            if ts <= deadline; buf(end+1,:) = [ts side]; end %#ok<AGROW>
        end
    end
    if ~isempty(buf)
        buf = sortrows(buf,1); t1 = buf(1,1); s1 = buf(1,2);
        near = buf(:,1) <= t1 + win;
        if any(near & buf(:,2) ~= s1)
            e.simultaneousPress = true; buf = buf(~near,:); continue;      % reject both presses
        end
        if now >= t1 + win                                                % window fully observed
            if s1 == 1; e.leftPressTime = t1; choice.side = 'L'; choice.source = p.leftSource;
            else; e.rightPressTime = t1; choice.side = 'R'; choice.source = p.rightSource; end
            choice.timeout = false; choice.responseTime = t1; choice.rt = t1 - onset;
            break;
        end
    end
    if now > drainUntil; break; end
    WaitSecs('YieldSecs', 0.001);
end
e.requestedOnset = t.requestedOnset; e.actualOnset = t.actualOnset; e.stimulusOnsetTime = t.stimulusOnsetTime;
e.onsetError = t.onsetError; e.missedFrame = t.missedFrame; e.requestedDuration = cfg.timing.choiceHardTimeout;
e.timeout = choice.timeout; e.rt = choice.rt; e.responseTime = choice.responseTime;
if ~choice.timeout
    e.choice = choice.source; e.chosenSide = choice.side;
    e.chosenRewardLevel = p.(['option' choice.source 'RewardLevel']);
    e.chosenValence = p.(['option' choice.source 'Valence']);
    if p.horizon == 6; e.chosenMoreInformative = double(strcmp(choice.source, p.moreInformativeOption)); end
    e.fastResponse = choice.rt < cfg.timing.fastRTFlag;
else
    e.note = 'no valid response within deadline';
end
end
