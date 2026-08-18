classdef (Abstract) ConfigurationData < matlab.mixin.indexing.RedefinesDot & ...
        matlab.mixin.indexing.OverridesPublicDotMethodCall & ...
        matlab.mixin.CustomDisplay
    %CONFIGURATIONDATA Abstract base class for structured hierarchical data
    %   Use format-specific subclasses: YAMLData, TOMLData.
    %   Provides dot notation access and support for special characters in keys.
    %
    %   This is a value class. Assignment creates an independent copy:
    %       newData = data;  % newData is independent of data
    %
    %   The copy() method is provided for compatibility but is equivalent
    %   to assignment for value classes.
    %
    %   NOTE: This class uses OverridesPublicDotMethodCall to avoid reserved
    %   name collisions. Users can have keys named "keys", "isfield" etc.
    %   To call methods, use function syntax: keys(obj), isfield(obj, key)

    properties (Access = protected)
        % Internal storage: string->cell dictionary preserving insertion order.
        % Key aliases are computed on the fly in resolveKey.
        Data dictionary = configureDictionary("string", "cell")
    end

    properties (Abstract, Constant, Access = protected)
        SourceFormat matlab.io.config.internal.SourceFormat
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

        obj.Data = configureDictionary("string", "cell");
        end

        show(obj)

        [k, perElementKeys] = keys(obj)

        tf = isfield(obj, key)

        s = struct(obj)

        m = map(obj)

        d = dictionary(obj)

        names = fieldnames(obj)

        tf = iskey(obj, key)

        obj = rmfield(obj, key)

        obj = remove(obj, key)

        result = describe(obj, options)
    end

    methods (Access = protected)
        header = getHeader(obj)

        displayScalarObject(obj)

        displayNonScalarObject(obj)

        str = formatValue(obj, value)
    end

    methods (Access = protected)
        n = dotListLength(obj, indexOp, indexContext)

        varargout = dotReference(obj, indexOp, indexContext)

        obj = dotAssign(obj, indexOp, varargin)

        obj = parenDotAssign(obj, indexOp, varargin)

        n = parenDotListLength(obj, indexOp, indexContext)

        resolvedKey = resolveKey(obj, key)

        s = dictToStruct(obj, d)

        value = convertImportValue(obj, value)

        result = tryConcatenate(obj, values, fieldName)
    end

    methods (Hidden)
        value = getData(obj, key)

        obj = setData(obj, key, value)

        obj = importFrom(obj, inputData)
    end

    methods (Access = protected)
        value = validateAndConvertValue(obj, value, key)
    end

    methods (Access = private)
        text = buildDescriptionText(obj, maxDepth)

        text = buildDescriptionTable(obj, maxDepth)

        lines = buildKeysText(obj, indent, currentDepth, maxDepth)

        lines = buildArrayKeysText(obj, indent)

        text = buildShowText(obj, varName)

        lines = buildShowKeysText(obj, indent, currentDepth, maxDepth)

        uniqueKeys = collectUnionOfKeys(obj)

        [paths, types, sizes] = collectRows(obj, prefix, paths, types, sizes, currentDepth, maxDepth)

        [paths, types, sizes] = collectArrayRows(obj, prefix, paths, types, sizes, currentDepth, maxDepth)
    end

    methods (Static, Access = private)
        word = pluralize(singular, count)

        array = normalizeVectorOrientation(array)

        shortName = shortClassName(fullName)

        str = formatShowLeafValue(value)

        str = formatLeafValue(value)
    end
end
