classdef (Abstract) ConfigurationDisplay < ...
        matlab.io.config.internal.ConfigurationStorage & ...
        matlab.mixin.CustomDisplay & ...
        matlab.mixin.CustomCompactDisplayProvider
    %CONFIGURATIONDISPLAY Custom display for configuration data

    methods
        show(obj)

        result = describe(obj, options)

        rep = compactRepresentationForSingleLine(obj, displayConfiguration, width)
    end

    methods (Access = protected)
        header = getHeader(obj)

        displayScalarObject(obj)

        displayNonScalarObject(obj)
    end
end
