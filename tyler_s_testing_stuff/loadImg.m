function image = loadImg(folder)

    bands = ["B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B09", "B11", "B12"];
    image = zeros(256, 256, numel(bands), "single");
    for i = 1:numel(bands)
        filename = fullfile(folder, bands(i) + "_raw.tif");

        if ~isfile(filename)
            error("missing band wtf, check %s", filename);
        end

        band = single(imread(filename));

        if ~isequal(size(band), [256, 256])
            error("weird band size wtf, check %s", filename);
        end

        % chatgpt recommended reflectance scaling, might need to change idk
        band = band / 10000;
        
        image(:,:,i) = band;
    end
end
