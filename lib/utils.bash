#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/a-h/templ"
TOOL_NAME="templ"
TOOL_TEST="templ version"

msg() {
  echo -e "\033[32m$1\033[39m" >&2
}

err() {
  echo -e "\033[31m$1\033[39m" >&2
}

fail() {
  err "$1"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if templ is not hosted on GitHub releases.
# if [ -n "${GITHUB_API_TOKEN:-}" ]; then
# 	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
# fi

get_platform() {
  local silent=${1:-}
  local platform=""

  platform="$(uname)"

  case "$platform" in
    Linux | Darwin)
      [ -z "$silent" ] && msg "Platform '${platform}' supported!"
      ;;
    *)
      fail "Platform '${platform}' not supported!"
      ;;
  esac

  printf "%s" "$platform"
}

get_arch() {
  local arch=""
  local arch_check=${ASDF_GOLANG_OVERWRITE_ARCH:-"$(uname -m)"}
  case "${arch_check}" in
    x86_64 | amd64) arch="x86_64" ;;
    # i686 | i386 | 386) arch="i386" ;; # not supported on Darwin
    aarch64 | arm64) arch="arm64" ;;
    *)
      fail "Arch '${arch_check}' not supported!"
      ;;
  esac

  printf "%s" "$arch"
}

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
	list_github_tags
}

download_release() {
	local version filename platform arch url
	version="$1"
	filename="$2"

	platform=$(get_platform)
	arch=$(get_arch)

	url="${GH_REPO}/releases/download/v${version}/${TOOL_NAME}_${platform}_${arch}.tar.gz"

	msg "* Downloading $TOOL_NAME release $version..."
	msg "from $url"
	msg "to $filename"
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		msg "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
