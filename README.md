# julia-run-testitems

A GitHub Action that runs `@testitem`-based Julia tests via the
[`juliati`](https://github.com/julia-vscode/TestItemApp.jl) CLI.

Failed test items are reported as GitHub error annotations (visible in the PR
"Files changed" view) and in the job log; the step fails when any test item
fails or a test definition error occurs.

## Usage

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: julia-actions/install-juliaup@v2
      - uses: julia-actions/cache@v2
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-run-testitems@main
```

## Inputs

All inputs are optional.

| Input | Default | Description |
| --- | --- | --- |
| `test-path` | `.` | Directory to search for test items. |
| `juliaup-channel` | `release` | Juliaup channel used for the test worker processes (e.g. `1.10.5~x64`, `lts`, `nightly`). |
| `results-path` | *(unset)* | Path to write the test-run results JSON (`TestItemControllers.Results` format). This is mainly the integration point for [`julia-actions/julia-report-ci-results`](https://github.com/julia-actions/julia-report-ci-results), which aggregates the JSON files of several matrix legs into one report; leave unset otherwise. |
| `env` | *(unset)* | Environment variables for the test processes, as a **JSON object string**, e.g. `{"FOO": "bar"}` — not `KEY=VALUE` lines. |
| `filter` | *(unset)* | A Julia expression over `name`, `tags`, `filename` and `package_name`; only test items for which it evaluates to `true` are run. Example: `:ci in tags && package_name == "MyPkg"`. |
| `profile-name` | `Default` | Profile name recorded in the results JSON. |
| `testitem-timeout` | `1200` | Per-test-item timeout in seconds. |
| `coverage` | `false` | Run the test processes in coverage mode. |
| `max-workers` | *(juliati default)* | Maximum number of parallel test processes. |
| `check-bounds` | `yes` | `--check-bounds` mode for the test processes: `yes` forces bounds checks everywhere (matching `Pkg.test` semantics); `auto` respects `@inbounds` annotations and reuses existing precompile caches. **Note this default differs from `juliati`'s own (`auto`)** — deliberately, so CI matches `Pkg.test`. The cost is that the first run precompiles the environment into a separate cache slot. |
| `annotations` | `true` | Emit GitHub error annotations for failed test items. |
| `junit-path` | *(unset)* | Path to write the results as JUnit XML. Most CI test reporters consume this format; `results-path` is richer but far less portable. |
| `coverage-lcov-path` | *(unset)* | Path to write the run's merged coverage in LCOV format, for Codecov, Coveralls and similar. Implies `coverage`. |
| `output-mode` | *(juliati default: `issues`)* | Which captured test-item output to echo into the job log: `issues` (only failing items), `all`, or `none`. Captured output is always in the results JSON regardless. |
| `threads` | *(Julia's default)* | Value for the test processes' `--threads`, e.g. `4`, `auto`, `2,1`. |
| `gc-between-testitems` | *(juliati default)* | `true`/`false` to force a full GC between test items. Unset leaves the default, which is on when more than one test process is used. |
| `memory-threshold` | *(off)* | Recycle a test process once system memory use exceeds this fraction (0–1). Experimental. |
| `schedule` | *(juliati default: `duration`)* | How test items are distributed over processes: `duration` orders by measured duration, past failures and warm setups; `contiguous` restores the previous chunk-by-position behaviour. Set to `contiguous` to rule the scheduler out when diagnosing a run. |

## Outputs

| Output | Description |
| --- | --- |
| `results-path` | Path of the results JSON that was written (empty if none was written). |
| `junit-path` | Path of the JUnit XML that was written (empty if none was written). |

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

Note: if the job sets `JULIA_DEPOT_PATH`, the action uses that depot
(earlier versions overrode it with a private depot under `runner.tool_cache`).
