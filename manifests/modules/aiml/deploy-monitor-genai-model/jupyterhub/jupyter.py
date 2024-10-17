# Verify NVIDIA GPU is visible
! nvidia-smi


import os
os.chdir("/home/jovyan")


# Clone the diffusers repo
! git clone https://github.com/huggingface/diffusers

# Change the directory
os.chdir("diffusers")

# Installs the necessary Python packages, including the Diffusers library, xformers, and bitsandbytes (for memory-efficient attention optimization).
! pip install -e .
! pip install xformers==0.0.16 diffusers[torch]
! wget https://raw.githubusercontent.com/TimDettmers/bitsandbytes/main/cuda_install.sh
! bash cuda_install.sh 117 ~/local 1
! pip install bitsandbytes==0.41.0

# Use the newly installed CUDA version for bitsandbytes
os.environ["BNB_CUDA_VERSION"] = "117"
os.environ["LD_LIBRARY_PATH"] = os.getenv("LD_LIBRARY_PATH") + ":/home/jovyan/local/cuda-11.7"

# Validate successful install of bitsandbytes
! python -m bitsandbytes

# Install requirements for dreambooth
os.chdir("examples/dreambooth")
! pip install -r requirements.txt

# Setup default configuration for accelerate
! accelerate config default

# Login to huggingface associated with your account (please create one if it doesn't exist)
! huggingface-cli login --token  <Your Hugging face token>

# Download sample dataset of the subject. See the sample images here https://huggingface.co/datasets/diffusers/dog-example
from huggingface_hub import snapshot_download

local_dir = "./dog"
snapshot_download(
    "diffusers/dog-example",
    local_dir=local_dir, repo_type="dataset",
    ignore_patterns=".gitattributes",
)

# Export environment variables to provide input model, dataset directory and output directory for the tuned model
os.environ["MODEL_NAME"] = "stabilityai/stable-diffusion-2-1"
os.environ["INSTANCE_DIR"] = "dog"
os.environ["OUTPUT_DIR"] = "dogbooth"
os.environ["RESOLUTION"] = "768"
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "garbage_collection_threshold:0.6,max_split_size_mb:128"



# Launch the training and push the output model to huggingface
! accelerate launch train_dreambooth.py \
  --pretrained_model_name_or_path=$MODEL_NAME  \
  --instance_data_dir=$INSTANCE_DIR \
  --output_dir=$OUTPUT_DIR \
  --instance_prompt="a photo of [v]dog" \
  --resolution=768 \
  --train_batch_size=1 \
  --gradient_accumulation_steps=1 \
  --gradient_checkpointing \
  --learning_rate=1e-6 \
  --lr_scheduler="constant" \
  --enable_xformers_memory_efficient_attention \
  --use_8bit_adam \
  --lr_warmup_steps=0 \
  --max_train_steps=800 \
  --push_to_hub


