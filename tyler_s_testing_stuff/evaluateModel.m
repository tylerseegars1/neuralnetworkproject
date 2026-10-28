function predictions = evaluateModel()

    % get model data
    root = fileparts(mfilename("fullpath"));
    resultsDir = fullfile(root, "results");
    model = load(fullfile(resultsDir, "hab_model.mat"));
    testSamples = model.samples(model.samples.Split == "Test", :);
    folders = string(testSamples.Path);

    % get predictions 
    scores = predictScores(model.net, folders, model.batchSize);

    predictedLabels = repmat("NonHAB", numel(folders), 1);
    predictedLabels(scores(:, 1) >= model.threshold) = "HAB";

    predictions = table(folders, scores(:, 1), predictedLabels, ...
        VariableNames=["Path", "HABScore", "Predicted"]);


    % calculate/print metrics
    metrics = getMetrics(testSamples.Label, scores(:, 1), model.threshold);
    disp(metrics);

    % confusion matrix
    confusion = [
        metrics.TP, metrics.FN
        metrics.FP, metrics.TN
    ];
    fig = figure;
    confusionchart(confusion, ["HAB", "NonHAB"]);
    title("Test set");
    exportgraphics(fig, fullfile(resultsDir, "confusion_matrix.png"));

end

% predict HAB score in image func
function scores = predictScores(net, paths, batchSize)

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

% get training metrics func
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
