[![Build](https://github.com/TheCBaH/pytorch.models.pt2/actions/workflows/build.yml/badge.svg)](https://github.com/TheCBaH/pytorch.models.pt2/actions/workflows/build.yml)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev+Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/TheCBaH/pytorch.models.pt2)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/TheCBaH/pytorch.models.pt2)

# pytorch.models.pt2

PyTorch model export and inference samples using the PT2 (`.pt2`) format.

## Samples

| Sample | Description |
|--------|-------------|
| [ImageNet classification](modules/litert-samples/end_to_end/imagenet/README.md) | Convert and run torchvision ImageNet models (EfficientNet, MobileNet, ResNet) via `torch.export` |

## Development

The repo ships a devcontainer with all dependencies pre-installed. Open it in VS Code Dev Containers or GitHub Codespaces using the badges above.

### Quick start (local)

```bash
# Apply patch to submodule and download assets
make patch.apply
make download

# Convert a model and run inference
make efficientnet_b0.convert
make efficientnet_b0.inference
```