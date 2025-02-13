# az-install

Install a spesific version of PowerShell module `Az`, from cache.

## How it works

1. Gets version number of latest available version of `Az` in PowerShell Gallery

2. Checks if version is specified

3. Using cache for latest or specified version, if cache is found

4. Installs latest or specified version, if not cached

5. Caches the version installed with version number as part of key

## How to use

```yaml
on:
  push:
jobs:
  install-az:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: ./.github/actions/az-install
      with:
        version: 8.0.0

```