#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019, 2020, Raphielscape LLC (@raphielscape)
# Copyright (C) 2019, 2020, Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020, Muhammad Fadlyas (@fadlyas07)
git clone https://github.com/andeh24/android_kernel_xiaomi_msm8917 -b aosp-ten-purecaf pure --depth=1
cd pure
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --depth=1 -b ndk-r19 gcc && git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 --depth=1 -b ndk-r19 gcc32
git clone --depth=1 --single-branch https://github.com/fabianonline/telegram.sh telegram
git clone --depth=1 --single-branch https://github.com/andeh24/AnyKernel3
mkdir $(pwd)/temp
export ARCH=arm64
export TEMP=$(pwd)/temp
export TELEGRAM_ID=-1001277959729
export TELEGRAM_TOKEN=1030153459:AAGtCY3MkrHNvYBAaArtjeAHYvzcebcS5iA
export pack=$(pwd)/AnyKernel3
export product_name=SimplifiedPureCAF
export device="Redmi Note 5A Lite"
export CROSS_COMPILE=$(pwd)/gcc/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=$(pwd)/gcc32/bin/arm-linux-androideabi-
export KBUILD_BUILD_HOST=$(git log --format='%H' -1)
export KBUILD_BUILD_USER=$(git log --format='%cn' -1)
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
build_start=$(date +"%s")

TELEGRAM=telegram/telegram
tg_channelcast() {
    "$TELEGRAM" -c "$TELEGRAM_ID" -H \
 "$(
  for POST in "$@"; do
   echo "$POST"
  done
 )"
}
tg_build() {
make -j$(nproc --all) O=out
}
date=$(TZ=Asia/Makassar date +'%H%M-%d%m%y')
make ARCH=arm64 O=out "ugglite_defconfig" && \
tg_build 2>&1| tee $(TZ=Asia/Makassar date +'%A-%H%M-%d%m%y').log
mv *.log $TEMP
if ! [[ -f "$kernel_img" ]]; then
    build_end=$(date +"%s")
    build_diff=$(($build_end - $build_start))
    curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
    tg_channelcast "<b>$product_name</b> for <b>$device</b> at commit <b>$(git log --pretty=format:'%s' -1)</b> Build errors in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
    exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
mv $kernel_img $pack/zImage
cd $pack && zip -r9q $product_name-ugglite-$date.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..
build_end=$(date +"%s")
build_diff=$(($build_end - $build_start))
kernel_ver=$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_channelcast "⚠️ <i>Warning: New build is available!</i> working on <b>$parse_branch</b> in <b>Linux $kernel_ver</b> using <b>$toolchain_ver</b> for <b>$device</b> at commit <b>$(git log --pretty=format:'%s' -1)</b>. Build complete in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
curl -F document=@$(echo $pack/*.zip) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
