%set i=1 before running

year = delta_ebtrkatlc(i,3);
month = delta_ebtrkatlc(i,4);
day = delta_ebtrkatlc(i,5);

%load initial eddy files
[anticyc_file, cyc_file] = findEddies(year, month, day);

% Account for how many days left in the week
 offset = delta_ebtrkatlc(i)/6 + ((weekday(strcat(year,...
     '-', month, '-', day)) - 1) * 4);
 nextEddyWeek = 28 - offset;

while(i <= 10860)
    lat = delta_ebtrkatlc(i,7);
    lon = delta_ebtrkatlc(i,8);
    % Keep track of when to load next weeks eddy bodies
    if(nextEddyWeek == 0)
        year = delta_ebtrkatlc(i,3);
        month = delta_ebtrkatlc(i,4);
        day = delta_ebtrkatlc(i,5);
        [anticyc_file, cyc_file] = findEddies(year, month, day);
         offset = delta_ebtrkatlc(i)/6 + ((weekday(strcat(year,...
            '-', month, '-', day)) - 1) * 4);
        nextEddyWeek = 28 - offset;
        [results(i,1), results(i,2), results(i,3)] = calcClosest(lat,...
            lon, anticyc_file, cyc_file);
        i = i + 1;
    else

        [results(i,1), results(i,2), results(i,3)] = calcClosest(lat,...
            lon, anticyc_file, cyc_file);
        i = i + 1;
        nextEddyWeek = nextEddyWeek - 1;
    end

end

