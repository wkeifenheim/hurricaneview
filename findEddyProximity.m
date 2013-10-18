%set i=1 before running
results = zeros(10860,6);
i = 1564; %Hurricane Francis - 1992/10/22

year = double(delta_ebtrkatlc(i,3));
month = double(delta_ebtrkatlc(i,4));
day = double(delta_ebtrkatlc(i,5));
hurID = cellstr(delta_ebtrkatlc(i,2));

year_str = num2str(year);
month_str = num2str(month);
day_str = num2str(day);

% load initial eddy files
[anticyc_file, cyc_file] = findEddies(year_str, month_str, day_str);
antiCyc = load(anticyc_file);
cyc = load(cyc_file);

% Start a results array for returning structures
%results_structs(10860).Lat = 30;

% create a canvas featuring both types of eddies.
% Currently used to ensure that the right type of eddy is returned by
% calcClosest.  Next iteration: use to search immediate surroundings for
% eddies, then find corresponding pixelIdx from the eddy files to identify
% the correct eddy
% canvas = zeros(721,1440,'uint8');
% for j=1 :  length(cyc.eddies)
%     canvas(cyc.eddies(j).Stats.PixelIdxList) = 1;
% end
% for j=1 : length(antiCyc.eddies)
%     canvas(antiCyc.eddies(j).Stats.PixelIdxList) = 2;
% end
% canvas = flipud(canvas);

% Account for how many time steps left in the week
 offset = double(delta_ebtrkatlc(i,6))/6 + ((weekday(strcat(year_str,...
     '-', month_str, '-', day_str)) - 1) * 4);
 % Number of time steps until eddy boddies need to be reloaded
 nextEddyWeek = 28 - offset;

 
 % Capped to stop after 2010 dates are run
while(i <= 9691)
    lat = double(delta_ebtrkatlc(i,7));
    lon = double(delta_ebtrkatlc(i,8));
    
    % Keep track of when to load next weeks eddy bodies
    % Or reload eddy files when next hurricane starts (hurricanes don't
    % necessarily end/start on consecutive days)
    if(nextEddyWeek == 0 || ~strcmpi(hurID, cellstr(delta_ebtrkatlc(i,2))))
        
        year = double(delta_ebtrkatlc(i,3));
        month = double(delta_ebtrkatlc(i,4));
        day = double(delta_ebtrkatlc(i,5));
        hurID = cellstr(delta_ebtrkatlc(i,2));
        
        year_str = num2str(year);
        month_str = num2str(month);
        day_str = num2str(day);
        
%         delete canvas;
%         delete anticyc_file;
%         delete cyc_file;
%         delete antiCyc;
%         delete cyc;
%         
        [anticyc_file, cyc_file] = findEddies(year_str, month_str, day_str);
        antiCyc = load(anticyc_file);
        cyc = load(cyc_file);
        
%         canvas = zeros(721,1440,'uint8');
%         for j=1 :  length(cyc.eddies)
%             canvas(cyc.eddies(j).Stats.PixelIdxList) = 1;
%         end
%         for j=1 : length(antiCyc.eddies)
%             canvas(antiCyc.eddies(j).Stats.PixelIdxList) = 2;
%         end
%         canvas = flipud(canvas);
        
        % Calculating offset is often redundant, but necessary to account
        % for begining a new hurricane
         offset = double(delta_ebtrkatlc(i,6))/6 + ((weekday(strcat(year_str,...
            '-', month_str, '-', day_str)) - 1) * 4);
        
        nextEddyWeek = 28 - offset;
        
        [results(i,1), results(i,2), results(i,3), results(i,4),...
            results(i,5), results(i,6)] = calcClosest(lat,lon, antiCyc, cyc);
        
        i = i + 1;
        
    else

        [results(i,1), results(i,2), results(i,3), results(i,4),...
            results(i,5), results(i,6)] = calcClosest(lat,lon, antiCyc, cyc);
        
        nextEddyWeek = nextEddyWeek - 1;
        i = i + 1;
        
        
    end

end

