# Module Registry - Riffle

> **The Highlander Rule**: There can be only one module per concern.
> ALWAYS check this file before creating a new module. If a module already owns that concern, use it.
> When you must create a new module, register it here FIRST, then create the file.

## Registry

### Predicate engine

| Concern                                 | THE Module                          | Notes                                                                          |
| --------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------ |
| Item shape + field/tag/metadata access  | Riffle.Predicate.Item               | fieldnames/fields/tags/metadata; add_tag prepends + dedups                     |
| Predicate definition + evaluation       | Riffle.Predicate                    | evaluate/2 is the one cached entry; create/1 the one body-to-function path     |
| Predicate grouping (OR-any)             | Riffle.Predicate.Loop               | filter/2 rides process/2 -- one evaluation path, cache honoured on streams     |
| Loop sequencing (AND of ORs)            | Riffle.Predicate.Pipeline           | struct paths only; map shapes normalise through the Resolver                   |
| Reference resolution + hydration        | Riffle.Predicate.Resolver           | THE path (DD-9); tagged core + bang wrappers; sources: module, defs-map, nil   |
| Coercion (numeric parse, truthiness)    | Riffle.Predicate.Coerce             | strict, tagged (DD-8); consumed by Evaluator + StandardLib                     |
| Evaluation cache                        | Riffle.Predicate.Cache              | ETS + GenServer; exact-term {predicate, item} keys                             |
| Runtime definition registry             | Riffle.Predicate.Registry           | GenServer; its state is a Resolver defs-map source                             |
| Standard predicate library              | Riffle.Predicate.StandardLib        | Text/Numeric/Boolean/Collection/Date; STD is its alias, nothing else           |
| Default-pipeline config surface         | Riffle.Predicate.default_pipeline/0 | config :riffle, :default_pipeline; DefaultPipelineConfig is the use-macro side |
| Pipeline-config behaviour               | Riffle.Predicate.PipelineConfig     | get_pipeline/get_loop/get_predicate callbacks                                  |
| DSL compile-time macros                 | Riffle.Predicate.Dsl.Macro          | defpredicate/defloop/defpipeline + expr; generated fns call the Resolver       |
| DSL block statement-shape ladder        | Riffle.Predicate.Dsl.Statements     | THE in-block grammar (refs + inline defs); Macro and Parser both consume it    |
| DSL expr evaluation                     | Riffle.Predicate.Dsl.Evaluator      | @field syntax; CoercionError converts to no-match at create_function/1         |
| .pred parsing                           | Riffle.Predicate.Dsl.Parser         | one top-level dispatch (extract_definitions!); junk raises at every level      |
| .pred loading + instance creation       | Riffle.Predicate.Dsl.Loader         | user-input boundary: raises become tagged errors                               |
| OTP application                         | Riffle.Application                  | supervises the Cache                                                           |

### ctx-next (the waist)

| Concern                                 | THE Module                          | Notes                                                                          |
| --------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------ |
| Run state (typed composite root)        | Riffle.Ctx                          | typed slots read by dot + ONE declared overlay; no pass-through accessors      |
| State transition (the pure knot)        | Riffle.Ctx.Knot                     | tick/2; pure, total, multi-clause; the single transition point (DD-4)          |
| Catalog mechanism + the type contract   | Riffle.Ctx.Catalog                  | THE registry machine; both catalogs use it; duplicate tags fail at compile time |
| Typed inputs (membership + union)       | Riffle.Ctx.Perturbation             | structs under Riffle.Ctx.Perturbation.*; unknown tag loud-fails                |
| Typed outputs (membership + union)      | Riffle.Ctx.Emission                 | structs under Riffle.Ctx.Emission.*; payloads opaque to the waist              |
| Waist identity + fence introspection    | Riffle.WaistHelpers (test/support)  | namespace, source paths, typespec + alias walks shared by every waist fence    |

<!-- Add entries as modules are created. Group by domain. Example:

### Auth

| Concern            | THE Module           | Notes                        |
| ------------------ | -------------------- | ---------------------------- |
| User authentication | MyApp.Auth.Guardian  | JWT tokens, session handling |
| Authorization       | MyApp.Auth.Policy    | Role-based access control    |

### Core

| Concern            | THE Module           | Notes                        |
| ------------------ | -------------------- | ---------------------------- |
| Email delivery      | MyApp.Core.Mailer    | Swoosh adapter               |
| Background jobs     | MyApp.Core.Jobs      | Oban worker coordinator      |

### Content

| Concern            | THE Module           | Notes                        |
| ------------------ | -------------------- | ---------------------------- |
| File uploads        | MyApp.Content.Upload | S3 storage, image processing |

-->

## How to Use This File

1. **Before creating a new module**: Search this table. If the concern is listed, use that module.
2. **When adding a new module**: Add a row here first, then create the file.
3. **When refactoring**: Update this table to reflect the new module ownership.
4. **When removing a module**: Remove its row from this table.

Violations of the Highlander Rule (duplicate modules for the same concern) are the #1 source of code quality debt.
