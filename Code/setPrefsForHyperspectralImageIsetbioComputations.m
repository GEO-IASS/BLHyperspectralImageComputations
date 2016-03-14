function setPrefsForHyperspectralImageIsetbioComputations

    sysInfo = GetComputerInfo();
    
    % Select dropbox location based on computer name
    switch (sysInfo.localHostName)
        case 'IoneanPelagos'
            dropBoxLocation = '/Volumes/IoneanPelagosTM/Dropbox/Dropbox (Aguirre-Brainard Lab)';
        case 'Manta'
            % dropbox location for Manta (Nicolas' iMac)
            dropBoxLocation = '/Volumes/Manta TM HD/Dropbox (Aguirre-Brainard Lab)';
    end
    
    originalDataBaseDir     = sprintf('%s/IBIO_data/BLHyperspectralImageComputations/HyperSpectralImages', dropBoxLocation);
    isetbioSceneDataBaseDir = sprintf('%s/IBIO_analysis/BLHyperspectralImageComputations/isetbioScenes', dropBoxLocation);
    opticalImagesCacheDir   = sprintf('%s/IBIO_analysis/BLHyperspectralImageComputations/isetbioOpticalImages', dropBoxLocation);

    
    % Specify project-specific preferences
    p = struct( ...
        'projectName',             'HyperSpectralImageIsetbioComputations', ...
        'isetbioSceneDataBaseDir',  isetbioSceneDataBaseDir, ... % where to put the scene files (before they are uploaded to archiva)
        'originalDataBaseDir',      originalDataBaseDir,...   % where the original data live
        'remoteDataToolboxConfig', '/Users/nicolas/Documents/1.code/2.matlabDevs/ProjectPrefs/rdt-config-isetbio-nicolas.json', ...
        'opticalImagesCacheDir',    opticalImagesCacheDir ...
        );
    
    generatePreferenceGroup(p);
end

function generatePreferenceGroup(p)
    % remove any existing preferences for this project
    if ispref(p.projectName)
        rmpref(p.projectName);
    end
    
    % generate and save the project-specific preferences
    preferences = setdiff(fieldnames(p), 'projectName');
    for k = 1:numel(preferences)
        setpref(p.projectName, preferences{k}, p.(preferences{k}));
    end
    fprintf('Generated and saved preferences specific to the ''%s'' project.\n', p.projectName);
end
