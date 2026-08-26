function lines = buildLines(keys, values, depth)
%BUILDLINES Assemble indented text lines from visitor results

indent = string(repmat('    ', 1, depth));
lines = strings(0, 1);

if isempty(keys)
    return;
end

maxKeyLen = max(strlength(keys));
keyColumnWidth = max(maxKeyLen + 2, 20);

for i = 1:numel(keys)
    value = values{i};

    if isstruct(value) && isfield(value, 'dimStr')
        % Expanded array
        paddedKey = pad(keys(i) + ":", keyColumnWidth);
        lines(end+1) = indent + paddedKey + value.dimStr + " array" + newline; %#ok<AGROW>
        childIndent = indent + "    ";
        for j = 1:numel(value.childLines)
            lines(end+1) = childIndent + value.childLines{j} + newline; %#ok<AGROW>
        end
    elseif isstring(value) && isscalar(value) && contains(value, newline)
        % Expanded scalar node — joined child lines
        lines(end+1) = indent + keys(i) + ":" + newline; %#ok<AGROW>
        lines(end+1) = value; %#ok<AGROW>
    else
        % Leaf or depth-limited node
        paddedKey = pad(keys(i) + ":", keyColumnWidth);
        lines(end+1) = indent + paddedKey + value + newline; %#ok<AGROW>
    end
end
end
