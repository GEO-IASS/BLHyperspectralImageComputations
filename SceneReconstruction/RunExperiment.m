function RunExperiment

    setPrefsForHyperspectralImageIsetbioComputations();
        
    % What to compute
    instructionSet = {...
        'compute outer segment responses' ...  % produces the contents of the scansData directory
        'assembleTrainingDataSet' ...       % produces the training/testing design matrices in the decodingData directory
        'computeDecodingFilter' ...       % inverts the training desing matrix to comptue the decoding filter (stored in the decodingData directory)
        'computeOutOfSamplePrediction' ...
       % 'visualizeScan' ...
       %'visualizeDecodingFilter' ...
       % 'visualizeInSamplePrediction' ...
       % 'visualizeOutOfSamplePrediction' ...
       %'makeReconstructionVideo' ...
        };
  
    % these following be used if 'compute outer segment responses' is not in the instructionSet.
    sceneSetName = 'manchester';
    descriptionString = 'AdaptEvery22Fixations/@osLinear';
    
    for k = 1:numel(instructionSet)
        
        if (exist('expParams', 'var'))
            sceneSetName = expParams.sceneSetName;
            descriptionString = sprintf('AdaptEvery%dFixations/%s', expParams.viewModeParams.consecutiveSceneFixationsBetweenAdaptingFieldPresentation,expParams.outerSegmentParams.type);
            fprintf('Will analyze data from %s and %s\n', sceneSetName, descriptionString);
        end
        
        switch instructionSet{k}
            case 'compute outer segment responses'
                expParams = experimentParams();
                core.computeOuterSegmentResponses(expParams);

            case 'visualizeScan'
                sceneIndex = input('Select the scene index to visualize: ');
                visualizer.renderScan(sceneSetName, descriptionString, sceneIndex);
                
            case 'assembleTrainingDataSet'
                trainingDataPercentange = 50;
                decoder.assembleTrainingSet(sceneSetName, descriptionString, trainingDataPercentange);

            case 'computeDecodingFilter'
                decoder.computeDecodingFilter(sceneSetName, descriptionString);
                
            case 'computeOutOfSamplePrediction'
                decoder.computeOutOfSamplePrediction(sceneSetName, descriptionString);
                
            case 'visualizeDecodingFilter'
                visualizer.renderDecoderFilterDynamicsFigures(sceneSetName, descriptionString);
          
            case 'visualizeInSamplePrediction'
                visualizer.renderInSamplePredictionsFigures(sceneSetName, descriptionString);
            
            case 'visualizeOutOfSamplePrediction'
                visualizer.renderOutOfSamplePredictionsFigures(sceneSetName, descriptionString);
                
            case 'makeReconstructionVideo'
                visualizer.renderReconstructionVideo(sceneSetName, descriptionString);
                
            otherwise
                error('Unknown instruction: ''%s''.\n', instructionSet{1});
        end  % switch 
    end % for k
end

function expParams = experimentParams()

        decoderParams = struct(...
        'type', 'optimalLinearFilter', ...
        'thresholdConeSeparationForInclusionInDecoder', 0, ...      % 0 to include all cones
        'spatialSamplingInRetinalMicrons', 3.0, ...                 % decode scene ((retinal projection)) at 5 microns resolution
        'extraMicronsAroundSensorBorder', 0, ...                   % decode this many additional (or less, if negative) microns on each side of the sensor
        'temporalSamplingInMilliseconds', 10, ...                   % decode every this many milliseconds
        'latencyInMillseconds', -150, ...
        'memoryInMilliseconds', 600 ...
    );

    sensorTimeStepInMilliseconds = 0.1;  % must be small enough to avoid numerical instability in the outer segment current computation
    integrationTimeInMilliseconds = 50;
    
    % sensor params for scene viewing
    sensorParams = struct(...
        'coneApertureInMicrons', 3.0, ...        
        'LMSdensities', [0.6 0.3 0.1], ...        
        'spatialGrid', [18 26], ...                      % [rows, cols]
        'samplingIntervalInMilliseconds', sensorTimeStepInMilliseconds, ...  
        'integrationTimeInMilliseconds', integrationTimeInMilliseconds, ...
        'randomSeed',  1552784, ...                                                % fixed value to ensure repeatable results
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', sensorTimeStepInMilliseconds, ...
            'meanFixationDurationInMilliseconds', 200, ...
            'stDevFixationDurationInMilliseconds', 20, ...
            'meanFixationDurationInMillisecondsForAdaptingField', 400, ...
            'stDevFixationDurationInMillisecondsForAdaptingField', 20, ...
            'fixationOverlapFactor', 0.6, ...     
            'saccadicScanMode',  'randomized'... %                        % 'randomized' or 'sequential', to visit eye position grid sequentially
        ) ...
    );
    
    outerSegmentParams = struct(...
        'type', '@osBiophys', ...                       % choose between '@osBiophys' and '@osLinear'
        'addNoise', true ...
    );
    
    adaptingFieldParams = struct(...
        'type', 'SpecifiedReflectanceIlluminatedBySpecifiedIlluminant', ...
        'surfaceReflectance', struct(...
                                'type', 'MacBethPatchNo', ...
                                'patchNo', 16 ...
                            ), ...
        'illuminantName', 'D65', ...
        'meanLuminance', 300 ...
    );
    
    viewModeParams = struct(...
        'fixationsPerScan', 20, ...                                             % each scan file will contains this many fixations
        'consecutiveSceneFixationsBetweenAdaptingFieldPresentation', 22, ...     % use 1 to insert adapting field data after each scene fixation 
        'adaptingFieldParams', adaptingFieldParams, ...
        'forcedSceneMeanLuminance', 300 ...
    );
    
    % assemble all  param structs into one superstruct
    descriptionString = sprintf('AdaptEvery%dFixations/%s', viewModeParams.consecutiveSceneFixationsBetweenAdaptingFieldPresentation, outerSegmentParams.type);
    expParams = struct(...
        'descriptionString',    descriptionString, ...                        % a unique string identifying this experiment. This will be the scansSubDir name
        'sceneSetName',         'manchester', ...                             % the name of the scene set to be used
        'viewModeParams',       viewModeParams, ...
        'sensorParams',         sensorParams, ...
        'outerSegmentParams',   outerSegmentParams, ...
        'decoderParams',        decoderParams ...
    );
end