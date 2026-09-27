function actual = avde_wait_until(targetTime)
% WaitSecs('UntilTime') wrapper returning actual wake time.
WaitSecs('UntilTime', targetTime);
actual = GetSecs;
end
