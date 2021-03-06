function unwrapMDSprojection(obj)
    
    swapMDSdimsYZ = true;
    if (swapMDSdimsYZ)
        % swap MDS dimension Y with MDS dimension Z
        MDSdimensionForXspatialDim = 3;
        MDSdimensionForYspatialDim = 2;
        tmp_MDSprojection = obj.MDSprojection;
        tmp_MDSprojection(:,2) = obj.MDSprojection(:,MDSdimensionForXspatialDim);
        tmp_MDSprojection(:,3) = obj.MDSprojection(:,MDSdimensionForYspatialDim);
        obj.MDSprojection = tmp_MDSprojection;
    end
        
    [rotatedMDSprojection, LconeIndices, MconeIndices, SconeIndices, LMconeIndices,...
     cLM, cS, pivot, cLMPrime, cSPrime, pivotPrime] = ...
         estimateConeMosaicFromMDSprojection(obj.MDSprojection);
   
    % For comparison to true spatial mosaic determine optimal scaling and
    % rotation (around the spectral (X) axis) of the MDS embedding
    coneIndices = LMconeIndices;
    %coneIndices = (1:size(trueConeXYLocations,1));
    [d,Z,transform] = procrustes(obj.core1Data.trueConeXYLocations(coneIndices,:), rotatedMDSprojection(coneIndices,2:3));

    % Form the rotation matrix around X-axis
    rotationMatrixAroundXaxis = ...
        [1 0                0; ...
         0 transform.T(1,1) transform.T(1,2); ...
         0 transform.T(2,1) transform.T(2,2) ...
         ];

    MDSspatialScalingFactor = transform.b;
        
    % apply rotation and scaling
    rotatedMDSprojection = rotatedMDSprojection * rotationMatrixAroundXaxis;
    rotatedMDSprojection = rotatedMDSprojection * MDSspatialScalingFactor;

    cSPrime = cSPrime * MDSspatialScalingFactor;
    cLMPrime = cLMPrime * MDSspatialScalingFactor;
    pivotPrime = pivotPrime * MDSspatialScalingFactor; 
       
    obj.unwrappedMDSprojection = rotatedMDSprojection;
    obj.unwrappedLconeIndices = LconeIndices;
    obj.unwrappedMconeIndices = MconeIndices;
    obj.unwrappedSconeIndices = SconeIndices;
    obj.unwrappedLMconeIndices = LMconeIndices;
    obj.unwrappedLMcenter = cLMPrime;
    obj.unwrappedScenter  = cSPrime;
    obj.unwrappedPrivot   = pivotPrime;
    
end


function [rotatedMDSprojection, LconeIndices, MconeIndices, SconeIndices, LMconeIndices, cLM, cS, pivot, cLMPrime, cSPrime, pivotPrime] = estimateConeMosaicFromMDSprojection(MDSprojection)

    % Step1: Identify S-cone positions
    [SconeIndices, LMconeIndices] = DetermineSconeIndices(MDSprojection); 
    
    % Identify line connecting centroids of S and LM
    cS    = mean(MDSprojection(SconeIndices,:),1);
    cLM   = mean(MDSprojection(LMconeIndices,:),1); 
    pivot = (cS + cLM)/2;
    
    % undo rotation of S-LM line along Y and Z axes
    diffVector = cS-cLM;
    rotationZaxis =  atan2(diffVector(2), diffVector(1)) / pi*180;
    rotationYaxis = -atan2(diffVector(3), diffVector(1)) / pi*180;
    
    % form rotation matrix around Y-axis
    cosTheta = cos(rotationYaxis/180*pi);
    sinTheta = sin(rotationYaxis/180*pi);
    rotationMatrixAroundYaxis = [...
        cosTheta  0  sinTheta; ...
        0         1  0; ...
        -sinTheta 0  cosTheta];
    
    % form rotation matrix around Z-axis
    cosTheta = cos(rotationZaxis/180*pi);
    sinTheta = sin(rotationZaxis/180*pi);
    rotationMatrixAroundZaxis = [...
        cosTheta -sinTheta  0; ...
        sinTheta  cosTheta  0; ...
        0         0         1];   
    
    rotationMatrixAroundYZ = rotationMatrixAroundYaxis * rotationMatrixAroundZaxis;
    rotatedMDSprojection(SconeIndices,:) = bsxfun(@minus, MDSprojection(SconeIndices,:), pivot);
    rotatedMDSprojection(SconeIndices,:) = rotatedMDSprojection(SconeIndices,:) * rotationMatrixAroundYZ;
    rotatedMDSprojection(SconeIndices,:) = bsxfun(@plus, rotatedMDSprojection(SconeIndices,:), pivot);
    
    rotatedMDSprojection(LMconeIndices,:) = bsxfun(@minus, MDSprojection(LMconeIndices,:), pivot);
    rotatedMDSprojection(LMconeIndices,:) = rotatedMDSprojection(LMconeIndices,:) * rotationMatrixAroundYZ;
    rotatedMDSprojection(LMconeIndices,:) = bsxfun(@plus, rotatedMDSprojection(LMconeIndices,:), pivot);
    
    cSPrime    = cS - pivot;
    cLMPrime   = cLM - pivot;
    cSPrime    = cSPrime  * rotationMatrixAroundYZ;
    cLMPrime   = cLMPrime * rotationMatrixAroundYZ;
    cSPrime    = cSPrime + pivot;
    cLMPrime   = cLMPrime + pivot;
    pivotPrime = pivot;
    
    % center on yz origin (spaceX x spaceY)
    for k = 2:3
        rotatedMDSprojection(:,k) = rotatedMDSprojection(:,k) - pivot(k);
        cSPrime(k) = cSPrime(k) - pivot(k);
        cLMPrime(k) = cLMPrime(k) - pivot(k);
        pivotPrime(k) = 0;
    end
    
    % Now separate the L from M cones
    [LconeIndices, MconeIndices] = DetermineLMconeIndices(rotatedMDSprojection, LMconeIndices, SconeIndices);
end


function [LconeIndices, MconeIndices] = DetermineLMconeIndices(rotatedMDSprojection, LMconeIndices, SconeIndices)
    
    xComponents = rotatedMDSprojection(LMconeIndices,1);
    
    rng(1); % For reproducibility
    %k-means with 2 clusters to find S cones
    [idx,~] = kmeans(xComponents,2);
    LconeIndices = LMconeIndices(find(idx==1));
    MconeIndices = LMconeIndices(find(idx==2));
    
    % Make sure that M cones closer to S than L cones to S
    xL = mean(squeeze(rotatedMDSprojection(LconeIndices,1)));
    xM = mean(squeeze(rotatedMDSprojection(MconeIndices,1)));
    xS = mean(squeeze(rotatedMDSprojection(SconeIndices,1)));
    
    if (abs(xL-xS) < abs(xM-xS))
        tmp = LconeIndices;
        LconeIndices = MconeIndices;
        MconeIndices = tmp;
    end
end

function [SconeIndices, LMconeIndices] = DetermineSconeIndices(MDSprojection)
        
    rng(1); % For reproducibility
    %k-means with 2 clusters to find S cones
    [idx,~] = kmeans(MDSprojection,2);
    coneAindices = find(idx==1);
    coneBindices = find(idx==2);

    if (numel(coneAindices) < numel(coneBindices))
        SconeIndices = coneAindices;
        LMconeIndices = coneBindices;
    else
        SconeIndices = coneBindices;
        LMconeIndices = coneAindices;
    end
end
