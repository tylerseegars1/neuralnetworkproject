% clean
clear;
clc;

% get files
root = fileparts(mfilename("fullpath"));
resultsDir = fullfile(root, "results");

load(fullfile(resultsDir, "hab_model.mat"), "net", "classNames");
load(fullfile(resultsDir, "dataset.mat"), "samples");

testSamples = samples(samples.Split == "Test", :);

if isempty(testSamples)
    error("no test samples u messed up somewhere");
end

testFiles = fullfile(testSamples.Path, "metadata.json");
testImages = fileDatastore(cellstr(testFiles), ReadFcn=@readSamples, FileExtensions=".json");

% get predictions and format
scores = minibatchpredict(net, testImages);
if isa(scores, "dlarray")
    scores = extractdata(scores);
end
scores = gather(scores);

if size(scores, 1) ~= height(testSamples) && size(scores, 2) == height(testSamples)
    scores = scores';
end

if ~isequal(size(scores), [height(testSamples), 2])
    error("wrong score dimensions dude");
end

% determine predictions
[~, predictedIdx] = max(scores, [], 2);

predictedLabels = categorical(classNames(predictedIdx), classNames);
actualLabels = testSamples.Label;

% create confusion matrix
classOrder = categorical(classNames, classNames);
C = confusionmat(actualLabels, predictedLabels, Order=classOrder);

TP = C(1, 1);
FN = C(1, 2);
FP = C(2, 1);
TN = C(2, 2);

% accuracy metrics
accuracy = (TP + TN) / sum(C(:));
precision = TP / max(TP + FP, 1);
recall = TP / max(TP + FN, 1);
specificity = TN / max(TN + FP, 1);

if precision + recall == 0
    f1 = 0;
else
    f1 = 2 * precision * recall / (precision + recall);
end

% print results
fprintf("\n===== Results =====\n");
fprintf("Accuracy:    %.2f%%\n", accuracy * 100);
fprintf("Precision:   %.2f%%\n", precision * 100);
fprintf("Recall:      %.2f%%\n", recall * 100);
fprintf("Specificity: %.2f%%\n", specificity * 100);
fprintf("F1 Score:    %.2f%%\n", f1 * 100);

% show confusion matrix
fprintf("\nConfusion matrix:\n");
disp(C);

fig = figure;
confusionchart(C, cellstr(classNames));
title("Test Set");

exportgraphics(fig, fullfile(resultsDir, "confusion_matrix.png"));

% save
testSamples.Predicted = predictedLabels;
testSamples.HABScore = scores(:, 1);
writetable(testSamples, fullfile(resultDir, "test_predictions.csv"));

metrics = table(accuracy, precision, recall, specificity, f1);
writetable(metrics, fullfile(resultsDir, "evaluation_metrics.csv"));

function image = readSamples(metadataFile)
    folder = fileparts(metadataFile);
    image = loadImg(folder);
end
