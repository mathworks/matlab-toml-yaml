classdef (Abstract) ConfigurationDotAccess < ...
        matlab.io.config.internal.ConfigurationStorage & ...
        matlab.mixin.indexing.RedefinesDot & ...
        matlab.mixin.indexing.OverridesPublicDotMethodCall
    %CONFIGURATIONDOTACCESS Dot notation access for configuration data

    methods (Access = protected)
        varargout = dotReference(obj, indexOp, indexContext)

        obj = dotAssign(obj, indexOp, varargin)

        n = dotListLength(obj, indexOp, indexContext)
    end
end
