function obj = assignKey(obj, key, val)
    %ASSIGNKEY Assign a key on a ConfigurationData object from outside the class.
    %   OverridesPublicDotMethodCall only applies to external access, so
    %   importFrom (a superclass method) cannot use obj.(key) = val when
    %   key matches a method name. This standalone function provides the
    %   external context needed for correct dot-assignment dispatch.
    obj.(key) = val;
end
