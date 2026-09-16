function summary = mergeCoverageReports(artifactsDir, options)
%MERGECOVERAGEREPORTS Merge coverage results and produce HTML + Markdown reports.
%   SUMMARY = MERGECOVERAGEREPORTS(ARTIFACTSDIR) searches ARTIFACTSDIR
%   recursively for result.mat files (saved by the test task on R2023a+),
%   merges them using the + operator on matlab.coverage.Result, and returns
%   a Markdown summary string.
%
%   MERGECOVERAGEREPORTS(..., OutputHtml=DIR) generates an interactive HTML
%   coverage report in DIR using generateHTMLReport.
%
%   MERGECOVERAGEREPORTS(..., OutputXml=PATH) generates a combined Cobertura
%   XML report at PATH using generateCoberturaReport.
%
%   MERGECOVERAGEREPORTS(..., OutputMarkdown=PATH) writes the Markdown
%   summary to PATH.

    arguments
        artifactsDir (1,1) string
        options.OutputHtml (1,1) string = string(missing)
        options.OutputXml (1,1) string = string(missing)
        options.OutputMarkdown (1,1) string = string(missing)
    end

    merged = loadAndCombine(artifactsDir);

    summary = buildMarkdownSummary(merged);
    fprintf("\n%s\n", summary);

    % Generate optional outputs.
    if ~ismissing(options.OutputHtml)
        generateHTMLReport(merged, options.OutputHtml);
        fprintf("Wrote HTML report to %s\n", options.OutputHtml);
    end

    if ~ismissing(options.OutputXml)
        generateCoberturaReport(merged, options.OutputXml);
        fprintf("Wrote %s\n", options.OutputXml);
    end

    if ~ismissing(options.OutputMarkdown)
        parentDir = fileparts(options.OutputMarkdown);
        if strlength(parentDir) > 0 && ~isfolder(parentDir)
            mkdir(parentDir);
        end
        writelines(summary, options.OutputMarkdown);
        fprintf("Wrote %s\n", options.OutputMarkdown);
    end
end

function merged = loadAndCombine(artifactsDir)
    matFiles = dir(fullfile(artifactsDir, '**', 'result.mat'));
    assert(~isempty(matFiles), "mergeCoverageReports:noFiles", ...
        "No result.mat files found in %s", artifactsDir);
    fprintf("Merging %d coverage result(s)\n", numel(matFiles));

    merged = matlab.coverage.Result.empty;
    for i = 1:numel(matFiles)
        matPath = fullfile(matFiles(i).folder, matFiles(i).name);
        fprintf("  %s\n", matPath);
        data = load(matPath, "result");
        if isempty(merged)
            merged = data.result;
        else
            merged = merged + data.result;
        end
    end
end

function summary = buildMarkdownSummary(merged)
    summaryMatrix = coverageSummary(merged, "statement");
    filenames = [merged.Filename]';
    filenames = replace(filenames, "\", "/");
    toolboxIdx = strfind(filenames, "toolbox/");
    for i = 1:numel(filenames)
        if ~isempty(toolboxIdx{i})
            filenames(i) = extractAfter(filenames(i), toolboxIdx{i}(1) + strlength("toolbox/") - 1);
        end
    end
    executed = summaryMatrix(:, 1);
    total = summaryMatrix(:, 2);

    coveredLines = sum(executed);
    totalLines = sum(total);
    overallRate = coveredLines / totalLines * 100;

    md = strings(0);
    md(end+1) = "### Combined Code Coverage";
    md(end+1) = "";
    md(end+1) = sprintf("**Overall: %.1f%% statement coverage (%d/%d)**", ...
        overallRate, coveredLines, totalLines);
    md(end+1) = "";
    md(end+1) = "| File | Coverage | Statements |";
    md(end+1) = "|------|-------:|-----------:|";
    for i = 1:numel(filenames)
        if total(i) == 0
            md(end+1) = sprintf("| %s | N/A | 0/0 |", filenames(i)); %#ok<AGROW>
        else
            rate = executed(i) / total(i) * 100;
            md(end+1) = sprintf("| %s | %.1f%% | %d/%d |", ...
                filenames(i), rate, executed(i), total(i)); %#ok<AGROW>
        end
    end
    summary = join(md, newline);
end
