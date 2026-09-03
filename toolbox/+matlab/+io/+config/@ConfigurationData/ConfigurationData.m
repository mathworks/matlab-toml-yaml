classdef (Abstract) ConfigurationData < ...
        matlab.io.config.internal.ConfigurationDotAccess & ...
        matlab.io.config.internal.ConfigurationDisplay & ...
        matlab.io.config.internal.ConfigurationToType & ...
        matlab.io.config.internal.TypeToConfigurationData
    %CONFIGURATIONDATA Abstract base class for structured hierarchical data
    %   Use format-specific subclasses: YAMLData, TOMLData.
    %   Provides dot notation access and support for special characters in keys.
    %
    %   This is a value class. Assignment creates an independent copy:
    %       newData = data;  % newData is independent of data
    %
    %   NOTE: This class uses OverridesPublicDotMethodCall to avoid reserved
    %   name collisions. Users can have keys named "keys", "isfield" etc.
    %   To call methods, use function syntax: keys(obj), isfield(obj, key)

    properties (Access = protected)
        Data = dictionary(string.empty, cell.empty)
    end

    methods
        function obj = ConfigurationData()
        %CONFIGURATIONDATA Constructor for subclasses
        %   This is an abstract class. Use YAMLData or TOMLData.
        %
        %   Subclass constructors create empty objects. To create from
        %   existing data, use the informal wrapper functions:
        %       config = tomldata(myStruct);   % from struct
        %       config = yamldata(myDict);     % from dictionary
        %
        %   See also TOMLDATA, YAMLDATA

        obj.Data = dictionary(string.empty, cell.empty);
        end
    end

    % properties(obj) is defined in properties.m (signature omitted here
    % because 'properties' is a reserved keyword in classdef blocks).
end
