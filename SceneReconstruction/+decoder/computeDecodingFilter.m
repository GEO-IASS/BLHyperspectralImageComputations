function computeDecodingFilter(sceneSetName, decodingDataDir, computeSVDbasedFilters, rankApproximations)

    fprintf('\n1. Loading training design matrix (X) and stimulus vector ... ');
    tic
    fileName = fullfile(decodingDataDir, sprintf('%s_trainingDesignMatrices.mat', sceneSetName));
    load(fileName, 'Xtrain', 'Ctrain', 'oiCtrain', 'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence','trainingScanInsertionTimes', 'trainingSceneLMSbackground', 'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', 'expParams', 'coneTypes', 'spatioTemporalSupport');
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    
    % Compute the rank of X
    timeSamples = size(Xtrain,1);
    filterDimensions = size(Xtrain,2);
    stimulusDimensions = size(Ctrain,2);
    fprintf('2a. Computing rank(X) [%d x %d]... ',  timeSamples, filterDimensions);
    tic
    XtrainRank = rank(Xtrain);
    fprintf('Done after %2.1f minutes.', toc/60);
    fprintf('<strong>Rank (X) = %d</strong>\n', XtrainRank);
     
    fprintf('2b. Computing optimal linear decoding filter: pinv(X) [%d x %d] ... ', timeSamples, filterDimensions);
    tic
    pseudoInverseOfX = pinv(Xtrain);
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    fprintf('2c. Computing optimal linear decoding filter: coefficients [%d x %d] ... ', filterDimensions, stimulusDimensions);
    tic
    wVector = zeros(filterDimensions, stimulusDimensions);
    for stimDim = 1:stimulusDimensions
        wVector(:,stimDim) = pseudoInverseOfX * Ctrain(:,stimDim);
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);
    
    if (computeSVDbasedFilters)
        % Compute and save the SVD decomposition of X so we can check (later) how the
        % filter dynamics depend on the # of SVD components
        fprintf('2d. Computing SVD-based low-rank approximation filters [%d x %d]... ',  size(Xtrain,1), size(Xtrain,2));
        tic
        [Utrain, Strain, Vtrain] = svd(Xtrain, 'econ');
        
        wVectorSVDbased = zeros(numel(rankApproximations), filterDimensions, stimulusDimensions);
        for kIndex = 1:numel(rankApproximations)
            includedComponentsNum = rankApproximations(kIndex);
            wVector = (Vtrain(:,1:includedComponentsNum)*inv(Strain(1:includedComponentsNum,1:includedComponentsNum))*(Utrain(:,1:includedComponentsNum))') * Ctrain;
            wVectorSVDbased(kIndex,:,:) = wVector;
        end
        fprintf('Done after %2.1f minutes.\n', toc/60);
    end
    
    fprintf('3. Computing in-sample predictions [%d x %d]...',  timeSamples, stimulusDimensions);
    tic
    CtrainPrediction = Ctrain*0;
    for stimDim = 1:stimulusDimensions
        CtrainPrediction(:, stimDim) = Xtrain * wVector(:,stimDim);
    end
    
    if (computeSVDbasedFilters)
        CtrainPredictionSVDbased = zeros(numel(rankApproximations), size(CtrainPrediction,1), size(CtrainPrediction,2));
        for kIndex = 1:numel(rankApproximations)
            w = squeeze(wVectorSVDbased(kIndex,:,:));
            for stimDim = 1:stimulusDimensions
                CtrainPredictionSVDbased(kIndex,:, stimDim) = Xtrain * w(:,stimDim);
            end
        end
    end
    
    fprintf('Done after %2.1f minutes.\n', toc/60);

    fprintf('4. Saving decoder filter and in-sample predictions ... ');
    fileName = fullfile(decodingDataDir, sprintf('%s_decodingFilter.mat', sceneSetName));
    tic
    save(fileName, 'wVector', 'spatioTemporalSupport', 'coneTypes', 'XtrainRank', 'expParams', '-v7.3');
    if (computeSVDbasedFilters)
        save(fileName, 'Utrain', 'Strain', 'Vtrain', 'wVectorSVDbased', 'rankApproximations', '-append'); 
    end
    
    fileName = fullfile(decodingDataDir, sprintf('%s_inSamplePrediction.mat', sceneSetName));
    save(fileName,  'Ctrain', 'oiCtrain', 'CtrainPrediction', ...
        'trainingTimeAxis', 'trainingSceneIndexSequence', 'trainingSensorPositionSequence', ...
        'trainingScanInsertionTimes', 'trainingSceneLMSbackground', ...
        'trainingOpticalImageLMSbackground', 'originalTrainingStimulusSize', ...
        'expParams',  '-v7.3');
    if (computeSVDbasedFilters)
        save(fileName, 'CtrainPredictionSVDbased', 'rankApproximations', '-append');
    end
    fprintf('Done after %2.1f minutes.\n', toc/60);
end


