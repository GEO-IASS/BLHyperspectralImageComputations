function C = computeContourData(spatialFilter, contourLevels, spatialSupportX, spatialSupportY, lConeIndices, mConeIndices, sConeIndices)
        
    dX = spatialSupportX(2)-spatialSupportX(1);
    dY = spatialSupportY(2)-spatialSupportY(1);
    contourXaxis = spatialSupportX(1)-dX:1:spatialSupportX(end)+dX;
    contourYaxis = spatialSupportY(1)-dY:1:spatialSupportY(end)+dY;
    [xx, yy] = meshgrid(contourXaxis,contourYaxis); 

    lConeWeights = []; mConeWeights = []; sConeWeights = [];
    lConeCoords = []; mConeCoords = []; sConeCoords = [];

    for iRow = 1:size(spatialFilter,1)
        for iCol = 1:size(spatialFilter,2) 
            coneLocation = [spatialSupportX(iCol) spatialSupportY(iRow)];
            xyWeight = [coneLocation(1) coneLocation(2) spatialFilter(iRow, iCol)];
            coneIndex = sub2ind(size(spatialFilter), iRow, iCol);
            if ismember(coneIndex, lConeIndices)
                lConeCoords(size(lConeCoords,1)+1,:) = coneLocation';
                lConeWeights(size(lConeWeights,1)+1,:) = xyWeight;
            elseif ismember(coneIndex, mConeIndices)
                mConeCoords(size(mConeCoords,1)+1,:) = coneLocation';
                mConeWeights(size(mConeWeights,1)+1,:) = xyWeight;
            elseif ismember(coneIndex, sConeIndices)
                sConeCoords(size(sConeCoords,1)+1,:) = coneLocation';
                sConeWeights(size(sConeWeights,1)+1,:) = xyWeight;
            end   
        end
    end
    lmConeWeights = [lConeWeights; mConeWeights];

    if (~isempty(lConeWeights))
        C.LconeMosaicSpatialWeightingKernel = griddata(lConeWeights(:,1), lConeWeights(:,2), lConeWeights(:,3), xx, yy, 'cubic');  
        C.LconeMosaicSamplingContours = getContourStruct(contourc(contourXaxis, contourYaxis, C.LconeMosaicSpatialWeightingKernel , contourLevels));
    end
    if (~isempty(mConeWeights))
        C.MconeMosaicSpatialWeightingKernel  = griddata(mConeWeights(:,1), mConeWeights(:,2), mConeWeights(:,3), xx, yy, 'cubic');
        C.MconeMosaicSamplingContours = getContourStruct(contourc(contourXaxis, contourYaxis, C.MconeMosaicSpatialWeightingKernel, contourLevels));
    end
    if (~isempty(sConeWeights))
        C.SconeMosaicSpatialWeightingKernel = griddata(sConeWeights(:,1), sConeWeights(:,2), sConeWeights(:,3), xx, yy, 'cubic');
        C.SconeMosaicSamplingContours = getContourStruct(contourc(contourXaxis, contourYaxis, C.SconeMosaicSpatialWeightingKernel, contourLevels));
    end
    if (~isempty(lmConeWeights))
        C.LMconeMosaicSpatialWeightingKernel = griddata(lmConeWeights(:,1), lmConeWeights(:,2), lmConeWeights(:,3), xx, yy, 'cubic');
        C.LMconeMosaicSamplingContours = getContourStruct(contourc(contourXaxis, contourYaxis, C.LMconeMosaicSpatialWeightingKernel, contourLevels));
    end
end
       

function Cout = getContourStruct(C)
    K = 0; n0 = 1;
    while n0<=size(C,2)
       K = K + 1;
       n0 = n0 + C(2,n0) + 1;
    end

    % initialize output struct
    el = cell(K,1);
    Cout = struct('level',el,'length',el,'x',el,'y',el);

    % fill the output struct
    n0 = 1;
    for k = 1:K
       Cout(k).level = C(1,n0);
       idx = (n0+1):(n0+C(2,n0));
       Cout(k).length = C(2,n0);
       Cout(k).x = C(1,idx);
       Cout(k).y = C(2,idx);
       n0 = idx(end) + 1; % next starting index
    end
end

    
    