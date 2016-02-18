function assembleTrainingDataSet

    % cd to here
    [rootPath,~] = fileparts(which(mfilename));
    cd(rootPath);
    
    [trainingImageSet, ~, ~, ~, ~] = configureExperiment('manchester');
    
    % change to see data from one scene only
    theSceneIndex = input(sprintf('Which scene to use ? [1 - %d] : ', numel(trainingImageSet)));
    trainingImageSet = {trainingImageSet{theSceneIndex}};
    
    trainingDataPercentange = input('Enter % of data to use for training [ e.g, 90]: ');
    if (trainingDataPercentange < 1) || (trainingDataPercentange > 100)
        error('% must be in [0 .. 100]\n');
    end

    
    % Compute number of training and testing scans
    totalTrainingScansNum = 0;
    totalTestingScansNum = 0;
    numel(trainingImageSet)
    for imageIndex = 1:numel(trainingImageSet)
        imsource = trainingImageSet{imageIndex};
        
        % See how many scan files there are for this image
        scanFilename = sprintf('%s_%s_scan1.mat', imsource{1}, imsource{2});
        load(scanFilename, 'scansNum', 'scanSensor');
        
        trainingScans = round(trainingDataPercentange/100.0*scansNum);
        fprintf('image %s/%s contains %d scans. Will use %d of these for training. \n', imsource{1}, imsource{2}, scansNum, trainingScans);
        totalTrainingScansNum = totalTrainingScansNum + trainingScans;
        totalTestingScansNum = totalTestingScansNum + (scansNum-trainingScans);
    end
    
    fprintf('Total training scans: %d\n', totalTrainingScansNum)
    fprintf('Total testing scans:  %d\n', totalTestingScansNum);
    
    % Parameters of decoding
    % The contrast sequences [space x time] to be decoded, have an original spatial resolution whose retinal size would be 1 micron
    % Here we subsample this. To first approximation, we take the mean over
    % all space, so we have only 1 spatial bin
    subSampledSpatialBins = [1 1];
    
    % Select how to subsample the cone mosaic.
    % thresholdConeSeparation = 0 to use the entire mosaic
    % thresholdConeSeparation = sqrt(2^2 + 2^2) to use cones separated by at least 2 cone apertures
    thresholdConeSeparation = sqrt(2^2 + 2^2);
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = determineConeIndicesToKeep(scanSensor, thresholdConeSeparation);
    
    % Hot to subsample time
    temporalSubSamplingResolutionInMilliseconds = 4;
    
    
    % partition the data into training and testing components
    trainingScanIndex = 0;
    testingScanIndex = 0;
   
    totalImages = numel(trainingImageSet);
    for imageIndex = 1:totalImages
  
        imsource = trainingImageSet{imageIndex};
        
        % See how many scan files there are for this image
        scanFilename = sprintf('%s_%s_scan1.mat', imsource{1}, imsource{2});
        load(scanFilename, 'scansNum');
        
        trainingScans = round(trainingDataPercentange/100.0*scansNum);
      
        % load training data
        for scanIndex = 1:trainingScans
            
            % filename for this scan
            scanFilename = sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex);
            
            % Load scan data
            [timeAxis, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, ...
                scanLcontrastSequence, scanMcontrastSequence, scanScontrastSequence, ...
                scanPhotoCurrents] = ...
                loadScanData(scanFilename, temporalSubSamplingResolutionInMilliseconds, keptLconeIndices, keptMconeIndices, keptSconeIndices);
            
            timeBins = numel(timeAxis);
            conesNum = size(scanPhotoCurrents,1);
            spatialBins = size(scanLcontrastSequence,1);
            
            % Spatially subsample LMS contrast sequences according to subSampledSpatialBins, e.g, [2 2]
            scanLcontrastSequence = subSampleSpatially(scanLcontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            scanMcontrastSequence = subSampleSpatially(scanMcontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            scanScontrastSequence = subSampleSpatially(scanScontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            
            % pre-allocate memory
            if (trainingScanIndex == 0)
                trainingTimeAxis            = (0:(timeBins*totalTrainingScansNum*totalImages-1))*(timeAxis(2)-timeAxis(1));
                trainingLcontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTrainingScansNum*totalImages, 'single');
                trainingMcontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTrainingScansNum*totalImages, 'single');
                trainingScontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTrainingScansNum*totalImages, 'single');
                trainingPhotocurrents       = zeros(conesNum, timeBins*totalTrainingScansNum*totalImages, 'single');
            end
            
            % determine insertion time point
            currentTimeBin = trainingScanIndex*timeBins+1;
            timeBinRange = (0:timeBins-1);
            theTimeBins = currentTimeBin + timeBinRange;
            binIndicesToPlot = 1:theTimeBins(end);
            
            % insert
            trainingLcontrastSequence(:, theTimeBins) = scanLcontrastSequence;
            trainingMcontrastSequence(:, theTimeBins) = scanMcontrastSequence;
            trainingScontrastSequence(:, theTimeBins) = scanScontrastSequence;
            trainingPhotocurrents(:, theTimeBins) = scanPhotoCurrents;
            size(trainingPhotocurrents)
            
            maxContrast = max([max(trainingLcontrastSequence(:)) max(trainingMcontrastSequence(:)) max(trainingScontrastSequence(:))]);
            
            % update training scan index
            trainingScanIndex = trainingScanIndex + 1;
      
            timeLims = [trainingTimeAxis(1) trainingTimeAxis(theTimeBins(end))]; %[0 1];
            
            hFig = figure(2);
            set(hFig, 'Color', [0 0 0], 'Name', sprintf('Scans: 1 - %d of %d', scanIndex, trainingScans), 'Position', [10 60 2880 1000]);
            clf;
            subplot('Position', [0.02 0.70 0.97 0.25]);
            hold on;
            plot(trainingTimeAxis(binIndicesToPlot), trainingLcontrastSequence(:,binIndicesToPlot), 'r.-');
            plot(trainingTimeAxis(binIndicesToPlot), trainingMcontrastSequence(:,binIndicesToPlot), 'g.-');
            plot(trainingTimeAxis(binIndicesToPlot), trainingScontrastSequence(:,binIndicesToPlot), 'b.-');
            ylabel('Weber cone contrast');
            set(gca, 'Color', [0 0 0 ], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'XLim', timeLims, 'YLim', maxContrast*[-1 1]);
            hold off;
            box on
            
            subplot('Position', [0.02 0.40 0.97 0.25]);
            hold on;
            lconeIndex = 1; 
            mconeIndex = numel(keptLconeIndices) + 1;
            sconeIndex = numel(keptLconeIndices) + numel(keptMconeIndices) + 1;
            plot(trainingTimeAxis(binIndicesToPlot), trainingPhotocurrents(lconeIndex,binIndicesToPlot), 'r.-');
            plot(trainingTimeAxis(binIndicesToPlot), trainingPhotocurrents(mconeIndex,binIndicesToPlot), 'g.-');
            plot(trainingTimeAxis(binIndicesToPlot), trainingPhotocurrents(sconeIndex,binIndicesToPlot), 'b.-');
            hold off;
            maxPhotoCurrent = max([...
                max(max(abs(trainingPhotocurrents(lconeIndex,binIndicesToPlot)))) ...
                max(max(abs(trainingPhotocurrents(mconeIndex,binIndicesToPlot)))) ...
                max(max(abs(trainingPhotocurrents(sconeIndex,binIndicesToPlot)))) 
                ]);
                
            set(gca, 'Color', [0 0 0 ], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'XLim', timeLims, 'YLim', [-1 1]*maxPhotoCurrent);
            xlabel('time (sec)');
            ylabel('cone %1');
            
            subplot('Position', [0.02 0.07 0.97 0.25]);
            imagesc(trainingTimeAxis(binIndicesToPlot), 1:conesNum, trainingPhotocurrents(:,binIndicesToPlot));
            set(gca, 'Color', [0 0 0 ], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'XLim', timeLims);
            set(gca, 'CLim', max(max(abs(trainingPhotocurrents(:,binIndicesToPlot))))*[-1 1]);
            xlabel('time (sec)');
            ylabel('cone id');
            colormap(bone(512));
            drawnow
            pause
            
        end % scanIndex
        fprintf('Added training data from image %d (%d scans)\n', imageIndex, trainingScanIndex);


        % load testing data
        for scanIndex = trainingScans+1:scansNum
            
            % filename for this scan
            scanFilename = sprintf('%s_%s_scan%d.mat', imsource{1}, imsource{2}, scanIndex);
            
            % Load scan data   
            [timeAxis, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons, ...
                scanLcontrastSequence, scanMcontrastSequence, scanScontrastSequence, ...
                scanPhotoCurrents] = ...
                loadScanData(scanFilename, temporalSubSamplingResolutionInMilliseconds, keptLconeIndices, keptMconeIndices, keptSconeIndices);
            
            timeBins = numel(timeAxis);
            conesNum = size(scanPhotoCurrents,1);
            spatialBins = size(scanLcontrastSequence,1);
            
            % Spatially subsample LMS contrast sequences according to subSampledSpatialBins, e.g, [2 2]
            scanLcontrastSequence = subSampleSpatially(scanLcontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            scanMcontrastSequence = subSampleSpatially(scanMcontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            scanScontrastSequence = subSampleSpatially(scanScontrastSequence, subSampledSpatialBins, LMSspatialXdataInRetinalMicrons, LMSspatialYdataInRetinalMicrons);
            
            % pre-allocate memory
            if (testingScanIndex == 0)
                testingTimeAxis            = (0:(timeBins*totalTestingScansNum*totalImages-1))*(timeAxis(2)-timeAxis(1));
                testingLcontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTestingScansNum*totalImages, 'single');
                testingMcontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTestingScansNum*totalImages, 'single');
                testingScontrastSequence   = zeros(prod(subSampledSpatialBins), timeBins*totalTestingScansNum*totalImages, 'single');
                testingPhotocurrents       = zeros(conesNum,    timeBins*totalTestingScansNum*totalImages, 'single');
            end
            
            % determine insertion time point
            currentTimeBin = testingScanIndex*timeBins+1;
            timeBinRange = (0:timeBins-1);
            theTimeBins = currentTimeBin + timeBinRange;
            
            % insert
            testingLcontrastSequence(:, theTimeBins) = scanLcontrastSequence;
            testingMcontrastSequence(:, theTimeBins) = scanMcontrastSequence;
            testingScontrastSequence(:, theTimeBins) = scanScontrastSequence;
            testingPhotocurrents(:, theTimeBins) = scanPhotoCurrents;
            
            % update testing scan index
            testingScanIndex = testingScanIndex + 1;
        end % scanIndex
        fprintf('Added testing data from image %d (%d scans)\n', imageIndex, testingScanIndex);
        
    end % imageIndex
end

function contrastSequence = subSampleSpatially(originalContrastSequence, subSampledSpatialBins, spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons)
    
    if (numel(subSampledSpatialBins) ~= 2)
        subSampledSpatialBins
        error('Expecting a 2 element vector');
    end
    
    if ((subSampledSpatialBins(1) == 1) && (subSampledSpatialBins(2) == 1))
        xRange = numel(spatialXdataInRetinalMicrons) * (spatialXdataInRetinalMicrons(2)-spatialXdataInRetinalMicrons(1));
        yRange = numel(spatialYdataInRetinalMicrons) * (spatialYdataInRetinalMicrons(2)-spatialYdataInRetinalMicrons(1));
        fprintf('\nOriginal spatial data %d x %d, covering an area of %2.2f x %2.2f microns.', numel(spatialXdataInRetinalMicrons), numel(spatialYdataInRetinalMicrons), xRange, yRange);
        fprintf('Will downsample to [1 x 1].');
        contrastSequence = mean(originalContrastSequence,1);
    else
       subSampledSpatialBins
       error('This subsampling is not yet implemented\n'); 
    end
    
end






function [timeAxis, spatialXdataInRetinalMicrons, spatialYdataInRetinalMicrons, ...
    LcontrastSequence, McontrastSequence, ScontrastSequence, ...
    photoCurrents] = loadScanData(scanFilename, temporalSubSamplingInMilliseconds, keptLconeIndices, keptMconeIndices, keptSconeIndices)
    % load stimulus LMS excitations and photocurrents 
    scanPlusAdaptationFieldLMSexcitationSequence = [];
    photoCurrents = [];
    
    load(scanFilename, ...
        'scanSensor', ...
        'photoCurrents', ...
        'scanPlusAdaptationFieldLMSexcitationSequence', ...
        'LMSexcitationXdataInRetinalMicrons', ...
        'LMSexcitationYdataInRetinalMicrons', ...
        'sensorAdaptationFieldParams');
    

    timeStep = sensorGet(scanSensor, 'time interval');
    timeBins = round(sensorGet(scanSensor, 'total time')/timeStep);
    timeAxis = (0:(timeBins-1))*timeStep;
    spatialBins = numel(LMSexcitationXdataInRetinalMicrons) * numel(LMSexcitationYdataInRetinalMicrons);
    
    % Compute baseline estimation bins (determined by the last points in the photocurrent time series)
    referenceBin = round(0.50*sensorAdaptationFieldParams.eyeMovementScanningParams.fixationDurationInMilliseconds/1000/timeStep);
    baselineEstimationBins = size(photoCurrents,3)-referenceBin+(-round(referenceBin/2):round(referenceBin/2));
    fprintf('Offsetting photocurrents by their baseline levels (estimated in [%2.2f - %2.2f] seconds.\n', baselineEstimationBins(1)*timeStep, baselineEstimationBins(end)*timeStep);
    
    % substract baseline from photocurrents
    photoCurrents = single(bsxfun(@minus, photoCurrents, mean(photoCurrents(:,:, baselineEstimationBins),3)));
    conesNum = size(photoCurrents,1) * size(photoCurrents,2);
    
    % reshape photoCurrent matrix to [ConesNum x timeBins]
    photoCurrents = reshape(photoCurrents(:), [conesNum timeBins]);
    
    % transform the scene's LMS Stockman excitations to LMS Weber contrasts
    adaptationFieldLMSexcitations = mean(scanPlusAdaptationFieldLMSexcitationSequence(baselineEstimationBins,:,:,:),1);
    scanPlusAdaptationFieldLMSexcitationSequence = bsxfun(@minus, scanPlusAdaptationFieldLMSexcitationSequence, adaptationFieldLMSexcitations);
    scanPlusAdaptationFieldLMSexcitationSequence = single(bsxfun(@rdivide, scanPlusAdaptationFieldLMSexcitationSequence, adaptationFieldLMSexcitations));
    
    % permute to make it [coneID X Y timeBins]
    LMScontrastSequences = permute(scanPlusAdaptationFieldLMSexcitationSequence, [4 2 3 1]);
    LcontrastSequence = squeeze(LMScontrastSequences(1, :, :, :));
    LcontrastSequence = reshape(LcontrastSequence(:), [spatialBins timeBins]);
    McontrastSequence = squeeze(LMScontrastSequences(2, :, :, :));
    McontrastSequence = reshape(McontrastSequence(:), [spatialBins timeBins]);
    ScontrastSequence = squeeze(LMScontrastSequences(3, :, :, :));
    ScontrastSequence = reshape(ScontrastSequence(:), [spatialBins timeBins]);
    
    % Select a subset of the cones based on the thresholdConeSeparation
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
    coneIndicesToKeep = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    
    plotTrainingMosaic = true;
    if (plotTrainingMosaic)
        xy = sensorGet(scanSensor, 'xy');
        figure(1);
        clf;
        hold on
        plot(xy(lConeIndices, 1), xy(lConeIndices, 2), 'ro', 'MarkerSize', 12, 'MarkerEdgeColor', [1 0.7 0.7]);
        plot(xy(mConeIndices, 1), xy(mConeIndices, 2), 'go', 'MarkerSize', 12, 'MarkerEdgeColor', [0.7 1.0 0.7]);
        plot(xy(sConeIndices, 1), xy(sConeIndices, 2), 'bo', 'MarkerSize', 12, 'MarkerEdgeColor', [0.7 0.7 1.0]);

        plot(xy(keptLconeIndices, 1), xy(keptLconeIndices, 2), 'ro', 'MarkerFaceColor', [1 0.2 0.2], 'MarkerSize', 8);
        plot(xy(keptMconeIndices, 1), xy(keptMconeIndices, 2), 'go', 'MarkerFaceColor', [0.2 1.0 0.2], 'MarkerSize', 8);
        plot(xy(keptSconeIndices, 1), xy(keptSconeIndices, 2), 'bo', 'MarkerFaceColor', [0.2 0.2 1.0], 'MarkerSize', 8);
        axis 'equal'; axis 'square'
    end
    photoCurrents = photoCurrents(coneIndicesToKeep, :);
    
    if (temporalSubSamplingInMilliseconds > 1)
        
        % According to Peter Kovasi:
        % http://www.peterkovesi.com/papers/FastGaussianSmoothing.pdf (equation 1)
        % Given a box average filter of width w x w, the equivalent 
        % standard deviation to apply to achieve roughly the same effect 
        % when using a Gaussian blur can be found by.
        % sigma = sqrt((w^2-1)/12)
        decimationFactor = round(temporalSubSamplingInMilliseconds/1000/timeStep);
        tauInSamples = sqrt((decimationFactor^2-1)/12);
        filterTime = -round(3*tauInSamples):1:round(3*tauInSamples);
        kernel = exp(-0.5*(filterTime/tauInSamples).^2);
        kernel = kernel / sum(kernel);
        
        for spatialSampleIndex = 1:spatialBins
            if (spatialSampleIndex == 1)
                % preallocate arrays
                tmp = single(downsample(conv(double(squeeze(LcontrastSequence(spatialSampleIndex,:))), kernel, 'same'),decimationFactor));
                LcontrastSequence2 = zeros(spatialBins, numel(tmp), 'single');
                McontrastSequence2 = zeros(spatialBins, numel(tmp), 'single');
                ScontrastSequence2 = zeros(spatialBins, numel(tmp), 'single');
                photoCurrents2     = zeros(size(photoCurrents,1), numel(tmp), 'single');
            end
            % Subsample LMS contrast sequences by a factor decimationFactor using a lowpass Chebyshev Type I IIR filter of order 8.
            LcontrastSequence2(spatialSampleIndex,:) = single(downsample(conv(double(squeeze(LcontrastSequence(spatialSampleIndex,:))), kernel, 'same'),decimationFactor));
            McontrastSequence2(spatialSampleIndex,:) = single(downsample(conv(double(squeeze(McontrastSequence(spatialSampleIndex,:))), kernel, 'same'),decimationFactor));
            ScontrastSequence2(spatialSampleIndex,:) = single(downsample(conv(double(squeeze(ScontrastSequence(spatialSampleIndex,:))), kernel, 'same'),decimationFactor));
        end
 
        for coneIndex = 1:size(photoCurrents,1)
            % Subsample photocurrents by a factor decimationFactor using a HammingWindow.
            photoCurrents2(coneIndex,:) = single(downsample(conv(double(squeeze(photoCurrents(coneIndex,:))), kernel, 'same'), decimationFactor));
        end

        % Also decimate time axis
        timeAxis = timeAxis(1:decimationFactor:end);
    end
    
    
    % Cut the initial 250 and trailing 50 mseconds of data
    initialPeriodInMilliseconds = 250;
    trailingPeriodInMilliseconds = 50;
    timeBinsToCutFromStart = round((initialPeriodInMilliseconds/decimationFactor)/1000/timeStep);
    timeBinsToCutFromEnd = round((trailingPeriodInMilliseconds/decimationFactor)/1000/timeStep);
    timeBinsToKeep = (timeBinsToCutFromStart+1):(numel(timeAxis)-timeBinsToCutFromEnd);
    
    
    
    LcontrastSequence = LcontrastSequence2(:, timeBinsToKeep);
    McontrastSequence = McontrastSequence2(:, timeBinsToKeep);
    ScontrastSequence = ScontrastSequence2(:, timeBinsToKeep);
    
    % Only return photocurrents for the cones we are keeping
    photoCurrents = photoCurrents2(:, timeBinsToKeep);
    
    timeAxis = timeAxis(timeBinsToKeep);
    % reset time axis to start at t = 0;
    timeAxis = timeAxis - timeAxis(1);
    
    spatialXdataInRetinalMicrons = LMSexcitationXdataInRetinalMicrons;
    spatialYdataInRetinalMicrons = LMSexcitationYdataInRetinalMicrons;
end


function [keptLconeIndices, keptMconeIndices, keptSconeIndices] = determineConeIndicesToKeep(scanSensor, thresholdConeSeparation)

    % Select a subset of the cones based on the thresholdConeSeparation
    coneTypes = sensorGet(scanSensor, 'coneType');
    lConeIndices = find(coneTypes == 2);
    mConeIndices = find(coneTypes == 3);
    sConeIndices = find(coneTypes == 4);
 
    [keptLconeIndices, keptMconeIndices, keptSconeIndices] = determineConesToKeep(coneTypes,  lConeIndices, mConeIndices, sConeIndices, thresholdConeSeparation);
end

function [keptLconeIndices, keptMconeIndices, keptSconeIndices] = determineConesToKeep(coneTypes,  lConeIndices, mConeIndices, sConeIndices, thresholdConeSeparation)
    
    % Eliminate cones separately for each of the L,M and S cone mosaics
    keptLconeIndices = determineConesToKeepForThisMosaic(coneTypes,  lConeIndices, thresholdConeSeparation);
    keptMconeIndices = determineConesToKeepForThisMosaic(coneTypes,  mConeIndices, thresholdConeSeparation);
    keptSconeIndices = determineConesToKeepForThisMosaic(coneTypes,  sConeIndices, thresholdConeSeparation);
    
    % Eliminate further so that we obtain the original LMS densities
    originalLconeDensity = numel(lConeIndices)/numel(coneTypes);
    newLconeDensity = numel(keptLconeIndices) / (numel(keptLconeIndices) + numel(keptMconeIndices) + numel(keptSconeIndices));
    f = newLconeDensity/originalLconeDensity;
    
    originalMconeDensity = numel(mConeIndices)/numel(coneTypes);
    newMconeDensity = numel(keptMconeIndices) / (numel(keptLconeIndices) + numel(keptMconeIndices) + numel(keptSconeIndices));
    desiredNumOfMcones = round(f*numel(keptMconeIndices) / newMconeDensity * originalMconeDensity);
    if (desiredNumOfMcones < numel(keptMconeIndices))
        randomIndices = randperm(numel(keptMconeIndices));
        keptMconeIndices = keptMconeIndices(randomIndices(1:desiredNumOfMcones));
    end
    
    originalSconeDensity = numel(sConeIndices)/numel(coneTypes);
    newSconeDensity = numel(keptSconeIndices) / (numel(keptLconeIndices) + numel(keptMconeIndices) + numel(keptSconeIndices));
    desiredNumOfScones = round(f*numel(keptSconeIndices) / newSconeDensity * originalSconeDensity);
    if (desiredNumOfScones < numel(keptSconeIndices))
        randomIndices = randperm(numel(keptSconeIndices));
        keptSconeIndices = keptSconeIndices(randomIndices(1:desiredNumOfScones));
    end
    
    % Do the subsampling
    coneIndicesToKeep = [keptLconeIndices(:); keptMconeIndices(:); keptSconeIndices(:) ];
    subsampledLconeDensity = numel(keptLconeIndices) / numel(coneIndicesToKeep);
    subsampledMconeDensity = numel(keptMconeIndices) / numel(coneIndicesToKeep);
    subsampledSconeDensity = numel(keptSconeIndices) / numel(coneIndicesToKeep);

    fprintf('kept L cones    : %d out of %d\n', numel(keptLconeIndices), numel(lConeIndices));
    fprintf('kept M cones    : %d out of %d\n', numel(keptMconeIndices), numel(mConeIndices));
    fprintf('kept S cones    : %d out of %d\n', numel(keptSconeIndices), numel(sConeIndices));
    fprintf('total kept cones: %d out of %d \n',  numel(coneIndicesToKeep), numel(lConeIndices)+numel(mConeIndices)+numel(sConeIndices));
    fprintf('original LMSratios  : %2.2f %2.2f %2.2f\n', originalLconeDensity, originalMconeDensity, originalSconeDensity);
    fprintf('subsampled LMSratios: %2.2f %2.2f %2.2f\n', subsampledLconeDensity, subsampledMconeDensity, subsampledSconeDensity);
    
    function keptConeIndices = determineConesToKeepForThisMosaic(coneTypes, theConeIndices, thresholdDistance)
    
        if (thresholdDistance <= 0)
            keptConeIndices = theConeIndices;
            return;
        end
    
        coneRowPositions = zeros(1, numel(theConeIndices));
        coneColPositions = zeros(1, numel(theConeIndices));
        for theConeIndex = 1:numel(theConeIndices)
            [coneRowPositions(theConeIndex), coneColPositions(theConeIndex)] = ind2sub(size(coneTypes), theConeIndices(theConeIndex));
        end

        originalConeRowPositions = coneRowPositions;
        originalConeColPositions = coneColPositions;
    
        % Lets keep the cone that is closest to the center.
        [~, idx] = min(sqrt(coneRowPositions.^2 + coneColPositions.^2));
        keptConeIndices(1) = idx;
        keptConeRows(1) = coneRowPositions(idx);
        keptConeCols(1) = coneColPositions(idx);

        remainingConeIndices = setdiff(1:numel(theConeIndices), keptConeIndices);

        scanNo = 1;
        while (~isempty(remainingConeIndices))

            for keptConeIndex = 1:numel(keptConeIndices) 
                % compute all distances between cones in the kept indices and all other cones
                distances = sqrt( (coneRowPositions - keptConeRows(keptConeIndex)).^2 + (coneColPositions - keptConeCols(keptConeIndex)).^2);
                coneIndicesThatAreTooClose = find(distances <= thresholdDistance);

                remainingConeIndices = setdiff(remainingConeIndices, remainingConeIndices(coneIndicesThatAreTooClose));
                coneRowPositions = originalConeRowPositions(remainingConeIndices);
                coneColPositions = originalConeColPositions(remainingConeIndices);
            end
            if (~isempty(remainingConeIndices))
                % Select next cone to keep
                keptConeIndices = [keptConeIndices remainingConeIndices(1)];
                keptConeRows(numel(keptConeIndices)) = originalConeRowPositions(remainingConeIndices(1));
                keptConeCols(numel(keptConeIndices)) = originalConeColPositions(remainingConeIndices(1));
                scanNo = scanNo + 1;
            end
        end

        keptConeIndices = theConeIndices(keptConeIndices);
    end

end


