function avde_export_csv(session, cfg, files)
% Analysis-ready CSVs. The complete MAT file remains authoritative.
% Every table carries participantID, buildID, runMode and dataStatus columns,
% so no exported table can be read without its scientific-validity label.
% Idempotent: re-running from the final MAT (avde_reexport) rewrites identical files.
if ~cfg.output.writeCsvAtEnd; return; end
p = files.prefix; m = session.meta;
ev = local_cat(session.gameLogs);
if ~isempty(ev); assert(all(strcmp({ev.attemptType},'core')), 'AVDE:ExportLabel', 'Core event not labelled core.'); end
ev = avde_finalize_event_derived_fields(ev);
local_write(ev, [p '_events.csv'], m);
local_write(session.gameSummaries, [p '_games.csv'], m);
local_write(session.plan, [p '_plan.csv'], m);
if ~isempty(session.breakLog); local_write(session.breakLog, [p '_breaks.csv'], m); end
if ~isempty(session.resumeLog); local_write(session.resumeLog, [p '_resume_log.csv'], m); end
if isfield(session,'practice') && ~isempty(session.practice.cycles)
    pe = repmat(avde_empty_event(),0,1); ps = repmat(avde_empty_game_summary(),0,1); cq = [];
    for c = 1:numel(session.practice.cycles)
        C = session.practice.cycles(c);
        pe = [pe; local_cat(C.gameLogs)]; ps = [ps; C.gameSummaries(:)]; %#ok<AGROW>
        a = C.comprehension; for q = 1:numel(a); a(q).cycle = c; end
        if isempty(cq); cq = a(:); else; cq = [cq; a(:)]; end %#ok<AGROW>
    end
    if ~isempty(pe); assert(all(strcmp({pe.attemptType},'practice')), 'AVDE:ExportLabel', 'Practice event not labelled practice.'); end
    local_write(pe, [p '_practice_events.csv'], m); local_write(ps, [p '_practice_games.csv'], m);
    local_write(cq, [p '_comprehension.csv'], m);
end
mf = fieldnames(m); kv = struct('key',mf,'value','');
for k = 1:numel(mf); x = m.(mf{k}); if ischar(x); kv(k).value = x; else; kv(k).value = mat2str(x); end; end
avde_write_csv(kv, [p '_meta.csv']);
end

function local_write(S, file, m)
if isempty(S); return; end
S = S(:);
for i = 1:numel(S)
    S(i).participantID = m.participantID; S(i).buildID = m.buildID; S(i).runMode = m.runMode; S(i).dataStatus = m.dataStatus;
end
avde_write_csv(S, file);
end

function E = local_cat(C)
E = repmat(avde_empty_event(),0,1);
for i = 1:numel(C); if ~isempty(C{i}); E = [E; C{i}(:)]; end; end %#ok<AGROW>
end
