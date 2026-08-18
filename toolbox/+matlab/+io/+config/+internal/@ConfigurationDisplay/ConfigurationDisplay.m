classdef (Abstract) ConfigurationDisplay < ...
        matlab.io.config.internal.ConfigurationStorage & ...
        matlab.mixin.CustomDisplay
    %CONFIGURATIONDISPLAY Custom display for configuration data

    methods
        show(obj)

        result = describe(obj, options)
    end

    methods (Access = protected)
        header = getHeader(obj)

        displayScalarObject(obj)

        displayNonScalarObject(obj)

        str = formatValue(obj, value)
    end
end
