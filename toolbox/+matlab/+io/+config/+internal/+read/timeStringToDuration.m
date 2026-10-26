function d = timeStringToDuration(str)
    v = sscanf(str, "%d:%d:%lf");
    d = hours(v(1)) + minutes(v(2)) + seconds(v(3));
    d.Format = "hh:mm:ss";
end
