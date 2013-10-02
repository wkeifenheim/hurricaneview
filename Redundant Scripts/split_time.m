%EBTracks month/day/hour was kept as one six digit integer. The
%following function splits that combined info into seperate columns
function timeColumns = split_time(time)
    timeColumns = [10860,3];
    for i=1:10860
        timeColumns(i,1) = floor(time(i)/10000); %month
        timeColumns(i,2) = floor(mod(time(i),10000)/100); %day
        timeColumns(i,3) = mod(time(i),100); %hour
    end

end