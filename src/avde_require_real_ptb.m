function avde_require_real_ptb(rootDir)
% Participant and timing-test modes must run on real Psychtoolbox: refuse the
% headless test simulator (tests/mock_ptb) or any shadowing Screen function.
w = which('Screen');
v = ''; try; v = PsychtoolboxVersion; catch; end
if isempty(w) || ~isempty(strfind(lower(w), 'mock_ptb')) || ~isempty(strfind(upper(v), 'MOCK')) || ...
        strncmp(w, fullfile(rootDir,'tests'), numel(fullfile(rootDir,'tests'))) %#ok<STREMP>
    error('AVDE:MockPsychtoolbox','Real Psychtoolbox is required in this mode (Screen resolves to "%s", version "%s"). Remove test folders from the MATLAB path.', w, v);
end
end
