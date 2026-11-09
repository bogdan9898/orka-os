# OrkaOS ISO builder: Arch Linux with what iso/build.sh needs, so the ISO can
# be built without sudo and without installing build dependencies on the
# host. Used by iso/build-in-docker.sh (see docs/iso.md).
FROM docker.io/library/archlinux:latest

# The build user: the same UID as the host user, so files in mounted folders
# (the finished ISO) belong to them.
ARG UID=1000
RUN pacman -Syu --noconfirm --needed archiso base-devel git python neovim tree-sitter-cli unzip \
 && pacman -Scc --noconfirm \
 && useradd -m -u "$UID" builder
