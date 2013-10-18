% Takes hurricane coordinates at a certain timestep, and finds the eddies
% closest to those coordinates.
% lat/lon are the hurricane coordinates, and antiCyc/cyc are file handles
% to eddy bodies from the timeframe cooresponding to hurricane coordinates
%
% proxType:
%           0 - miss
%           1 - within 1-2 grid cells
%           2 - edge
%           3 - core (or nearly so) overlap
% eddyClass:
%           +1 - Anticyclonic
%           -1 - Cyclonic
%

function [proxType, eddyClass, eddyLat, eddyLon, eddyAmp, eddyU] = calcClosest(lat, lon,...
    antiCyc, cyc)
    
    p2ll = load('/project/expeditions/eddies_project_data/ssh_data/data/pixels_2_lat_lon_map.mat');
    distanceToEddy = Inf('double');
    EddyIndex = [0 0]; % Type [-1,1] and index
    
    for i=1 : size(antiCyc.eddies,2)
        latProximity = abs(lat - antiCyc.eddies(i).Lat);
        lonProximity = abs(lon - antiCyc.eddies(i).Lon);


        % Restrict the search area
        if(latProximity <= 3.0 && lonProximity <= 3.0)
            
            pixelLatLons = pid2latlon(antiCyc.eddies(i).Stats.PixelIdxList, p2ll.latLonMap);
            pixelLatLons(:,2) = pixelLatLons(:,2) - 360;
            
            distances = zeros(size(pixelLatLons,1),1);
            
%             for j = 1 : size(distances,1)
%                 distances(j) = geoddistance(lat, lon, pixelLatLons(j,1),...
%                     pixelLatLons(j,2));
%             end

            for j = 1 : size(distances,1)
                distances(j) = deg2km(distance(lat,lon,pixelLatLons(j,1),...
                    pixelLatLons(j,2)));
            end
            
            [d,di] = min(distances);
            
            if(d <= 10) %10 km
                if(d < distanceToEddy)
                    distanceToEddy = d;
                    EddyIndex = [1, i];
                    eddyLat = antiCyc.eddies(i).Lat;
                    eddyLon = antiCyc.eddies(i).Lon;
                    eddyAmp = antiCyc.eddies(i).Amplitude;
                    eddyU = antiCyc.eddies(i).MeanGeoSpeed;
                end
            end         
        else
            % do nothing
        end
    end
        
    for i=1 : size(cyc.eddies,2)
        latProximity = abs(lat - cyc.eddies(i).Lat);
        lonProximity = abs(lon - cyc.eddies(i).Lon);


        % Restrict the search area
        if(latProximity <= 3.0 && lonProximity <= 3.0)
            
            pixelLatLons = pid2latlon(cyc.eddies(i).Stats.PixelIdxList, p2ll.latLonMap);
            pixelLatLons(:,2) = pixelLatLons(:,2) - 360;
            
            distances = zeros(size(pixelLatLons,1),1);
            
%             for j = 1 : size(distances,1)
%                 distances(j) = geoddistance(lat, lon, pixelLatLons(j,1),...
%                     pixelLatLons(j,2));
%             end

            for j = 1 : size(distances,1)
                distances(j) = deg2km(distance(lat,lon,pixelLatLons(j,1),...
                    pixelLatLons(j,2)));
            end
            
            [d,di] = min(distances);
            
            if(d <= 10) %10 km
                if(d < distanceToEddy)
                    distanceToEddy = d;
                    EddyIndex = [-1, i];
                    eddyLat = cyc.eddies(i).Lat;
                    eddyLon = cyc.eddies(i).Lon;
                    eddyAmp = cyc.eddies(i).Amplitude;
                    eddyU = cyc.eddies(i).MeanGeoSpeed;
                end
            end         
        else
            % do nothing
        end
    end
        


    
    % Found something
    if(EddyIndex(1,1) == 1)
        
        proxType = NaN; % for now %TODO: calculate eddy boundaries
        eddyClass = 1;
        %eddyStruct = antiCyc.eddies(EddyIndex(2));
        
    elseif (EddyIndex(1,1) == -1)
            
        proxType = NaN;
        eddyClass = -1;
        %eddyStruct = cyc.eddies(EddyIndex(2));
    
    % Found nothing    
    else
        
        proxType = NaN;
        eddyClass = NaN;
        eddyLat = NaN;
        eddyLon = NaN;
        eddyAmp = NaN;
        eddyU = NaN;
        %eddyStruct = NaN;
        
    end
    
    
              
end