# The `.pred` language

A `.pred` file declares predicates, loops and pipelines as text, so changing what a run matches is a change to a file rather than to code. `Riffle.Sia.DefaultPipeline` declares the same things in Elixir through `Riffle.Predicate.Dsl.Macro`, and the two forms accept the same words: `priv/sia/sia.pred` and that module are kept identical on purpose, and a test holds them to producing the same items with the same tags.

The file is read with Elixir's own parser, so the syntax is Elixir syntax -- atoms, strings, `do` blocks, and the operators below. It is not run as Elixir. Only three forms are recognised at the top level, and anything else raises rather than being quietly skipped: a misspelled definition that vanished silently would change what a pipeline matches with no signal at all.

## The three definitions

A **predicate** is a name, a description and a test on one item.

A **loop** is a group of predicates. An item survives a loop if _any_ of its predicates match, and it carries away the name of every predicate that did match, as a tag.

A **pipeline** is a sequence of loops. An item survives a pipeline only if it survives _every_ loop in turn, so each loop is a strictly narrower cut than the one before it. One loop is one stage of a run: a pipeline with four loops runs as four stages, and nothing in the runner knows how many there are meant to be.

```pred
predicate(:high_activity, "Users with more than fifty logins") do
  expr(@login_count > 50)
end

loop(:signals, "What the raw fields say") do
  predicate(:high_activity)
end

pipeline(:main, "The whole run") do
  loop(:signals)
end
```

The description is optional in all three:

```pred
predicate(:active) do
  expr(@status == "active")
end
```

A name is written as an atom. A bare word is accepted as the same name -- `predicate(active, ...)` and `predicate(:active, ...)` define the same predicate -- but the atom is the form to write.

### References and inline definitions

A loop body holds predicate _references_ -- `predicate(:name)` -- or whole predicate definitions written in place. A pipeline body holds loop references or whole loop definitions, and an inline loop's body follows the loop-body grammar in turn. So the example above can be written as one nested definition:

```pred
pipeline(:main, "Everything declared in place") do
  loop(:signals, "What the raw fields say") do
    predicate(:high_activity, "More than fifty logins") do
      expr(@login_count > 50)
    end
  end
end
```

Both spellings produce the same pipeline. Separate definitions are worth it when a predicate is shared by more than one loop; inline is worth it when it is not.

Anything else inside a block raises an `ArgumentError` naming the container -- a loop body may contain only predicate references or predicate definitions, and a pipeline body only loop references or loop definitions.

## Predicate bodies

A predicate body takes one of three forms.

```pred
predicate(:by_expr, "The expression language") do
  expr(@status == "active")
end

predicate(:by_call, "A standard-library predicate, applied") do
  call &STD.Text.equals/2, ["status", "active"]
end

predicate(:by_function, "An anonymous function over the item") do
  fn item -> item.fields["status"] == "active" end
end
```

`expr` is the expression language documented below, and is the form to reach for first.

`call` names a builder function and the arguments to apply to it; the builder must return a function of one argument, which becomes the predicate. `STD` is bound to `Riffle.Predicate.StandardLib` wherever a body is evaluated, so `.pred` text can name the standard library without an alias of its own.

Any other body is evaluated as Elixir and must produce a function of one argument. A body that fails to evaluate raises rather than becoming a predicate that quietly matches nothing.

## The expression language

An expression reads an item and returns a value -- usually a boolean, since the caller is deciding whether the predicate matches.

### Fields

```expr
@status
fields["status"]
has_field("tier")
```

`@name` and `fields["name"]` are the same read. Field values arriving from a CSV are text, and the comparison operators coerce, so `@age > 30` parses the field rather than comparing a string to a number.

`fields.get("name")`, `fields(["name"])` and `fields[:name]` are also accepted and read the same field; the atom key is stringified. Prefer `@name`.

`has_field/1` asks whether the field is present at all, which is not the same question as whether it holds anything.

### Tags and metadata

```expr
has_tag(:seen)
metadata[:source]
metadata.get(:source)
```

`has_tag/1` asks what earlier stages concluded. Since an item carries the name of every predicate that matched it, a later stage matches on an earlier stage's finding -- and that, rather than anything in the runner, is the whole of sense to infer to act.

### Comparison

```expr
@status == "active"
@status != "inactive"
@age > 30
@age < 100
@age >= 42
@age <= 42
```

Mixed types coerce one way only: a string compared against a number must parse _completely_. `"42"` against `40` compares as `42`; `"42kg"` against `40` is false rather than `42`, because a partial parse is a guess about what the author meant.

Equality is total and ordering is not. A missing field equals nothing -- not even another missing field:

```expr
@absent == nil
@absent == @also_absent
```

Both are false. Ordering against a value that will not coerce is likewise false rather than an error, so a single unparseable row does not stop a run.

### Logical operators

```expr
@status == "active" && @tier == "premium"
@status == "active" || @tier == "basic"
!has_tag(:done)
```

Operands must be booleans or fall inside the truthiness enumeration -- `true`, `yes`, `y`, `1`, `on`, `t` and their negatives `false`, `no`, `n`, `0`, `off`, `f`, case-insensitively. Anything else is not silently truthy: it fails the coercion, and the predicate does not match. Elixir's own truthiness would make every unrecognised string match, and `!` on a missing field match as well.

To branch on a value outside that enumeration, compare it explicitly or convert it.

### Text

```expr
contains(@email, "example")
starts_with(@status, "act")
ends_with(@email, ".com")
```

Both operands coerce to text. A missing field is not `""` -- it is simply no match, so an absent value can never positively match a test for a prefix or a substring.

### Conversions

```expr
to_integer(@age) > 40
to_float(@score) > 7.0
to_string(@age) == "42"
to_boolean(@verified)
```

These are the explicit, strict conversions: a string must parse in full, and `to_boolean/1` accepts only the truthiness enumeration above. Input outside the contract makes the predicate not match. It never becomes a fabricated zero, or an empty string that compares equal to something.

### Literals, and what is not accepted

Strings, numbers, `true`, `false` and `nil` are literals and evaluate to themselves. A bare word that is not one of the forms above evaluates to the atom of the same name.

Anything else raises `Unsupported expression`. The language is a closed list -- there is no escape into arbitrary Elixir from inside `expr`, which is what makes a `.pred` file readable as a statement of intent rather than as code.

## The standard library

Ready-made predicate builders, reached as `STD` inside a `.pred` file and as `Riffle.Predicate.StandardLib` from Elixir. Each returns a function of one item, so each is a `call` body:

```pred
predicate(:premium, "Users on a premium account") do
  call &STD.Text.equals/2, ["tier", "premium"]
end
```

Every entry below is doctested in its own module; the examples there are the executable ones.

### Text

| Builder                  | Matches when the field         | Example                                |
| ------------------------ | ------------------------------ | -------------------------------------- |
| `STD.Text.equals/2`      | equals the value exactly       | `equals("status", "active")`           |
| `STD.Text.not_equals/2`  | does not equal the value       | `not_equals("status", "inactive")`     |
| `STD.Text.contains/2`    | contains the substring         | `contains("description", "premium")`   |
| `STD.Text.starts_with/2` | starts with the prefix         | `starts_with("code", "ABC")`           |
| `STD.Text.ends_with/2`   | ends with the suffix           | `ends_with("email", "example.com")`    |
| `STD.Text.matches/2`     | matches the regular expression | `matches("email", ~r/@example\.com$/)` |

A non-text value never matches any of these, rather than being stringified first.

### Numeric

Each parses the field as a number before comparing, and a field that will not parse does not match.

| Builder                                  | Matches when the field         | Example                               |
| ---------------------------------------- | ------------------------------ | ------------------------------------- |
| `STD.Numeric.equal_to/2`                 | equals the number              | `equal_to("age", 30)`                 |
| `STD.Numeric.greater_than/2`             | is greater than the number     | `greater_than("age", 30)`             |
| `STD.Numeric.less_than/2`                | is less than the number        | `less_than("age", 30)`                |
| `STD.Numeric.greater_than_or_equal_to/2` | is at least the number         | `greater_than_or_equal_to("age", 30)` |
| `STD.Numeric.less_than_or_equal_to/2`    | is at most the number          | `less_than_or_equal_to("age", 30)`    |
| `STD.Numeric.between/3`                  | is within the range, inclusive | `between("age", 18, 30)`              |
| `STD.Numeric.valid_number/1`             | parses as a number at all      | `valid_number("value")`               |

### Boolean

| Builder                   | Matches when the field       | Example                |
| ------------------------- | ---------------------------- | ---------------------- |
| `STD.Boolean.is_true/1`   | is in the truthy enumeration | `is_true("verified")`  |
| `STD.Boolean.is_false/1`  | is in the falsey enumeration | `is_false("verified")` |
| `STD.Boolean.has_value/1` | is present and not empty     | `has_value("email")`   |
| `STD.Boolean.is_empty/1`  | is missing or empty          | `is_empty("email")`    |

`has_value/1` and `is_empty/1` are opposites over the same question; `is_true/1` and `is_false/1` are not -- a value in neither enumeration answers false to both.

### Collection

Each reads the field as a comma-separated list, trimming each entry and dropping empty ones.

| Builder                           | Matches when the list            | Example                                   |
| --------------------------------- | -------------------------------- | ----------------------------------------- |
| `STD.Collection.contains_any/2`   | holds at least one of the values | `contains_any("roles", ["admin", "dev"])` |
| `STD.Collection.contains_all/2`   | holds every one of the values    | `contains_all("roles", ["admin", "dev"])` |
| `STD.Collection.count_at_least/2` | has at least that many entries   | `count_at_least("roles", 3)`              |
| `STD.Collection.count_at_most/2`  | has at most that many entries    | `count_at_most("roles", 3)`               |

### Date

Each reads the field as an ISO 8601 date or datetime, and a field that will not parse does not match. The comparison date is resolved once, when the predicate is built, rather than on each evaluation -- so a cached result cannot flip when the wall-clock day rolls over, and a typo in the date fails loudly at construction instead of silently meaning "today" forever.

| Builder                       | Matches when the field's date is | Example                                             |
| ----------------------------- | -------------------------------- | --------------------------------------------------- |
| `STD.Date.before/2`           | before the given date            | `before("created_at", "2026-01-01")`                |
| `STD.Date.date_after/2`       | after the given date             | `date_after("created_at", "2026-01-01")`            |
| `STD.Date.between/3`          | within the range, inclusive      | `between("created_at", "2026-01-01", "2026-06-30")` |
| `STD.Date.within_last_days/2` | within the last n days           | `within_last_days("created_at", 3)`                 |

### Combining

These take predicate functions rather than field names, so they compose the builders above.

| Builder          | Matches when               | Example                   |
| ---------------- | -------------------------- | ------------------------- |
| `STD.all/1`      | every predicate matches    | `all([premium, active])`  |
| `STD.any/1`      | at least one matches       | `any([premium, active])`  |
| `STD.none/1`     | none of them match         | `none([premium, active])` |
| `STD.not_pred/1` | the one predicate does not | `not_pred(premium)`       |

A loop already ORs its own predicates and a pipeline already ANDs its loops, so reach for these when the combination has to live _inside_ one predicate.

## Loading a file

From the command line, a source is a file or a module:

```
$ riffle sia.pipelines --from priv/sia/sia.pred
$ riffle sia.run --input data.csv --from priv/sia/sia.pred --pipeline main
```

From Elixir, `Riffle.Service.run/1` takes the same source:

```elixir
{:ok, result} = Riffle.Service.run(input: "data.csv", source: {:file, "definitions.pred"}, pipeline: :main)
```

`Riffle.Predicate.Dsl.Loader` is the level below, for reading definitions without running anything: `load_string/1` and `load_file/1` return the definitions, and `create_instances/1` turns them into predicates, loops and pipelines with every reference resolved.

## When something is wrong

`.pred` text is user input, so the loader reports rather than raises. Every failure is tagged and carries the message that explains it:

| Tag                                  | Means                                                                                                                      |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `{:invalid_dsl, message}`            | a statement that is not a definition, at the top level or inside a block                                                   |
| `{:invalid_predicate_body, message}` | a body that would not build -- an unresolved reference, or a `call` builder that returned something other than a predicate |

Neither is ever a quiet empty result. A pipeline that silently lost a loop, or a loop that silently lost a predicate, would keep running and keep giving answers -- just not the answers the file asks for.

`priv/sia/sia.pred` is the shipped example, and `Riffle.Sia.DefaultPipeline` is the same definitions in Elixir.
