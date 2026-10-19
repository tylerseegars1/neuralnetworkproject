function image = loadImg(sampleName)
    
    scriptFolder = fileparts(mfilename("fullpath"));
    projectRoot = fileparts(scriptFolder);
    dataRoot = fullfile(projectRoot, "data/amfitrite", "data/amfitrite");

    folder = fullfile(dataRoot, string(sampleName));

    bands = ["B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B09", "B11", "B12"];
    image = zeros(256, 256, numel(bands), "single");
    
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

        % there is two different values for the bands, one normal and
        % another one with a +1000 offset, that must be fixed
        % Remove the optional 1000-unit offset from shifted band values.
        % if any(band(:) >= 1000)
        %     band = band - 1000;
        % end

        % chatgpt recommended reflectance scaling, might need to change idk
        band = band / 10000;
        
        image(:,:,i) = band;
    end
end

