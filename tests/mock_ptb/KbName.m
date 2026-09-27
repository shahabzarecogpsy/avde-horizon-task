function out = KbName(x)
names = {'LeftArrow',37;'RightArrow',39;'space',32;'ESCAPE',27};
if ischar(x)
    if strcmp(x,'UnifyKeyNames'); out = []; return; end
    out = names{strcmp(names(:,1),x),2};
else
    k = find(x,1); if isscalar(x) && x>1; k = x; end
    out = names{[names{:,2}]==k,1};
end
end
