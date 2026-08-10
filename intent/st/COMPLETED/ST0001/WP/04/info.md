---
verblock: "10 Aug 2026:v0.1: matts - Initial version"
wp_id: WP-04
title: "PFIC transform and hydration consolidation"
scope: Medium
status: Done
---

# WP-04: PFIC transform and hydration consolidation

## Objective

Execute DD-7 (hv ruling): transform the ported engine to house shape -- pattern-matched clause heads, with-railways, tagged tuples -- and collapse the six ad-hoc hydration/resolution sites (four different failure behaviours) into one loud resolver, of which `Loop.resolve_reference!/2` and `Dsl.Macro.hydrate_*_ref!/2` are the seeds. File-by-file, gate green at every step; the behaviour pins landed by WP-03 (un-neutered filtering tests, exact tag/counter pins) are the safety net.

## Deliverables

- Single hydration/resolution module; pipeline.ex, loop.ex, registry.ex, loader.ex, and the macro layer all route through it (kills the remaining nil-propagation and silent-drop warnings from the critic report)
- Loop single-item and stream paths share one evaluation entry point (today `process/2` is cached, `filter/2` bypasses the cache entirely)
- One STD access path (delete the `Riffle.Predicate.STD` / `Dsl.STD` twin)
- macro/parser block-level unrecognised statements raise instead of silently dropping
- expr-macro test family consolidated: one canonical expr test file + shared support helper; bug/workaround scratch files deleted (diagnosis lives in git history)
- DSL coercion contract (to_integer garbage->0, truthiness drift between Evaluator and StandardLib) decided by hv, then enforced in one canonical coercion module
- critic-elixir re-run on lib/ + test/: zero CRITICAL, zero Highlander/PFIC WARNINGs

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-04` heading (single source of truth). Do not restate ACs here.

## Dependencies

- WP-03 done (behaviour pins in place). The critic advisory suggests a socrates design pass on the resolver consolidation before implementation. AC-04.5 (coercion contract) needs an hv ruling before its implementation starts.
