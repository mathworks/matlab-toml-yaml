function showAllValuesLink(varName)
%SHOWALLVALUESLINK Print "Show all values" hyperlink
if ~isempty(varName)
    fprintf('\n    <a href="matlab:show(%s)">Show all values</a>\n', varName);
end
fprintf('\n');
end
