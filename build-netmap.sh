#!/usr/bin/env bash

# utility
{
  [[ -t 2 ]] && \
    colorize() { local fmt="$1"; shift; echo -en "${fmt}$@\x1b[0m"; } || \
    colorize() { shift; echo -n "$@"; }

  log() {
    local code="$1" lvl="$2"; shift 2
    echo -e "[ $(colorize "\x1b[${code}m" "${lvl}") ]:" "$@"
  } >&2

  info() { log 32 info "$@"; }
  die() { log 31 fatal "$@"; exit 1; }

  [[ -n "$DEBUG" ]] && \
    debug() { log 34 debug "$@"; } || \
    debug() { :; }
}

# constants
{
  DEFAULT_NETMAP=master
  DEFAULT_OUTPUT=$PWD
  IMAGE_NAME=netmap_builder
  GH_USER=luigirizzo
  GH_REPO=netmap
}

randomcontainer() {
  echo "netmap_builder_${RANDOM}"
}

summarize() {
  local kernel="$1" netmap="$2" output="$3"
  info "building netmap from ${netmap} for kernel release ${kernel}"
  info "kernel module will be output to ${output}"
}

help() {
  echo "Usage: $0 [--netmap REF] [--output DIR] --kernel VERSION"
  echo "Build netmap kernel module for a specific kernel version"
  echo
  echo "Mandatory arguments:"
  echo "  --kernel VERSION target kernel version (formatted like \`uname -r\`)"
  echo "Optional arguments:"
  echo "  --netmap REF github ref OR path to source"
  echo "           (default: $DEFAULT_NETMAP)"
  echo "  --output DIR output directory"
  echo "           (default: $DEFAULT_OUTPUT)"
}

# build the docker image if not built yet
# FIXME this requires the script to be run from the root dir
initimage() {
  local imagename="$1"
  (
    cd ./docker
    docker build -t $imagename .
  )
}

# acquire the source if it doesn't exist yet
acquiresource() {
  local ref="$1" srcdir
  if [[ -d "$ref" ]]; then
    # ref is a source directory, no need to do anything
    srcdir="$ref"
  else
    # need to download source from github
    local tmpdir=$(mktemp -d -p '')
    (
      cd $tmpdir
      wget -q -O - https://github.com/$GH_USER/$GH_REPO/archive/${ref}.tar.gz | \
        tar xz
    )
    srcdir="${tmpdir}/${GH_REPO}-${ref}"
  fi
  ls -d "$srcdir"
}

buildmodule() {
  local srcdir="$1" imagename="$2" kernel="$3" container

  # create a random container name
  container=$(randomcontainer)
  docker rm -f "${container}" 2>/dev/null

  docker run --name "$container" -v "${srcdir}:/src" "${imagename}" "${kernel}" >/dev/null && \
    echo "$container"
}

extractmodule() {
  local container="$1" output="$2"
  docker cp "${container}:/out/netmap.ko" "${output}"
  ls -d "${output}/netmap.ko"
}

main() {
  local kernel netmap output
  while (( $# > 0 )); do
    case "$1" in
      -h|--help) help; exit 0;;
      --kernel) kernel="$2"; shift;;
      --netmap) netmap="$2"; shift;;
      --output) output="$2"; shift;;
    esac
    shift
  done

  [[ -z "$output" ]] && output=$PWD
  [[ -z "$netmap" ]] && netmap=master

  [[ -z "$kernel" ]] && \
    die "no kernel version specified"

  summarize "$kernel" "$netmap" "${output}/netmap.ko"
  info initializing docker image "(name: $IMAGE_NAME)"
  initimage "$IMAGE_NAME" || die "failed to initialize docker image"

  local srcdir
  info acquiring source "(ref: $netmap)"
  srcdir=$(acquiresource "$netmap")
  (( $? == 0 )) || die "failed to locate/acquire netmap source"
  debug "source is at ${srcdir}"

  local container
  info building kernel module in netmap container
  container=$(buildmodule "$srcdir" "$IMAGE_NAME" "$kernel")
  (( $? == 0 )) || die "failed to build kernel module"
  debug "container is called ${container}"

  local artifact
  info extracting artifact from container
  artifact=$(extractmodule "$container" "$output")
  (( $? == 0 )) || die "failed to extract artifact"
  info "build artifact is located at $artifact"
}

main "$@"
