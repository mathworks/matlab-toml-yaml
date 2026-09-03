classdef (Abstract) ConfigurationDisplay < ...
        matlab.io.config.internal.ConfigurationStorage & ...
        matlab.mixin.CustomDisplay & ...
        matlab.mixin.CustomCompactDisplayProvider
    %CONFIGURATIONDISPLAY Custom display for configuration data

    methods (Hidden)
        rep = compactRepresentationForSingleLine(obj, displayConfiguration, width)

        function rep = compactRepresentationForColumn(obj, displayConfiguration, width)
            % Redefining this method to mark as Hidden. Forward to
            % superclass impl.
            rep = compactRepresentationForColumn@matlab.mixin.CustomCompactDisplayProvider(obj, displayConfiguration, width);
        end
    end

    methods (Access = protected)
        header = getHeader(obj)

        displayScalarObject(obj)

        displayNonScalarObject(obj)
    end
end
