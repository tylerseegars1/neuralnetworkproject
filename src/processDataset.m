clear;
clc;

rng(42);

% !! Must ensure "same" images never get split between test,train,val

% get files
scriptFolder = fileparts(mfilename("fullpath"));
root = fileparts(scriptFolder);
dataDir = fullfile(root, "data/amfitrite", "data/amfitrite");
resultsDir = fullfile(root, "results");


if ~isfolder(dataDir)
    error("no dataset wtf");
end
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

bands = ["B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B09", "B11", "B12"];



% get sample folders
folders = dir(dataDir);
folders = folders([folders.isdir]);
names = string({folders.name});
folders = folders(~ismember(names, [".", ".."]));

% storage
paths = strings(0, 1);
labels = strings(0, 1);
groups = strings(0, 1);
satItems = strings(0, 1);

for i = 1:numel(folders)
    name = string(folders(i).name);
    folder = fullfile(dataDir, name);

    % Label either HAB or nonHAB (nonHAB + land + clouds)
    if endsWith(name, "_HAB")
        label = "HAB";
    elseif endsWith(name, "_nonHAB") || endsWith(name, "_land") || endsWith(name, "_clouds")
        label = "NonHAB";
    else
        % excludes distractors for now
        continue;
    end

    % verify file integrity (remove later?)
    valid = true;
    for b = 1:numel(bands)
        filename = fullfile(folder, bands(b) + "_raw.tif");
        if ~isfile(filename)
            valid = false;
            break;
        end
    end

    if ~valid
        warning("skipped %s, bands missing wtf", name);
        continue;
    end

    % read metadata.json
    metadataFile = fullfile(folder, "metadata.json");
    if ~isfile(metadataFile)
        warning("missing metadata for %s wtf", name);
        continue;
    end
    meta = jsondecode(fileread(metadataFile));
    fields = ["center_lat", "center_lon", "sat_item"];
    if ~all(isfield(meta, cellstr(fields)))
        warning("incomplete metadata in %s wtf", name);
        continue;
    end
    lat = double(meta.center_lat);
    lon = double(meta.center_lon);

    % group images by geolocation
    latGroup = floor(lat);
    lonGroup = floor(lon);
    group = sprintf("geo_%d_%d", latGroup, lonGroup);

    paths(end+1, 1) = string(folder);
    labels(end+1, 1) = label;
    groups(end+1, 1) = group;
    satItems(end+1, 1) = string(meta.sat_item);
end

if isempty(paths)
    error("no valid samples wtf");
end

samples = table(paths, categorical(labels, ["HAB", "NonHAB"]), groups, satItems, variableNames=["Path", "Label", "Group", "SatelliteItem"]);

% shuffle groups before classifying
uniqueGroups = unique(samples.Group);
nGroups = numel(uniqueGroups);
uniqueGroups = uniqueGroups(randperm(nGroups));

% 70/15/15 split for training validation and test
nTrain = floor(0.7 * nGroups);
nVal = floor(0.15 * nGroups);
groupSplit = strings(nGroups, 1);

groupSplit(1:nTrain) = "Train";
groupSplit(nTrain+1:nTrain+nVal) = "Validation";
groupSplit(nTrain+nVal+1:end) = "Test";

% assign samples to groups
[~, groupIdx] = ismember(samples.Group, uniqueGroups);
samples.Split = groupSplit(groupIdx);

% check for all groups containing all data types (hab and nonhab)
for split = ["Train", "Validation", "Test"]
    idx = samples.Split == split;
    nHAB = sum(samples.Label(idx) == "HAB");
    nNonHAB = sum(samples.Label(idx) == "NonHAB");
    if nHAB == 0 || nNonHAB == 0
        error("adjust grouping it messed up my bad");
    end
end

% validation for no unique values in groups
assert(numel(unique(samples.Group(samples.Split == "Train"))) + ...
    numel(unique(samples.Group(samples.Split == "Validation"))) + ...
    numel(unique(samples.Group(samples.Split == "Test"))) ...
    == numel(unique(samples.Group)));

% save processed dataset
save(fullfile(resultsDir, "dataset.mat"), "samples");

writetable(samples, fullfile(resultsDir, "dataset_split.csv"));

fprintf("\ndone");
