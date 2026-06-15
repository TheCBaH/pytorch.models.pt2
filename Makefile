ROOT         := $(CURDIR)
LITERT_DIR   := $(ROOT)/modules/litert-samples
IMAGENET_DIR := $(LITERT_DIR)/end_to_end/imagenet
SCRIPTS_DIR  := $(ROOT)/scripts
IMAGE_DIR    := $(IMAGENET_DIR)/data
PATCH_FILE   := $(ROOT)/patches/imagenet-pt2.patch
MODELS_DIR   := $(ROOT)/models

MODELS := \
	efficientnet_b0 \
	efficientnet_b1 \
	efficientnet_b2 \
	efficientnet_b3 \
	efficientnet_b4 \
	efficientnet_b5 \
	efficientnet_b6 \
	efficientnet_b7 \
	efficientnet_v2_s \
	efficientnet_v2_m \
	efficientnet_v2_l \
	mobilenet_v2 \
	mobilenet_v3_large \
	mobilenet_v3_small \
	resnet18 \
	resnet34 \
	resnet50 \
	resnet101 \
	resnet152

.PHONY: download convert inference extract check patch.create patch.apply FORCE

# ── Check ─────────────────────────────────────────────────────────────────────

# Verify extracted model JSONs match git HEAD; pretty-prints diffs via jq on mismatch
check:
	bash $(SCRIPTS_DIR)/check_models.sh $(MODELS_DIR)

# ── Patch ─────────────────────────────────────────────────────────────────────

# Capture current submodule edits into patches/imagenet-pt2.patch
patch.create:
	git -C $(LITERT_DIR) diff \
	    -- end_to_end/imagenet/main.py \
	       end_to_end/imagenet/pyproject.toml \
	    > $(PATCH_FILE)

# Apply patch to a clean submodule checkout
patch.apply:
	git -C $(LITERT_DIR) apply $(PATCH_FILE)

# ── Data ──────────────────────────────────────────────────────────────────────

# Download label files and sample test images
download:
	bash $(SCRIPTS_DIR)/download.sh $(IMAGE_DIR) $(IMAGENET_DIR)

# ── Single-model targets ──────────────────────────────────────────────────────

# FORCE causes pattern rules to always re-run (equivalent to .PHONY for patterns)
FORCE:

# Convert one model to .pt2:   make mobilenet_v2.convert
%.convert: FORCE
	uv run --directory $(IMAGENET_DIR) main.py convert --arch $* --output $(IMAGENET_DIR)/$*.pt2

# Run inference on all downloaded images:   make mobilenet_v2.inference
%.inference: FORCE
	uv run --directory $(IMAGENET_DIR) main.py \
		--model $(IMAGENET_DIR)/$*.pt2 \
		$(patsubst %,--image %,$(wildcard $(IMAGE_DIR)/*.jpg))

# Extract .pt2 contents into models/<name>/:   make mobilenet_v2.extract
%.extract: FORCE
	rm -rf $(MODELS_DIR)/$*
	mkdir -p $(MODELS_DIR)/$*/.tmp
	unzip -q $(IMAGENET_DIR)/$*.pt2 -d $(MODELS_DIR)/$*/.tmp
	cd $(MODELS_DIR)/$*/.tmp && mv -- */* ..
	rm -rf $(MODELS_DIR)/$*/.tmp
	find $(MODELS_DIR)/$* -name '*.json' -exec git add {} +

# ── All-models targets ────────────────────────────────────────────────────────

# Convert all supported models
convert: $(addsuffix .convert,$(MODELS))

# Run inference on all supported models with all downloaded images
inference: $(addsuffix .inference,$(MODELS))

# Extract all supported models
extract: $(addsuffix .extract,$(MODELS))
