function run_all_tests_octave(cfdRoot, outDir, nSeeds)
% Full headless verification suite (GNU Octave >= 8; no Psychtoolbox).
%   run_all_tests_octave(cfdRoot, outDir, nSeeds)
% outDir must be OUTSIDE the release folder (results never modify manifest-
% covered files). Run data go to isolated temp roots; the package data/ folder
% is never touched. Exits with an error if any check fails.
here = fileparts(mfilename('fullpath')); pkg = fileparts(here);
if nargin < 3; nSeeds = 100; end
if strncmp(outDir, pkg, numel(pkg)); error('AVDE:TestOutput','outDir must be outside the release folder.'); end
if ~exist(outDir,'dir'); mkdir(outDir); end
fails = 0;
fails = fails + test_unit(cfdRoot, fullfile(outDir,'unit_tests.csv'));
f = fullfile(outDir,'crash_resume.csv'); fid = fopen(f,'w'); fprintf(fid,'scenario,crashes,ok,hardKill,detail\n'); fclose(fid);
fails = fails + test_crash_resume(cfdRoot, f);
f = fullfile(outDir,'multiseed.csv'); fid = fopen(f,'w');
fprintf(fid,'seed,pid,planID,planSeconds,h6pn8888,minImgLag,minIdLag,maxRewardAttempt,maxRunHorizon,lowMean,highMean,forcedGapMin,forcedGapMax,nImages,chiIdentityHighLow,pIdentityHighLow,chiIdentityLessMore,pIdentityLessMore,practiceCoverageOK\n'); fclose(fid);
test_multiseed(1, nSeeds, cfdRoot, f);            % throws on any validation failure
if fails > 0; error('AVDE:TestsFailed','%d check(s) failed; see %s', fails, outDir); end
fprintf('ALL TESTS PASSED (results in %s)\n', outDir);
end
