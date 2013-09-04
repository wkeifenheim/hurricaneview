function [RGB] = chooseRGB(category)
% Based on the category input (-8:5), return values of RGB that correspond to the
% category
    switch category
        case 5
            RGB = [0 0 0]; %category 5 (black)
        case 4
            RGB = [1 0 0]; %category 4 (red)
        case 3
            RGB = [0 1 0]; %category 3 (green)
        case 2
            RGB = [0 0 1]; %category 2 (blue)
        case 1
            RGB = [1 1 0]; %category 1 (yellow)
        case 0
            RGB = [0 1 1]; %tropical storm (cyan)
        case -1
            RGB = [1 0 1]; %tropical depression (pink)
        case -2
            RGB = [0.75 0.75 0.75]; %tropical disturbance (gray)
        case -3
            RGB = [0 1 1]; %subtropical storm (cyan)
        case -4
            RGB = [1 0 1]; %subtropical depression (pink)
        case -5
            RGB = [0 1 1]; %extratropical storm (cyan)
        case -6
            RGB = [1 0 1]; %extratropical depression (pink)
        case -7
            RGB = [0.39 0.39 0.78]; %low (purple)
        case -8
            RGB = [0.9 0.31 0]; %no type specified (orange)
    end
    
    % Delete Me!!!!
    %RGB = [1 1 1];
end