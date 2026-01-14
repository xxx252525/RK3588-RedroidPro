#!/bin/bash
# ============================================================
#  reDroid RK3588 / RK3588S Environment Check Script
#  Author : QingYao
#  Device : RK3588 / RK3588S (OrangePi 5 / 5 Pro)
#  Target : reDroid Android in Docker
# ============================================================

SCRIPT_NAME="reDroid RK3588 EnvCheck"
SCRIPT_VER="1.0.0"

# ---------------- Colors ----------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

command -v zgrep >/dev/null 2>&1 && GREP_EXE=zgrep || GREP_EXE=grep

color_echo() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# ---------------- Logo ----------------
print_logo() {
    color_echo $CYAN "
 ██████╗ ███████╗██████╗ ██████╗  ██████╗ ██╗██████╗
 ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔═══██╗██║██╔══██╗
 ██████╔╝█████╗  ██║  ██║██████╔╝██║   ██║██║██║  ██║
 ██╔══██╗██╔══╝  ██║  ██║██╔══██╗██║   ██║██║██║  ██║
 ██║  ██║███████╗██████╔╝██║  ██║╚██████╔╝██║██████╔╝
 ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═════╝
"
    color_echo $BLUE " $SCRIPT_NAME  v$SCRIPT_VER"
    echo
}

# ---------------- Checks ----------------
check_arch() {
    ARCH=$(uname -m)
    if [ "$ARCH" != "aarch64" ]; then
        color_echo $RED "FATAL: Architecture must be ARM64 (aarch64), current: $ARCH"
        export FATAL=1
    else
        color_echo $GREEN "Architecture: $ARCH"
    fi
}

check_kernel_config_location() {
    if [ -f /proc/config.gz ] && command -v zgrep >/dev/null 2>&1; then
        CONFIG_PATH=/proc/config.gz
    elif [ -f /boot/config-$(uname -r) ]; then
        CONFIG_PATH=/boot/config-$(uname -r)
    fi

    if [ -z "$CONFIG_PATH" ]; then
        color_echo $RED "FATAL: Kernel config not found"
        export FATAL=1
    else
        color_echo $GREEN "Kernel config: $CONFIG_PATH"
    fi
}

# check_mali_driver() {
#     if $GREP_EXE -q "^CONFIG_MALI_BIFROST=(y|m)" $CONFIG_PATH 2>/dev/null; then
#         color_echo $GREEN "Mali GPU driver enabled"
#         [ -c /dev/mali0 ] || {
#             color_echo $RED "FATAL: /dev/mali0 not found (GPU disabled in DT)"
#             export FATAL=1
#         }
#     else
#         color_echo $RED "FATAL: Mali GPU kernel driver missing"
#         export FATAL=1
#     fi
# }

check_mali_driver() {
    # Bifrost (vendor mali)
    if $GREP_EXE -q "^CONFIG_MALI_BIFROST=(y|m)" $CONFIG_PATH 2>/dev/null; then
        color_echo $GREEN "Mali Bifrost kernel driver enabled"
        [ -c /dev/mali0 ] || {
            color_echo $RED "WARN: /dev/mali0 not found (DT may disable vendor Mali)"
        }
        return
    fi

    # Panfrost (open source)
    if $GREP_EXE -q "^CONFIG_DRM_PANFROST=(y|m)" $CONFIG_PATH 2>/dev/null; then
        color_echo $GREEN "Mali Panfrost kernel driver enabled"
        [ -c /dev/dri/renderD128 ] && color_echo $GREEN "DRM render node present"
        return
    fi

    color_echo $RED "FATAL: No supported Mali GPU driver found (Bifrost / Panfrost)"
    export FATAL=1
}



check_mali_firmware() {
    if [ -f /lib/firmware/mali_csffw.bin ]; then
        color_echo $GREEN "Mali CSF firmware present"
    else
        color_echo $PURPLE "WARN: Mali CSF firmware missing"
        color_echo $CYAN "Hint: Place mali_csffw.bin under /lib/firmware if GPU unstable"
    fi
}

check_kernel_features() {
    $GREP_EXE -q "CONFIG_ANDROID_BINDERFS=y" $CONFIG_PATH \
        && color_echo $GREEN "CONFIG_ANDROID_BINDERFS=y" \
        || { color_echo $RED "FATAL: CONFIG_ANDROID_BINDERFS missing"; export FATAL=1; }

    $GREP_EXE -q "CONFIG_PSI=y" $CONFIG_PATH \
        && color_echo $GREEN "CONFIG_PSI=y" \
        || { color_echo $RED "FATAL: CONFIG_PSI missing"; export FATAL=1; }

    if $GREP_EXE -q "CONFIG_ARM64_VA_BITS=39" $CONFIG_PATH; then
        color_echo $GREEN "CONFIG_ARM64_VA_BITS=39"
    else
        color_echo $PURPLE "WARN: CONFIG_ARM64_VA_BITS != 39 (recommended)"
    fi
}

check_binderfs() {
    grep -q binder /proc/filesystems \
        && color_echo $GREEN "binderfs mounted" \
        || { color_echo $RED "FATAL: binderfs not available"; export FATAL=1; }
}

check_dma_heap() {
    if [ -c /dev/dma_heap/system-uncached ]; then
        color_echo $GREEN "DMA Heap device present"
    else
        color_echo $RED "FATAL: /dev/dma_heap/system-uncached missing"
        export FATAL=1
    fi
}

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        color_echo $GREEN "Docker detected: $(docker --version)"
    else
        color_echo $RED "FATAL: Docker not installed"
        export FATAL=1
    fi
}

# ---------------- Main ----------------
main() {
    print_logo

    color_echo $YELLOW "== Basic System Check =="
    check_arch
    check_docker

    color_echo $YELLOW "\n== Kernel & GPU Check =="
    check_kernel_config_location
    check_mali_driver
    check_mali_firmware

    color_echo $YELLOW "\n== Android Required Features =="
    check_kernel_features
    check_binderfs
    check_dma_heap

    echo
    if [ -n "$FATAL" ]; then
        color_echo $RED "========================================"
        color_echo $RED " Environment NOT suitable for reDroid ❌"
        color_echo $RED " Please fix above FATAL issues first."
        color_echo $RED "========================================"
        exit 1
    else
        color_echo $GREEN "========================================"
        color_echo $GREEN " Environment ready for reDroid ✅"
        color_echo $GREEN " You can safely start the container."
        color_echo $GREEN "========================================"
    fi
}

main "$@"
