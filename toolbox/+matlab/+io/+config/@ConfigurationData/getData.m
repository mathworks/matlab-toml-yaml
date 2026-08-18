function value = getData(obj, key)
%GETDATA Get value from Data dictionary (unwraps cell)
key = string(key);
val = obj.Data(key);
value = val{1};
end
