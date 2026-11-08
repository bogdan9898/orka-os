#!/usr/bin/env bash
# Scripted desktop test in the installed VM: boots it (iso/test/vm.sh), logs
# in, then runs each argument as a step and saves a screenshot after each
# (shot1.png, shot2.png, ... in $SHOTS, default /tmp/orka-shots). Run as the
# build user inside the archlinux WSL distro, in ONE `wsl ... bash -c` call
# (the VM dies when the wsl call returns). Needs socat and imagemagick.
#
#   iso/test/vm-session.sh "@20 tester" "!meta_l-ret" "@3 ls" ...
#
# Steps:
#   "!<qemu key>"     press a key combo (QEMU sendkey names: meta_l-k, ret,
#                     esc, audiomute, volumeup, caps_lock...); waits $KEYWAIT (2 s)
#   "@N <command>"    type the text + Enter, wait N seconds (default 4)
#   "%<text>"         type the text without Enter
#   "^x,y"            mouse click at screen pixel x,y (QMP, scaled for 1280x800)
#   "^x1,y1-x2,y2"    drag with the left button from x1,y1 to x2,y2 (e.g. slurp)
#   "#<monitor cmd>"  a raw QEMU monitor command
#
# Environment:
#   NOLOGIN=1    don't log in on tty1 (the login screen is graphical: start
#                with "@20 tester" to type the password there)
#   VMOPTS=      pass "" for a guest with network (default --offline), e.g. to
#                curl files from iso/test/vm-http.py at 10.0.2.2
#   KEYWAIT=0.6  shorter wait after keys (to catch the 1.2 s OSD)
#   CLICKWAIT=   wait after a click (default 1.5 s)
# The typer maps US-layout characters; add a case below for any it lacks.
# The VM is shut down cleanly at the end (system_powerdown): killing QEMU
# right away can leave just-written files empty on the guest's Btrfs.
set -u
S="${SHOTS:-/tmp/orka-shots}"
mkdir -p "$S"
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
pkill -x qemu-system-x86 2>/dev/null; sleep 1
rm -f /tmp/orka-serial.log "$S"/shot*.png
bash iso/test/vm.sh ${VMOPTS---offline} > /tmp/orka-vm.log 2>&1 &
mon() { printf '%s\n' "$1" | socat - UNIX-CONNECT:/tmp/orka-qmon.sock >/dev/null 2>&1; }
keys() { for k in $1; do mon "sendkey $k"; sleep 0.12; done; }
for i in $(seq 120); do grep -q "login:" /tmp/orka-serial.log 2>/dev/null && break; sleep 2; done
if [[ -n ${NOLOGIN:-} ]]; then
  sleep 12   # graphical login screen: the steps log in themselves
else
  sleep 5; keys "t e s t e r ret"; sleep 2; keys "t e s t e r ret"; sleep 25
  mon "sendkey meta_l-ret"; sleep 4
fi
n=0
for line in "$@"; do
  n=$((n + 1)); wait=4
  if [[ $line == !* ]]; then
    mon "sendkey ${line#!}"; sleep "${KEYWAIT:-2}"
  elif [[ $line == \#* ]]; then   # "#<monitor command>", e.g. "#mouse_move 0 100"
    mon "${line#\#}"; sleep 1
  elif [[ $line =~ ^\^([0-9]+),([0-9]+)-([0-9]+),([0-9]+)$ ]]; then   # "^x1,y1-x2,y2": drag with the left button
    abs() { echo '{"execute":"input-send-event","arguments":{"events":[{"type":"abs","data":{"axis":"x","value":'$(( $1 * 32767 / 1280 ))'}},{"type":"abs","data":{"axis":"y","value":'$(( $2 * 32767 / 800 ))'}}]}}'; }
    btn() { echo '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":'$1',"button":"left"}}]}}'; }
    x1=${BASH_REMATCH[1]} y1=${BASH_REMATCH[2]} x2=${BASH_REMATCH[3]} y2=${BASH_REMATCH[4]}
    { echo '{"execute":"qmp_capabilities"}'; sleep 0.1; abs "$x1" "$y1"; sleep 0.15; abs "$x1" "$y1"; sleep 0.15; btn true; sleep 0.1
      for s in 1 2 3 4 5 6 7 8; do abs $(( x1 + (x2 - x1) * s / 8 )) $(( y1 + (y2 - y1) * s / 8 )); sleep 0.05; done
      sleep 0.1; btn false; sleep 0.2; } | socat - UNIX-CONNECT:/tmp/orka-qmp.sock >/dev/null 2>&1
    sleep "${CLICKWAIT:-1.5}"
  elif [[ $line =~ ^\^([0-9]+),([0-9]+)$ ]]; then   # "^x,y": click at screen pixel x,y (1280x800)
    ax=$(( BASH_REMATCH[1] * 32767 / 1280 )); ay=$(( BASH_REMATCH[2] * 32767 / 800 ))
    move='{"execute":"input-send-event","arguments":{"events":[{"type":"abs","data":{"axis":"x","value":'$ax'}},{"type":"abs","data":{"axis":"y","value":'$ay'}}]}}'
    btn() { echo '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":'$1',"button":"left"}}]}}'; }
    { echo '{"execute":"qmp_capabilities"}'; sleep 0.1; echo "$move"; sleep 0.15; echo "$move"; sleep 0.15; btn true; sleep 0.08; btn false; sleep 0.2; } |
      socat - UNIX-CONNECT:/tmp/orka-qmp.sock >/dev/null 2>&1
    sleep "${CLICKWAIT:-1.5}"
  else
    noret=0
    if [[ $line == %* ]]; then noret=1; line="${line#%}"; wait=2; fi   # "%text": type only, no Enter
    if [[ $line =~ ^@([0-9]+)\ (.*)$ ]]; then wait="${BASH_REMATCH[1]}"; line="${BASH_REMATCH[2]}"; fi
    for ((i = 0; i < ${#line}; i++)); do
      c="${line:i:1}"
      case "$c" in
        " ") k=spc ;; "-") k=minus ;; ".") k="dot" ;; "/") k=slash ;; ";") k=semicolon ;; "|") k=shift-backslash ;;
        "_") k=shift-minus ;; "=") k=equal ;; "'") k=apostrophe ;; '"') k=shift-apostrophe ;; "&") k=shift-7 ;;
        ">") k=shift-dot ;; "<") k=shift-comma ;; ",") k=comma ;; "*") k=shift-8 ;; "\$") k=shift-4 ;;
        "%") k=shift-5 ;; "#") k=shift-3 ;; "!") k=shift-1 ;; "^") k=shift-6 ;; "+") k=shift-equal ;;
        "[") k=bracket_left ;; "]") k=bracket_right ;; "{") k=shift-bracket_left ;; "}") k=shift-bracket_right ;;
        "?") k=shift-slash ;; "@") k=shift-2 ;; "(") k=shift-9 ;; ")") k=shift-0 ;; ":") k=shift-semicolon ;; "~") k=shift-grave_accent ;; [A-Z]) k="shift-${c,,}" ;; *) k="$c" ;;
      esac
      mon "sendkey $k"; sleep 0.05
    done
    ((noret)) || mon "sendkey ret"; sleep "$wait"
  fi
  mon "screendump /tmp/vmshot.ppm"; sleep 1
  magick /tmp/vmshot.ppm "$S/shot$n.png"
done
# Shut down cleanly (ACPI power button): killing QEMU right away can leave
# files written just before as empty files on the guest's Btrfs.
mon "system_powerdown"
for _ in $(seq 60); do pgrep -x qemu-system-x86 >/dev/null || break; sleep 1; done
pkill -x qemu-system-x86
