#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019, 2020 Raphielscape LLC (@raphielscape)
# Copyright (C) 2019, 2020 Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020 Muhammad Fadlyas (@fadlyas07)
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
export device="Xiaomi Redmi 4A"
export config_device=rolex_defconfig
git clone --depth=1 --single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r55 gcc
git clone --depth=1 --single-branch https://github.com/fabianonline/telegram.sh telegram
git clone --depth=1 --single-branch https://github.com/fadlyas07/anykernel-3
mkdir $(pwd)/temp
export ARCH=arm64
export TEMP=$(pwd)/temp
export TELEGRAM_ID=$chat_id
export TELEGRAM_TOKEN=$token
export pack=$(pwd)/anykernel-3
export product_name=GreenForce
export KBUILD_BUILD_HOST=$(git log --format='%H' -1)
export KBUILD_BUILD_USER=$(git log --format='%cn' -1)
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
build_start=$(date +"%s")

tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="CAACAgUAAxkBAAEYl9pee0jBz-DdWSsy7Rik8lwWE6LARwACmQEAAn1Cwy4FwzpKLPPhXRgE" \
	-d chat_id="$TELEGRAM_ID"
}
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
PATH=$(pwd)/gcc/bin:$PATH \
make -j$(nproc) O=out \
                ARCH=arm64 \
                CROSS_COMPILE=aarch64-linux-android-
}
date=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make ARCH=arm64 O=out "$config_device" && \
tg_build 2>&1| tee $(TZ=Asia/Jakarta date +'%A-%H%M-%d%m%y').log
mv *.log $TEMP
if ! [[ -f "$kernel_img" ]]; then
    build_end=$(date +"%s")
    build_diff=$(($build_end - $build_start))
    curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
    tg_channelcast "<b>$product_name</b> for <b>$device</b> Build errors in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
    exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
mv $kernel_img $pack/zImage
cd $pack && zip -r9q $product_name-rolex-$date1.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..
build_end=$(date +"%s")
build_diff=$(($build_end - $build_start))
kernel_ver=$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "⚠️ <i>Warning: New build is available!</i> working on <b>$parse_branch</b> in <b>Linux $kernel_ver</b> using <b>$toolchain_ver</b> for <b>$device</b> at commit <b>$(git log --pretty=format:'%s' -1)</b>. Build complete in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
curl -F document=@$pack/$product_name-rolex-$date.zip "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
