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
%   See also keys

arguments
    obj
    options.Depth (1,1) double {mustBePositive} = Inf
end

if nargout == 0
    v = matlab.io.config.internal.DescribeTextVisitor(options.Depth);
    fprintf('%s', describeRoot(v, obj));
else
    v = matlab.io.config.internal.DescribeTableVisitor(options.Depth);
    result = describeRoot(v, obj);
end
end
