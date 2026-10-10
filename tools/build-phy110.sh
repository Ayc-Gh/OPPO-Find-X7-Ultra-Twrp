#!/usr/bin/env bash
# Creates a candidate image on the build host. No device access or publishing.
set -euo pipefail
tree_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $# != 1 ]]; then
    echo 'Usage: bash tools/build-phy110.sh /absolute/path/to/new-build-directory' >&2
    exit 2
fi
for tool in repo python python3 java javac git rsync make gcc g++ flex bison zip unzip; do
    if ! command -v "$tool" >/dev/null; then
        echo "Missing build prerequisite: $tool" >&2
        exit 2
    fi
done
build_dir=$(realpath -m -- "$1")
if [[ "$build_dir" != /* || -e "$build_dir" ]]; then
    echo 'Choose a new absolute build directory; existing checkouts are never overwritten.' >&2
    exit 2
fi
mkdir -p -- "$build_dir"
cd -- "$build_dir"
manifest_url=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["manifest_url"])' "$tree_dir/source-lock.json")
manifest_sha=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["manifest_commit"])' "$tree_dir/source-lock.json")
recovery_sha=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["recovery_commit"])' "$tree_dir/source-lock.json")

repo init -u "$manifest_url" -b "$manifest_sha" --depth=1
repo sync -c -j2 --fail-fast
git -C bootable/recovery fetch --depth=1 origin "$recovery_sha"
git -C bootable/recovery checkout --detach "$recovery_sha"
[[ "$(git -C bootable/recovery rev-parse HEAD)" == "$recovery_sha" ]]
mkdir -p device/oplus/sm86xx
rsync -a --exclude=.git -- "$tree_dir/" device/oplus/sm86xx/
mkdir -p build-record
repo manifest -r -o build-record/resolved-manifest.xml
cp "$tree_dir/source-lock.json" "$tree_dir/validation/phy110-observed.json" build-record/
git -C "$tree_dir" diff HEAD --binary > build-record/device-tree.diff
python3 "$tree_dir/tests/test_spl.py"

# Android's environment scripts are not compatible with nounset.
set +u
source build/envsetup.sh
lunch twrp_sm86xx
set -u
export ALLOW_MISSING_DEPENDENCIES=true
m -j2 recoveryimage 2>&1 | tee build-record/build.log
image=out/target/product/sm86xx/recovery.img
[[ -f "$image" ]]
size=$(stat -c %s "$image")
if (( size > 104857600 )); then
    echo "Image exceeds observed 100 MiB recovery partition: $size" >&2
    exit 1
fi
sha256sum "$image" > build-record/recovery.sha256
echo "Candidate only; no boot/decryption validation performed: $build_dir/$image"
