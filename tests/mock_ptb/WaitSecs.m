function WaitSecs(a, b)
global AVDE_MOCK
mock_advance();
if ischar(a)
    switch a
        case 'YieldSecs'; AVDE_MOCK.V = AVDE_MOCK.V + max(b, AVDE_MOCK.yield);
        case 'UntilTime'; AVDE_MOCK.V = max(AVDE_MOCK.V, b);
    end
else
    AVDE_MOCK.V = AVDE_MOCK.V + a;
end
end
