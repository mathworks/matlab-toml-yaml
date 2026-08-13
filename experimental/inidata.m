function data = inidata(input)
%INIDATA Create an INIData object for storing INI-style configuration
%   data = INIDATA() creates an empty INIData object.
%
%   data = INIDATA(input) creates an INIData object initialized from input,
%   which can be a struct or dictionary.
%
%   Example:
%       % Create empty and populate
%       config = inidata();
%       config.database.host = 'localhost';
%       config.database.port = 5432;
%
%       % Create from struct
%       s.section1.key1 = 'value1';
%       s.section2.key2 = 42;
%       config = inidata(s);
%
%   See also: readini, writeini, matlab.io.config.INIData

    if nargin == 0
        data = matlab.io.config.INIData();
    else
        data = matlab.io.config.INIData();
        data = importFrom(data, input);
    end
end
