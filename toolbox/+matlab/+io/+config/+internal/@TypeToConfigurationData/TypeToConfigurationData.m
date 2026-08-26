classdef (Abstract) TypeToConfigurationData < matlab.io.config.internal.ConfigurationStorage
    %TYPETOCONFIGURATIONDATA Import external data into ConfigurationData

    methods (Hidden)
        obj = importFrom(obj, inputData)
    end
end
