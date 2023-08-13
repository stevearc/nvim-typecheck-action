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
      - uses: actions/checkout@v3
      - uses: stevearc/nvim-typecheck-action@v1
```

## Inputs

The following optional inputs can be specified using `with:`

### `path`

The path to typecheck

```yaml
- uses: stevearc/nvim-typecheck-action@v1
  with:
    path: lua
```

### `level`

The minimum level of diagnostic that should be logged. One of `Error`, `Warning`, or `Information`

```yaml
- uses: stevearc/nvim-typecheck-action@v1
  with:
    level: Error
```

### `configpath`

Path to a [`luarc.json`](https://luals.github.io/wiki/configuration/) file

```yaml
- uses: stevearc/nvim-typecheck-action@v1
  with:
    configpath: ".luarc.json"
```

### `libraries`

Space-separated list of github repos to add to the library path.
Use this if your plugin depends on types that are declared in another plugin.

```yaml
- uses: stevearc/nvim-typecheck-action@v1
  with:
    libraries: |
        https://github.com/rcarriga/neotest
```

### `neodev-version`

Which version of neodev types to use. The options are `stable`, `nightly`, or `none` (to disable).

This action uses [neodev.nvim](https://github.com/folke/neodev.nvim) to get the type annotations for core Neovim. This input determines which version of the types to use.

```yaml
- uses: stevearc/nvim-typecheck-action@v1
  with:
    neodev-version: nightly
```

### `neodev-rev`

Which git rev to check out for neodev.nvim. Ignored if `neodev-version` is `none`.

```yaml
- uses: stevearc/nvim-typecheck-action@v1
  with:
    neodev-rev: v2.5.1
```

### `nvim-version`

Which version of Neovim to use to run the check.

```yaml
- uses: stevearc/nvim-typecheck-action@v1
  with:
    nvim-version: v0.9.1
```

### `luals-version`

Which version of lua-language-server to use to run the check.

```yaml
- uses: stevearc/nvim-typecheck-action@v1
  with:
    luals-version: 3.6.25
```
