function [ hurricaneBounds ] = getHurricaneBounds(hurricaneIndeces,  hurDat)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    start = hurricaneIndeces(1);
    finish = hurricaneIndeces(2);
    hurricaneBounds(1,1) = min(hurDat(start:finish,6));
    hurricaneBounds(1,2) = max(hurDat(start:finish,6));
    hurricaneBounds(2,1) = min(hurDat(start:finish,7));
    hurricaneBounds(2,2) = max(hurDat(start:finish,7));

end

