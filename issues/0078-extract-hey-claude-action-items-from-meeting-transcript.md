# #78: Extract "Hey Claude" action items from a meeting transcript

**State:** open
**Created:** 2026-02-27
**Labels:** tooling, workflow

## Description

## Background

During meetings, it's common to address Claude directly with action items (e.g., "Hey Claude", "Claude, do X"). These explicit directives get lost in long transcripts and need to be extracted systematically.

## Proposal

Implement a transcript parser or workflow that:

1. **Detects direct addresses**: Find phrases like:
   - "Hey Claude"
   - "Claude, [action]"
   - "@Claude"
   - Other patterns indicating explicit direction to Claude

2. **Extracts context**: Capture the full sentence(s) containing the directive, including enough surrounding context to understand intent.

3. **Infers action items**: For each detected instance:
   - Quote the relevant text
   - Infer the intended task or request
   - Rewrite as a clear, standalone action item

4. **Returns structured output**: A concise list of action items, ideally in a format suitable for issue creation or task tracking.

## Use Cases

- Post-meeting processing of transcripts
- Ensuring no action items are missed
- Converting meeting notes into actionable tasks
- Integration with issue tracking (automatic issue file creation)

## Example Input

```
[Meeting transcript]
"...and the YAML parser is handling most cases well. Hey Claude, can you
look into whether we should normalize array orientation? Also, Claude,
create an issue for the schema preservation idea we discussed..."
```

## Example Output

```markdown
1. **Action**: Investigate normalizing YAML array orientation
   - Source: "Hey Claude, can you look into whether we should normalize array orientation?"
   - Task: Research and propose a consistent orientation convention for YAML arrays

2. **Action**: Create issue for schema preservation
   - Source: "Claude, create an issue for the schema preservation idea we discussed"
   - Task: Document schema preservation as a feature request with design considerations
```

## Implementation Options

- MATLAB script using text processing
- LLM-based extraction (prompt engineering)
- Integration with meeting transcript tools
- Part of a broader meeting notes workflow

## Related

- Could be implemented as a MATLAB function or skill
- May benefit from LLM summarization capabilities
- Related to issue creation automation
