% Takes a hurricane coordinates at a certain timestep, and finds the eddies
% closest to those coordinates.
% lat/lon are the hurricane coordinates, and antiCyc/cyc are file handles
% to eddy bodies from the timeframe cooresponding to hurricane coordinates
% proxType:
%           0 - miss
%           1 - within 1-2 grid cells
%           2 - edge
%           3 - core (or nearly so) overlap
% eddyClass:
%           +1 - Anticyclonic
%           -1 - Cyclonic
% eddyStruct: a copy of the nearest eddy from the antiCyc or cyc file

function [proxType, eddyClass] = calcClosest(lat, lon,...
    antiCyc, cyc, canvas, GeoToSurfaceIndex)
    
    distanceToEddy = Inf('double');
    EddyIndex = [0 0]; % Type [-1,1] and index
    canvasIndex = findSurfaceCDataIndex(lat, lon, GeoToSurfaceIndex);
    color = canvas(canvasIndex);
    %color
    
    if(color ~= 1)
        %disp('Entering first if case...')
        for i=1 : size(antiCyc.eddies,2)
            latProximity = abs(lat - antiCyc.eddies(i).Lat);
            lonProximity = abs(lon - antiCyc.eddies(i).Lon);
            
            
            % Restrict the search area
            if(latProximity <= 1.5 && lonProximity <= 1.5)

                tempDistance = geoddistance(lat, lon, antiCyc.eddies(i).Lat,...
                    antiCyc.eddies(i).Lon);

                if(tempDistance < distanceToEddy)
                    EddyIndex = [1, i];
                    distanceToEddy = tempDistance;
                end

            else
                % do nothing
            end
            
%             % Leap of faith..
%             if(EddyIndex(1,1) == 0) %eddy center was too far away
%                 NeoGeo = flipud(GeoToSurfaceIndex);
%                 
%                 
%                 for i=1 : size(antiCyc.eddies,2)
%                     latProximity = abs(lat - antiCyc.eddies(i).Lat);
%                     lonProximity = abs(lon - antiCyc.eddies(i).Lon);
%                     
%                     if(latProximity <= 3.0 && lonProximity <= 3.0)
%                         
%                         % Increase the bounds to search, then attempt to
%                         % find the cooresponding pixel of the eddy in a
%                         % antiCyc.eddies(i).Stats.PixelIdxList
%                         results
%                         
                

        end    

    elseif(color ~= 2)
        for i=1 : size(cyc.eddies,2)
            latProximity = abs(lat - cyc.eddies(i).Lat);
            lonProximity = abs(lon - cyc.eddies(i).Lon);

            if(latProximity <= 2.5 && lonProximity <= 2.5)

                tempDistance = geoddistance(lat, lon, cyc.eddies(i).Lat,...
                    cyc.eddies(i).Lon);

                if(tempDistance < distanceToEddy)
                    EddyIndex = [-1, i];
                    distanceToEddy = tempDistance;
                end

            else
                % do nothing
            end

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
        %eddyStruct = NaN;
        
    end
    
    
              
end