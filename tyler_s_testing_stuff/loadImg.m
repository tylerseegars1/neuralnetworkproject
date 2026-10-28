function image = loadImg(folder)

    % determine reflectance scaling offset
    meta = jsondecode(fileread(fullfile(folder, "metadata.json")));
    date = datetime(string(meta.date), InputFormat="yyyy-MM-dd");
    offset = 0;

    if date >= datetime(2022, 1, 25)
        offset = 1000;
    end
    
    bands = ["B01", "B02", "B03", "B04", "B05", "B06", ...
        "B07", "B08", "B8A", "B09", "B11", "B12"];

    image = zeros(256, 256, 12, "single");

    for i = 1:numel(bands)
        filename = fullfile(folder, bands(i) + "_raw.tif");
        image(:, :, i) = single(imread(filename));
    end


    % get the scl data (new)
    scl = imread(fullfile(folder, "SCL_raw.tif"));
    noData = image == 0;

    % ignore no-data, defective pixels, and invalid spectral values
    valid = all(isfinite(image), 3) & any(image ~= 0, 3) ...
        & scl ~= 0 & scl ~= 1;

    % reflectance scaling
    image = (image - offset) ./ 10000;
    image(noData) = 0;

    for i = 1:12
        band = image(:, :, i);
        band(~valid) = 0;
        image(:, :, i) = band;
    end

    % water/cloud channels
    water = scl == 6 & valid;
    clouds = ismember(scl, [3, 8, 9, 10]) & valid;

    % 12 spectral bands + water + clouds
    image = cat(3, image, single(water), single(clouds));

end
