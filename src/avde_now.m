function s = avde_now()
% Wall-clock timestamp as ISO-8601 text (portable; avoids datetime objects in data files).
s = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF');
end
