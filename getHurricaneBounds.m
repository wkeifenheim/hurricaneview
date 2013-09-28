%Only display the portion of the world cooresponding to the bounds of a
%given hurricane
function [ hurricaneBounds ] = getHurricaneBounds(hurricaneIndeces,  hurDat)

    start = hurricaneIndeces(1);
    finish = hurricaneIndeces(2);
    hurricaneBounds(1,1) = min(hurDat(start:finish,6));
    hurricaneBounds(1,2) = max(hurDat(start:finish,6));
    hurricaneBounds(2,1) = min(hurDat(start:finish,7));
    hurricaneBounds(2,2) = max(hurDat(start:finish,7));

end

