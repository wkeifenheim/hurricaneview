result = [10860,2];
result(1,1) = -9999;
result(1,2) = -9999;

%find first delta
for i=2:10860
    if(double(delta_ebtrkatlc(i,13)) ~= -99 && double(delta_ebtrkatlc(i-1,13)) ~= -99)
        result(i,1) = double(delta_ebtrkatlc(i,13)) - double(delta_ebtrkatlc(i-1,13));
    else
        result(i,1) = -9999;
    end
        

end

%find second delta
for i=2:10860
    if(result(i,1) ~= -9999 && result(i-1,1) ~= -9999)
        result(i,2) = result(i,1) + result(i-1,1);
    else
        result(i,2) = -9999;
    end
        

end