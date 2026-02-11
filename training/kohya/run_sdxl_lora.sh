#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/session.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE"
  echo "Copy template: cp $ROOT_DIR/session.env.example $ROOT_DIR/session.env"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

required=(KOHYA_ROOT BASE_MODEL_PATH TRAIN_DATA_DIR OUTPUT_DIR LOGGING_DIR OUTPUT_NAME)
for var in "${required[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required variable: $var"
    exit 1
  fi
done

if [[ ! -d "$KOHYA_ROOT" ]]; then
  echo "KOHYA_ROOT does not exist: $KOHYA_ROOT"
  exit 1
fi

if [[ ! -e "$BASE_MODEL_PATH" ]]; then
  echo "BASE_MODEL_PATH does not exist: $BASE_MODEL_PATH"
  exit 1
fi

if [[ ! -d "$TRAIN_DATA_DIR" ]]; then
  echo "TRAIN_DATA_DIR does not exist: $TRAIN_DATA_DIR"
  exit 1
fi

OUT_DIR="$OUTPUT_DIR"
LOG_DIR="$LOGGING_DIR"
if [[ "$OUTPUT_DIR" != /* ]]; then
  OUT_DIR="$REPO_DIR/$OUTPUT_DIR"
fi
if [[ "$LOGGING_DIR" != /* ]]; then
  LOG_DIR="$REPO_DIR/$LOGGING_DIR"
fi
mkdir -p "$OUT_DIR" "$LOG_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$OUT_DIR/run_$TIMESTAMP"
mkdir -p "$RUN_DIR"
CONFIG_FILE="$RUN_DIR/sdxl_lora_config.toml"

cat > "$CONFIG_FILE" <<CFG
pretrained_model_name_or_path = "$BASE_MODEL_PATH"
vae = "${VAE_PATH:-}"
train_data_dir = "$TRAIN_DATA_DIR"
reg_data_dir = "${REG_DATA_DIR:-}"
output_dir = "$OUT_DIR"
logging_dir = "$LOG_DIR"
output_name = "$OUTPUT_NAME"
resolution = "${RESOLUTION:-1024,1024}"
network_module = "networks.lora"
network_dim = ${NETWORK_DIM:-16}
network_alpha = ${NETWORK_ALPHA:-16}
learning_rate = ${LEARNING_RATE:-1e-4}
unet_lr = ${UNET_LR:-1e-4}
text_encoder_lr = ${TEXT_ENCODER_LR:-5e-6}
train_batch_size = ${TRAIN_BATCH_SIZE:-1}
max_train_steps = ${MAX_TRAIN_STEPS:-2400}
save_every_n_steps = ${SAVE_EVERY_N_STEPS:-200}
seed = ${SEED:-42}
lr_scheduler = "${LR_SCHEDULER:-cosine_with_restarts}"
lr_warmup_steps = ${LR_WARMUP_STEPS:-100}
mixed_precision = "${MIXED_PRECISION:-bf16}"
save_precision = "${SAVE_PRECISION:-bf16}"
cache_latents = true
gradient_checkpointing = true
xformers = true
sdpa = true
caption_extension = ".txt"
shuffle_caption = true
keep_tokens = 1
bucket_reso_steps = 64
min_bucket_reso = 256
max_bucket_reso = 2048
optimizer_type = "AdamW8bit"
max_data_loader_n_workers = 0
persistent_data_loader_workers = false
save_model_as = "safetensors"
clip_skip = 1
prior_loss_weight = 1.0
full_bf16 = true

[model_arguments]
v_parameterization = false

[additional_network_arguments]
network_train_unet_only = false
network_train_text_encoder_only = false

[sample_prompt_arguments]
sample_every_n_steps = ${SAVE_EVERY_N_STEPS:-200}
sample_sampler = "euler_a"
sample_prompts = "${TRIGGER_WORD:-style} portrait photo, detailed skin, cinematic lighting"
CFG

echo "Run config: $CONFIG_FILE"
cd "$KOHYA_ROOT"

accelerate launch --num_cpu_threads_per_process 2 sdxl_train_network.py --config_file="$CONFIG_FILE"
