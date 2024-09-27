import torch
import numpy as np
import os
import torch_neuronx
from torchvision import models

image = torch.zeros([1, 3, 224, 224], dtype=torch.float32)

## Load a pretrained ResNet50 model
model = models.resnet50(pretrained=True)

## Tell the model we are using it for evaluation (not training)
model.eval()
model_neuron = torch_neuronx.trace(model, image)

## Export to saved model
model_neuron.save("resnet50_neuron.pt")
