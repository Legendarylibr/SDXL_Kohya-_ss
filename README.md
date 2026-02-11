# SDXL Kohya SS

Minimal, sanitized Kohya SS pipeline for local SDXL LoRA training and ComfyUI usage.

## Included
- `training/kohya/session.env.example` config template
- `training/kohya/run_sdxl_lora.sh` launch script
- `training/kohya/datasets/` placeholder
- `training/kohya/output/` output folder (ignored)
- `training/kohya/logs/` logs folder (ignored)

## Quick Start
1. Copy and edit env file:
   - `cp training/kohya/session.env.example training/kohya/session.env`
2. Set:
   - `KOHYA_ROOT` (path to your `kohya_ss`)
   - `BASE_MODEL_PATH`
   - `TRAIN_DATA_DIR`
3. Run:
   - `training/kohya/run_sdxl_lora.sh training/kohya/session.env`
4. Use generated `.safetensors` LoRA in ComfyUI (`ComfyUI/models/loras/`).

## Notes
- Uses `sdxl_train_network.py` in `kohya_ss`.
- No personal paths or tokens are stored in this repository.
