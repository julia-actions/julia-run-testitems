# julia-run-testitems

This is an experiment, nothing to see at the moment.

## Requirements and caching

The action requires [juliaup](https://github.com/JuliaLang/juliaup) on the
PATH (e.g. via `julia-actions/install-juliaup`); it adds the `release` channel
itself for its host tooling.

The action does not cache anything itself — it instantiates its tooling into
the default Julia depot (`~/.julia`). To cache the depot (including the
precompilation done by the test worker processes), add a job-level cache step
before this action:

```yaml
- uses: julia-actions/install-juliaup@v2
- uses: julia-actions/cache@v2
```

Note: if the job sets `JULIA_DEPOT_PATH`, the action now uses that depot
(earlier versions overrode it with a private depot under `runner.tool_cache`).
