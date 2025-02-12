import os
import json
import logging
from fastapi import FastAPI
from ray import serve
import torch
import torch_neuronx
from transformers import AutoTokenizer
from transformers_neuronx.mistral.model import MistralForSampling
from huggingface_hub import snapshot_download

# Initialize FastAPI
app = FastAPI()

neuron_cores = int(os.getenv('NEURON_CORES', 2))  # Default to 2 for trn1.2xlarge
cacheDir = os.path.join('/tmp','model','neuron-mistral7bv0.3')

# --- Logging Setup ---
logger = logging.getLogger("ray.serve")
logger.setLevel(logging.INFO)
logging.basicConfig(level=logging.INFO)

@serve.deployment(num_replicas=1)
@serve.ingress(app)
class APIIngress:
    def __init__(self, mistral_model_handle):
        self.handle = mistral_model_handle

    @app.get("/infer")
    async def infer(self, sentence: str):
        result = await self.handle.infer.remote(sentence)
        return result

@serve.deployment(
    name="mistral-7b",
    autoscaling_config={"min_replicas": 1, "max_replicas": 1},
    ray_actor_options={
        "resources": {"neuron_cores": neuron_cores}
    }
)
class MistralModel:
    def __init__(self):
        try:
            logger.info("Initializing model with pre-compiled files...")

            mistral_model = os.getenv('MODEL_ID', 'askulkarni2/neuron-mistral7bv0.3')
            logger.info(f"Using model ID: {mistral_model}")
            
            model_path='/tmp/model/neuron-mistral7bv0.3'
            model_cache='/tmp/model/cache'

            # Initialize model state
            self.neuron_model = None
            self.tokenizer = None

            #Downloading files to local dir
            if not os.path.exists(model_path): 
                os.makedirs(cacheDir, exist_ok=True)
                os.makedirs(model_cache, exist_ok=True)
                logger.info("downloading model file to../tmp/model/neuron-mistral7bv0.3")
                model_path = snapshot_download(repo_id=mistral_model, local_dir=cacheDir, local_dir_use_symlinks=False)
                logger.info(f"model path: {model_path}")
            
            logger.info(f"Checking model path contents: {os.listdir(model_path)}")

            # Set the environment variable with absolute path
            os.environ.update({
                "NEURON_RT_VISIBLE_CORES": "0,1",
                "NEURON_RT_NUM_CORES": "2",
                "NEURON_RT_USE_PREFETCHED_NEFF": "1",
            })

            logger.info("Loading tokenizer...")
            self.tokenizer = AutoTokenizer.from_pretrained(
                model_path,
                local_files_only=True
            )

            # Set padding token
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
                logger.info("Set padding token to EOS token")


            logger.info("Loading  model...")
            # Load model with minimal configuration
            self.neuron_model = MistralForSampling.from_pretrained(
                model_path, batch_size=1, tp_degree=2, amp='bf16' 
            )

            logger.info("Model preparation...")

            neuronxcc_dirs = [d for d in os.listdir(model_cache)]
            if not neuronxcc_dirs:
                # compile modele first time and save compile artifacts in cache dir
                self.neuron_model.to_neuron()
                self.neuron_model.save(model_cache)
            else:
                # load pre-complied .neff files
                self.neuron_model.load(model_cache)
                self.neuron_model.to_neuron()

            logger.info("Model successfully prepared for inference")

            # Verify initialization
            if not self._verify_model_state():
                raise RuntimeError("Model initialization failed verification")
            
            logger.info("Model initialization complete")

        except Exception as e:
            logger.error(f"Error during model initialization: {e}")
            raise

    def _verify_model_state(self):
        if self.neuron_model is None:
            return False
        if not hasattr(self.neuron_model, 'sample'):
            return False
        if self.tokenizer is None:
            return False
        return True
    
    def infer(self, sentence: str):
        input_ids = self.tokenizer.encode(sentence, return_tensors="pt")
        with torch.inference_mode():
            try:
                logger.info(f"Performing inference on input: {sentence}")
                generated_sequences = self.neuron_model.sample(
                    input_ids, sequence_length=2048, top_k=50
                )
                decoded_sequences = [self.tokenizer.decode(seq, skip_special_tokens=True) for seq in generated_sequences]
                logger.info(f"Inference result: {decoded_sequences}")
                return decoded_sequences
            except Exception as e:
                logger.error(f"Error during inference: {e}")
                return {"error": "Inference failed"}


# Create an entry point for the FastAPI application
entrypoint = APIIngress.bind(MistralModel.bind())
