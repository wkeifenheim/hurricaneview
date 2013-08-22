handles = zeros(1,41198);   %personal note: using handles attaches
                            %negligable performance hit
                          
hurDatTrans = hurDat';      %speeds up plotting > 10 fold
                          
for i=1:2000
    %Determine appropriate hurricane category color
    windspeed = hurDatTrans(10,i);
    if(windspeed <= 95)
        linespec = 'g*'; %category 1
    elseif(windspeed <= 110)
        linespec = 'y*'; %category 2
    elseif(windspeed <= 129)
        linespec = 'c*'; %category 3
    elseif(windspeed <= 156)
        linespec = 'r*'; %category 4
    else
        linespec = 'k*'; %category 5
    end
    
    %store a handle to each plotted point for easy removal/modification
    handles(i) = plotm(hurDatTrans(6,i),hurDatTrans(7,i),linespec);
    
end