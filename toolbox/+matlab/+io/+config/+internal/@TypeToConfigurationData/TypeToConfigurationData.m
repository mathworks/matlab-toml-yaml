classdef (Abstract) TypeToConfigurationData < matlab.io.config.internal.ConfigurationStorage
    %TYPETOCONFIGURATIONDATA Import external data into ConfigurationData

    methods (Hidden)
        obj = importFrom(obj, inputData)
    end

    methods (Access = protected)
        value = convertImportValue(obj, value)
    end
end
