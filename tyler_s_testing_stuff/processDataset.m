function processDataset()

    % get files
    root = fileparts(mfilename("fullpath"));
    dataDir = fullfile(root, "..", "data", "amfitrite-open-waters-hab-sentinel2", "data");
    masterFile = fullfile(root, "amfitrite_open_waters_master.csv");
    resultsDir = fullfile(root, "results");
    master = readtable(masterFile, TextType="string", VariableNamingRule="preserve");
    ids = str2double(string(master.ID));

    % get sample folders
    folders = dir(dataDir);
    folders = folders([folders.isdir]);
    folders = folders(~ismember(string({folders.name}), [".", ".."]));

    n = height(master);

    paths = strings(n, 1);
    labels = strings(n, 1);
    scenes = strings(n, 1);
    dates = NaT(n, 1);
    lat = nan(n, 1);
    lon = nan(n, 1);


    % read sample metadata
    for i = 1:numel(folders)
        name = string(folders(i).name);
        token = regexp(name, '^(\d+)_(HAB|nonHAB|land|clouds)$', 'tokens', 'once');

        if isempty(token)
            continue;
        end

        row = find(ids == str2double(token{1}));

        folder = fullfile(dataDir, name);

        meta = jsondecode(fileread(fullfile(folder, "metadata.json")));

        paths(row) = folder;
        scenes(row) = string(meta.sat_item);
        dates(row) = datetime(string(meta.date), InputFormat="yyyy-MM-dd");
        lat(row) = double(meta.center_lat);
        lon(row) = double(meta.center_lon);

        % use nonHAB for cloud/land files
        labels(row) = "NonHAB";
        if string(token{2}) == "HAB"
            labels(row) = "HAB";
        end
    end

    % connect samples with same measurement location/date for grouping
    sampleA = [];
    sampleB = [];

    [sampleA, sampleB] = connectSamples(scenes, sampleA, sampleB);
    source = string(master.dataset);
    source(ismissing(source)) = "";
    measurementLat = str2double(string(master.decimalLatitude));
    measurementLon = str2double(string(master.decimalLongitude));
    event = string(master.eventDate);

    present = isfinite(measurementLat) & isfinite(measurementLon) ...
        & ~ismissing(event) & strlength(event) > 0;

    keys = strings(n, 1);
    keys(present) = source(present) + ":" ...
        + compose('%.6f', measurementLat(present)) + ":" ...
        + compose('%.6f', measurementLon(present)) + ":" + event(present);

    [sampleA, sampleB] = connectSamples(keys, sampleA, sampleB);


    % updated geographic grouping (10km grouping)
    for i = 1:n-1
        j = (i+1:n)';

        h = sind((lat(j) - lat(i)) / 2) .^ 2 ...
            + cosd(lat(i)) * cosd(lat(j)) .* sind((lon(j) - lon(i)) / 2) .^ 2;

        distance = 2 * 6371 * asin(sqrt(min(1, max(0, h))));
        neighbors = j(distance < 10);

        sampleA = [sampleA; repmat(i, numel(neighbors), 1)]; 
        sampleB = [sampleB; neighbors]; 
    end

    group = conncomp(graph(sampleA, sampleB, [], n))';


    % find split close to 70/15/15
    rng(42069);

    ratios = [0.70, 0.15, 0.15];
    splitNames = ["Train", "Validation", "Test"];
    nGroups = max(group);

    counts = accumarray(group, 1, [nGroups, 1]);
    positives = accumarray(group, double(labels == "HAB"), [nGroups, 1]);

    bestScore = inf;
    split = strings(n, 1);

    for attempt = 1:5000
        order = randperm(nGroups)';

        % split groups as best as possible based on midpoint
        midpoint = (cumsum(counts(order)) - counts(order) / 2) / n;
        assignments = 1 + (midpoint > ratios(1)) ...
            + (midpoint > sum(ratios(1:2)));

        map = zeros(nGroups, 1);
        map(order) = assignments;
        score = 0;

        for s = 1:3
            selected = map == s;
            total = sum(counts(selected));
            nHAB = sum(positives(selected));

            if nHAB == 0 || total == nHAB
                score = inf;
                break;
            end

            score = score + abs(total / n - ratios(s)) ...
                + abs(nHAB / total - mean(labels == "HAB"));
        end

        if score < bestScore
            bestScore = score;
            split = reshape(splitNames(map(group)), [], 1);
        end
    end

    assert(isfinite(bestScore), ...
    "Didn't find a good split try again");

    % create split data table
    samples = table(ids, paths, categorical(labels, ["HAB", "NonHAB"]), ...
        scenes, dates, lat, lon, group, split, string(master.tile_status), source, ...
        VariableNames=["ID", "Path", "Label", "SatelliteItem", "Date", ...
        "Latitude", "Longitude", "Group", "Split", "TileStatus", "Source"]);


    % save
    if ~isfolder(resultsDir)
        mkdir(resultsDir);
    end

    save(fullfile(resultsDir, "dataset.mat"), "samples", "dataDir");

    fprintf("\nProcessing done\n");

end

% connect samples func
function [sampleA, sampleB] = connectSamples(keys, sampleA, sampleB)

    seen = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for i = 1:numel(keys)
        if ismissing(keys(i)) || strlength(keys(i)) == 0
            continue;
        end

        key = char(keys(i));

        if isKey(seen, key)
            sampleA(end+1, 1) = seen(key);
            sampleB(end+1, 1) = i;
        else
            seen(key) = i;
        end
    end

end
