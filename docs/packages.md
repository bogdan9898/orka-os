# Packages

The lists live in [`packages.txt`](../packages.txt) (official repos) and [`packages-aur.txt`](../packages-aur.txt) (AUR). Both are drafts based on Omarchy v3.8.4's `install/omarchy-base.packages` (149 packages) and `install/omarchy-other.packages` (60 packages), checked against the Arch repos and the AUR on 2026-11-05.

## Changes from Omarchy

### Added or replaced for this machine

| Package | Why |
|---|---|
| `linux-zen` + `linux` | Desktop-tuned kernel, with stock as fallback |
| `amd-ucode` | Ryzen microcode |
| `linux-firmware-{amd,amdgpu,mediatek,realtek,whence}` | Only the firmware this hardware needs, instead of the full `linux-firmware` (12 sub-packages) |
| `bluez`, `bluez-utils` | Bluetooth stack (Omarchy pulls these in elsewhere) |
| `quickshell` | Toolkit for our own desktop shell |
| `ffmpeg`, `lazydocker`, `yazi` (+ `poppler`, `7zip` for its previews) | Requested |
| `dolphin` + `kio-extras`, `ffmpegthumbs`, `kdegraphics-thumbnailers` | File manager, replaces `nautilus`, `nautilus-python`, `sushi` and the `gvfs-*` add-ons (`kio-extras` covers phones, SMB and SFTP) |
| `kwallet` + `kwallet-pam` | Secret Service, replaces `gnome-keyring` |
| `gparted` + `ntfsprogs` | Partition editor, replaces `gnome-disk-utility`. `ntfsprogs` lets it handle the Windows NTFS partitions |
| `filelight` | Disk usage map; Dolphin links to it |
| `termdown` | Countdown timer and stopwatch in the terminal (a Quickshell timer widget may come later) |
| `kvantum` | Qt 6 theming, replaces `kvantum-qt5` |

### Dropped: hardware this machine doesn't have

NVIDIA (`nvidia-*`, `lib32-nvidia-*`, `libva-nvidia-driver`, `egl-wayland`), Intel (`intel-media-driver`, `libva-intel-driver`, `libvpl`, `vpl-gpu-rt`, `vulkan-intel`, `intel-lpmd`, `intel-ipu7-camera`, `thermald`), Apple (`vulkan-asahi`, `linux-t2*`, `apple-*`, `t2fanrd`, `tiny-dfr`, `macbook12-spi-driver-dkms`, `asdcontrol`), laptops (`asusctl`, `dell-xps-touchpad-haptics`, `tuxedo-drivers-*`, `brightnessctl`, `sof-firmware`, `linux-firmware-marvell`), other (`linux-ptl*`, `broadcom-wl`, `yt6801-dkms`, `bolt`: no Thunderbolt on the B650 Tomahawk). Without DKMS modules, `dkms` and `linux-headers` aren't needed either.

### Dropped: debloat

| Package(s) | Notes |
|---|---|
| `obsidian`, `xournalpp`, `pinta`, `kdenlive` | Notes, drawing, video editing |
| `dotnet-runtime-9.0`, `ruby`, `python-poetry-core`, `jdk-openjdk`, `autoconf-archive` | Language runtimes Omarchy needs for its own extras |
| `mariadb-libs`, `postgresql-libs`, `libyaml` | Database / Ruby libraries |
| `fcitx5`, `fcitx5-gtk`, `fcitx5-qt` | CJK input methods |
| `ufw-docker` | Only needed with Docker |
| `tzupdate` | Timezone is set at install time |
| `aether`, `cliamp`, `tobi-try`, `omarchy-nvim`, `hyprland-preview-share-picker`, `python-terminaltexteffects`, `ttf-ia-writer` | Omarchy's own apps, configs and extras |

Networking follows Omarchy v3: `iwd` + `impala` for Wi-Fi, no NetworkManager.

### Cleanup (2026-11-05)

- **Removed, not needed at all:** `qt5-wayland` (nothing in the list uses Qt 5; saves ~21 MB).
- **Removed from the list, still installed as dependencies:** `linux-firmware-whence`, `less`, `avahi`, `libpulse`, `hyprland-guiutils`, `libsecret`, `qt6-wayland`, `gtk4-layer-shell`, `fontconfig`, `kio-extras`, `tesseract`. The list now only names what we want on purpose.
- **Kept on purpose although pulled in anyway**, because we use or configure them directly: `sudo`, `git`, `btrfs-progs`, `mesa`, `iwd`, `bluez`, `pipewire`, `wireplumber` (makes sure WirePlumber is the session manager), `polkit`, `kwallet`, `xdg-desktop-portal-gtk`, `ripgrep`, `unzip`, `socat`, `poppler`, `ffmpeg`, `python`.

### User choices (2026-11-05)

| Choice | Picked | Not included |
|---|---|---|
| Browser | `firefox` | `chromium` (Omarchy's default; its web-app launchers won't be ported) |
| Terminal | `ghostty` | `alacritty` |
| Apps | `claude-code` (AUR), `sublime-text-4` (AUR), `libreoffice-fresh`, `kdeconnect`, `pavucontrol`, `fastfetch`, `tmux` | `spotify`, `signal-desktop`, `1password-*`, `typora`, `localsend`, `obs-studio` |
| Extras | OCR (`tesseract`), screen recording (`gpu-screen-recorder`) | printing (`cups*`), `noto-fonts-cjk`, `power-profiles-daemon` |
| Development | `docker` (+ buildx, compose), `rust`, `python`, `gcc`/`g++` (via `base-devel`), `git` | `github-cli`, `mise`, `clang`, `llvm` |

### Desktop tools removed (2026-11-05)

`waybar`, `mako`, `swayosd`, `hyprlock`, `walker`/`elephant`, `sddm` and `polkit-gnome` are not installed: each will be replaced by our own Quickshell implementation (see [quickshell](quickshell.md)). Until then the system is used from the TTY.


Notes for `install.sh`:
- KDE Connect needs `ufw allow 1714:1764/tcp` and `/udp`. It pulls in about 120 MB of KDE libraries.
- GParted needs admin rights: it opens through our Quickshell polkit agent once that exists. Until then run it from a terminal with `sudo -E gparted` (a root app on Wayland may also need `xorg-xhost`, check when testing).
- Docker: enable `docker.service` and add the user to the `docker` group.
- KWallet: add `pam_kwallet5.so` to `/etc/pam.d/login` (auth + `session ... auto_start`) so the wallet unlocks on TTY login. The wallet must be named `kdewallet`, use the classic Blowfish format and have the same password as the user account.
