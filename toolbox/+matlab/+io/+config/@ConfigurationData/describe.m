function result = describe(obj, options)
%DESCRIBE Show structural overview of ConfigurationData
%   describe(obj) prints a recursive tree showing all keys, their
%   types, and values for scalar leaves.
%
%   describe(obj, Depth=N) limits recursion to N levels.
%
%   info = describe(obj) returns a table with Path, Type, and Size
%   columns for programmatic querying.
%
%   Examples:
%       describe(config)
%       describe(config, Depth=2)
%       info = describe(config);
%       info(info.Type == "string", :)
%
%   See also keys, show

arguments
    obj
    options.Depth (1,1) double {mustBePositive} = Inf
end
if nargout == 0
    text = buildDescriptionText(obj, options.Depth);
    fprintf('%s', text);
else
    result = buildDescriptionTable(obj, options.Depth);
end
end
