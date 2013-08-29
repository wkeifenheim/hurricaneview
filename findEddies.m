% This function expects year/month/day to be strings
% If the input weekday is a Sun/Mon/Tue then the following wednesday is
% selected as the date to display eddy bodies.
% If the input weekday is a Wed, then that date is returned in the eddy
% filenames
% If the input weekday is a Thu/Fri/Sat, then the previous wednesday is
% selected for eddy bodies.
% Function returns the appropriate filenames (with paths) to the calling
% process
% NOTE: Only good for dates 1992.10.14 through 2011.01.19
% NOTE: DayNumer is a value 1-7 corresponding to a Sun-Sat week

function [anticycFile cyclonicFile] = findEddies(year, month, day)
    
    % Find the day of the week.  We're only interested in DayName
    dayWeekNumber = weekday(strcat(year,'-',month,'-',day));
    
    % Determine the last day of the month in case we need to roll over to
    % the next month to select the proper eddy body files
    yearNum = str2double(year);
    monthNum = str2double(month);
    lastDay = eomday(yearNum, monthNum);
    
    if(str2double(day) > lastDay)
        disp('Error: the value of `day` entered is invalid')
        return;
    end
    
    
    
    % Determine the nearest Wednesday
    % Some additional if-statements in here to make sure that month/day
    % values < 10 being with a 0
    if(dayWeekNumber ~= 4)
        dayMonthNum = str2double(day);
        if (dayWeekNumber <= 3) % day is a Sun/Mon/Tue
            while (dayWeekNumber ~= 4) 
                if(dayMonthNum == lastDay) % Change month case
                    if(monthNum == 12) % + change year case
                        yearNum = yearNum + 1;
                        monthNum = 1;
                        dayMonthNum = 1;
                        year = num2str(yearNum);
                        month = '01';
                    else % increment month, reset day
                        monthNum = monthNum + 1;
                        dayMonthNum = 1;
                        if(monthNum < 10)
                            month = strcat('0',num2str(monthNum));
                        else
                            month = num2str(monthNum);
                        end
                    end
                else % increment day
                    dayMonthNum = dayMonthNum + 1;
                end
                if(dayMonthNum < 10)
                    day = strcat('0',num2str(dayMonthNum));
                else
                    day = num2str(dayMonthNum);
                end
                dayWeekNumber = weekday(strcat(year,'-',month,'-',day));
            end
        else %day is a Thu/Fri/Sat
            while (dayWeekNumber ~= 4)
                if(dayMonthNum == 1) % Change month case
                    if(monthNum == 1) % Change year/month case, set day
                        yearNum = yearNum -1;
                        monthNum = 12;
                        dayMonthNum = eomday(yearNum, monthNum);
                        year = num2str(yearNum);
                    else % decrement month, set day
                        monthNum = monthNum - 1;
                        dayMonthNum = eomday(yearNum, monthNum);
                        if(monthNum < 10)
                            month = strcat('0',num2str(monthNum));
                        else
                            month = num2str(monthNum);
                        end
                    end
                else % decrement day
                    dayMonthNum = dayMonthNum - 1;
                end
                if(dayMonthNum < 10)
                    day = strcat('0',num2str(dayMonthNum));
                else
                    day = num2str(dayMonthNum);
                end
                dayWeekNumber = weekday(strcat(year,'-',month,'-',day));
            end
        end
    end
    
    anticycFile = strcat('/project/expeditions/eddies_project_data/results/ESv2-0823/',...
        'anticyc_', year, month, day, '.mat');
    cyclonicFile = strcat('/project/expeditions/eddies_project_data/results/ESv2-0823/',...
        'cyclonic_', year, month, day, '.mat');

end