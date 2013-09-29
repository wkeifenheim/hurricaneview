%set i=1 before running
results = zeros(10860,3);
i = 7073; %Katrina

year = cellstr(delta_ebtrkatlc(i,3));
month = cellstr(delta_ebtrkatlc(i,4));
day = cellstr(delta_ebtrkatlc(i,5));
hurID = cellstr(delta_ebtraklc(i,2));

% load initial eddy files
[anticyc_file, cyc_file] = findEddies(year, month, day);
antiCyc = load(anticyc_file);
cyc = load(cyc_file);

% create a canvas featuring both types of eddies.
% Currently used to ensure that the right type of eddy is returned by
% calcClosest.  Next iteration: use to search immediate surroundings for
% eddies, then find corresponding pixelIdx from the eddy files to identify
% the correct eddy
canvas = zeros(721,1440,'uint8');
for j=1 :  size(cyc.eddies)
    canvas(cyc.eddies(j).Stats.PixelIdxList) = 1;
end
for j=1 : size(antiCyc.eddies)
    canvas(antiCyc.eddies(j).Stats.PixelIdxList) = 2;
end
canvas = flipud(canvas);

% Account for how many time steps left in the week
 offset = delta_ebtrkatlc(i,6)/6 + ((weekday(strcat(year,...
     '-', month, '-', day)) - 1) * 4);
 % Number of time steps until eddy boddies need to be reloaded
 nextEddyWeek = 28 - offset;

while(i <= 10860)
    lat = double(delta_ebtrkatlc(i,7));
    lon = double(delta_ebtrkatlc(i,8));
    % Keep track of when to load next weeks eddy bodies
    % Or reload eddy files when next hurricane starts (hurricanes don't
    % necessarily end/start on consecutive days)
    if(nextEddyWeek == 0 || ~strcmpi(hurID, cellstr(delta_ebtraktlc(i,2))))
        
        year = cellstr(delta_ebtrkatlc(i,3));
        month = cellstr(delta_ebtrkatlc(i,4));
        day = cellstr(delta_ebtrkatlc(i,5));
        hurID = cellstr(delta_ebtraklc(i,2));
        
        [anticyc_file, cyc_file] = findEddies(year, month, day);
        antiCyc = load(anticyc_file);
        cyc = load(cyc_file);
        
        canvas = zeros(721,1440,'uint8');
        for j=1 :  size(cyc.eddies)
            canvas(cyc.eddies(j).Stats.PixelIdxList) = 1;
        end
        for j=1 : size(antiCyc.eddies)
            canvas(antiCyc.eddies(j).Stats.PixelIdxList) = 2;
        end
        canvas = flipud(canvas);
        
        % Calculating offset is often redundant, but necessary to account
        % for begining a new hurricane
         offset = delta_ebtrkatlc(i)/6 + ((weekday(strcat(year,...
            '-', month, '-', day)) - 1) * 4);
        
        nextEddyWeek = 28 - offset;
        
        [results(i,1), results(i,2), results(i,3)] = calcClosest(lat,...
            lon, antiCyc, cyc, canvas);
        
        i = i + 1;
        
    else

        [results(i,1), results(i,2), results(i,3)] = calcClosest(lat,...
            lon, antiCyc, cyc, canvas);
        
        nextEddyWeek = nextEddyWeek - 1;
        i = i + 1;
        
        
    end

end

