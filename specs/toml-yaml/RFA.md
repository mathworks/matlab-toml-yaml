# RFA Spec: Adding TOML and YAML support to MATLAB

**Project:** Adding TOML and YAML support to MATLAB
**Author:** Michelle Hirsch
**Date:** January 15, 2026
**Revised:** February 2026
**Status:** Draft

---

## Overview

This RFA describes MATLAB functions and classes for reading and writing YAML and TOML.

**Core design choices:**
- Returns `YAMLData` / `TOMLData` value class objects — not plain structs — to support keys with hyphens and other special characters ubiquitous in real config files
- Data round-trip fidelity: values are preserved through read → modify → write; comments and formatting are not
- Pure MATLAB implementation: no Java libraries, MEX files, or toolbox dependencies

---

## Sections

- [Project Details](project-details.md) — motivation, key users, supported workflows, technical constraints, risks
- [Format Background](format-background.md) — YAML and TOML primer; core concepts, real-world examples, MATLAB mapping, and a side-by-side comparison
- [Requirements Analysis](requirements.md) — user roles, use cases with concrete examples and pain points, benchmark review of existing tools, and requirement tables
- [Functional Design](functional-design.md) — full API reference (`readyaml`, `writeyaml`, `readtoml`, `writetoml`, `yamldata`, `tomldata`, class docs), design cases, and alternate designs considered
- [Architectural Design](architectural-design.md) — class hierarchy, internal storage (`xInternal__`), value semantics via `dictionary`, informal/formal interface split, and alternate architectures considered
- [Test Strategy](test-strategy.md) — test categories, sample files, and test execution patterns
- [Documentation Notes](documentation-notes.md) — documentation deliverables checklist and key points to cover
