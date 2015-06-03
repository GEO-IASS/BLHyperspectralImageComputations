classdef HyperSpectralImageDataExtractor < handle
%HYPERSPECTRALIMAGEDATAEXTRACTOR Abstarct class to extract hyperspectral image data
% Use one of its subclasses, such as @ManchesterHyperSpectralImageDataExtractor.
% For more information: doc ManchesterHyperSpectralImageDataExtractor
%
%    4/28/2015   npc    Wrote it.
%
    
    properties(SetAccess = private) 
        % Luminance map of hyperspectral image
        sceneLuminanceMap;
        
        % XYZ sensor map of hyperspectral image
        sceneXYZmap;
        
        % sRGBimage of the scene with the reference object outlined in red
        sRGBimage;
        
        % struct with spectral data of the scene and the illuminant
        radianceData = struct(...
            'sceneName',    '', ...
            'wave',         [], ...
            'illuminant',   [], ... 
            'radianceMap',  [] ...                                                
        );
    end
    
    % Protected properties, so that our subclasses can set them
    properties (SetAccess = protected)
        % struct with various information regarding the reference object in the scene
        referenceObjectData = struct(...
            'spectroRadiometerReadings', struct(), ...
            'paintMaterial',             struct(), ...
            'geometry',                  struct(), ...
            'info',                      ''...
        );  
    
        % flag indicating whether the spectral data contained in the scene
        % files are inconsistent (e.g., different number of spectral bands
        % in illuminant and reflectance data)
        inconsistentSpectralData;
        
        % the full reflectance map
        reflectanceMap = [];
        
        % the illuminant SPD
        illuminant = struct('wave', [], 'spd', []);
    end
    
    properties(SetAccess = private, Dependent = true)
        % The computed isetbio scene object
        isetbioSceneObject;
        
        % Information about the scene shooting
        shootingInfo;
    end
    
    properties (Constant)
        wattsToLumens = 683;
    end
    
    % Protected, so that our subclasses can set/get them
    properties (Access = protected)
        % struct with filenames of different data files for the current scene
        % generated by the instantiated @HyperSpectralImageDataExtractor
        % subclass (e.g., ManchesteryperSpectralImageDataExtractor)
        sceneData = struct();
        
        % The XYZ CMFs
        sensorXYZ = [];
    end
    
    % Public API
    methods
        % Constructor
        function obj = HyperSpectralImageDataExtractor()
            loadXYZCMFs(obj);
        end
        
        % Method to display an sRGB version of the hyperspectral image with the reference object outlined in red
        showLabeledsRGBImage(obj, clipLuminance, gammaValue, outlineWidth);
        
        % Method to export the generated isetbio scene object
        exportFileName = exportIsetbioSceneObject(obj);
        
        % Getter for dependent property isetbioSceneObject
        function scene = get.isetbioSceneObject(obj)
			% Generate isetbio scene
            fprintf('<strong>Generating isetbio scene object.</strong>\n');
            scene = sceneFromHyperSpectralImageData(...
                'sceneName',            obj.radianceData.sceneName, ...
                'wave',                 obj.illuminant.wave, ...
                'illuminantEnergy',     obj.illuminant.spd, ... 
                'radianceEnergy',       obj.radianceData.radianceMap, ...
                'sceneDistance',        obj.referenceObjectData.geometry.distanceToCamera, ...
                'scenePixelsPerMeter',  obj.referenceObjectData.geometry.sizeInPixels/obj.referenceObjectData.geometry.sizeInMeters  ...
            );
        end
        
        % Method to return various info about the shooting of the scene
        function info = get.shootingInfo(obj)
            info = obj.referenceObjectData.info;
        end
        
        % Method to plot the scene illuminnat
        plotSceneIlluminant(obj);
    end
    
    % Methods that must be implemented by the subclasses
    methods (Abstract, Access=protected)
        % Subclasses must implement the populateSceneDataStruct according to 
        % the peculiarities of the associated database of hyperspectral images
        populateSceneDataStruct(obj,sceneName);
        
        % Subclasses must implement the loadReflectanceMap according to 
        % the peculiarities of the associated database of hyperspectral images
        loadReflectanceMap(obj);
        
        % Subclasses must implement the loadIlluminant according to 
        % the peculiarities of the associated database of hyperspectral images
        loadIlluminant(obj);
    end
    
    % Protected methods so that our subclasses can call them
    methods (Access = protected)
        % Method to generate an illuminant for scenes with no information about the illuminant
        generateIlluminant(obj, sceneCalibrationStruct);
        
        % Method to adjsut the scene reflectance based on a region of known reflectance
        adjustSceneReflectanceBasedOnRegionOfKnownReflectance(obj);
        
        % Method that computes the radianceMap from the imported reflectance and
        % the illuminant. This method also computes the luminance and xy chroma of
        % the reference object and contrasts this to the values measured and
        % catalogued in the database.
        inconsistentSpectralData = generateRadianceDataStruct(obj);
        
        % Method to compute the mean luminance of the reference object ROI
        roiLuminance = computeROIluminance(obj);
        
        % Method to compute the mean chromaticity of the  the reference object ROI
        chromaticity = computeROIchromaticity(obj);
    end
    
    methods (Access = private)
       % Method to load the CIE '31 XYZ CMFs
       loadXYZCMFs(obj); 
    end
end

