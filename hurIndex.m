%Create a 1442x2 matrix containing the indeces of a specific hurricane
%in the hurDat matrix

HurricaneIndex = zeros([1442,2]);

HurricaneIndex(1,1) = 1;
for i=1:41197
    j = hurDat(i,1);
    if(hurDat(i+1,1) ~= j)
        HurricaneIndex(j,2) = i;
        HurricaneIndex(j+1,1) = i+1;
    end
end
HurricaneIndex(1442,2) = 41198;