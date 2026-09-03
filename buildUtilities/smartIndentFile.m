function changed = smartIndentFile(filePath)
    %SMARTINDENTFILE Auto-indent a single .m file using the MATLAB editor.
    %   Returns true if the file was modified, false otherwise.
    original = fileread(filePath);
    doc = matlab.desktop.editor.openDocument(filePath);
    smartIndentContents(doc);
    save(doc);
    closeNoPrompt(doc);
    changed = ~strcmp(fileread(filePath), original);
end
