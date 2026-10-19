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

# How to download amfitrite 
```
# AMFITRITE open-waters HAB dataset (~7.9 GB, ~47.7k files)
# Run from the folder you want it in; creates .\amfitrite-open-waters
$dest = Join-Path (Get-Location) "amfitrite-open-waters"

# If huggingface install cli not installed, install it.
if (-not (Get-Command hf -ErrorAction SilentlyContinue)) {
    powershell -ExecutionPolicy ByPass -c "irm https://hf.co/cli/install.ps1 | iex"
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}

# Download the entirity 
hf download kostaspic/amfitrite-open-waters-hab-sentinel2 --repo-type dataset --local-dir $dest
explorer $dest
```


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

