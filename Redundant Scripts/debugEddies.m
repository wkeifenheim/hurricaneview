function debugEddies()
    ant = load('/project/expeditions/eddies_project_data/results/ESv2-0823/anticyc_19951004.mat');
    cyc = load('/project/expeditions/eddies_project_data/results/ESv2-0823/cyclonic_19951004.mat');
    ssh = load('/project/expeditions/eddies_project_data/ssh_data/data/global_ssh_1992_2011_with_nan.mat',...
        'lat','lon');
    %axesm('pcarre');
    worldmap('world')
    canvas = zeros(721,1440,'uint8');
    for i = 1:length(cyc.eddies)
        canvas(cyc.eddies(i).Stats.PixelIdxList) = 1;
    end
    for i = 1:length(ant.eddies)
        canvas(ant.eddies(i).Stats.PixelIdxList) = 2;
    end
    
    pcolorm(ssh.lat,ssh.lon,canvas);
    
    land = shaperead('landareas', 'UseGeoCoords', true);
    geoshow(gca, land, 'FaceColor', [1 1 1]);
end