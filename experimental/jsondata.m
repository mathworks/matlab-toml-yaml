function data = jsondata(input)
%JSONDATA Create a JSONData object for storing JSON-style configuration
%   data = JSONDATA() creates an empty JSONData object.
%
%   data = JSONDATA(input) creates a JSONData object initialized from input,
%   which can be a struct or dictionary.
%
%   Example:
%       % Create empty and populate
%       config = jsondata();
%       config.name = 'my-package';
%       config.version = '1.0.0';
%
%       % Create from struct
%       s.name = 'MyApp';
%       s.version = '1.0';
%       config = jsondata(s);
%
%   See also: readjson, writejson, matlab.io.config.JSONData

    if nargin == 0
        data = matlab.io.config.JSONData();
    else
        data = matlab.io.config.JSONData();
        data = importFrom(data, input);
    end
end
