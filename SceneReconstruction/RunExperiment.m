function RunExperiment

    setPrefsForHyperspectralImageIsetbioComputations();
    
    decoderParams = struct(...
        'type', 'optimalLinearFilter', ...
        'thresholdConeSeparationForInclusionInDecoder', 0, ...      % 0 to include all cones
        'spatialSamplingInRetinalMicrons', 3.0, ...                 % decode scene ((retinal projection)) at 5 microns resolution
        'extraMicronsAroundSensorBorder', 15, ...                   % decode this many additional microns on each side of the sensor
        'temporalSamplingInMilliseconds', 10, ...                   % decode every this many milliseconds
        'latencyInMillseconds', -200, ...
        'memoryInMilliseconds', 600 ...
    );

    sensorTimeStepInMilliseconds = 0.1;  % must be small enough to avoid numerical instability in the outer segment current computation
    integrationTimeInMilliseconds = 50;
    
    % sensor params for scene viewing
    sensorParams = struct(...
        'coneApertureInMicrons', 3.0, ...        
        'LMSdensities', [0.6 0.3 0.1], ...        
        'spatialGrid', [20 20], ...  
        'samplingIntervalInMilliseconds', sensorTimeStepInMilliseconds, ...  
        'integrationTimeInMilliseconds', integrationTimeInMilliseconds, ...
        'randomSeed',  1552784, ...                                                % fixed value to ensure repeatable results
        'eyeMovementScanningParams', struct(...
            'samplingIntervalInMilliseconds', sensorTimeStepInMilliseconds, ...
            'meanFixationDurationInMilliseconds', 200, ...
            'stDevFixationDurationInMilliseconds', 20, ...
            'meanFixationDurationInMillisecondsForAdaptingField', 400, ...
            'stDevFixationDurationInMillisecondsForAdaptingField', 20, ...
            'fixationOverlapFactor', 1.0, ...     
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
        'meanLuminance', 200 ...
    );
    
    viewModeParams = struct(...
        'fixationsPerScan', 20, ...                                             % each scan file will contains this many fixations
        'consecutiveSceneFixationsBetweenAdaptingFieldPresentation', 5, ...     % use 1 to insert adapting field data after each scene fixation 
        'adaptingFieldParams', adaptingFieldParams, ...
        'forcedSceneMeanLuminance', 200 ...
    );
    
    expParams = struct(...
        'sceneSetName', 'manchester', ...
        'viewModeParams', viewModeParams, ...
        'sensorParams', sensorParams, ...
        'outerSegmentParams', outerSegmentParams, ...
        'decoderParams', decoderParams ...
    );
        
    % What to compute
    instructionSet = {'compute outer segment responses', 'assembleTrainingDataSet'};
   
    for instrIndex = 1:numel(instructionSet)  
       switch (instructionSet{instrIndex})
            case 'compute outer segment responses'
                core.computeOuterSegmentResponses(expParams);
               
            case 'assembleTrainingDataSet'
                core.assembleTrainingSet(expParams);
               
           otherwise
                error('Unknown instruction: ''%s''.\n', instructionSet{instrIndex});
        end   
    end % instrIndex
end

