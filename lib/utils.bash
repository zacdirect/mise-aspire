#!/usr/bin/env bash

set -euo pipefail

TOOL_NAME="aspire"
TOOL_TEST="aspire --version"

# Aspire CLI binaries are distributed as nightly builds from ci.dot.net.
# GitHub releases exist but carry no binary assets.
#
# Two version identifiers are supported:
#   daily       — rolling nightly via aka.ms redirect; no checksum available
#   <specific>  — e.g. 9.3.0-preview.1.25201.3; SHA-512 verified from ci.dot.net
#
# PINNING WORKFLOW
#   1. Install the rolling nightly:   mise install aspire@daily
#   2. Note the exact build:          aspire --version  (-> 9.3.0-preview.1.25201.3)
#   3. Add to mise.toml:              aspire = "9.3.0-preview.1.25201.3"
#   4. Re-run mise install            -> downloads & verifies that exact build

fail() {
	echo "asdf-$TOOL_NAME: $*" >&2
	exit 1
}

# ── Platform detection ──────────────────────────────────────────────────────

get_rid() {
	local os arch
	os="$(uname -s | tr '[:upper:]' '[:lower:]')"
	case "$os" in
	darwin) os="osx" ;;
	linux)
		if command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -q musl; then
			os="linux-musl"
		fi
		;;
	*) fail "Unsupported OS: $os" ;;
	esac

	arch="$(uname -m)"
	case "$arch" in
	x86_64 | amd64) arch="x64" ;;
	aarch64 | arm64) arch="arm64" ;;
	*) fail "Unsupported architecture: $arch" ;;
	esac

	echo "${os}-${arch}"
}

# ── Version listing ─────────────────────────────────────────────────────────

sort_versions() {
	# Standard semver-aware sort used by the asdf ecosystem.
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_all_versions() {
	# 'daily' is always available as the rolling nightly.
	echo "daily"

	# Surface any pinned builds already installed locally, so users can
	# re-select them in mise.toml after noting the version from `aspire --version`.
	local mise_data installs
	mise_data="${ASDF_DATA_DIR:-${MISE_DATA_DIR:-$HOME/.local/share/mise}}"
	installs="${mise_data}/installs/aspire"
	if [ -d "${installs}" ]; then
		find "${installs}" -mindepth 1 -maxdepth 1 -type d \
			-exec basename {} \; |
			grep -v '^daily$' |
			sort -rV ||
			true
	fi
}

# ── Download ─────────────────────────────────────────────────────────────────

download_release() {
	local version filename rid archive_url checksum_url
	version="$1"
	filename="$2"
	rid="$(get_rid)"

	if [ "$version" = "daily" ]; then
		# aka.ms always redirects to the latest nightly build; no checksum available.
		archive_url="https://aka.ms/dotnet/9/aspire/daily/aspire-cli-${rid}.tar.gz"
		checksum_url=""
	else
		# Specific nightly builds are hosted on ci.dot.net with SHA-512 checksums.
		archive_url="https://ci.dot.net/public/aspire/${version}/aspire-cli-${rid}-${version}.tar.gz"
		checksum_url="https://ci.dot.net/public-checksums/aspire/${version}/aspire-cli-${rid}-${version}.tar.gz.sha512"
	fi

	echo "* Downloading $TOOL_NAME $version for ${rid}..."
	curl -fsSL --retry 3 --max-time 600 "$archive_url" -o "$filename" ||
		fail "Could not download $archive_url"

	if [ -n "$checksum_url" ]; then
		local checksum_file expected actual
		checksum_file="${filename}.sha512"
		curl -fsSL --retry 3 --max-time 60 "$checksum_url" -o "$checksum_file" ||
			fail "Could not download checksum from $checksum_url"

		expected="$(tr -d '\n\r' <"$checksum_file" | tr '[:upper:]' '[:lower:]')"
		if command -v sha512sum >/dev/null 2>&1; then
			actual="$(sha512sum "$filename" | cut -d' ' -f1)"
		elif command -v shasum >/dev/null 2>&1; then
			actual="$(shasum -a 512 "$filename" | cut -d' ' -f1)"
		else
			fail "No sha512sum or shasum found — cannot verify checksum"
		fi

		[ "$expected" = "$actual" ] ||
			fail "SHA-512 mismatch for $archive_url"

		rm -f "$checksum_file"
	fi
}

# ── Install ───────────────────────────────────────────────────────────────────

install_version() {
	local install_type version install_path install_root bin_dir tool_cmd
	install_type="$1"
	version="$2"
	install_path="$3"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports version installs only"
	fi

	# The tarball ships aspire + libsodium.so at the archive root.
	# aspire resolves libsodium.so via $ORIGIN rpath, so both files must live
	# in the same directory.  We keep them at the install root and expose only
	# the aspire binary via a bin/ symlink so mise shims just that executable.
	install_root="${install_path%/bin}"
	bin_dir="${install_root}/bin"

	(
		mkdir -p "$install_root"
		cp -r "$ASDF_DOWNLOAD_PATH/." "$install_root/"
		chmod +x "${install_root}/aspire"

		mkdir -p "$bin_dir"
		ln -sf "../aspire" "${bin_dir}/aspire"

		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "${bin_dir}/${tool_cmd}" ||
			fail "Expected ${bin_dir}/${tool_cmd} to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_root"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
