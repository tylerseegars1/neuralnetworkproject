# AMFITRITE Open-Waters HAB Dataset — Notes

## Table of Contents
1. [Dataset Composition](#dataset-composition)
2. [Tile/Folder Composition](#tilefolder-composition)
   1. [12 Spectral Bands](#12-spectral-bands)
   2. [Per-Pixel Scene Classification](#per-pixel-scene-classification)
   3. [Atmospheric Haze and Water Vapour Maps](#atmospheric-haze-and-water-vapour-maps)
   4. [Visualization for Humans](#visualization-for-humans)
   5. [Metadata](#metadata)
3. [Master CSV](#master-csv)

---

## Dataset Composition

**Total: 2,982 tiles (folders)**

| Category                    | Tile Count |
|-----------------------------|-----------:|
| HAB                         |      1,445 |
| non-HAB                     |      1,317 |
| Pure cloud (>99% cloud)     |        110 |
| Pure land (>99% land)       |        110 |
| **Total**                   |  **2,982** |

---

## Tile/Folder Composition

## Tile/Folder Composition

**General path:** `data/<ID>_<HAB|nonHAB|land|clouds>/`

| File                         | Contents                                   | Role                     |
|------------------------------|--------------------------------------------|--------------------------|
| `B01_raw.tif` … `B12_raw.tif` | 12 files, one spectral band each          | Main model input         |
| `SCL_raw.tif`                | Per-pixel scene classification             | Water mask               |
| `AOT_raw.tif`                | Atmospheric haze map                       | Optional extra input     |
| `WVP_raw.tif`                | Water vapour map                           | Optional extra input     |
| `cyfi_prediction_map.png`    | Rendered CyFi prediction image             | Human visualization only |
| `metadata.json`              | Date, location, cloud %, counts            | Per-tile info            |

### 12 Spectral Bands
`<BAND>_raw.tif` — one file per band (e.g., `B01_raw.tif`, `B8A_raw.tif`)

| File          | Wavelength | Resolution | Name                   | Typical Use                                          |
|---------------|-----------:|-----------:|------------------------|------------------------------------------------------|
| `B01_raw.tif` |     443 nm |       60 m | Coastal Aerosol        | Coastal aerosol and deep-blue atmospheric studies    |
| `B02_raw.tif` |     490 nm |       10 m | Blue                   | Soil/vegetation discrimination, water penetration    |
| `B03_raw.tif` |     560 nm |       10 m | Green                  | Water contrast, vegetation green peak                |
| `B04_raw.tif` |     665 nm |       10 m | Red                    | Chlorophyll absorption, urban/soil mapping           |
| `B05_raw.tif` |     705 nm |       20 m | Vegetation Red Edge 1  | Vegetation classification, plant stress              |
| `B06_raw.tif` |     740 nm |       20 m | Vegetation Red Edge 2  | Leaf area index, biomass tracking                    |
| `B07_raw.tif` |     783 nm |       20 m | Vegetation Red Edge 3  | Forest classification, advanced vegetation indices   |
| `B08_raw.tif` |     842 nm |       10 m | NIR (Broad)            | Shoreline delineation, high-resolution vigor mapping |
| `B8A_raw.tif` |     865 nm |       20 m | Narrow NIR             | Moisture indices, specialized vegetation profiling   |
| `B09_raw.tif` |     945 nm |       60 m | Water Vapour           | Atmospheric correction, water-vapour detection       |
| `B11_raw.tif` |    1610 nm |       20 m | SWIR 1                 | Soil/canopy moisture, snow/cloud differentiation     |
| `B12_raw.tif` |    2190 nm |       20 m | SWIR 2                 | Moisture, geology/mineral mapping, burn areas        |             |

### Per-Pixel Scene Classification
`SCL_raw.tif`

| Property        | Detail                                                        |
|-----------------|---------------------------------------------------------------|
| What it labels  | Each pixel's surface type (water, cloud, vegetation, etc.)    |
| Key class       | **Class 6 = water**                                           |
| Recommended use | Mask out non-water pixels (authors' recommendation)           |

### Atmospheric Haze and Water Vapour Maps
`AOT_raw.tif` and `WVP_raw.tif`

| File          | Measures             | Status          |
|---------------|----------------------|-----------------|
| `AOT_raw.tif` | Aerosol optical thickness (haze) | Optional input |
| `WVP_raw.tif` | Water vapour                     | Optional input |

### Visualization for Humans
`cyfi_prediction_map.png` — a rendered image for viewing, not a model input.

### Metadata
`metadata.json`

| Field                | Description                    |
|----------------------|--------------------------------|
| `date`               | Acquisition date               |
| `latitude/longitude` | Tile location                  |
| `cloud %`            | Cloud cover percentage         |
| `water-pixel count`  | Number of water pixels         |
| `CyFi severity counts` | Pixel counts per CyFi severity level |

---

## Master CSV

`amfitrite_open_waters_master.csv` — *Note: some columns are in French.*

| Column            | Meaning                              |
|-------------------|--------------------------------------|
| `ID`              | Tile identifier (matches folder)     |
| `tile_is_hab`     | Whether the tile is labeled HAB      |
| `date`            | Acquisition date                     |
| `center_lat/lon`  | Tile center coordinates              |
| `dataset`         | Source/subset name                   |
| `tile_status`     | Tile category/status                 |