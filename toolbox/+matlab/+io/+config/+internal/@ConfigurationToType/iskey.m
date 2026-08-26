function tf = iskey(obj, key)
%ISKEY Check if key exists in each element of the array
%   tf = iskey(obj, key) returns a logical array the same size as obj.
%   tf(i) is true if obj(i) contains the key.
%
%   For scalar objects, returns a scalar logical.
%   For array objects, returns a logical array allowing filtering:
%       hasEmail = iskey(data.users, "email");
%       emailUsers = data.users(hasEmail);
%
%   To check if ALL elements have a key: all(iskey(obj, key))
%
%   See also ISFIELD, KEYS

tf = ~ismissing(resolveKey(obj, key));
end
