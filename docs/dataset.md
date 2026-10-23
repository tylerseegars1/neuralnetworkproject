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


## Tile/Folder Composition

**General path:** `dataset/amfitrite_open_waters/data/<ID>_<HAB|nonHAB|land|clouds>/`

| File                         | Contents                                   | Role                     |
|------------------------------|--------------------------------------------|--------------------------|
| `B01_raw.tif` … `B12_raw.tif`| 12 files, one spectral band each           | Main model input         |
| `SCL_raw.tif`                | Per-pixel scene classification             | Water mask               |
| `AOT_raw.tif`                | Atmospheric haze map                       | Optional extra input     |
| `WVP_raw.tif`                | Water vapour map                           | Optional extra input     |
| `cyfi_prediction_map.png`    | Rendered CyFi prediction image             | Human visualization only |
| `metadata.json`              | Date, location, cloud %, counts            | Per-tile info            |

### 

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
| `sat_item`        | Sentinel-2 scene ID the tile was cut from. **Blank for all 220 cloud/land tiles** (checked in the CSV 2026-10-17) |

### Anatomy of a `sat_item`

Example: `S2B_MSIL2A_20210227T101029_R022_T34VCL_20210227T214401`

| Piece | Meaning |
|-------|---------|
| `S2B` | Which Sentinel-2 satellite took it: A, B or C (2C took over from 2A on 21 Jan 2025; 8 imputed tiles are `S2C`) |
| `MSIL2A` | MultiSpectral Instrument, Level-2A = atmospherically corrected (that is why `SCL`, `AOT`, `WVP` exist) |
| `20210227T101029` | Sensing date and time (UTC) |
| `R022` | Relative orbit number (which ground track) |
| `T34VCL` | MGRS square: UTM zone 34, latitude band V, square CL. Squares sit on a 100 km grid but are 109.8 km wide, so neighbours overlap by ~10 km |
| `20210227T214401` | When the product file was generated |

So a `sat_item` is one ~110 km granule on one date. The same square of Earth is revisited every 5 days at the equator, and every 2-3 days at mid-latitudes because neighbouring ground tracks overlap, and gets a new `sat_item` each time. Our 256x256 tiles are small cut-outs from inside a granule.

https://sentiwiki.copernicus.eu/web/s2-processing

### From orbit to tile

1. **Datatake:** the camera is a pushbroom scanner with a 290 km wide swath. The observation plan switches it on at most once per orbit, over land, coastal water up to 20 km offshore, the Mediterranean and closed seas. It then records one continuous run, up to 15,000 km long. Far-open ocean is mostly not imaged.
2. **Granule = `sat_item`:** the datatake is cut onto the fixed MGRS grid, about 3 squares across the swath. Edge squares can be partly empty.
3. **Tile:** the authors cut 256x256 px (2.56 km at 10 m) out of a granule.
4. **3x3 grid:** 9 tiles (7.7 km) around an in-situ measurement, all from the **same** `sat_item` (true for every group in the CSV). Many grids lost tiles during verification.
5. **Imputed:** the same centre from a **different** `sat_item`, on a date with no water sample. Any satellite or track, from 40 days to ~10 years away. Its label comes only from CyFi, the DL models and a manual check.

Sources: https://sentiwiki.copernicus.eu/web/s2-mission, https://sentiwiki.copernicus.eu/web/s2-products

### `tile_status` values 

| Value | Meaning | Count in master CSV |
|-------|---------|--------------------:|
| `on_measurment` | Tile contains the exact in-situ measurement point | ___ |
| `near_measurment` | One of the 8 tiles around a measurement tile (the authors' 3x3 grid strategy) | ___ |
| `imputed` | Same known location, different date, downloaded mainly to get clean non-HAB tiles for class balance. 18 imputed tiles turned out to be HAB on inspection | ___ |
| `land` | Distractor, >99% land pixels | 110 |
| `clouds` | Distractor, >99% cloud pixels | 110 |

(Spelling "measurment" is the authors' own; match it exactly when comparing text.)

Why it matters for the split: a measurement tile and its 8 neighbours overlap the same water on the same day, and imputed tiles revisit the same spot on other days. Tiles that share a location must stay in the same split or the test set is not independent. Source: https://huggingface.co/datasets/kostaspic/amfitrite-open-waters-hab-sentinel2

Two more facts from the card's methodology section:
- Imputed tiles come from **HAB locations** that had no clean non-HAB neighbour, re-downloaded on other dates. So an imputed non-HAB tile and a HAB tile often share the exact same centre. A model that learns "this spot = HAB" will look good on a random split and be wrong.
- Labels were decided by CyFi + an ensemble of 4 deep-learning models + manual checks, so the ground truth is partly model-made (see the "Watch out: label leakage" section of the project plan).
