function flags = staticLibcxxFlags()
    % On Linux, statically link libstdc++ so the MEX binary works even when
    % the system compiler is newer than MATLAB's bundled C++ runtime.
    flags = string.empty;
    if ~isunix || ismac
        return
    end
    archDir = fullfile(matlabroot, "bin", computer("arch"));
    extDir  = fullfile(matlabroot, "extern", "bin", computer("arch"));
    flags = ["LDFLAGS=$LDFLAGS -static-libstdc++", ...
        "LINKLIBS=-Wl,--as-needed" ...
        + " -L" + archDir + " -L" + extDir ...
        + " -lMatlabDataArray -lmx -lmex -lm -lmat"];
end
