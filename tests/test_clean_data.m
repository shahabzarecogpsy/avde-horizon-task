function test_clean_data(dataRoot)
% Remove ONLY an isolated test data root created by test_env (never data/).
[parent, name] = fileparts(dataRoot);
if ~strncmp(name, 'AVDE_test_data_', 15) || ~strcmp(strrep([parent filesep],[filesep filesep],filesep), strrep(tempdir,[filesep filesep],filesep))
    error('AVDE:TestCleanup','Refusing to delete %s (not an isolated test data root).', dataRoot);
end
if exist(dataRoot,'dir'); if exist('confirm_recursive_rmdir','builtin') || exist('confirm_recursive_rmdir'); confirm_recursive_rmdir(false); end; rmdir(dataRoot,'s'); end %#ok<EXIST>
end
