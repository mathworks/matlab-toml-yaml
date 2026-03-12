classdef ConfigurationData < matlab.mixin.indexing.RedefinesDot & ...
                            matlab.mixin.indexing.OverridesPublicDotMethodCall & ...
                            matlab.mixin.CustomDisplay
    %CONFIGURATIONDATA Base class for structured hierarchical data
    %   Can be used directly via configdata() for format-neutral data, or via
    %   format-specific subclasses: YAMLData, TOMLData, JSONData, INIData.
    %   Provides dot notation access and support for special characters in keys.
    %
    %   This is a value class. Assignment creates an independent copy:
    %       newData = data;  % newData is independent of data
    %
    %   The copy() method is provided for compatibility but is equivalent
    %   to assignment for value classes.
    %
    %   NOTE: This class uses OverridesPublicDotMethodCall to avoid reserved
    %   name collisions. Users can have keys named "keys", "isfield", etc.
    %   To call methods, use function syntax: keys(obj), isfield(obj, key)

    properties (Access = public, Hidden = true)
        % Consolidated internal state in a single property to minimize
        % reserved key names while preserving tab completion.
        % See Claude/TAB_COMPLETION_DESIGN.md for rationale.
        xInternal__ struct = struct(...
            'Data', configureDictionary("string", "cell"), ...
            'KeyAliases', configureDictionary("string", "string"), ...
            'OriginalKeys', string.empty, ...
            'SourceFormat', "unknown")
    end

    methods
        function obj = ConfigurationData()
            %CONFIGURATIONDATA Constructor for subclasses
            %   This is an abstract class. Use YAMLData, TOMLData, or INIData.
            %
            %   Subclass constructors create empty objects. To create from
            %   existing data, use the informal wrapper functions:
            %       config = tomldata(myStruct);   % from struct
            %       config = yamldata(myDict);     % from dictionary
            %
            %   See also TOMLDATA, YAMLDATA, INIDATA

            obj.xInternal__.Data = configureDictionary("string", "cell");
            obj.xInternal__.KeyAliases = configureDictionary("string", "string");
            obj.xInternal__.OriginalKeys = string.empty;
        end

        function newObj = copy(obj)
            %COPY Create an independent copy of the ConfigurationData object
            %   With value semantics, assignment already creates a copy.
            %   This method is retained for backwards compatibility.
            newObj = obj;
        end

        function show(obj)
            %SHOW Display all values as an indented tree
            %   For format-specific subclasses (YAMLData, TOMLData, etc.), show()
            %   displays in the native file format. For format-neutral ConfigurationData
            %   objects created via configdata(), show() displays an indented tree
            %   with actual values (not type annotations).
            %
            %   Arrays are displayed using the same style as MATLAB's ND array
            %   display, with each element labeled varname(i) =
            %
            %   See also describe
            varName = inputname(1);
            if isempty(varName)
                varName = 'ans';
            end
            text = buildShowText(obj, varName);
            fprintf('%s', text);
        end

        function [k, perElementKeys] = keys(obj)
            if ~isscalar(obj)
                keySets = cell(size(obj));
                for i = 1:numel(obj)
                    keySets{i} = keys(obj(i));
                end
                k = unique([keySets{:}], 'stable');
                if nargout > 1
                    perElementKeys = keySets;
                end
                return;
            end
            k = obj.xInternal__.OriginalKeys;
            if nargout > 1
                perElementKeys = {k};
            end
        end

        function tf = isfield(obj, key)
            %ISFIELD Check if key exists (delegates to iskey)
            tf = iskey(obj, key);
        end

        function s = struct(obj)
            % Handle non-scalar array: convert each element
            if ~isscalar(obj)
                structCell = cell(size(obj));
                for i = 1:numel(obj)
                    structCell{i} = struct(obj(i));
                end
                s = reshape([structCell{:}], size(obj));
                return;
            end

            s = struct;
            for i = 1:length(obj.xInternal__.OriginalKeys)
                key = obj.xInternal__.OriginalKeys(i);
                value = obj.getData(key);

                if isa(value, 'matlab.io.config.ConfigurationData')
                    if isscalar(value)
                        value = struct(value);
                    else
                        % Handle array of ConfigurationData objects
                        structCell = cell(1, numel(value));
                        for iVal = 1:numel(value)
                            structCell{iVal} = struct(value(iVal));
                        end
                        value = [structCell{:}];
                    end
                elseif isa(value, 'dictionary')
                    % Recursively convert dictionary to struct
                    value = obj.dictToStruct(value);
                end

                fieldName = matlab.lang.makeValidName(key);
                s.(fieldName) = value;
            end
        end

        function m = map(obj)
            %MAP Convert to containers.Map (for compatibility)
            m = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for i = 1:length(obj.xInternal__.OriginalKeys)
                key = obj.xInternal__.OriginalKeys(i);
                value = obj.getData(key);

                if isa(value, 'matlab.io.config.ConfigurationData')
                    value = map(value);
                end

                m(char(key)) = value;
            end
        end

        function d = dictionary(obj)
            %DICTIONARY Convert to MATLAB dictionary
            %   d = dictionary(obj) converts the ConfigurationData to a
            %   dictionary with string keys and cell values.
            %
            %   Nested ConfigurationData objects are recursively converted
            %   to nested dictionaries.
            %
            %   Example:
            %       config = readyaml('config.yaml');
            %       d = dictionary(config);
            %       value = d{"keyName"};
            %
            %   See also STRUCT, MAP

            d = configureDictionary("string", "cell");
            for i = 1:length(obj.xInternal__.OriginalKeys)
                key = obj.xInternal__.OriginalKeys(i);
                value = obj.getData(key);

                if isa(value, 'matlab.io.config.ConfigurationData')
                    if isscalar(value)
                        value = dictionary(value);  % Recursive
                    else
                        % Array of ConfigurationData -> cell array of dictionaries
                        tmpCell = cell(1, numel(value));
                        for iVal = 1:numel(value)
                            tmpCell{iVal} = dictionary(value(iVal));
                        end
                        value = tmpCell;
                    end
                end

                d(key) = {value};
            end
        end

        function p = properties(obj)
            %PROPERTIES Return list of dynamic properties (keys)
            %   Returns cell array of char for MATLAB IDE tab completion.
            p = cellstr(obj.xInternal__.OriginalKeys);
        end

        function names = fieldnames(obj)
            %FIELDNAMES Get field names (alias for keys)
            names = keys(obj);
        end

        function tf = iskey(obj, key)
            %ISKEY Check if key exists in each element of the array
            %   tf = iskey(obj, key) returns a logical array the same size as obj.
            %   tf(i) is true if obj(i) contains the key.
            %
            %   For scalar objects, returns a scalar logical.
            %   For array objects, returns a logical array allowing filtering:
            %       hasEmail = iskey(data.users, "email");
            %       emailUsers = data.users(hasEmail);
            %
            %   To check if ALL elements have a key: all(iskey(obj, key))
            %
            %   See also ISFIELD, KEYS

            tf = false(size(obj));
            for i = 1:numel(obj)
                resolvedKey = obj(i).resolveKey(key);
                tf(i) = ~isempty(resolvedKey);
            end
        end

        function obj = rmfield(obj, key)
            %RMFIELD Remove a field
            resolvedKey = obj.resolveKey(key);
            if isempty(resolvedKey)
                error('ConfigurationData:InvalidKey', ...
                    'Key "%s" does not exist.', key);
            end

            % Remove from data (dictionary requires capturing return)
            obj.xInternal__.Data = remove(obj.xInternal__.Data, resolvedKey);

            % Remove from order tracking
            obj.xInternal__.OriginalKeys(obj.xInternal__.OriginalKeys == resolvedKey) = [];

            % Remove alias if exists
            validKey = matlab.lang.makeValidName(key);
            if isKey(obj.xInternal__.KeyAliases, validKey)
                obj.xInternal__.KeyAliases = remove(obj.xInternal__.KeyAliases, validKey);
            end
        end

        function obj = remove(obj, key)
            %REMOVE Remove a key (alias for rmfield)
            obj = obj.rmfield(key);
        end

        function result = describe(obj, options)
            %DESCRIBE Show structural overview of ConfigurationData
            %   describe(obj) prints a recursive tree showing all keys, their
            %   types, and values for scalar leaves.
            %
            %   describe(obj, Depth=N) limits recursion to N levels.
            %
            %   info = describe(obj) returns a table with Path, Type, and Size
            %   columns for programmatic querying.
            %
            %   Examples:
            %       describe(config)
            %       describe(config, Depth=2)
            %       info = describe(config);
            %       info(info.Type == "string", :)
            %
            %   See also keys, show

            arguments
                obj
                options.Depth (1,1) double {mustBePositive} = Inf
            end
            if nargout == 0
                text = buildDescriptionText(obj, options.Depth);
                fprintf('%s', text);
            else
                result = buildDescriptionTable(obj, options.Depth);
            end
        end

    end

    methods (Access = protected)
        % CustomDisplay implementation
        function header = getHeader(obj)
            %GETHEADER Customize header to use "keys" instead of "properties"
            if isscalar(obj)
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                nKeys = length(obj.xInternal__.OriginalKeys);
                if nKeys == 0
                    header = sprintf('  %s with no keys\n', className);
                elseif nKeys == 1
                    header = sprintf('  %s with keys:\n', className);
                else
                    header = sprintf('  %s with keys:\n', className);
                end
            else
                % Non-scalar handled by displayNonScalarObject
                header = getHeader@matlab.mixin.CustomDisplay(obj);
            end
        end

        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);

            if length(obj.xInternal__.OriginalKeys) == 0
                return;
            end

            % Check if there's nested hierarchy
            hasHierarchy = false;
            for i = 1:length(obj.xInternal__.OriginalKeys)
                value = obj.getData(obj.xInternal__.OriginalKeys(i));
                if isa(value, 'matlab.io.config.ConfigurationData') || isa(value, 'dictionary')
                    hasHierarchy = true;
                    break;
                end
            end

            % Display each field
            for i = 1:length(obj.xInternal__.OriginalKeys)
                key = obj.xInternal__.OriginalKeys(i);
                value = obj.getData(key);

                % Format the value for display
                valueStr = obj.formatValue(value);

                fprintf('    %s: %s\n', key, valueStr);
            end

            % Add footer with show link if there's hierarchy
            if hasHierarchy
                fprintf('\n    <a href="matlab:show(%s)">Show all values</a>\n', inputname(1));
            end

            fprintf('\n');
        end

        function displayNonScalarObject(obj)
            % Display for object arrays
            dims = size(obj);
            dimStr = sprintf('%dx', dims);
            dimStr = dimStr(1:end-1); % Remove trailing 'x'

            % Collect all keys from array elements
            allKeys = string.empty(0,1); % String array to hold all unique keys
            keySets = cell(numel(obj), 1);

            for i = 1:numel(obj)
                keySets{i} = keys(obj(i)); % Use keys() method
                % Ensure column vector for concatenation
                allKeys = [allKeys; reshape(keySets{i}, [], 1)];
            end

            % Get unique keys while preserving order from first occurrence
            [uniqueKeys, ~] = unique(allKeys, 'stable');

            % Check if all elements have identical keys
            isHomogeneous = true;
            if numel(obj) > 1
                firstKeySet = keySets{1};
                for i = 2:numel(obj)
                    if ~isequal(sort(firstKeySet), sort(keySets{i}))
                        isHomogeneous = false;
                        break;
                    end
                end
            end

            % Display header
            shortName = matlab.io.config.ConfigurationData.shortClassName(class(obj));
            fprintf('  %s <a href="matlab:helpPopup %s">%s</a> array with keys:\n\n', ...
                dimStr, class(obj), shortName);

            % Display keys
            for i = 1:length(uniqueKeys)
                fprintf('    %s\n', uniqueKeys(i));
            end

            % Add heterogeneous note if needed
            if ~isHomogeneous && numel(obj) > 1
                fprintf('\n    (keys vary by element)\n');
            end

            % Add show link for arrays (they always have potential hierarchy)
            fprintf('\n    <a href="matlab:show(%s)">Show all values</a>\n\n', inputname(1));
        end

        function str = formatValue(~, value)
            % Format a value for display (similar to struct)
            if isa(value, 'matlab.io.config.ConfigurationData')
                if numel(value) > 1
                    % Array of ConfigurationData
                    sizeStr = sprintf('%dx', size(value));
                    sizeStr = sizeStr(1:end-1);
                    shortName = matlab.io.config.ConfigurationData.shortClassName(class(value));
                    str = sprintf('[%s %s]', sizeStr, shortName);
                else
                    % Scalar ConfigurationData - show actual subclass name
                    nFields = length(value.xInternal__.OriginalKeys);
                    shortName = matlab.io.config.ConfigurationData.shortClassName(class(value));
                    str = sprintf('[1x1 %s with %d %s]', shortName, nFields, matlab.io.config.ConfigurationData.pluralize("key", nFields));
                end
            elseif isa(value, 'dictionary')
                nKeys = numEntries(value);
                str = sprintf('[1x1 dictionary with %d %s]', nKeys, matlab.io.config.ConfigurationData.pluralize("entry", nKeys));
            elseif ischar(value)
                if length(value) > 50
                    str = sprintf('''%s...'' [1x%d char]', value(1:50), length(value));
                else
                    str = sprintf('''%s''', value);
                end
            elseif isstring(value) && isscalar(value)
                if strlength(value) > 50
                    str = sprintf('"%s..."', extractBefore(value, 51));
                else
                    str = sprintf('"%s"', value);
                end
            elseif isnumeric(value)
                if isscalar(value)
                    str = sprintf('%g', value);
                elseif numel(value) <= 5
                    % Show small arrays inline
                    numStr = sprintf('%g ', value);
                    str = sprintf('[%s]', strtrim(numStr));
                else
                    % Show size and type for large arrays
                    sizeStr = sprintf('%dx', size(value));
                    sizeStr = sizeStr(1:end-1); % Remove trailing 'x'
                    str = sprintf('[%s %s]', sizeStr, class(value));
                end
            elseif islogical(value)
                if isscalar(value)
                    if value
                        str = 'true';
                    else
                        str = 'false';
                    end
                else
                    sizeStr = sprintf('%dx', size(value));
                    sizeStr = sizeStr(1:end-1);
                    str = sprintf('[%s logical]', sizeStr);
                end
            else
                % Generic handling
                sizeStr = sprintf('%dx', size(value));
                sizeStr = sizeStr(1:end-1);
                str = sprintf('[%s %s]', sizeStr, class(value));
            end
        end

    end

    methods (Access = protected)
        function n = dotListLength(~, ~, ~)
            n = 1;
        end

        function varargout = dotReference(obj, indexOp, ~)
            % Handle dot notation (.) for data key access
            %
            % With OverridesPublicDotMethodCall, ALL dot notation from outside
            % the class comes here first. We prioritize data keys over methods,
            % so users can have keys named "keys", "isfield", etc.
            % To call methods, use function syntax: keys(obj), isfield(obj, key)

            % Handle array dot reference: arr.field returns concatenated values
            if ~isscalar(obj)
                fieldName = indexOp(1).Name;

                % Block reserved key
                if fieldName == "xInternal__"
                    error('ConfigurationData:ReservedKey', ...
                        'Key "xInternal__" is reserved for internal use.');
                end

                % Check if next operation is Paren - pre-filter array by any valid index
                % This enables patterns: arr.field(1), arr.field(1:5), arr.field(logicalMask)
                remainingIndexOp = indexOp(2:end);
                if numel(indexOp) > 1 && indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
                    indices = indexOp(2).Indices;
                    if numel(indices) == 1
                        idx = indices{1};
                        % Pre-filter the array by any valid index (numeric, logical, range, etc.)
                        obj = obj(idx);
                        % Preserve index shape: reshape result to match idx shape
                        % For numeric idx, use idx shape; for logical, use sum(idx) with idx orientation
                        if isnumeric(idx)
                            obj = reshape(obj, size(idx));
                        elseif islogical(idx)
                            % Logical index: result count is sum(idx), preserve row/column orientation
                            if isrow(idx)
                                obj = reshape(obj, 1, []);
                            elseif iscolumn(idx)
                                obj = reshape(obj, [], 1);
                            end
                            % Otherwise keep whatever MATLAB gave us
                        end
                        remainingIndexOp = indexOp(3:end);  % Skip the Paren we just consumed
                    end
                end

                % Check which elements have the key (on potentially pre-filtered array)
                hasKey = iskey(obj, fieldName);

                % Collect values from all elements
                % For elements lacking the key, insert missing (read-only convenience)
                values = cell(size(obj));
                for i = 1:numel(obj)
                    if hasKey(i)
                        resolvedKey = obj(i).resolveKey(fieldName);
                        values{i} = obj(i).getData(resolvedKey);
                    else
                        values{i} = missing;
                    end
                end

                % Try to concatenate homogeneously
                result = obj.tryConcatenate(values, fieldName);

                % Handle chained indexing on the result
                if ~isempty(remainingIndexOp)
                    if isa(result, 'matlab.io.config.ConfigurationData') && ~isscalar(result)
                        % Recursive array dot reference
                        result = dotReference(result, remainingIndexOp);
                    elseif isa(result, 'matlab.io.config.ConfigurationData') && isscalar(result)
                        result = dotReference(result, remainingIndexOp);
                    else
                        % Can't chain into non-ConfigurationData
                        error('ConfigurationData:InvalidChain', ...
                            'Cannot chain into non-ConfigurationData value');
                    end
                end

                varargout{1} = result;
                return;
            end

            if indexOp(1).Type == "Dot"
                % Dot notation: obj.key
                key = indexOp(1).Name;

                % Block access to reserved internal property name
                if key == "xInternal__"
                    error('ConfigurationData:ReservedKey', ...
                        'Key "xInternal__" is reserved for internal use.');
                end

                % PRIORITY 1: Check if key exists in data (allows "keys", "isfield", etc.)
                resolvedKey = obj.resolveKey(key);
                if ~isempty(resolvedKey)
                    value = obj.getData(resolvedKey);

                    % Handle chained indexing
                    if length(indexOp) > 1
                        if indexOp(2).Type == "Paren"
                            % Array indexing: obj.key(indices)
                            indices = indexOp(2).Indices{:};
                            value = value(indices);

                            % Handle further chaining: obj.key(1).field
                            if length(indexOp) > 2
                                if isa(value, 'matlab.io.config.ConfigurationData')
                                    value = dotReference(value, indexOp(3:end));
                                else
                                    error('ConfigurationData:InvalidChain', ...
                                        'Cannot chain into non-ConfigurationData value');
                                end
                            end
                        elseif indexOp(2).Type == "Brace"
                            % Cell array indexing: obj.key{indices}
                            indices = indexOp(2).Indices{:};
                            value = value{indices};

                            % Handle further chaining: obj.key{1}.field
                            if length(indexOp) > 2
                                if isa(value, 'matlab.io.config.ConfigurationData')
                                    value = dotReference(value, indexOp(3:end));
                                else
                                    error('ConfigurationData:InvalidChain', ...
                                        'Cannot chain into non-ConfigurationData value');
                                end
                            end
                        elseif indexOp(2).Type == "Dot"
                            % Nested dot: obj.key.field
                            if isa(value, 'matlab.io.config.ConfigurationData')
                                value = dotReference(value, indexOp(2:end));
                            else
                                error('ConfigurationData:InvalidChain', ...
                                    'Cannot chain into non-ConfigurationData value');
                            end
                        end
                    end

                    varargout{1} = value;
                    return;
                end

                % Key doesn't exist - error
                error('ConfigurationData:InvalidKey', ...
                    'Key "%s" does not exist.', key);

            elseif indexOp(1).Type == "Paren"
                % Direct array indexing on obj: should not happen
                error('ConfigurationData:UnsupportedIndexing', ...
                    'Direct parenthesis indexing not supported');
            else
                error('ConfigurationData:UnsupportedIndexing', ...
                    'Unsupported indexing type: %s', indexOp(1).Type);
            end
        end

        function obj = dotAssign(obj, indexOp, varargin)
            key = indexOp(1).Name;

            % Block assignment to reserved internal property name
            if key == "xInternal__"
                error('ConfigurationData:ReservedKey', ...
                    'Key "xInternal__" is reserved for internal use.');
            end

            % Handle non-scalar array assignment
            if ~isscalar(obj)
                value = varargin{end};
                numElements = numel(obj);

                % Case 1: arr.field = value (assign to ALL elements)
                if numel(indexOp) == 1
                    if isscalar(value) || (numel(value) == 1)
                        % Broadcast scalar to all elements
                        for i = 1:numElements
                            obj(i) = dotAssign(obj(i), indexOp, value);
                        end
                    elseif numel(value) == numElements
                        % Element-wise assignment
                        for i = 1:numElements
                            obj(i) = dotAssign(obj(i), indexOp, value(i));
                        end
                    else
                        error('ConfigurationData:SizeMismatch', ...
                            ['Value size (%d) does not match array size (%d).'], ...
                            numel(value), numElements);
                    end
                    return;
                end

                % Case 2: arr.field(idx) = value (assign to indexed elements)
                if indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
                    indices = indexOp(2).Indices;
                    if numel(indices) == 1
                        idx = indices{1};

                        % Convert any index type to linear indices
                        if islogical(idx)
                            selectedIndices = find(idx);
                        elseif isnumeric(idx)
                            selectedIndices = idx(:)';  % Ensure row vector
                        elseif ischar(idx) && idx == ':'
                            selectedIndices = 1:numel(obj);
                        else
                            selectedIndices = idx;  % Let MATLAB handle other types
                        end
                        numSelected = numel(selectedIndices);

                        % Get field name for Case 2
                        fieldName = indexOp(1).Name;
                        hasMoreChain = numel(indexOp) > 2;
                        remainingChain = indexOp(3:end);

                        % Determine if value should be broadcast or indexed
                        if isscalar(value) || (numel(value) == 1)
                            % Scalar value - broadcast to all filtered elements
                            for i = 1:numSelected
                                objIdx = selectedIndices(i);
                                elem = obj(objIdx);
                                if hasMoreChain
                                    % More chaining: arr.field(idx).subfield = value
                                    % Get nested, apply chain, write back
                                    nested = elem.getData(fieldName);
                                    nested = dotAssign(nested, remainingChain, value);
                                    elem = elem.setData(fieldName, nested);
                                else
                                    % Direct: arr.field(idx) = value
                                    elem = elem.setData(fieldName, value);
                                end
                                obj(objIdx) = elem;
                            end
                        elseif numel(value) == numSelected
                            % Array value matching filtered size - assign element-wise
                            for i = 1:numSelected
                                objIdx = selectedIndices(i);
                                elem = obj(objIdx);
                                elemValue = value(i);
                                if hasMoreChain
                                    nested = elem.getData(fieldName);
                                    nested = dotAssign(nested, remainingChain, elemValue);
                                    elem = elem.setData(fieldName, nested);
                                else
                                    elem = elem.setData(fieldName, elemValue);
                                end
                                obj(objIdx) = elem;
                            end
                        else
                            error('ConfigurationData:SizeMismatch', ...
                                ['Value size (%d) does not match number of ' ...
                                 'selected elements (%d).'], numel(value), numSelected);
                        end
                        return;
                    end
                end
            end

            % Handle chained assignment: obj.a.b.c = value or obj.a(idx).b = value
            if length(indexOp) > 1
                % Check if next operation is Paren (array indexing)
                if indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
                    % Pattern: obj.field(idx)... = value
                    % Get the array
                    if ~isKey(obj.xInternal__.Data, key)
                        error('ConfigurationData:InvalidIndex', ...
                            'Cannot index into non-existent field ''%s''', key);
                    end
                    arr = obj.getData(key);

                    % Extract index
                    idx = indexOp(2).Indices{:};

                    % Get the element
                    elem = arr(idx);

                    % Apply remaining chain to element
                    if length(indexOp) > 2
                        % More operations after the paren: obj.field(idx).subfield = value
                        elem = dotAssign(elem, indexOp(3:end), varargin{:});
                    else
                        % Direct element replacement: obj.field(idx) = value
                        elem = varargin{end};
                    end

                    % Write element back to array
                    arr(idx) = elem;

                    % Store array back
                    obj = obj.setData(key, arr);
                else
                    % Pattern: obj.field.subfield = value (next op is Dot)
                    % Get or create the nested object
                    if isKey(obj.xInternal__.Data, key)
                        nested = obj.getData(key);
                        if ~isa(nested, 'matlab.io.config.ConfigurationData')
                            % Scalar value exists - replace with same class as parent
                            nested = feval(class(obj));
                            nested = copySourceFormat(obj, nested);
                        end
                    else
                        % Create new nested object of same class as parent
                        nested = feval(class(obj));
                        nested = copySourceFormat(obj, nested);
                    end

                    % Recursively assign to nested object
                    nested = dotAssign(nested, indexOp(2:end), varargin{:});

                    % Store the nested ConfigurationData directly (preserve order)
                    obj = obj.setData(key, nested);
                end

                % Track order
                if ~any(obj.xInternal__.OriginalKeys == key)
                    obj.xInternal__.OriginalKeys(end+1) = key;
                end

                % Create alias if needed
                validKey = matlab.lang.makeValidName(key);
                if ~strcmp(validKey, key)
                    obj.xInternal__.KeyAliases(validKey) = key;
                end
            else
                % Simple assignment: obj.key = value
                value = varargin{end};

                % Create alias if needed
                validKey = matlab.lang.makeValidName(key);
                if ~strcmp(validKey, key)
                    obj.xInternal__.KeyAliases(validKey) = key;
                end

                % Store
                obj = obj.setData(key, value);

                % Track order
                if ~any(obj.xInternal__.OriginalKeys == key)
                    obj.xInternal__.OriginalKeys(end+1) = key;
                end
            end
        end

        function obj = parenDotAssign(obj, indexOp, varargin)
            % Handle patterns:
            %   1. obj(idx).field = value  (array element assignment)
            %   2. obj.methodName = value  (method name conflicts)
            %
            % For pattern 1, indexOp(1) is Paren, indexOp(2) is Dot
            % For pattern 2, indexOp(1) is Dot (method name)

            value = varargin{end};

            if indexOp(1).Type == matlab.indexing.IndexingOperationType.Paren
                % Pattern: obj(idx).field = value (or obj(idx).field.subfield = ...)
                idx = indexOp(1).Indices{:};

                % Get the indexed element
                elem = obj(idx);

                % Apply the remaining dot operations
                if length(indexOp) > 1
                    elem = dotAssign(elem, indexOp(2:end), varargin{:});
                else
                    % Shouldn't happen for parenDot, but handle it
                    elem = value;
                end

                % Write element back
                obj(idx) = elem;
            else
                % Pattern: obj.methodName = value (method name conflict)
                key = indexOp(1).Name;

                % Block assignment to reserved internal property name
                if key == "xInternal__"
                    error('ConfigurationData:ReservedKey', ...
                        'Key "xInternal__" is reserved for internal use.');
                end

                % Store directly using setData to bypass method resolution
                obj = obj.setData(key, value);

                % Track order
                if ~any(obj.xInternal__.OriginalKeys == key)
                    obj.xInternal__.OriginalKeys(end+1) = key;
                end

                % Create alias if needed
                validKey = matlab.lang.makeValidName(key);
                if ~strcmp(validKey, key)
                    obj.xInternal__.KeyAliases(validKey) = key;
                end
            end
        end

        function n = parenDotListLength(~, ~, ~)
            n = 1;
        end

        function resolvedKey = resolveKey(obj, key)
            key = string(key);

            if isKey(obj.xInternal__.Data, key)
                resolvedKey = key;
                return;
            end

            if isKey(obj.xInternal__.KeyAliases, key)
                resolvedKey = obj.xInternal__.KeyAliases(key);
                return;
            end

            resolvedKey = '';
        end

        function s = dictToStruct(obj, d)
            %DICTTOSTRUCT Convert dictionary to struct recursively (private helper)
            s = struct;
            dictKeys = keys(d);
            for i = 1:length(dictKeys)
                key = dictKeys(i);
                val = d(key);
                value = val{1};  % Unwrap from cell

                % Recursively handle nested dictionaries
                if isa(value, 'dictionary')
                    value = obj.dictToStruct(value);
                end

                fieldName = matlab.lang.makeValidName(key);
                s.(fieldName) = value;
            end
        end

        function value = convertImportValue(obj, value)
            %CONVERTIMPORTVALUE Recursively convert nested structs/dicts to ConfigurationData
            %   This preserves the class type (YAMLData stays YAMLData, etc.)

            if isstruct(value)
                if isscalar(value)
                    % Scalar struct -> ConfigurationData of same class
                    nested = feval(class(obj));
                    nested = importFrom(nested, value);
                    value = nested;
                else
                    % Struct array -> array of ConfigurationData
                    arr(numel(value)) = feval(class(obj));
                    for iVal = 1:numel(value)
                        arr(iVal) = obj.convertImportValue(value(iVal));
                    end
                    value = arr;
                end
            elseif isa(value, 'dictionary')
                % Dictionary -> ConfigurationData of same class
                nested = feval(class(obj));
                nested = importFrom(nested, value);
                value = nested;
            end
            % Other types (numeric, string, etc.) pass through unchanged
            % They will be validated by setData when assigned
        end

        function result = tryConcatenate(~, values, fieldName)
            %TRYCONCATENATE Attempt to concatenate cell array of values into typed array
            %   Returns typed array if all values have same type, otherwise errors.
            %   This implements the "strict homogeneous" policy: no surprise cells.
            %
            %   Handles missing values: if an element lacks the key, missing is inserted.
            %   MATLAB's concatenation coerces missing to NaN for double/single, keeps it
            %   for string, but errors for integer/logical types.
            %
            %   The shape of the result matches the shape of the values cell array.
            %   If values is Nx1, result is Nx1. If values is 1xN, result is 1xN.

            if isempty(values)
                % Return empty double array (MATLAB-idiomatic "nothing")
                % This occurs when pre-filtering selects no elements
                result = [];
                return;
            end

            % Remember input shape to preserve it
            inputShape = size(values);

            % Get types of all values
            types = cellfun(@class, values, 'UniformOutput', false);

            % Check for missing values
            isMissingValue = strcmp(types, 'missing');

            if all(isMissingValue)
                % All values are missing - return missing array with correct shape
                result = repmat(missing, inputShape);
                return;
            end

            % Filter out missing when checking type homogeneity
            nonMissingTypes = types(~isMissingValue);
            uniqueTypes = unique(nonMissingTypes);

            if numel(uniqueTypes) > 1
                % Find first mismatch to report helpful error (ignoring missing)
                firstType = nonMissingTypes{1};
                firstIdx = find(~isMissingValue, 1, 'first');
                for i = 1:numel(types)
                    if ~isMissingValue(i) && ~strcmp(types{i}, firstType)
                        error('ConfigurationData:TypeMismatch', ...
                            ['Cannot concatenate values for key "%s": types differ.\n' ...
                             'Element %d is %s, element %d is %s.\n' ...
                             'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for heterogeneous values.'], ...
                            fieldName, firstIdx, firstType, i, types{i}, fieldName);
                    end
                end
            end

            % All non-missing values have same type
            theType = uniqueTypes{1};

            % Check for integer or logical types with missing values
            if any(isMissingValue) && ...
               (startsWith(theType, 'int') || startsWith(theType, 'uint') || strcmp(theType, 'logical'))
                error('ConfigurationData:MissingNotSupported', ...
                    ['Cannot concatenate values for key "%s": field has missing values.\n' ...
                     'Type %s cannot represent missing in MATLAB.\n' ...
                     'Use iskey(arr, ''%s'') to filter elements before accessing, or\n' ...
                     'use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
                    fieldName, theType, fieldName, fieldName);
            end

            % Handle different types appropriately
            if strcmp(theType, 'char')
                % char arrays -> convert to string array, preserve shape
                result = reshape(string(values), inputShape);
            elseif contains(theType, 'ConfigurationData') || ...
                   startsWith(theType, 'matlab.io.config.')
                % ConfigurationData objects -> concatenate into array
                try
                    result = reshape([values{:}], inputShape);
                catch
                    % Different sizes or incompatible - error
                    error('ConfigurationData:ConcatenationFailed', ...
                        ['Cannot concatenate ConfigurationData values for key "%s".\n' ...
                         'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
                        fieldName, fieldName);
                end
            elseif isnumeric(values{1}) || islogical(values{1}) || isstring(values{1})
                % Numeric, logical, string - try direct concatenation
                try
                    % Check if all values are scalars
                    allScalars = all(cellfun(@isscalar, values));
                    if allScalars
                        result = reshape([values{:}], inputShape);
                    else
                        % Non-scalar values - need to verify compatibility
                        % Check all have same size
                        sizes = cellfun(@size, values, 'UniformOutput', false);
                        if all(cellfun(@(s) isequal(s, sizes{1}), sizes))
                            % Same size - can concatenate
                            result = cat(1, values{:});
                        else
                            error('ConfigurationData:SizeMismatch', ...
                                ['Cannot concatenate values for key "%s": sizes differ.\n' ...
                                 'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
                                fieldName, fieldName);
                        end
                    end
                catch ME
                    if contains(ME.identifier, 'ConfigurationData:')
                        rethrow(ME);
                    end
                    error('ConfigurationData:ConcatenationFailed', ...
                        ['Cannot concatenate values for key "%s".\n' ...
                         'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
                        fieldName, fieldName);
                end
            else
                % Other types - try generic concatenation
                try
                    result = reshape([values{:}], inputShape);
                catch
                    error('ConfigurationData:ConcatenationFailed', ...
                        ['Cannot concatenate values for key "%s" of type %s.\n' ...
                         'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
                        fieldName, theType, fieldName);
                end
            end
        end
    end

    methods (Hidden)
        % Helper methods for dictionary access (encapsulate cell wrapping)
        % Public but hidden - needed for workarounds when key names conflict with methods
        function value = getData(obj, key)
            %GETDATA Get value from Data dictionary (unwraps cell)
            key = string(key);
            val = obj.xInternal__.Data(key);
            value = val{1};
        end

        function obj = setData(obj, key, value)
            %SETDATA Set value in Data dictionary (wraps in cell)
            %   Validates the value type before storing.
            key = string(key);
            value = obj.validateAndConvertValue(value, key);
            obj.xInternal__.Data(key) = {value};
        end

        function obj = addKey(obj, key)
            %ADDKEY Add a key to the key order tracking if not already present
            %   Used by parsers when directly manipulating data.
            key = string(key);
            if ~any(obj.xInternal__.OriginalKeys == key)
                obj.xInternal__.OriginalKeys(end+1) = key;
            end
        end

        function obj = setKeyAlias(obj, alias, originalKey)
            %SETKEYALIAS Set a key alias mapping
            %   Used by parsers when key names need valid MATLAB identifiers.
            alias = string(alias);
            originalKey = string(originalKey);
            obj.xInternal__.KeyAliases(alias) = originalKey;
        end

        function obj = importFrom(obj, inputData)
            %IMPORTFROM Import data from struct or dictionary
            %   This method handles conversion from external data types.
            %   It preserves the class type for nested objects.
            %
            %   For struct arrays, returns an array of ConfigurationData objects
            %   with the same shape as the input struct array.
            %
            %   Example:
            %       obj = tomldata();
            %       obj = importFrom(obj, myStruct);
            %
            %       % Struct array creates ConfigurationData array
            %       s = struct(A={1 2 3});  % 1x3 struct array
            %       arr = importFrom(jsondata(), s);  % 1x3 JSONData array

            if isstruct(inputData)
                if ~isscalar(inputData)
                    % Struct array -> array of ConfigurationData
                    % Create array with same size as input
                    arr(numel(inputData)) = feval(class(obj));
                    for i = 1:numel(inputData)
                        arr(i) = importFrom(feval(class(obj)), inputData(i));
                    end
                    obj = reshape(arr, size(inputData));
                    return;
                end

                % Scalar struct handling
                fields = fieldnames(inputData);
                for i = 1:numel(fields)
                    key = fields{i};
                    value = inputData.(key);
                    value = obj.convertImportValue(value);
                    obj.(key) = value;
                end
            elseif isa(inputData, 'dictionary')
                keyList = keys(inputData);
                for i = 1:numel(keyList)
                    key = keyList(i);
                    val = inputData(key);
                    value = val{1};  % Unwrap from cell
                    value = obj.convertImportValue(value);
                    obj.(key) = value;
                end
            else
                error('ConfigurationData:InvalidInput', ...
                    'Input must be struct or dictionary. Got %s.', class(inputData));
            end
        end
    end

    methods (Access = protected)
        function value = validateAndConvertValue(obj, value, key)
            %VALIDATEANDCONVERTVALUE Validate and optionally convert a value
            %   Subclasses can override to add format-specific type handling.
            %   Returns the (possibly converted) value, or throws an error.
            %
            %   Format-neutral objects (SourceFormat "unknown") accept all MATLAB
            %   types since they are not constrained by serialization requirements.

            % Format-neutral objects accept any MATLAB type
            if obj.xInternal__.SourceFormat == "unknown"
                return;
            end

            % Handle cell arrays recursively
            if iscell(value)
                for i = 1:numel(value)
                    value{i} = obj.validateAndConvertValue(value{i}, key);
                end
                return;
            end

            % Handle struct recursively
            if isstruct(value)
                fields = fieldnames(value);
                for i = 1:numel(value)
                    for j = 1:numel(fields)
                        value(i).(fields{j}) = obj.validateAndConvertValue(value(i).(fields{j}), key);
                    end
                end
                return;
            end

            % Allowed base types (numeric must be real - complex checked separately below)
            if (isnumeric(value) && isreal(value)) || islogical(value) || ischar(value) || isstring(value)
                return;  % OK
            end

            % ConfigurationData is always allowed
            if isa(value, 'matlab.io.config.ConfigurationData')
                return;  % OK
            end

            % missing represents JSON/config null
            if isa(value, 'missing')
                return;  % OK
            end

            % Empty values
            if isempty(value)
                return;  % OK (will revisit serialization)
            end

            % Datetime - base class converts to ISO 8601 string
            % Subclasses (like TOMLData) can override to keep native datetime
            if isa(value, 'datetime')
                value = string(value, 'yyyy-MM-dd''T''HH:mm:ss');
                return;
            end

            % Duration - convert to ISO 8601 duration or seconds
            if isa(value, 'duration')
                value = seconds(value);  % Convert to numeric seconds
                return;
            end

            % Disallowed types with helpful messages
            if isa(value, 'function_handle')
                error('ConfigurationData:InvalidType', ...
                    ['Cannot assign function_handle to key "%s".\n' ...
                     'Function handles cannot be serialized to configuration files.'], key);
            end

            if isa(value, 'table') || isa(value, 'timetable')
                error('ConfigurationData:InvalidType', ...
                    ['Cannot assign %s to key "%s".\n' ...
                     'Convert to struct first: struct(yourTable)'], class(value), key);
            end

            if isa(value, 'categorical')
                error('ConfigurationData:InvalidType', ...
                    ['Cannot assign categorical to key "%s".\n' ...
                     'Convert to string first: string(yourCategorical)'], key);
            end

            if isnumeric(value) && ~isreal(value)
                error('ConfigurationData:InvalidType', ...
                    ['Cannot assign complex numbers to key "%s".\n' ...
                     'Configuration files do not support imaginary numbers.'], key);
            end

            % Generic unsupported type
            error('ConfigurationData:InvalidType', ...
                ['Cannot assign %s to key "%s".\n' ...
                 'Supported types: numeric, logical, char, string, cell, struct, ' ...
                 'datetime, duration, and ConfigurationData objects.'], class(value), key);
        end
    end

    methods (Access = private)
        function target = copySourceFormat(obj, target)
            %COPYSOURCEFORMAT Copy SourceFormat to another ConfigurationData object
            %   Uses builtin to bypass overloaded dot methods, preventing
            %   SourceFormat from being added as a user data key.
            s = substruct('.', 'xInternal__');
            internal = builtin('subsref', target, s);
            internal.SourceFormat = obj.xInternal__.SourceFormat;
            target = builtin('subsasgn', target, s, internal);
        end

        function text = buildDescriptionText(obj, maxDepth)
            %BUILDDESCRIPTIONTEXT Build visual tree string for describe()
            lines = {};

            if ~isscalar(obj)
                % Non-scalar array header
                dims = size(obj);
                dimStr = join(string(dims), "x");
                lines{end+1} = sprintf('\n  %s array\n\n', dimStr);
                lines = [lines, buildArrayKeysText(obj, "    ")];
                lines{end+1} = newline;
            else
                % Scalar object header
                className = matlab.io.config.ConfigurationData.shortClassName(class(obj));
                nKeys = length(obj.xInternal__.OriginalKeys);
                if nKeys == 0
                    lines{end+1} = sprintf('\n  %s with no keys\n\n', className);
                else
                    lines{end+1} = sprintf('\n  %s with %d %s\n\n', className, nKeys, ...
                        matlab.io.config.ConfigurationData.pluralize("key", nKeys));
                    lines = [lines, buildKeysText(obj, "    ", 1, maxDepth)];
                    lines{end+1} = newline;
                end
            end

            text = strjoin(lines, '');
        end

        function text = buildDescriptionTable(obj, maxDepth)
            %BUILDDESCRIPTIONTABLE Build flat table for programmatic use
            paths = string.empty(0,1);
            types = string.empty(0,1);
            sizes = string.empty(0,1);

            if ~isscalar(obj)
                % Non-scalar array at root
                [paths, types, sizes] = collectArrayRows(obj, "", paths, types, sizes, 1, maxDepth);
            else
                [paths, types, sizes] = collectRows(obj, "", paths, types, sizes, 1, maxDepth);
            end

            text = table(paths, types, sizes, 'VariableNames', ["Path", "Type", "Size"]);
        end

        function lines = buildKeysText(obj, indent, currentDepth, maxDepth)
            %BUILDKEYSTEXT Build visual tree lines for a scalar object's keys
            lines = {};
            originalKeys = obj.xInternal__.OriginalKeys;

            if isempty(originalKeys)
                return;
            end

            % Calculate key column width for alignment
            maxKeyLen = max(strlength(originalKeys));
            keyColumnWidth = max(maxKeyLen + 2, 20);

            for i = 1:length(originalKeys)
                key = originalKeys(i);
                value = getData(obj, key);

                if isa(value, 'matlab.io.config.ConfigurationData')
                    if isscalar(value)
                        if currentDepth >= maxDepth
                            % Depth-limited: show key count
                            nKeys = length(keys(value));
                            paddedKey = pad(key + ":", keyColumnWidth);
                            lines{end+1} = sprintf('%s%s(%d %s)\n', indent, paddedKey, ...
                                nKeys, matlab.io.config.ConfigurationData.pluralize("key", nKeys)); %#ok<AGROW>
                        else
                            % Expanded: show key as header, recurse
                            lines{end+1} = sprintf('%s%s:\n', indent, key); %#ok<AGROW>
                            childLines = buildKeysText(value, indent + "    ", currentDepth + 1, maxDepth);
                            lines = [lines, childLines]; %#ok<AGROW>
                        end
                    else
                        % ConfigurationData array
                        dims = size(value);
                        dimStr = join(string(dims), "x");
                        if currentDepth >= maxDepth
                            % Depth-limited: show array dims and key count
                            allKeys = collectUnionOfKeys(value);
                            nUniqueKeys = length(allKeys);
                            paddedKey = pad(key + ":", keyColumnWidth);
                            lines{end+1} = sprintf('%s%s%s array (%d %s each)\n', indent, paddedKey, ...
                                dimStr, nUniqueKeys, matlab.io.config.ConfigurationData.pluralize("key", nUniqueKeys)); %#ok<AGROW>
                        else
                            % Expanded: show array header then union of keys with types
                            paddedKey = pad(key + ":", keyColumnWidth);
                            lines{end+1} = sprintf('%s%s%s array\n', indent, paddedKey, dimStr); %#ok<AGROW>
                            childLines = buildArrayKeysText(value, indent + "    ");
                            lines = [lines, childLines]; %#ok<AGROW>
                        end
                    end
                elseif isa(value, 'missing')
                    paddedKey = pad(key + ":", keyColumnWidth);
                    lines{end+1} = sprintf('%s%smissing\n', indent, paddedKey); %#ok<AGROW>
                elseif ischar(value)
                    paddedKey = pad(key + ":", keyColumnWidth);
                    lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
                        matlab.io.config.ConfigurationData.formatLeafValue(value)); %#ok<AGROW>
                elseif isempty(value)
                    paddedKey = pad(key + ":", keyColumnWidth);
                    sizeStr = join(string(size(value)), "x");
                    lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
                elseif isscalar(value) && (isstring(value) || isnumeric(value) || islogical(value))
                    % Scalar leaf - show value with type annotation
                    paddedKey = pad(key + ":", keyColumnWidth);
                    lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
                        matlab.io.config.ConfigurationData.formatLeafValue(value)); %#ok<AGROW>
                else
                    % Non-scalar leaf - show size and type
                    paddedKey = pad(key + ":", keyColumnWidth);
                    sizeStr = join(string(size(value)), "x");
                    lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
                end
            end
        end

        function lines = buildArrayKeysText(obj, indent)
            %BUILDARRAYKEYSTEXT Build type-only display for ConfigurationData array keys
            lines = {};

            uniqueKeys = collectUnionOfKeys(obj);

            if isempty(uniqueKeys)
                return;
            end

            maxKeyLen = max(strlength(uniqueKeys));
            keyColumnWidth = max(maxKeyLen + 2, 20);

            for i = 1:length(uniqueKeys)
                key = uniqueKeys(i);

                % Find type from first element that has this key
                typeDisplay = "";
                for j = 1:numel(obj)
                    if iskey(obj(j), key)
                        value = getData(obj(j), key);
                        if isa(value, 'matlab.io.config.ConfigurationData')
                            if isscalar(value)
                                nKeys = length(keys(value));
                                typeDisplay = sprintf("(%d %s)", nKeys, ...
                                    matlab.io.config.ConfigurationData.pluralize("key", nKeys));
                            else
                                dims = size(value);
                                dimStr = join(string(dims), "x");
                                childKeys = collectUnionOfKeys(value);
                                nKeys = length(childKeys);
                                typeDisplay = sprintf("%s array (%d %s each)", dimStr, nKeys, ...
                                    matlab.io.config.ConfigurationData.pluralize("key", nKeys));
                            end
                        else
                            typeDisplay = string(class(value));
                        end
                        break;
                    end
                end

                paddedKey = pad(key + ":", keyColumnWidth);
                lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, typeDisplay); %#ok<AGROW>
            end
        end

        function text = buildShowText(obj, varName)
            %BUILDSHOWTEXT Build value-focused display string for show()
            lines = {};

            if ~isscalar(obj)
                % Top-level array: ND array style (like X(:,:,k) = )
                for i = 1:numel(obj)
                    lines{end+1} = sprintf('%s(%d) =\n', varName, i); %#ok<AGROW>
                    lines{end+1} = newline; %#ok<AGROW>
                    childLines = buildShowKeysText(obj(i), "    ", 1, Inf);
                    lines = [lines, childLines]; %#ok<AGROW>
                    lines{end+1} = newline; %#ok<AGROW>
                    lines{end+1} = newline; %#ok<AGROW>
                end
            else
                % Scalar: header then indented key-value tree
                className = matlab.io.config.ConfigurationData.shortClassName(class(obj));
                nKeys = length(obj.xInternal__.OriginalKeys);
                if nKeys == 0
                    lines{end+1} = sprintf('\n  %s with no keys\n\n', className);
                else
                    lines{end+1} = sprintf('\n  %s with %d %s\n\n', className, nKeys, ...
                        matlab.io.config.ConfigurationData.pluralize("key", nKeys));
                    lines = [lines, buildShowKeysText(obj, "    ", 1, Inf)];
                    lines{end+1} = newline;
                end
            end

            text = strjoin(lines, '');
        end

        function lines = buildShowKeysText(obj, indent, currentDepth, maxDepth)
            %BUILDSHOWKEYSTEXT Build value tree lines for show() — no type annotations,
            %   arrays expanded with ND-array style key(i) = headers
            lines = {};
            originalKeys = obj.xInternal__.OriginalKeys;

            if isempty(originalKeys)
                return;
            end

            maxKeyLen = max(strlength(originalKeys));
            keyColumnWidth = max(maxKeyLen + 2, 20);

            for i = 1:length(originalKeys)
                key = originalKeys(i);
                value = getData(obj, key);

                if isa(value, 'matlab.io.config.ConfigurationData')
                    if isscalar(value)
                        if currentDepth >= maxDepth
                            nKeys = length(keys(value));
                            paddedKey = pad(key + ":", keyColumnWidth);
                            lines{end+1} = sprintf('%s%s(%d %s)\n', indent, paddedKey, ...
                                nKeys, matlab.io.config.ConfigurationData.pluralize("key", nKeys)); %#ok<AGROW>
                        else
                            lines{end+1} = sprintf('%s%s:\n', indent, key); %#ok<AGROW>
                            childLines = buildShowKeysText(value, indent + "    ", currentDepth + 1, maxDepth);
                            lines = [lines, childLines]; %#ok<AGROW>
                        end
                    else
                        % ConfigurationData array: ND-array style, one element per block
                        dims = size(value);
                        dimStr = join(string(dims), "x");
                        paddedKey = pad(key + ":", keyColumnWidth);
                        lines{end+1} = sprintf('%s%s%s array\n', indent, paddedKey, dimStr); %#ok<AGROW>
                        for j = 1:numel(value)
                            lines{end+1} = sprintf('%s%s(%d) =\n', indent, key, j); %#ok<AGROW>
                            childLines = buildShowKeysText(value(j), indent + "    ", currentDepth + 1, maxDepth);
                            lines = [lines, childLines]; %#ok<AGROW>
                        end
                    end
                elseif isa(value, 'missing')
                    paddedKey = pad(key + ":", keyColumnWidth);
                    lines{end+1} = sprintf('%s%smissing\n', indent, paddedKey); %#ok<AGROW>
                elseif isempty(value)
                    paddedKey = pad(key + ":", keyColumnWidth);
                    sizeStr = join(string(size(value)), "x");
                    lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
                elseif ischar(value)
                    paddedKey = pad(key + ":", keyColumnWidth);
                    lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
                        matlab.io.config.ConfigurationData.formatShowLeafValue(value)); %#ok<AGROW>
                elseif isscalar(value) && (isstring(value) || isnumeric(value) || islogical(value))
                    paddedKey = pad(key + ":", keyColumnWidth);
                    lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
                        matlab.io.config.ConfigurationData.formatShowLeafValue(value)); %#ok<AGROW>
                else
                    % Non-scalar leaf: show size and type
                    paddedKey = pad(key + ":", keyColumnWidth);
                    sizeStr = join(string(size(value)), "x");
                    lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
                end
            end
        end

        function uniqueKeys = collectUnionOfKeys(obj)
            %COLLECTUNIONOFKEYS Get union of keys across array elements (preserving order)
            allKeys = string.empty(0,1);
            for i = 1:numel(obj)
                elementKeys = keys(obj(i));
                allKeys = [allKeys; reshape(elementKeys, [], 1)]; %#ok<AGROW>
            end
            uniqueKeys = unique(allKeys, 'stable');
        end

        function [paths, types, sizes] = collectRows(obj, prefix, paths, types, sizes, currentDepth, maxDepth)
            %COLLECTROWS Collect table rows for a scalar ConfigurationData
            originalKeys = obj.xInternal__.OriginalKeys;

            for i = 1:length(originalKeys)
                key = originalKeys(i);
                value = getData(obj, key);

                if prefix == ""
                    fullPath = key;
                else
                    fullPath = prefix + "." + key;
                end

                % Get size and type strings
                sizeStr = join(string(size(value)), "x");
                typeName = string(matlab.io.config.ConfigurationData.shortClassName(class(value)));

                % Add row for this key
                paths(end+1,1) = fullPath; %#ok<AGROW>
                types(end+1,1) = typeName; %#ok<AGROW>
                sizes(end+1,1) = sizeStr; %#ok<AGROW>

                % Recurse into nested ConfigurationData
                if isa(value, 'matlab.io.config.ConfigurationData') && currentDepth < maxDepth
                    if isscalar(value)
                        [paths, types, sizes] = collectRows(value, fullPath, paths, types, sizes, currentDepth + 1, maxDepth);
                    else
                        [paths, types, sizes] = collectArrayRows(value, fullPath, paths, types, sizes, currentDepth + 1, maxDepth);
                    end
                end
            end
        end

        function [paths, types, sizes] = collectArrayRows(obj, prefix, paths, types, sizes, ~, ~)
            %COLLECTARRAYROWS Collect table rows for a ConfigurationData array
            uniqueKeys = collectUnionOfKeys(obj);

            for i = 1:length(uniqueKeys)
                key = uniqueKeys(i);

                if prefix == ""
                    fullPath = key;
                else
                    fullPath = prefix + "." + key;
                end

                % Collect types across all elements that have this key
                foundTypes = string.empty(0,1);
                firstSize = "";
                for j = 1:numel(obj)
                    if iskey(obj(j), key)
                        val = getData(obj(j), key);
                        typeName = string(matlab.io.config.ConfigurationData.shortClassName(class(val)));
                        if ~any(foundTypes == typeName)
                            foundTypes(end+1,1) = typeName; %#ok<AGROW>
                        end
                        if firstSize == ""
                            firstSize = join(string(size(val)), "x");
                        end
                    end
                end

                if isscalar(foundTypes)
                    displayType = foundTypes(1);
                else
                    displayType = "mixed types: " + join(foundTypes, ", ");
                end

                paths(end+1,1) = fullPath; %#ok<AGROW>
                types(end+1,1) = displayType; %#ok<AGROW>
                sizes(end+1,1) = firstSize; %#ok<AGROW>
            end
        end
    end

    methods (Static, Access = private)
        function word = pluralize(singular, count)
            %PLURALIZE Return singular or plural form based on count
            if count == 1
                word = singular;
            else
                word = singular + "s";
            end
        end

        function shortName = shortClassName(fullName)
            %SHORTCLASSNAME Strip namespace prefix from class name for cleaner display
            %   'matlab.io.config.TOMLData' -> 'TOMLData'
            shortName = regexprep(fullName, '^matlab\.io\.config\.', '');
        end

        function str = formatShowLeafValue(value)
            %FORMATSHOWLEAFVALUE Format a scalar leaf value for show() — no type annotation
            if isstring(value)
                if strlength(value) > 40
                    str = sprintf('"%s..."', extractBefore(value, 41));
                else
                    str = sprintf('"%s"', value);
                end
            elseif ischar(value)
                if length(value) > 40
                    str = sprintf('''%s...''', value(1:40));
                else
                    str = sprintf('''%s''', value);
                end
            elseif isnumeric(value)
                str = sprintf('%g', value);
            elseif islogical(value)
                if value
                    str = "true";
                else
                    str = "false";
                end
            else
                str = sprintf('%s', class(value));
            end
        end

        function str = formatLeafValue(value)
            %FORMATLEAFVALUE Format a scalar leaf value for describe() display
            if isstring(value)
                if strlength(value) > 40
                    str = sprintf('"%s..." (string)', extractBefore(value, 41));
                else
                    str = sprintf('"%s" (string)', value);
                end
            elseif ischar(value)
                if length(value) > 40
                    str = sprintf('''%s...'' (char)', value(1:40));
                else
                    str = sprintf('''%s'' (char)', value);
                end
            elseif isnumeric(value)
                str = sprintf('%g (%s)', value, class(value));
            elseif islogical(value)
                if value
                    str = "true (logical)";
                else
                    str = "false (logical)";
                end
            else
                str = sprintf('%s', class(value));
            end
        end
    end
end
