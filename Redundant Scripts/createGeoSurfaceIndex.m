GeoToSurfaceIndex = zeros(721,1440);

index = 1;

for i=1:1440
    for j=1:721
        GeoToSurfaceIndex(j,i) = index;
        index = index + 1;
    end
end

GeoToSurfaceIndex = flipud(GeoToSurfaceIndex);

