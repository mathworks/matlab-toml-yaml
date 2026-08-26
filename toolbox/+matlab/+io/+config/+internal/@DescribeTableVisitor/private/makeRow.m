function row = makeRow(value)
%MAKEROW Create a single-row table with Path, Type, Size columns
import matlab.io.config.internal.shortClassName

t = emptyDescribeTable();
sizeStr = join(string(size(value)), "x");
typeName = string(shortClassName(class(value)));
row = [t; {"", typeName, sizeStr}];
end
