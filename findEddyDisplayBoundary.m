function [latIndexStart latIndexEnd lonIndexStart lonIndexEnd  ] = findEddyDisplayBoundary(...
    latMin, latMax, lonMin, lonMax, eddyData)
% Takes input lat/lon arguments of the area in which a hurricane's path
% existed and translates them into indices that will draw eddy bodies only
% in the area of the hurricane's path

    latS_found = false;
    latE_found = false;
    lonS_found = false;
    lonE_found = false;
    % Latitude
    for i=1:721
        if(eddyData.lat(i) > latMin && ~latS_found)
            latIndexStart = i - 20; % -20 to draw eddies slightly outside area of hurricane
            latS_found = true;
        end
        if(eddyData.lat(i) > latMax && ~latE_found)
            latIndexEnd = i + 20;
            latE_found = true;
            break;
        end
    end
    
    % Longitude
    for i=1440:-1:1
        if(eddyData.lon(i) < lonMin && ~lonS_found)
            lonIndexStart = i + 20;
            lonS_found = true;
            break
        end
        if(eddyData.lon(i) < lonMax && ~lonE_found)
            lonIndexEnd = i - 20;
            lonE_found = true;
        end
    end
    
    
    
end

