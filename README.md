<div align="center">

# mise-aspire [![Build](https://github.com/zacdirect/mise-aspire/actions/workflows/build.yml/badge.svg)](https://github.com/zacdirect/mise-aspire/actions/workflows/build.yml) [![Lint](https://github.com/zacdirect/mise-aspire/actions/workflows/lint.yml/badge.svg)](https://github.com/zacdirect/mise-aspire/actions/workflows/lint.yml)

[Aspire CLI](https://learn.microsoft.com/en-us/dotnet/aspire/overview) plugin for [mise](https://mise.jdx.dev) (and [asdf](https://asdf-vm.com)).

</div>

# Contents

- [About](#about)
- [Dependencies](#dependencies)
- [Install](#install)
- [Versions and pinning](#versions-and-pinning)
- [Contributing](#contributing)
- [License](#license)

# About

The [.NET Aspire CLI](https://github.com/dotnet/aspire) (`aspire`) is the primary tool for scaffolding,
running, and managing Aspire applications.  Binaries are distributed as rolling nightly builds; there
is no stable release channel with binary assets.

This plugin downloads directly from Microsoft's build infrastructure (`aka.ms` / `ci.dot.net`) and,
for pinned builds, verifies the SHA-512 checksum before installation.

# Dependencies

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html)
- `sha512sum` or `shasum` — for checksum verification of pinned builds (standard on Linux/macOS)
- [.NET SDK](https://dotnet.microsoft.com/download) — required to create and run Aspire projects (not needed just to install this plugin)

# Install

**With mise (recommended):**

```shell
# Add the plugin
mise plugin add aspire https://github.com/zacdirect/mise-aspire.git

# Install the rolling nightly
mise install aspire@daily

# Or add to mise.toml
echo 'aspire = "daily"' >> mise.toml
mise install
```

**With asdf:**

```shell
asdf plugin add aspire https://github.com/zacdirect/mise-aspire.git
asdf install aspire daily
asdf global aspire daily
```

# Versions and pinning

Aspire CLI ships as nightly builds — there is no GitHub release with attached binaries.
Two version identifiers are supported:

| Version | Source | Checksum |
|---------|--------|----------|
| `daily` | `aka.ms` redirect → latest nightly | none (rolling) |
| `9.3.0-preview.1.25201.3` | `ci.dot.net` exact build | SHA-512 verified |

**Pinning workflow** — for hermetic toolchains:

```shell
# 1. Install the rolling nightly
mise install aspire@daily

# 2. Note the exact build number
aspire --version
#  → Aspire CLI (9.3.0-preview.1.25201.3+...)

# 3. Pin in mise.toml
#    aspire = "9.3.0-preview.1.25201.3"

# 4. Re-run install — downloads & SHA-512 verifies that exact build
mise install
```

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/zacdirect/mise-aspire/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [zacdirect](https://github.com/zacdirect/)
