#! /usr/bin/env bash
#
# Builds Aseprite for iPad (iPadOS 15+, arm64).
#
# Usage:
#
#   ios/build.sh deps                     Download & compile Skia for iOS and the host "gen" tool
#   ios/build.sh xcode TEAM_ID [BUNDLE]   Generate build-ios-xcode/aseprite.xcodeproj (open it and press Run)
#   ios/build.sh ninja [BUNDLE]           Compile the app bundle with Ninja (unsigned, for development)
#
# Environment variables:
#
#   DEPS_DIR   Where Skia is downloaded/compiled (default: ../deps relative to the repo)
#   BUILD_DIR  Root directory for build folders (default: .. relative to the repo)
#
# Requirements: Xcode, cmake, ninja, python3, git (brew install cmake ninja)

set -e

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source_dir=$(cd "$script_dir/.." && pwd)
deps_dir=${DEPS_DIR:-$(cd "$source_dir/.." && pwd)/deps}
build_root=${BUILD_DIR:-$(cd "$source_dir/.." && pwd)}

skia_dir=$deps_dir/skia
skia_lib_dir=$skia_dir/out/Release-ios-arm64
gen_build_dir=$build_root/build-host
default_bundle_id=com.example.aseprite

ios_min_version=15.0

function build_deps() {
  mkdir -p "$deps_dir"

  # Skia (aseprite-m124 branch)
  if [ ! -d "$skia_dir" ] ; then
    git clone --depth 1 -b aseprite-m124 https://github.com/aseprite/skia.git "$skia_dir"
  fi
  pushd "$skia_dir" > /dev/null
  if git apply --check "$script_dir/skia-ios.patch" 2> /dev/null ; then
    git apply "$script_dir/skia-ios.patch"
  fi
  # Only the dependencies needed for a raster-only iOS build
  cp "$script_dir/skia-deps.txt" DEPS.ios
  GIT_SYNC_DEPS_PATH="$PWD/DEPS.ios" GIT_SYNC_DEPS_SKIP_EMSDK=1 python3 tools/git-sync-deps || true
  python3 bin/fetch-gn
  bin/gn gen out/Release-ios-arm64 --args="target_os=\"ios\" target_cpu=\"arm64\" ios_min_target=\"$ios_min_version\" is_debug=false is_official_build=true skia_use_system_expat=false skia_use_system_icu=false skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_freetype=true skia_use_harfbuzz=true skia_pdf_subset_harfbuzz=true skia_use_system_freetype2=false skia_use_system_harfbuzz=false skia_enable_ganesh=false skia_enable_graphite=false skia_use_gl=false skia_use_metal=false skia_use_vulkan=false skia_use_dawn=false skia_enable_tools=false skia_use_dng_sdk=false skia_enable_skottie=false skia_enable_svg=false skia_use_lua=false extra_cflags_cc=[\"-frtti\"]"
  ninja -C out/Release-ios-arm64 skia modules
  popd > /dev/null

  # The "gen" tool runs on the host (macOS) during the build to
  # generate source code from data/ files.
  cmake -S "$source_dir" -B "$gen_build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DLAF_BACKEND=none \
    -DENABLE_CCACHE=OFF -DENABLE_NEWS=OFF -DENABLE_UPDATER=OFF \
    -DENABLE_SCRIPTING=OFF -DENABLE_WEBSOCKET=OFF
  ninja -C "$gen_build_dir" gen
}

cmake_ios_args=(
  -DCMAKE_SYSTEM_NAME=iOS
  -DCMAKE_OSX_ARCHITECTURES=arm64
  -DCMAKE_OSX_DEPLOYMENT_TARGET=$ios_min_version
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  -DLAF_BACKEND=skia
  "-DSKIA_DIR=$skia_dir"
  "-DSKIA_LIBRARY_DIR=$skia_lib_dir"
  "-DSKIA_LIBRARY=$skia_lib_dir/libskia.a"
  "-DSKUNICODE_LIBRARY=$skia_lib_dir/libskunicode.a"
  "-DSKSHAPER_LIBRARY=$skia_lib_dir/libskshaper.a"
  "-DFREETYPE_LIBRARY=$skia_lib_dir/libfreetype2.a"
  "-DHARFBUZZ_LIBRARY=$skia_lib_dir/libharfbuzz.a"
  "-DWEBP_LIBRARIES=$skia_lib_dir/libwebp.a"
  "-DLIBJPEG_TURBO_LIBRARY=$skia_lib_dir/libjpeg.a"
  "-DGEN_EXE=$gen_build_dir/bin/gen"
  -DENABLE_CCACHE=OFF
  -DENABLE_NEWS=OFF
  -DENABLE_UPDATER=OFF
  -DENABLE_WEBSOCKET=OFF
  -DENABLE_TESTS=OFF
  -DENABLE_DESKTOP_INTEGRATION=OFF
  -DLAF_WITH_EXAMPLES=OFF
  -DLAF_WITH_TESTS=OFF
)

function check_deps() {
  if [ ! -f "$skia_lib_dir/libskia.a" ] || [ ! -x "$gen_build_dir/bin/gen" ] ; then
    echo "Run \"$0 deps\" first"
    exit 1
  fi
}

case "$1" in
  deps)
    build_deps
    ;;

  xcode)
    check_deps
    team_id=$2
    bundle_id=${3:-$default_bundle_id}
    if [ -z "$team_id" ] ; then
      echo "Usage: $0 xcode TEAM_ID [BUNDLE_ID]"
      echo "  TEAM_ID is your Apple Developer Team ID (Xcode > Settings > Accounts)"
      exit 1
    fi
    cmake -S "$source_dir" -B "$build_root/build-ios-xcode" -G Xcode \
      "${cmake_ios_args[@]}" \
      -DCMAKE_CONFIGURATION_TYPES=RelWithDebInfo \
      -DASEPRITE_IOS_TEAM_ID="$team_id" \
      -DASEPRITE_IOS_BUNDLE_ID="$bundle_id"
    echo ""
    echo "Open $build_root/build-ios-xcode/aseprite.xcodeproj, select the"
    echo "\"aseprite\" scheme and your iPad, and press Run."
    ;;

  ninja)
    check_deps
    bundle_id=${2:-$default_bundle_id}
    cmake -S "$source_dir" -B "$build_root/build-ios" -G Ninja \
      "${cmake_ios_args[@]}" \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DASEPRITE_IOS_BUNDLE_ID="$bundle_id"
    ninja -C "$build_root/build-ios" aseprite
    echo ""
    echo "Unsigned app: $build_root/build-ios/bin/Aseprite.app"
    ;;

  *)
    sed -n '3,16p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
