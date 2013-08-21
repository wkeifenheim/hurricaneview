% The following is used only for extablishing the latatude/longitude
% bounds needed for the map overlay
latlim = [min(hurDat(:,6)) max(hurDat(:,6))];
lonlim = [min(hurDat(:,7)) max(hurDat(:,7))];

%Create a map bound by the coordinates of hurDat
%worldmap(latlim,lonlim)
%land = shaperead('landareas.shp','UseGeoCoords',true);
%geoshow(land)

%Create a world map with coastlines drawn
%set up a map axes and frame:
%
%load coast
%axesm mollweid
%framem('FEdgeColor','blue','FLineWidth',0.5)
%
%Pot the coast vector
%
%plotm(lat,long,'LineWidth',1,'Color','blue')
