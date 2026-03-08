# Contributing

## Testing locally

```shell
# With asdf:
asdf plugin test aspire https://github.com/zacdirect/mise-aspire.git "aspire --version"

# With mise:
mise plugin add aspire https://github.com/zacdirect/mise-aspire.git
mise install aspire@daily
aspire --version
```

## Lint & format

```shell
# Install shellcheck and shfmt via asdf/.tool-versions
asdf plugin add shellcheck https://github.com/luizm/asdf-shellcheck.git
asdf plugin add shfmt https://github.com/luizm/asdf-shfmt.git
asdf install

./scripts/lint.bash
./scripts/format.bash
```

Tests are automatically run in GitHub Actions on push and PR.
