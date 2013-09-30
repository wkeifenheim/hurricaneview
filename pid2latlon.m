function lat_lon_of_pixels = pid2latlon(pixelIdxList)

    load('/project/expeditions/eddies_project_data/ssh_data/data/pixels_2_lat_lon_map.mat')
    
    
    
    for i=1 : length(pixelIdxList)
        
        [x, y] = ind2sub([size(latLonMap,1) size(latLonMap,2)],pixelIdxList(i));
        lat_lon_of_pixels(i,:) = squeeze(latLonMap(x,y,:));
        
    end
    
    

end