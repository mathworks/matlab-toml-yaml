classdef (Abstract) ConfigurationToType < matlab.io.config.internal.ConfigurationStorage
    %CONFIGURATIONTOTYPE Conversion from ConfigurationData to MATLAB types

    methods
        [k, perElementKeys] = keys(obj)

        tf = isfield(obj, key)

        s = struct(obj)

        m = map(obj)

        d = dictionary(obj)

        names = fieldnames(obj)

        tf = iskey(obj, key)

        obj = rmfield(obj, key)

        obj = remove(obj, key)
    end

end
