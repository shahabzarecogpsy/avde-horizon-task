function [passed, answers] = avde_run_comprehension(ds, cfg)
% Five two-alternative questions on essential task rules (not wording).
% Answer key positions: L R L R L. Early/simultaneous presses are ignored.
qfiles = {'comp_q1.png','comp_q2.png','comp_q3.png','comp_q4.png','comp_q5.png'};
key = 'LRLRL';
answers = repmat(struct('question',NaN,'side','','correct',false,'rt',NaN,'invalidCount',0,'cycle',NaN),numel(qfiles),1);
for q = 1:numel(qfiles)
    avde_mock_hint('answer', key(q));
    avde_kb_release_wait(ds);
    onset = avde_show_asset_screen(ds, cfg, qfiles{q}, false);
    avde_kb_flush(ds); side = ''; pt = NaN; inv = 0;
    if avde_autopilot(); WaitSecs(1.0); side = key(q); pt = GetSecs; end
    while isempty(side)
        [pressed, fp] = avde_kb_check(ds);
        if pressed
            if fp(ds.keys.escape) > 0; error('AVDE:UserAbort','Aborted by ESCAPE.'); end
            l = fp(ds.keys.left); r = fp(ds.keys.right);
            if (l>0 && l<onset) || (r>0 && r<onset) || (l>0 && r>0 && abs(l-r)<=cfg.input.simultaneousWindow)
                inv = inv + 1; avde_kb_flush(ds); continue;
            end
            if l>0 && (r==0 || l<r); side = 'L'; pt = l; elseif r>0; side = 'R'; pt = r; end
        end
        WaitSecs('YieldSecs', 0.004);
    end
    answers(q).question = q; answers(q).side = side; answers(q).rt = pt - onset; answers(q).invalidCount = inv;
    answers(q).correct = side == key(q);
end
avde_kb_release_wait(ds);
passed = all([answers.correct]);
end
