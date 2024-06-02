# nvim-typecheck-action

Github action for typechecking a neovim plugin

If you are using the [type annotations from LuaLS](https://luals.github.io/wiki/annotations/), this action will typecheck your plugin.

## Usage

Create the file `.github/workflows/typecheck.yml` with the following contents:

```yaml
---
name: Type check
on:
  pull_request: ~
  push:
    branches:
      - master

jobs:
  build:
    name: Type check
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - uses: stevearc/nvim-typecheck-action@v2
```

## Inputs

The following optional inputs can be specified using `with:`

### `path`

The path to typecheck

```yaml
- uses: stevearc/nvim-typecheck-action@v2
  with:
    path: lua
```

### `level`

The minimum level of diagnostic that should be logged. One of `Error`, `Warning`, or `Information`

```yaml
- uses: stevearc/nvim-typecheck-action@v2
  with:
    level: Error
```

### `configpath`

Path to a [`luarc.json`](https://luals.github.io/wiki/configuration/) file

```yaml
- uses: stevearc/nvim-typecheck-action@v2
  with:
    configpath: ".luarc.json"
```

### `libraries`

Space-separated list of github repos to add to the library path.
Use this if your plugin depends on types that are declared in another plugin.

```yaml
- uses: stevearc/nvim-typecheck-action@v2
  with:
    libraries: |
      https://github.com/nvim-neotest/neotest
```

### `nvim-version`

Which version of Neovim to use to run the check.

```yaml
- uses: stevearc/nvim-typecheck-action@v2
  with:
    nvim-version: v0.10.0
```

### `luals-version`

Which version of lua-language-server to use to run the check.

```yaml
- uses: stevearc/nvim-typecheck-action@v2
  with:
    luals-version: 3.9.1
```
