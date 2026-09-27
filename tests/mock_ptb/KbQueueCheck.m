function [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck(varargin)
global AVDE_MOCK
mock_advance();
firstPress = zeros(1,256); firstRelease = firstPress; lastPress = firstPress; lastRelease = firstPress; pressed = false;
st = dbstack; names = {st.name};
if any(strcmp(names,'avde_collect_choice'))
    T = AVDE_MOCK.trial; P = T.presses; und = find(~T.delivered);
    if isempty(und)   % poll at 1 ms until the adjudication window has passed, then coarser
        if AVDE_MOCK.V > max([P(:,1); T.onset]) + 0.05 && AVDE_MOCK.V < T.onset + 3.9; AVDE_MOCK.yield = 0.05; else; AVDE_MOCK.yield = 0.001; end   % 1 ms polling near the deadline, as on real hardware
        return;
    end
    due = und(P(und,1) <= AVDE_MOCK.V);
    if isempty(due)                                   % nothing yet: wait (jump) to the next press
        [~,j] = min(P(und,1)); due = und(j); AVDE_MOCK.V = P(due,1);
    end
    AVDE_MOCK.yield = 0.001;
    for i = due(:)'
        key = P(i,2); tt = P(i,1);
        if firstPress(key) == 0 || tt < firstPress(key); firstPress(key) = tt; end
        lastPress(key) = max(lastPress(key), tt);
    end
    AVDE_MOCK.trial.delivered(due) = true; pressed = true;
elseif any(strcmp(names,'avde_run_comprehension'))
    ans_ = AVDE_MOCK.expectedAnswer;
    AVDE_MOCK.compAnswers = AVDE_MOCK.compAnswers + 1;
    if ceil(AVDE_MOCK.compAnswers/5) <= AVDE_MOCK.failComprehensionCycles
        if ans_=='L'; ans_='R'; else; ans_='L'; end
    end
    AVDE_MOCK.V = AVDE_MOCK.V + 2; pressed = true;
    if ans_=='L'; firstPress(37) = AVDE_MOCK.V; else; firstPress(39) = AVDE_MOCK.V; end
elseif any(strcmp(names,'avde_wait_for_continue'))
    if any(strcmp(names,'avde_run_break'))
        if isfinite(AVDE_MOCK.crashInBreak) && AVDE_MOCK.crashInBreak == AVDE_MOCK.sectionBreak
            AVDE_MOCK.crashInBreak = NaN; AVDE_MOCK.crashed = true; error('MOCK:Crash','Simulated crash during break %d', AVDE_MOCK.sectionBreak);
        end
        AVDE_MOCK.V = AVDE_MOCK.V + AVDE_MOCK.breakSeconds;
    else
        AVDE_MOCK.V = AVDE_MOCK.V + 3;
    end
    pressed = true; firstPress(32) = AVDE_MOCK.V;
end
end
