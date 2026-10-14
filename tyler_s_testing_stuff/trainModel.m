% clean
clc;

rng(42069);

% get files
root = fileparts(mfilename("fullpath"));
resultsDir = fullfile(root, "results");

load(fullfile(resultsDir, "dataset.mat"), "samples");

trainSamples = samples(samples.Split == "Train", :);
validationSamples = samples(samples.Split == "Validation", :);

if isempty(trainSamples) || isempty(validationSamples)
    error("missing training or validation data brother");
end

trainFiles = fullfile(trainSamples.Path, "metadata.json");
validationFiles = fullfile(validationSamples.Path, "metadata.json");

trainImages = fileDatastore(cellstr(trainFiles), ReadFcn=@readSample, FileExtensions=".json");
validationImages = fileDatastore(cellstr(validationFiles), ReadFcn=@readSample, FileExtensions=".json");

trainLabels = arrayDatastore(trainSamples.Label);
validationLabels = arrayDatastore(validationSamples.Label);

trainingData = combine(trainImages, trainLabels);
validationData = combine(validationImages, validationLabels);

trainingData = transform(trainingData, @augmentSample);

% network config
imageSize = [256, 256, 12];
classNames = ["HAB", "NonHAB"];
layers = createCNN(imageSize, numel(classNames));

% training config
options = trainingOptions("adam", ...
    InitialLearnRate=0.0003, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.5, ...
    LearnRateDropPeriod=5, ...
    MaxEpochs=40, ...
    MiniBatchSize=16, ...
    Shuffle="every-epoch", ...
    ValidationData=validationData, ...
    ValidationFrequency=25, ...
    ValidationPatience=12, ...
    OutputNetwork="best-validation", ...
    ExecutionEnvironment="gpu", ...
    Plots="training-progress", ...
    Verbose=true);

% train
[net, info] = trainnet(trainingData, layers, "crossentropy", options);

% save
save(fullfile(resultsDir, "hab_model.mat"), "net", "info", "imageSize", "classNames", "-v7.3");

% randomly flip images func
function data = augmentSample(data)
    image = data{1};

    if rand < 0.5
        image = fliplr(image);
    end

    if rand < 0.5
        image = flipud(image);
    end

    image = rot90(image, randi([0, 3]));
    data{1} = image;
end

% image load func
function image = readSample(metadataFile)
    folder = fileparts(metadataFile);
    image = loadImg(folder);
end