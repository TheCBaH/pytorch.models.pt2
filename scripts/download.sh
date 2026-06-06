#!/usr/bin/env bash
# Downloads ImageNet label files and sample test images.
#
# Usage: ./download.sh [IMAGE_DIR [LABEL_DIR]]
#   IMAGE_DIR  Where to save images  (default: <repo_root>/modules/litert-samples/end_to_end/imagenet/data)
#   LABEL_DIR  Where to save labels  (default: <repo_root>/modules/litert-samples/end_to_end/imagenet)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGENET_DIR="$REPO_ROOT/modules/litert-samples/end_to_end/imagenet"

IMAGE_DIR="${1:-$IMAGENET_DIR/data}"
LABEL_DIR="${2:-$IMAGENET_DIR}"

mkdir -p "$IMAGE_DIR" "$LABEL_DIR"

download() {
  local url="$1"
  local dir="$2"
  local name
  name="$(basename "$url")"
  local dest="$dir/$name"
  if [[ -f "$dest" && -s "$dest" ]]; then
    printf "Skipping %s (already exists)\n" "$name"
    return 0
  fi
  printf "Downloading %s ...\n" "$name"
  if curl -fsSL -A "imagenet-pt2-sample/1.0" -o "$dest" "$url"; then
    printf "  Saved to: %s\n" "$dest"
  else
    printf "  FAILED (HTTP error or network issue): %s\n" "$url" >&2
    return 1
  fi
}

# --- ImageNet label files ---
download \
  "https://raw.githubusercontent.com/tensorflow/models/refs/heads/master/research/slim/datasets/imagenet_lsvrc_2015_synsets.txt" \
  "$LABEL_DIR"

download \
  "https://raw.githubusercontent.com/tensorflow/models/refs/heads/master/research/slim/datasets/imagenet_metadata.txt" \
  "$LABEL_DIR"

# --- COCO128 sample images ---
# Subset of COCO train2017 images, packaged by Ultralytics (~7 MB).
# https://github.com/ultralytics/assets/releases/tag/v0.0.0
COCO128_URL="https://github.com/ultralytics/assets/releases/download/v0.0.0/coco128.zip"
COCO128_N=10
COCO128_STAMP="$IMAGE_DIR/.coco128"
if [[ -f "$COCO128_STAMP" && "$(cat "$COCO128_STAMP")" == "$COCO128_N" ]]; then
  printf "Skipping COCO128 images (already extracted %s images)\n" "$COCO128_N"
else
  printf "Downloading COCO128 images (~7 MB), extracting first %s ...\n" "$COCO128_N"
  tmp_zip="$(mktemp --suffix=.zip)"
  trap 'rm -f "$tmp_zip"' EXIT
  if curl -fsSL -L -A "imagenet-pt2-sample/1.0" -o "$tmp_zip" "$COCO128_URL"; then
    set -- $(unzip -Z1 "$tmp_zip" 'coco128/images/train2017/*.jpg' | head -"$COCO128_N")
    unzip -q -j "$tmp_zip" "$@" -d "$IMAGE_DIR"
    printf "%s\n" "$COCO128_N" > "$COCO128_STAMP"
    printf "  Saved %s images to: %s\n" "$#" "$IMAGE_DIR"
  else
    printf "  FAILED (HTTP error or network issue): %s\n" "$COCO128_URL" >&2
    exit 1
  fi
fi

printf "\nDone. Run inference with:\n"
printf "  make mobilenet_v2.inference\n"
