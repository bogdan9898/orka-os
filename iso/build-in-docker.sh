#!/usr/bin/env bash
# Build the OrkaOS ISO inside a Docker container, as your normal user: no
# sudo, and nothing gets installed on this system (the AUR build
# dependencies, caches and archiso's work files all stay in Docker).
#
#   iso/build-in-docker.sh [stage...]     same stages as iso/build.sh
#   iso/build-in-docker.sh --cleanup      delete the images, the build volume,
#                                         the output folder and all of Docker's
#                                         build cache
#
# Needs Docker, and your user in the "docker" group (OrkaOS does that).
# The container runs --privileged: mkarchiso (pacstrap) mounts /proc, /sys
# and /dev inside the image it builds, which an unprivileged container can't.
#
#   image   orka-iso-builder            Arch + archiso etc. (iso/docker/Dockerfile)
#   volume  orka-build                  build files, caches between builds (~15 GB)
#   output  ~/dev/orka-build-out/       the finished ISO (owned by you)
set -euo pipefail

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE=orka-iso-builder
VOLUME=orka-build
OUT="${ORKA_ISO_OUT:-$HOME/dev/orka-build-out}"

if [[ "${1:-}" == --cleanup ]]; then
  docker volume rm -f "$VOLUME" >/dev/null && echo "removed volume $VOLUME"
  docker image rm -f "$IMAGE" >/dev/null 2>&1 && echo "removed image $IMAGE" || true
  docker image rm docker.io/library/archlinux:latest >/dev/null 2>&1 && echo "removed image archlinux:latest" || true
  docker builder prune -f >/dev/null && echo "removed Docker's build cache"
  rm -rf "$OUT" && echo "removed $OUT"
  exit 0
fi

command -v docker >/dev/null || { echo "build-in-docker: Docker is not installed" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "build-in-docker: can't reach Docker (is it running, are you in the docker group?)" >&2; exit 1; }

# --pull: a fresh Arch base image each time, so the builder is never a
# partial upgrade behind the packages it downloads.
docker build --pull -q -t "$IMAGE" --build-arg UID="$(id -u)" "$R/iso/docker" >/dev/null
mkdir -p "$OUT"

# The repo read-only; this system's mirrorlist; build files in a Docker
# volume; the ISO folder from this system on top of the volume's out/.
exec docker run --rm --privileged \
  -v "$R:/src:ro" \
  -v /etc/pacman.d/mirrorlist:/etc/pacman.d/mirrorlist:ro \
  -v "$VOLUME:/build" \
  -v "$OUT:/build/out" \
  -e ORKA_BUILD_DIR=/build \
  -e ORKA_BUILD_USER=builder \
  "$IMAGE" /src/iso/build.sh "$@"
