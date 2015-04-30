function batchImportHyperSpectralImages
   
    % set to true if you want to see the generated isetbio data
    showIsetbioData = false;
    
    % Scenes with recorded information regarding geometry and illuminant.
    set1 = { ...
        struct('databaseName', 'manchester_database', 'sceneName','scene1', 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene2', 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene3', 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene4', 'clipLuminance',12000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene5', 'clipLuminance',12000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', showIsetbioData) ...  % this will bomb because of discrepancy b/n number of spectral bands in reflectance/illuminant
        struct('databaseName', 'manchester_database', 'sceneName','scene6', 'clipLuminance',14000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene7', 'clipLuminance',8000,  'gammaValue', 1.7, 'outlineWidth', 2, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene8', 'clipLuminance',8000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        };

    % Scenes with filled-in (by Nicolas) information regarding geometry and illuminant.
    set2 = { ...
        struct('databaseName', 'manchester_database', 'sceneName','scene9',  'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene10', 'clipLuminance', 4000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene11', 'clipLuminance', 5000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene12', 'clipLuminance', 5000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene13', 'clipLuminance', 5000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene14', 'clipLuminance', 9000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene15', 'clipLuminance', 12000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        struct('databaseName', 'manchester_database', 'sceneName','scene16', 'clipLuminance', 12000,  'gammaValue', 1.7, 'outlineWidth', 1, 'showIsetbioData', showIsetbioData) ...
        };
    
    % Full set
    set = {set1{:} set2{:}};
    
    % Start the batch import and process
    for k = 1:numel(set)
        s = set{k};
        fprintf('\n<strong>--------------------------------------------------------------------------------------------</strong>\n');
        fprintf('<strong>%2d. Importing data files for scene ''%s'' of database ''%s''.</strong>\n', k, s.sceneName, s.databaseName);
        fprintf('<strong>--------------------------------------------------------------------------------------------</strong>\n');
        importHyperSpectralImage(set{k});
    end
end







