function image = loadImg(folder)
    
    bands = ["B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B09", "B11", "B12"];
    image = zeros(256, 256, numel(bands), "single");
    
    
    % open metadata.json --/-> acquire satItem --/-> subtract bands by .1
    metadataFile = fullfile(folder, "metadata.json");
    if ~isfile(metadataFile)
         error("missing metadata file, check %s", metadataFile);
    end
    metadata = jsondecode(fileread(metadataFile));
    
    for i = 1:numel(bands)
        filename = fullfile(folder, bands(i) + "_raw.tif");

        if ~isfile(filename)
            error("missing band wtf, check %s", filename);
        end

        % consider optional cli argument somewhere around here to drop
        % bands or not
        band = single(imread(filename));

        if ~isequal(size(band), [256, 256])
            error("weird band size wtf, check %s", filename);
        end

        band = band / 10000;

        splitSatItem = split(metadata.sat_item(),'_');
        splitByT_splitSatItem = split(splitSatItem(end), 'T');
        processedDate = datetime(splitByT_splitSatItem(1), "InputFormat", "yyyyMMdd");
        if processedDate >= datetime(2022, 1, 25)
            band = band - 0.1;
        end

        % in case of below 0 values; introduce a floor to the bands ...
        % Clamp corrected reflectance values to the valid range.
        band = max(band, 0);

        image(:,:,i) = band;
    end
end

