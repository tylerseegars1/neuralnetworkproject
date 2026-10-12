
function layers = createCNN(imageSize, numClasses)

    % imageSize: [height, width, channels]
    % numClasses: # of classification categories

    layers = [
        % input
        imageInputLayer(imageSize, Normalization="none")

        % learn spectral bands
        convolution2dLayer(1, 32, Padding="same", Name="spectral_conv")
        batchNormalizationLayer
        reluLayer

        % extract spatial patterns
        convolution2dLayer(3, 32, Padding="same", Name="conv1")
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(2, Stride=2)

        convolution2dLayer(3, 64, Padding="same", Name="conv2")
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(2, Stride=2)

        convolution2dLayer(3, 128, Padding="same", Name="conv3")
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(2, Stride=2)

        convolution2dLayer(3, 128, Padding="same", Name="conv4")
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(2, Stride=2)

        % classification
        globalAveragePooling2dLayer
        fullyConnectedLayer(64, Name="classifier")
        reluLayer
        dropoutLayer(0.4)

        % Output
        fullyConnectedLayer(numClasses, Name="output")
        softmaxLayer
    ];
end
