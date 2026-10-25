% clean
clear;
clc;

rng(42);

% get files
scriptFolder = fileparts(mfilename('fullpath'));
baseFolder = fileparts(scriptFolder);

dataDir = fullfile(baseFolder, "data", "amfitrite-open-waters-hab-sentinel2", "data");
resultsDir = fullfile(baseFolder, "results");

if ~isfolder(dataDir)
    error("no dataset wtf");
end

if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

bands = ["B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B09", "B11", "B12"];

kmThreshold_TileNeigbors = 4;



% get sample folders
folders = dir(dataDir);
folders = folders([folders.isdir]);
names = string({folders.name});

% filters the folders array to exclude entries whoses names are "." or ".."
folders = folders(~ismember(names, [".", ".."]));

% storage
% it will eventually be possible to preallocate these sizes to save on
% time processed
lats = zeros(0,1); %added lats and lons to allow for distance calculations
lons = zeros(0,1);

paths = strings(0, 1);
labels = strings(0, 1);
kinds = strings(0, 1);
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

    % Acquire True Label for customization of image flipping scenarios
    kind = extractAfter(name, "_");

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


    lats(end+1, 1)      = lat;
    lons(end+1, 1)      = lon;
    paths(end+1, 1)     = string(folder);
    kinds(end+1, 1)     = kind;
    labels(end+1, 1)    = label;
    % groups(end+1, 1)    = group;
    satItems(end+1, 1)  = string(meta.sat_item);
end

if isempty(paths)
    error("no valid samples wtf");
end

% Finding the distance between a main tile and its surroundings
MdeltaLats = (lats - lats') * 111.2;

meanLat = (lats + lats') / 2;
MdeltaLons = (lons - lons') * 111.2 .* cosd(meanLat);

% calculate the direct distance between a tile and all other tiles
MstraightLineDist = sqrt(MdeltaLats.^2 + MdeltaLons.^2);

% 
tileNeigbors = MstraightLineDist <= kmThreshold_TileNeigbors;
adjM_graph = graph(tileNeigbors, "omitselfloops");

clusterID = conncomp(adjM_graph);
nClusters = numel(unique(clusterID));

Group = clusterID(:);

samples = table(paths, categorical(labels, ["HAB", "NonHAB"]), Group, categorical(kinds, ["HAB", "nonHAB", "land", "clouds"]), satItems, variableNames=["Path", "Label", "Group", "Kind", "SatelliteItem"]);

% grouping and train/validate/test sets
uniqueGroups = unique(samples.Group);
nGroups = numel(uniqueGroups);

ratios = [0.7, 0.15, 0.15];
splitNames = ["Train", "Validation", "Test"];

bestScore = inf;
bestSplit = strings(height(samples), 1);

for attempt = 1:1000
    shuffledGroups = uniqueGroups(randperm(nGroups));

    nTrain = floor(0.7 * nGroups);
    nVal = floor(0.15 * nGroups);

    groupAssignments = strings(nGroups, 1);
    groupAssignments(1:nTrain) = "Train";
    groupAssignments(nTrain+1:nTrain+nVal) = "Validation";
    groupAssignments(nTrain+nVal+1:end) = "Test";
    
    [~, groupIdx] = ismember(samples.Group, shuffledGroups);

    candidateSplit = groupAssignments(groupIdx);
    score = 0;
    valid = true;

    for s = 1:3
        idx = candidateSplit == splitNames(s);

        total = sum(idx);
        nHAB = sum(samples.Label(idx) == "HAB");
        nNonHAB = sum(samples.Label(idx) == "NonHAB");

        if total == 0 || nHAB == 0 || nNonHAB == 0
            valid = false;
            break;
        end

        actualRatio = total / height(samples);
        score = score + abs(actualRatio - ratios(s));

        overallHABRatio = mean(samples.Label == "HAB");
        splitHABRatio = nHAB / total;

        score = score + abs(splitHABRatio - overallHABRatio);
    end

    if valid && score < bestScore
        bestScore = score;
        bestSplit = candidateSplit;
    end
end

if isinf(bestScore)
    error("couldnt find split woops");
end

samples.Split = bestSplit;


% make sure each group has diverse data types (hab and nonhab)
for split = ["Train", "Validation", "Test"]
    idx = samples.Split == split;
    nHAB = sum(samples.Label(idx) == "HAB");
    nNonHAB = sum(samples.Label(idx) == "NonHAB");
    if nHAB == 0 || nNonHAB == 0
        error("adjust grouping it messed up my bad");
    end
end

% plot for graph, and subgraph to plot cluster tile 6 belongs to, therefore
% visually seeing the grid as dots




% validation for unique values in groups
assert(numel(unique(samples.Group(samples.Split == "Train"))) + ...
    numel(unique(samples.Group(samples.Split == "Validation"))) + ...
    numel(unique(samples.Group(samples.Split == "Test"))) ...
    == numel(unique(samples.Group)));

% save processed dataset
save(fullfile(resultsDir, "dataset.mat"), "samples");

writetable(samples, fullfile(resultsDir, "dataset_split.csv"));

fprintf("\ndone");
