ssh = load('/project/expeditions/eddies_project_data/ssh_data/data/global_ssh_1992_2011_with_nan.mat',...
'lat','lon');

ant = load('/project/expeditions/eddies_project_data/results/ESv2-0823/cyclonic_19951004.mat');
k = zeros(length(ant.eddies),1);
targetsFound = 0;
targetIndex = [];

for i=1:length(ant.eddies)
    if(ant.eddies(i).Lat >= 20 && ant.eddies(i).Lat <= 28)
        if(ant.eddies(i).Lon <= -78 && ant.eddies(i).Lon >= -82)
            targetIndex = [targetIndex, i];
            k(i) = abs(ant.eddies(i).Lon + 80.5);
            targetsFound = targetsFound + 1;
        end
    end
end