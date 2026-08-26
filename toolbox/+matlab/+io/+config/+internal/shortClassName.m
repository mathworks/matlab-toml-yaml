function shortName = shortClassName(fullName)
%SHORTCLASSNAME Strip namespace prefix from class name for cleaner display
%   'matlab.io.config.TOMLData' -> 'TOMLData'
shortName = regexprep(fullName, '^matlab\.io\.config\.', '');
end
