function trainModel()

    rng(42069);

    % get files
    root = fileparts(mfilename("fullpath"));
    resultsDir = fullfile(root, "results");
    modelFile = fullfile(resultsDir, "hab_model.mat");

    load(fullfile(resultsDir, "dataset.mat"), "samples");

    trainSamples = samples(samples.Split == "Train", :);
    validationSamples = samples(samples.Split == "Validation", :);
    
    batchSize = 16; % reduce if needed
    classNames = ["HAB", "NonHAB"];

    % combine images and labels
    trainFiles = fullfile(trainSamples.Path, "B01_raw.tif");
    validationFiles = fullfile(validationSamples.Path, "B01_raw.tif");

    trainImages = fileDatastore(cellstr(trainFiles), ...
        ReadFcn=@(file) loadImg(fileparts(file)), ...
        FileExtensions=".tif");

    validationImages = fileDatastore(cellstr(validationFiles), ...
        ReadFcn=@(file) loadImg(fileparts(file)), ...
        FileExtensions=".tif");

    trainLabels = arrayDatastore(trainSamples.Label);
    validationLabels = arrayDatastore(validationSamples.Label);

    trainingData = combine(trainImages, trainLabels);
    validationData = combine(validationImages, validationLabels);

    % transform all 14 channels together 
    trainingData = transform(trainingData, @augmentSample);


    % create network
    net = createCNN();
    iterationsPerEpoch = ceil(height(trainSamples) / batchSize);


    % training config ------------------------------------------
    options = trainingOptions("adam", ...
        InitialLearnRate=0.0003, ...
        LearnRateSchedule="piecewise", ...
        LearnRateDropFactor=0.5, ...
        LearnRateDropPeriod=15, ...
        MaxEpochs=80, ...
        MiniBatchSize=batchSize, ...
        Shuffle="every-epoch", ...
        L2Regularization=0.0001, ...
        GradientThreshold=5, ...
        ValidationData=validationData, ...
        ValidationFrequency=iterationsPerEpoch, ...
        ValidationPatience=15, ...
        OutputNetwork="best-validation", ...
        ExecutionEnvironment="gpu", ...
        Plots="training-progress", ...
        Verbose=true);
    % ----------------------------------------------------------

    % train and save the best-validation network
    [net, info] = trainnet(trainingData, net, "crossentropy", options);

    save(modelFile, "net", "info", "classNames", ...
        "samples", "batchSize", "-v7.3");


    % determine optimal scoring threshold
    scores = predictScores(net, validationSamples.Path, batchSize);
    threshold = selectThreshold(validationSamples.Label, scores(:, 1));

    validationMetrics = getMetrics(validationSamples.Label, scores(:, 1), threshold);
    objective = "mean(F1,F2)";

    save(modelFile, "threshold", "validationMetrics", "objective", "-append");


    % save and display best validation results
    results = validationMetrics(:, [ ...
        "Threshold", "Accuracy", "Precision", "Recall", "F1", "F2", "F1F2Mean"]);

    writetable(results, fullfile(resultsDir, "validation_metrics.csv"));

    disp(results);

    % confusion matrix
    confusion = [
        validationMetrics.TP, validationMetrics.FN
        validationMetrics.FP, validationMetrics.TN
    ];
    fig = figure;
    confusionchart(confusion, ["HAB", "NonHAB"]);
    title("Validation set");
    exportgraphics(fig, fullfile(resultsDir, "confusion_matrix.png"));

    fprintf("\nTraining done\n");
end

% image flipping func (maybe remove idk)
function data = augmentSample(data)

    image = data{1};

    if rand < 0.5
        image = fliplr(image);
    end

    if rand < 0.5
        image = flipud(image);
    end

    data{1} = rot90(image, randi(4) - 1);

end

% dynamically determine scoring threshold
function threshold = selectThreshold(labels, scores)

    thresholds = unique([0; double(scores(:)); 1 + eps]);
    best = getMetrics(labels, scores, thresholds(1));

    for i = 2:numel(thresholds)
        metrics = getMetrics(labels, scores, thresholds(i));

        % compare to find best threshold value
        best = sortrows([best; metrics], ...
            ["F1F2Mean", "F1", "F2", "Precision", "Recall", "Threshold"], ...
            ["descend", "descend", "descend", "descend", "descend", "descend"]);
        best = best(1, :);
    end
    threshold = best.Threshold;
end

% predict HAB score in image func
function scores = predictScores(net, paths, batchSize)

    % load image folders, predict in batches
    paths = string(paths(:));

    files = fullfile(paths, "B01_raw.tif");

    images = fileDatastore(cellstr(files), ...
        ReadFcn=@(file) loadImg(fileparts(file)), ...
        FileExtensions=".tif");

    scores = minibatchpredict(net, images, ...
        MiniBatchSize=batchSize, ExecutionEnvironment="gpu");

    if isa(scores, "dlarray")
        scores = extractdata(scores);
    end

    scores = gather(scores);
end

% get performance metrics func
function metrics = getMetrics(actual, scores, threshold)

    actual = string(actual(:));
    scores = double(scores(:));

    positive = actual == "HAB";
    predicted = scores >= threshold;

    TP = sum(positive & predicted);
    FN = sum(positive & ~predicted);
    FP = sum(~positive & predicted);
    TN = sum(~positive & ~predicted);

    accuracy = (TP + TN) / numel(scores);
    precision = TP / max(TP + FP, 1);
    recall = TP / (TP + FN);
    specificity = TN / (TN + FP);

    balancedAccuracy = (recall + specificity) / 2;
    f1 = 2 * TP / max(2 * TP + FP + FN, 1);
    f2 = 5 * TP / max(5 * TP + FP + 4 * FN, 1);
    f1f2Mean = (f1 + f2) / 2;

    metrics = table(threshold, TP, FN, FP, TN, accuracy, precision, ...
        recall, specificity, balancedAccuracy, f1, f2, f1f2Mean, ...
        VariableNames=["Threshold", "TP", "FN", "FP", "TN", "Accuracy", ...
        "Precision", "Recall", "Specificity", "BalancedAccuracy", ...
        "F1", "F2", "F1F2Mean"]);

end
