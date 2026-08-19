function array = normalizeVectorOrientation(array)
%NORMALIZEVECTORORIENTATION Normalize vectors to column orientation
%   Ensures consistent concatenation behavior across all configuration
%   formats (YAML, TOML).
%
%   Rationale: Column vector values enable natural concatenation when
%   extracting from 1xN object arrays (the common case). For 1xN objArray:
%     objArray.key with column values -> clean MxN array via horzcat
%     objArray.key with row values -> flattened 1x(M*N) via horzcat
%
%   What gets normalized:
%     - Numeric arrays (double, single, int*, uint*)
%     - String arrays
%     - Logical arrays
%     - ConfigurationData object arrays
%
%   What does NOT get normalized:
%     - Cell arrays (no clear orientation semantics)
%     - Struct arrays (complex semantics)
%     - Scalar values (orientation-neutral)
%     - Empty arrays (no orientation)
%     - Multi-dimensional arrays (only true vectors - one dimension is 1)
%
%   See Issue #77.

% Skip empty, scalar, cell arrays, and struct arrays
if isempty(array) || isscalar(array) || iscell(array) || isstruct(array)
    return;
end

% Get array size
arraySize = size(array);

% Only normalize true vectors (one dimension is 1, the other > 1)
% This skips multi-dimensional arrays like 2x3 matrices
if numel(arraySize) == 2 && arraySize(1) == 1 && arraySize(2) > 1
    % Row vector (1xN) -> transpose to column (Nx1)
    array = array(:);
end
% Column vectors (Nx1) and multi-dimensional arrays pass through unchanged
end
