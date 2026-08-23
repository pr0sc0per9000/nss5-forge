# New Star Soccer 5 Reconstruction Tools

Accuracy to the original executable is the main goal of this project. To
facilitate the effort and maintain overall quality, we have a set of tools that
verify the accuracy of recompiled function bodies, class tables, Global addresses
and more.

Every script has a module docstring saying what it does and why it exists. Run
any of them with no arguments to see usage. One-off analysis does not belong
here; put it in `scripts/workflow`, which is not tracked.

## Getting started

These five are all you need to build and run the project.

* [`setup.py`](/scripts/setup.py): Populates a fresh clone from your own copy of
  the game. Run this first.
* [`assemble.py`](/scripts/assemble.py): Emits `src/assembled` from the recovered
  bodies and compiles it. `--check-selfcontained` reports bodies that reference a
  Global they do not declare.
* [`progress.py`](/scripts/progress.py): How much of the reconstruction is
  byte-identical. `--write-status` regenerates `docs/STATUS.md`.
* [`smoke_boot.py`](/scripts/smoke_boot.py): Boots the build briefly, kills it,
  and reports how far it got. The regression gate.
* [`debug_game.py`](/scripts/debug_game.py): **The way to run the game.** Forced
  windowed and watchdog-killed like `play.py`, which it calls for those guarantees,
  but it also KEEPS the evidence: every run lands in `status/debugruns/<timestamp>/`
  with stdout, stderr, the decoded call trace, and `globals.tsv` -- every module
  Global and its value at the moment of a fault.
* [`instrument_trace.py`](/scripts/instrument_trace.py): Injects a call tracer into
  the assembled source. Use `--filter` and `--arm`; tracing everything produces ~41M
  records for a 21-second boot.
* [`debug_shims.py`](/scripts/debug_shims.py): Guards the reads NSS5.exe performs
  through Null and survives, in the generated debug source only, so a `-d` build can
  walk past the original's own bugs to reach ours. `--list` prints the registry and
  the disassembly each entry rests on. `build_debug.sh` runs it; release never does.
* [`dead_globals.py`](/scripts/dead_globals.py): Every module Global that is read but
  never written, triaged by severity. Approximately the remaining runtime-bug backlog.
* [`play.py`](/scripts/play.py): The plain launcher, and the home of the
  forced-windowed guarantee that the others reuse. Prefer `debug_game.py`; on a fault
  `play.py --debug` captures the exception line but NOT the stack trace or the Globals
  dump, because it does not answer the debug stub's prompt.

Never launch the executable yourself. It can start in exclusive fullscreen and
hang holding the display and the input queue, which needs a power cycle to clear.
`play.py` and `smoke_boot.py` both call `play.force_windowed()` first, and
anything new that starts the executable must do the same.

## Comparing against the original

The reconstruction is judged by whether it compiles to the same bytes as
`NSS5.exe`.

* [`localise_diff.py`](/scripts/localise_diff.py): Aligns before comparing and
  masks relocations. Use this for any fidelity claim.
* [`bytematch.py`](/scripts/bytematch.py): Positional byte compare of one method.
  Its `FIRST DIFFERENCE` offset is trustworthy; its percentage is not, because
  one length-changing difference desynchronises everything after it.
* [`check_assembled.py`](/scripts/check_assembled.py): Whether the corpus still
  matches after assembly rather than individually. `--layout` also checks
  instance sizes and method slots.
* [`reverify.py`](/scripts/reverify.py): Re-runs the oracle over bodies already on
  disk. `--shard i/n` splits the work, `--pending` scores candidate trees.
* [`harness.py`](/scripts/harness.py): The build-and-compare core the rest of the
  tooling is built on. Rarely run directly.
* [`coverage.py`](/scripts/coverage.py): The canonical coverage number. Quote this
  rather than counting by hand.

## Correctness checks

A byte match does not certify everything. Each of these covers a class of defect
the oracle cannot see.

* [`check_literals.py`](/scripts/check_literals.py): String literals, which reach
  the code as a masked address, so a match says nothing about their text.
  `--order` also checks their order.
* [`check_floats.py`](/scripts/check_floats.py): Float constants, invisible for
  the same reason.
* [`check_array_bounds.py`](/scripts/check_array_bounds.py): Arrays indexed past
  their declared length. An out-of-bounds write kills the process.
* [`predict_crashes.py`](/scripts/predict_crashes.py): Dereferences of Globals
  that nothing ever writes.
* [`check_docs.py`](/scripts/check_docs.py): The header claims themselves. A body
  whose VA header does not parse leaves the corpus entirely, numerator and
  denominator both, so the reported percentage goes UP when work is lost. Also
  catches two bodies claiming one VA, match markers spelled in a form
  `progress.py` does not count, and a header asserting both `BUILD_FAIL` and
  byte-identical. Build-free, so there is no excuse for not running it.
* [`check_global_calls.py`](/scripts/check_global_calls.py): Globals that are
  called but whose declared type is not callable. `assemble.py` regenerates each
  `Global name:Type` line rather than copying the `'!Global` pragma, so a
  function-pointer type can lose everything after its first space and turn a call
  into `Expression of type 'Byte' cannot be invoked`.

## Global name unification

One memory address often collected several different recovered names, so a write
lands on one name and a read comes from another. This is the largest defect class
in the project and most of the tooling addresses it.

* [`explain_global.py`](/scripts/explain_global.py): Everything known about one
  Global: address, tier, evidence. Start here.
* [`addr_oracle.py`](/scripts/addr_oracle.py): Reads Globals out of `NSS5.exe` in
  machine-code order. The ground truth.
* [`unify_names.py`](/scripts/unify_names.py): The alignment solver, matching
  declared names to the addresses actually touched.
* [`emit_unified_aliases.py`](/scripts/emit_unified_aliases.py): Turns solved
  addresses into merges, applying the safety guards.
* [`validate_verdicts.py`](/scripts/validate_verdicts.py): Re-checks every
  proposed merge against the binary. Nothing is applied without it.
* [`find_dead_globals.py`](/scripts/find_dead_globals.py): Globals that are read
  but never written. `--batches` splits the result into work units.
* [`find_live_splits.py`](/scripts/find_live_splits.py): One address, two names,
  both written. Invisible to the above. `--impact` ranks by which subsystem is
  actually broken.
* [`link_dead_to_writers.py`](/scripts/link_dead_to_writers.py): Matches a dead
  Global to the name its writer uses.
* [`module_body_types.py`](/scripts/module_body_types.py): Address to type, read
  from the bootstrap's own allocations. Outranks inference.
* [`resolve_type_conflicts.py`](/scripts/resolve_type_conflicts.py): Resolves a
  Global declared with two different types.
* [`merge_globals.py`](/scripts/merge_globals.py): Produces the authoritative
  module-Global table, fed by
  [`name_globals.py`](/scripts/name_globals.py),
  [`type_globals_by_new.py`](/scripts/type_globals_by_new.py) and
  [`decode_module_globals.py`](/scripts/decode_module_globals.py).
* [`build_alias_map.py`](/scripts/build_alias_map.py): The weakest of the three
  alias tables `assemble.py` reads, kept so a fresh clone can rebuild it.

## Reading the binary

* [`disasm.py`](/scripts/disasm.py): Minimal PE reader plus disassembler.
* [`parse_reflection.py`](/scripts/parse_reflection.py): Reads the BlitzMax
  reflection tables out of the executable. The object model is built on this.
* [`resolve_vtables.py`](/scripts/resolve_vtables.py): Method to class-table slot
  resolution.
* [`decomp_index.py`](/scripts/decomp_index.py): The way into the exported
  decompilation corpus without opening Ghidra.
* [`annotate.py`](/scripts/annotate.py): Annotates decompiled C with recovered
  types, refusing any substitution it cannot validate.
* [`helper_map.py`](/scripts/helper_map.py): Names the C-runtime helpers on both
  sides of the comparison, which is what makes most of the codebase matchable.
* [`name_brl.py`](/scripts/name_brl.py): Names the BRL and PUB library functions
  inside the executable.
* [`extract_imports.py`](/scripts/extract_imports.py): Names every DLL import
  thunk.
* [`extract_incbin.py`](/scripts/extract_incbin.py): Recovers the embedded assets,
  which are most of the file and cannot be committed.
* [`build_dependency_graph.py`](/scripts/build_dependency_graph.py): Call graph
  and dependency ordering, which decides what can be worked on next.
* [`status.py`](/scripts/status.py): The per-function record store.
* [`outstanding_game.py`](/scripts/outstanding_game.py): What is still
  unrecovered, split by whether anyone has opened it. `--thirdparty` covers the
  library trees.

## Emulation and probing

Used to establish behaviour empirically rather than by reading code.

* [`emu_probe.py`](/scripts/emu_probe.py): Calls functions from the real image
  inside an emulator. `--sweep` cold-calls everything and classifies what happens.
* [`build_probe_dataset.py`](/scripts/build_probe_dataset.py): Builds the method
  to address to size table the classification runs on.
* [`gen_probeability_doc.py`](/scripts/gen_probeability_doc.py): Classifies every
  method by whether its behaviour can be established by calling it.
* [`framework_probe.py`](/scripts/framework_probe.py): Measures what a `Framework`
  statement costs, module by module.
* [`framework_assembled.py`](/scripts/framework_assembled.py): Lets the real
  program's missing-symbol errors name the modules it needs.

## Ghidra scripts

[`scripts/ghidra_scripts`](/scripts/ghidra_scripts) run inside Ghidra, not from a
shell. They resolve the repository root from the `NSS5_REPO` environment variable
or the first script argument.

* `NSS5Seed.java`: Harvests anchors from strings and labels the binary.
* `NSS5ExportAll.java` and `NSS5ExportList.java`: The bulk decompilation export
  that produces the corpus `decomp_index.py` reads.
* `NSS5Decompile.java` and `NSS5Where.java`: Decompile given addresses, or the
  function containing an address.
* `NSS5CallGraph.java`: Whole-program call-graph extraction.

## Finding matching functions

This is not a recipe, but rather a list of things you can try.

* Start from the reflection tables. `parse_reflection.py` and
  `resolve_vtables.py` give you a method name, its class-table slot and its
  address, so most functions can be located by name without searching at all.
* If a function is not in the reflection tables it is a module-level `Function`
  rather than a `Method`. Those have no reflection record, so find them through
  the call graph or through a string they reference.
* Search for a string the function uses. `check_literals.py` decodes BBStrings out
  of `.data`, and a literal is often the fastest way to identify a screen or a
  message handler.
* Walk up the call tree. `build_dependency_graph.py` resolves callers and callees,
  so if you can find something that calls your function you can usually name it.
* A body that will not match may not be wrong. Check that the Globals it
  references resolve to the right addresses first; a name collision produces a
  correct-looking body that reads from the wrong slot.
* _If you find any other strategies, please add them here._
