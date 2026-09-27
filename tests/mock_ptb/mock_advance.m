function mock_advance()
global AVDE_MOCK
t = time(); AVDE_MOCK.V = AVDE_MOCK.V + (t - AVDE_MOCK.lastReal); AVDE_MOCK.lastReal = t;
end
