% Requires GeoToSurfaceIndex
% Takes as input geo-coordinates [lat, lon] and returns the cooresponding
% index to the pixel in the surface CData

function CDataIndex = findSurfaceCDataIndex(lat, lon)

    if(lat ~= 0)
        latXfourIndex = ((lat + 90) * 4) + 1;
    elseif(lat == 0)
        latXfourIndex = 361;
    else
        disp('error, illegal value for lat')
    end
        
    if(lon > 0)
        lonXfourIndex = (lon * 4) + 1;
    elseif(lon < 0)
        lonXfourIndex = ((lon + 180) * 4) + 721;
    elseif(lon == 0)
        lonXfourIndex = 1;
    else
        disp('error, illegal value for lon')
    end
    
    CDataIndex = GeoToSurfaceIndex(latXfourIndex, lonXfourIndex);
end



