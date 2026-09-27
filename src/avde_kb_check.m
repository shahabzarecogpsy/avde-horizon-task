function [pressed,firstPress,firstRelease,lastPress,lastRelease]=avde_kb_check(ds)
[pressed,firstPress,firstRelease,lastPress,lastRelease]=KbQueueCheck(ds.keyboardDeviceIndex);
end
