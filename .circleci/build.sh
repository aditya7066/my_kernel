#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/The3ven/android_prebuilts_clang_host_linux-x86_clang-6443078 clang
git clone --depth=1 https://github.com/The3ven/prebuilts_gcc_linux-x86_aarch64_aarch64-linaro-7  gcc
git clone --depth=1 https://github.com/The3ven/linaro_arm-linux-gnueabihf-7.5  gcc32
git clone https://github.com/The3ven/AnyKernel.git AnyKernel
echo "Installing Env dependencies"
apt-get install git -y fakeroot -y build-essential -y ncurses-dev -y xz-utils -y libssl-dev -y bc -y flex -y libelf-dev -y bison -y
sleep 20
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_HOST=ZeroKernal
export KBUILD_BUILD_USER="Zero Two"
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgIAAxkBAAEDj8Fhx2p4bScwO1YFhXS7BphRfykHlwAC2hMAAjFFUErF3KBfiXHVSCME" \
        -d chat_id=$chat_id
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• Zero Kernel •</b>%0ABuild started on <code>Circle CI</code>%0AFor device <b>Realme C25/C25S </b> (Even) %0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#Stable"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Realme C25/C25S (EVEN)</b> | <b>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
    make O=out ARCH=arm64 RMX3195_defconfig
    PATH="$${KERNEL_DIR}/clang/bin:${PATH}:${KERNEL_DIR}/gcc/bin:${PATH}:${KERNEL_DIR}/gcc32/bin:${PATH}" \
    make -j$(nproc --all) O=out \
                    ARCH=arm64 \
                    CC=clang \
                    CLANG_TRIPLE=aarch64-linux-gnu- \
                    CROSS_COMPILE="${PWD}/gcc/bin/aarch64-linux-gnu-" \
                    CROSS_COMPILE_ARM32="${PWD}/gcc32/bin/arm-linux-gnueabihf-" \
                    CONFIG_NO_ERROR_ON_MISMATCH=y

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 Test-ZeroKernel-${TANGGAL}.zip *
    cd ..
}
sticker
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
