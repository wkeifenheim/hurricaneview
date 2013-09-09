% Requires 'Basin' to be loaded into the workspace
function indeces = findHurricane(searchString, source)

    indeces = 0;
    NewInstance = true;
    results = strcmpi(searchString,source(:));
    for i=1:length(results)
        if results(i) == 1
            if(indeces == 0)
                indeces = i;
                NewInstance = false;
            elseif(NewInstance == true)
                indeces = [indeces; i];
                NewInstance = false;
            end
            if(results(i+1) == 0)
                NewInstance = true;
            end
        end
    end

    
end