function sceneSet = sceneSetWithName(sceneSetName)

    switch (sceneSetName)
        case 'manchester'
            sceneSet = {...
                {'manchester_database', 'scene1'} ...
                {'manchester_database', 'scene2'} ...
                {'manchester_database', 'scene3'} ...
                {'manchester_database', 'scene6'} ...
                {'manchester_database', 'scene7'} ...
                {'manchester_database', 'scene8'} ... 
                %{'manchester_database', 'scene4'} ...
            };
        otherwise
            error('Unknown scene set name: ''%s''.\n', sceneSetName);
    end
    
end
