# CSCI482 Intro to Neural Network

# How to connect to MATLAB to Github
Open MATLAB (R2026b)
Top-right Home tab -> Environment section -> Connections
Available connections -> GitHub
```
To create a personal access token, 
visit https://github.com/settings/tokens. 
Then enter the token here:
```

# How to download the dataset
About 7.9 GB (50,697 files). It lands in `data/amfitrite-open-waters-hab-sentinel2`, where `processDataset.m` reads it.

Run in PowerShell from the repo root:
```powershell
py --version                          # needs 3.10+; if missing: winget install Python.Python.3.12
py -m pip install -U huggingface_hub
hf auth login                         # optional: free read token, raises the download rate limit
hf download kostaspic/amfitrite-open-waters-hab-sentinel2 --repo-type dataset --local-dir data/amfitrite-open-waters-hab-sentinel2
```
- `hf` not found? Open a new terminal, or replace `hf` with `py -m huggingface_hub.cli.hf` in both lines.
- Stopped, or printed 429 errors? Run the same `hf download` line again. Finished files are skipped.
- Quick test first: add `--include "data/0_HAB/*"` to the download line.
- Done when `data/amfitrite-open-waters-hab-sentinel2/data` has 2,982 folders.

# Datasets
## Amfitrite
### Open Waters
[Link to Dataset](https://huggingface.co/datasets/kostaspic/amfitrite-open-waters-hab-sentinel2)

[Dataset Info](docs/dataset.md)
### Inland
https://huggingface.co/datasets/kostaspic/amfitrite-inland-waters-hab-sentinel2

### Models author made
https://huggingface.co/kostaspic/AMFITRITE-Sentinel2-HAB-RDNet

https://huggingface.co/kostaspic/AMFITRITE-Sentinel2-HAB-Universal-ResNet18

