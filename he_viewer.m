function varargout = he_viewer(varargin)
% HE_VIEWER MATLAB code for he_viewer.fig
%      HE_VIEWER, by itself, creates a new HE_VIEWER or raises the existing
%      singleton*.
%
%      H = HE_VIEWER returns the handle to a new HE_VIEWER or the handle to
%      the existing singleton*.
%
%      HE_VIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HE_VIEWER.M with the given input arguments.
%
%      HE_VIEWER('Property','Value',...) creates a new HE_VIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before he_viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to he_viewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help he_viewer

% Last Modified by GUIDE v2.5 04-Feb-2014 12:46:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @he_viewer_OpeningFcn, ...
                   'gui_OutputFcn',  @he_viewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end


% --- Executes just before he_viewer is made visible.
function he_viewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to he_viewer (see VARARGIN)

% Choose default command line output for he_viewer
handles.output = hObject;

    s = load('/panfs/roc/groups/6/kumarv/keifenhe/Documents/Datasets/IBTrACS_1992_2010_bu_all.mat');
    handles.ibtracs = s.IBTrACS_1992_2010;
    
    s = load('/panfs/roc/groups/6/kumarv/keifenhe/Documents/Datasets/IBTrACS_indices_v1.mat');
    handles.ibtracs_idx = s.IBTrACS_indices;

    please_wait = msgbox('Loading eddy track files, this will take up to 30 seconds..');
    s = load(strcat('/project/expeditions/eddies_project_data/results/',...
        'tracks_new_landmask_10_30_2013/lnn/bu_anticyc_new_landmask.mat'));
    handles.bu_anti_tracks = s.bu_anticyc_tracks;
    s = load(strcat('/project/expeditions/eddies_project_data/results/',...
        'tracks_new_landmask_10_30_2013/lnn/bu_cyclonic_new_landmask.mat'));
    handles.bu_cyc_tracks = s.bu_cyclonic_tracks;
    delete(please_wait)

    s = load(strcat('/panfs/roc/groups/6/kumarv/keifenhe/Documents/',...
            'Datasets/eddy_track_date_indices.mat'));
    handles.track_index = s.eddy_track_date_indices;
            
    % Maintain a history of which hurricanes have been plotted so we can
    % easily clear the most recent
    handles.HurIndexHist = 0;

    % Handle for keeping track of plotting hurricanes stepwise
     handles.stepPlace = 0;
     handles.plotStack = [];

    % Attempting to step repeatedly on the last hurricane
    % coordinate doesn't overwrite the cooresponding original handle
    handles.plotStop = 0;

    % used to handle drawing eddy bodies only around the hurricane path
    % Rows: Latitute Longitude
    % Columns: Min Max
    handles.coordLimits = cell(1,2);
    
    %Set by hurID_callback and used by plotEddies_callback
    %Case 1: not 2 or 3
    %Case 2: crosses 180 degrees longitude
    %Case 3: crosses 0 degrees longitude
    handles.case = NaN;

    % Establish colorScale for hurricane intensity
    handles.colorScale = jet(181); %for min/max of 10/160 kt

    % Load up the map
    axes(handles.axes1);
    plot(1,1, 'o','MarkerSize',10,'MarkerEdgeColor',...
        [1 0 0], 'MarkerFaceColor',[1 0 0]);
    hold on;
    plot(1,1, 'o','MarkerSize',10,'MarkerEdgeColor',...
        [1 .45 0], 'MarkerFaceColor',[1 .45 0]);
    plot(1,1, 'o','MarkerSize',10,'MarkerEdgeColor',...
        [0 1 .3], 'MarkerFaceColor',[0 1 .3]);
    plot(1,1, 'o','MarkerSize',10,'MarkerEdgeColor',...
        [0.08 .5 .87], 'MarkerFaceColor',[0.08 .5 .87]);
    hleg = legend('Anticyclonic','Anticyclonic 1-week','Cyclonic','Cyclonic 1-week',...
        'Location','Southeast');
    htitle = get(hleg,'Title');
    set(htitle,'String','Eddy Legend');
    cla
    handles.figure = axesm('pcarre', 'Origin', [0 180 0]);%, 'MapLatLimit', [0 70], 'MapLonLimit', [-120 0]);
    load coast
    plotm(lat,long)
    whitebg('k')
%     grid_h = gridm('on');
%     set(grid_h, 'Clipping','on');
%     set(handles.axes1,'Clipping','on');
    
    axes(handles.axes2);
    title('windspeed')
    ylabel('knots')
    axes(handles.axes5);
    title('pressure')
    ylabel('millibars')
    axes(handles.axes6);
    title('displacement')
    ylabel('kilometers')
    xlabel('time-steps (6-hour)')

    % Load ssh lat/lon data
    handles.ssh = load('/project/expeditions/eddies_project_data/ssh_data/data/global_ssh_1992_2011_with_new_landmask.mat',...
        'lat','lon');
    
    %keep track of the hurricane age (time-steps)
    handles.hurr_age = 1;
    
   %handles for current time-step of hurricane on plots
   handles.wind_current = 1;
   handles.pres_current = 1;
   handles.disp_current = 1;
    
    %keep track of consecutive encounters with the same eddy
    handles.curr_eddy_class = NaN;
    handles.curr_eddy_idx = NaN;
    
    %load legend into axes8
    axes(handles.axes8);
    %light green
    p1 = plot(1,1, 'o','MarkerSize',10,'MarkerEdgeColor',...
        [.25 .85 .5], 'MarkerFaceColor',[.25 .85 .5]);
    hold on
    %dark green
    p2 = plot(1,1, 'o','MarkerSize',10,'MarkerEdgeColor',...
        [.2 .5 .2], 'MarkerFaceColor',[.2 .5 .2]);
    %light red
    p3 = plot(1,1, 'o','MarkerSize',10,'MarkerEdgeColor',...
        [1 .1 .1], 'MarkerFaceColor',[1 .1 .1]);
    %dark red
    p4 = plot(1,1, 'o','MarkerSize',10,'MarkerEdgeColor',...
        [.6 .1 .1], 'MarkerFaceColor',[.7 .1 .1]);
    
    ylims = get(handles.axes8,'YLim');
    p5 = line([1 1],ylims,'Color',[0.94 0.35 0]);
    p6 = line([1 1],ylims,'Color',[0.94 0.35 .5]);
    
    hleg = legend('unique cyclonic','non-unique cyclonic',...
        'unique anticyclonic','non-unique anticyc', 'Location',...
        'South', 'Max(Min) of figure', 'map->plot indicator');
    htitle = get(hleg,'Title');
    set(htitle,'String','Plots Legend');
    
 
    cla
    axis off;
    
    
    axes(handles.axes1);
    
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes he_viewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end


% --- Outputs from this function are returned to the command line.
function varargout = he_viewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


function hurID_Callback(hObject, eventdata, handles)

    handles.ibtracsID = get(hObject,'String');
    if(handles.stepPlace ~= 0)
        handles.oldStepPlace = handles.stepPlace;
    end
    for i = 1 : size(handles.ibtracs_idx,1)
        if(strcmp(handles.ibtracsID,cellstr(handles.ibtracs_idx(i,1))))
            handles.stepPlace = handles.ibtracs_idx.Start_Index(i);
            handles.lastIndex = handles.ibtracs_idx.Stop_Index(i);
            break
        end
    end
    handles.plotStop = 0;
    handles.TimeSlice = handles.ibtracs.TimeSlice(handles.stepPlace);
    
    %reset hurricane age
    handles.hurr_age = 1;

    %find bounds for which to color map with eddy bodies..
    lats = handles.ibtracs.Latitude_for_mapping(handles.stepPlace:handles.lastIndex);
    lons = handles.ibtracs.Longitude_for_mapping(handles.stepPlace:handles.lastIndex);
    
    % Columns: Latitute Longitude
    % Rows: Min Max
    min_lat = floor(min(lats)/0.25)*0.25 - 5;
    max_lat = floor(max(lats)/0.25)*0.25 + 5;
    min_lon = floor(min(lons)/0.25)*0.25;
    max_lon = floor(max(lons)/0.25)*0.25;
    
    a = find(handles.ssh.lat == min_lat);
    b = find(handles.ssh.lat == max_lat);
    c = find(handles.ssh.lon == min_lon);
    d = find(handles.ssh.lon == max_lon);
    
    %Repair the coordinate limits if 0 or 180 degrees latitude is crossed
    if((min_lon < 0 && max_lon > 0))
       
        pos_lons = lons(lons(:) >= 0);
        neg_lons = lons(lons(:) < 0);
        min_pos = floor(min(pos_lons)/0.25)*0.25 - 5;
        max_neg = floor(max(neg_lons)/0.25)*0.25 + 5;
        
       
        %track cross 180 degrees longitude
        if((max_lon-180) <= 2 && (max_lon-180) >= -2)
            min_pos = find(handles.ssh.lon == min_pos);
            max_neg = find(handles.ssh.lon == max_neg);
            handles.coordLimits{1,2} = (min_pos:max_neg);
            handles.case = 2;
        else %Crosses 0 degress longitude
            handles.coordLimits{1,2} = [1:(d+20), (c-20):1440];
            handles.case = 3;
        end
        handles.coordLimits{1,1} = (a:b);
    else
        handles.case = 1;
        handles.coordLimits{1,1} = (a:b);
        min_lon = min_lon - 5;
        if(max_lon < -5)
            max_lon = max_lon + 5;
        end
        c = find(handles.ssh.lon == min_lon);
        d = find(handles.ssh.lon == max_lon);
        handles.coordLimits{1,2} = (c:d);
    end
    
    %Populate plots of hurricane characteristics
    hur_idx = strcmp(handles.ibtracs.Serial_Num(:),handles.ibtracsID);
    temp_ibtracs = [handles.ibtracs.WindWMO(hur_idx), handles.ibtracs.PresWMO(hur_idx),...
        handles.ibtracs.Displacement_d1(hur_idx)];
    [toss max_wind] = max(temp_ibtracs(:,1));
    [toss min_pres] = min(temp_ibtracs(:,2));
    [toss max_disp] = max(temp_ibtracs(:,3));
    hurr_eddies = handles.ibtracs.EddyClass(hur_idx);
    idx = ~isnan(hurr_eddies(:));

    %make color scheme for scatter plot of eddies in each line
    %plot
    colors = cell2mat(handles.ibtracs.Eddy_Assoc_Color(hur_idx));
    colors = colors(idx,:);
   
    
    %x values for scatter...
    xs = (1:1:sum(hur_idx))';
    xs = xs(idx);
    hurr_wind = temp_ibtracs(idx,1);
    hurr_pres = temp_ibtracs(idx,2);
    hurr_disp = temp_ibtracs(idx,3); 
    
    %windspeed plot
    axes(handles.axes2);
    cla
    plot(handles.ibtracs.WindWMO(hur_idx));
    ylims = get(handles.axes2,'YLim');
    line([max_wind max_wind],ylims,...
        'Color',[0.94 0.35 0]);
    hold on
    scatter(xs, hurr_wind, 36, colors, '.');
    title('windspeed');
    ylabel('knots');
    
    %pressure plot
    axes(handles.axes5);
    cla
    plot(handles.ibtracs.PresWMO(hur_idx));
    ylims = get(handles.axes5,'YLim');
    line([min_pres min_pres],ylims,...
        'Color',[0.94 0.35 0]);
%     ys = ylims(2);
%     ys = ones(size(xs)) * (ys - 1);
    hold on
%     scatter(xs, ys, 36, colors, '.');    
    scatter(xs, hurr_pres, 36, colors, '.');
    title('pressure')
    ylabel('millibars')
    
    %displacement plot
    axes(handles.axes6);
    cla
    plot(handles.ibtracs.Displacement_d1(hur_idx));
    ylims = get(handles.axes6,'YLim');
    line([max_disp max_disp],ylims,...
        'Color',[0.94 0.35 0]);
%     ys = ylims(2);
%     ys = ones(size(xs)) * ys;
    hold on
%     scatter(xs, ys, 36, colors, '.'); 
    scatter(xs, hurr_disp, 36, colors, '.');
    title('displacement')
    ylabel('kilometers')
    xlabel('time-steps (6-hour)')
    
    axes(handles.axes1);
    
    hurr_info1_Callback(hObject, eventdata, handles);
    
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function hurID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hurID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in plotAll.
function plotAll_Callback(hObject, eventdata, handles)
    
    if(handles.plotStop == 1)
        errordlg('Current hurricane has been fully plotted');
        return
    end
    tic
    
    %push the first index of the current timeslice being plotted..
    handles.plotStack(length(handles.plotStack) + 1) = handles.stepPlace;
    
    %extract date information
    isovec = datevec(handles.ibtracs.ISO_time(handles.stepPlace));
    handles.Year = isovec(1);
    handles.Month = isovec(2);
    handles.Day = isovec(3);
    
    %Clear the map
    cla
    handles.figure = axesm('pcarre', 'Origin', [0 180 0]);
    load coast
    plotm(lat,long)
    whitebg('k')
   
    % Display eddies
    plotEddies_Callback(hObject,eventdata,handles);

    
    %Draw hurricane time-steps and any associated eddy
    %Also draw the track for each eddy that is associated with a hurricane
    %time-step..
    
    %Used so a track isn't plotted multiple time
    type_toggle = NaN;
    idx_toggle = NaN;

    %toggle to mark first instance of a weeks track...
    first_plot_hurr = 1;

    %Plot hurricane time-steps and eddy interactions..
    while(handles.TimeSlice == handles.ibtracs.TimeSlice(handles.stepPlace))
        
        %disp(strcat('plotting point cooresponding to stepPlace:',num2str(handles.stepPlace)))
        %Determine the category of the hurricane, represented by markersize
        %when plotting..
        windspeed = handles.ibtracs.WindWMO(handles.stepPlace);
        if(isnan(windspeed))
            m_size = 8;
        elseif(windspeed >= 64 && windspeed <= 82)
            m_size = 10;
        elseif(windspeed >= 83 && windspeed <= 95)
            m_size = 12;
        elseif(windspeed >= 96 && windspeed <= 112)
            m_size = 14;
        elseif(windspeed >= 113 && windspeed <= 136)
            m_size = 16;
        elseif(windspeed >= 137)
            m_size = 18;
        else
            m_size = 8;
        end
        
        if(handles.plotStop == 0)
            e_index = handles.stepPlace;
            color = handles.ibtracs.Eddy_Assoc_Color{handles.stepPlace};
            
            hurLat = handles.ibtracs.Latitude_for_mapping(handles.stepPlace);
            hurLon = handles.ibtracs.Longitude_for_mapping(handles.stepPlace);
            eddyLat = handles.ibtracs.EddyLat(handles.stepPlace);
            eddyLon = handles.ibtracs.EddyLon(handles.stepPlace);
            
            if(handles.ibtracs.EddyClass(handles.stepPlace) == 1) %associated with anticyclonic eddy
                
                
                
                if(first_plot_hurr)
                    plotm(hurLat, hurLon,'d','MarkerSize',m_size,'MarkerEdgeColor',...
                        color, 'MarkerFaceColor',color, 'ButtonDownFcn',...
                        {@clickMap_Callback,handles});
                    first_plot_hurr = 0;
                else
                    plotm(hurLat, hurLon,'o','MarkerSize',m_size,'MarkerEdgeColor',...
                        color, 'MarkerFaceColor',color, 'ButtonDownFcn',...
                        {@clickMap_Callback,handles});
                end

%                 plotm(eddyLat,eddyLon,'o','MarkerSize',10,'MarkerEdgeColor',...
%                     color, 'ButtonDownFcn',...
%                         {@clickMap_Callback,handles});
%                 linem([hurLat;eddyLat],[hurLon;eddyLon],'r');
                
                %plot eddy track, if not already plotted..
%                 if(handles.ibtracs.EddyClass(e_index) ~= type_toggle || ...
%                         handles.ibtracs.EddyTrackIdx(e_index) ~= idx_toggle)
%                     
%                     type_toggle = handles.ibtracs.EddyClass(e_index);
%                     idx_toggle = handles.ibtracs.EddyIdx(e_index);
%                     
%                     k = handles.ibtracs.EddyTrackIdx(e_index);
%                     if(~isnan(k))
%                         track = cell2mat(handles.bu_anti_tracks(k));
%                         linem(track(:,1), track(:,2), 'o-', 'LineWidth',...
%                             1.5, 'Color', color);
%                         plotm(track(1,1), track(1,2), 'd-', 'Color', color);
%                     end
%                     
%                 end
                
            elseif(handles.ibtracs.EddyClass(handles.stepPlace) == -1) %associated with cyclonic eddy
                
                if(first_plot_hurr)
                    plotm(hurLat, hurLon,'d','MarkerSize',m_size,'MarkerEdgeColor',...
                        color, 'MarkerFaceColor',color, 'ButtonDownFcn',...
                        {@clickMap_Callback, handles});
                    first_plot_hurr = 0;
                else
                    plotm(hurLat, hurLon,'o','MarkerSize',m_size,'MarkerEdgeColor',...
                        color, 'MarkerFaceColor',color, 'ButtonDownFcn',...
                        {@clickMap_Callback, handles});
                end
                
%                 plotm(eddyLat,eddyLon,'o','MarkerSize',10,'MarkerEdgeColor',...
%                     color, 'ButtonDownFcn',...
%                         {@clickMap_Callback, handles});
%                 linem([hurLat;eddyLat],[hurLon;eddyLon],'Color',color);
%                 
                %plot eddy track, if not already plotted..
%                 if(handles.ibtracs.EddyClass(e_index) ~= type_toggle || ...
%                         handles.ibtracs.EddyIdx(e_index) ~= idx_toggle)
%                     
%                     type_toggle = handles.ibtracs.EddyClass(e_index);
%                     idx_toggle = handles.ibtracs.EddyIdx(e_index);
%                    
%                     k = handles.ibtracs.EddyTrackIdx(e_index);
%                     if(~isnan(k))
%                         track = cell2mat(handles.bu_cyc_tracks(k));
%                         linem(track(:,1), track(:,2), 'o-', 'LineWidth',...
%                             1.5, 'Color', color);
%                         plotm(track(1,1), track(1,2), 'd',...
%                             'Color', color);
%                     end
%                     
%                 end
                
            else
                if(first_plot_hurr)
                    plotm(hurLat, hurLon,'d','MarkerSize',m_size,'MarkerEdgeColor',...
                        [0 0 0], 'MarkerFaceColor',[0 0 0], 'ButtonDownFcn',...
                        {@clickMap_Callback,handles});
                    first_plot_hurr = 0;
                else
                    plotm(hurLat, hurLon,'o','MarkerSize',m_size,'MarkerEdgeColor',...
                        [0 0 0], 'MarkerFaceColor',[0 0 0], 'ButtonDownFcn',...
                        {@clickMap_Callback,handles});
                end
            end 
        end
        
        if(handles.stepPlace < handles.lastIndex)
            handles.stepPlace = handles.stepPlace + 1;
        else
            handles.plotStop = 1; %Step will not plot the last coordinate again
                                  %in order to not lose any handles
            break
        end    
        handles.hurr_age = handles.hurr_age + 1;
    end

    handles.TimeSlice = handles.ibtracs.TimeSlice(handles.stepPlace);
    toc
    
    guidata(hObject, handles);
end


% Plot the previous timeslice of the hurricane track
function previous_Callback(hObject, eventdata, handles)
    i = length(handles.plotStack);
    handles.stepPlace = handles.plotStack(i-1);
    handles.plotStack = handles.plotStack(1:(i-2));
    handles.TimeSlice = handles.ibtracs.TimeSlice(handles.stepPlace);
    handles.plotStop = 0;
    guidata(hObject,handles);
    plotAll_Callback(hObject, eventdata, handles);
end


% --- Executes on button press in plotEddies.
function plotEddies_Callback(hObject, eventdata, handles)
% some business to create the proper name string for loading eddy
    % bodies    
    anticycFile = strcat('/project/expeditions/eddies_project_data/results/new_bottom_up_w_land_mask_09_16_2013/',...
    'anticyc_', num2str(handles.TimeSlice), '.mat');
    cyclonicFile = strcat('/project/expeditions/eddies_project_data/results/new_bottom_up_w_land_mask_09_16_2013/',...
        'cyclonic_', num2str(handles.TimeSlice), '.mat');
    

    handles.canvas = zeros(721, 1440, 'uint8');
    
    %Takes approx. 1.3 seconds to load these two files..
    handles.eddy2 = load(anticycFile);
    handles.eddy1 = load(cyclonicFile);
    %--------------------------------------------------%
    
    % 0.1 seconds
    subset = handles.ibtracs(handles.stepPlace:handles.lastIndex,:);
%     last_idx = NaN;
%     for i = handles.stepPlace : handles.lastIndex
%         if(handles.ibtracs.TimeSlice(i) ~= handles.TimeSlice)
%             last_idx = i-1;
%             break
%         end
%     end
    %subset = handles.ibtracs(handles.stepPlace:last_idx,:);
    subset = subset(subset.EddyTrackLength(:) == 1,:);
    cyclonic_eddies = subset(subset.EddyClass(:) == -1,:); %cyclonic
    anticyc_eddies = subset(subset.EddyClass(:) == 1,:); %anticyclonic
    %--------------------------------------------------%
    a = handles.coordLimits{1,1};
    b = handles.coordLimits{1,2};
    lats = handles.ssh.lat(a);
    lons = handles.ssh.lon(b);
    
    %I hate that I have to do this....
    pos_lons = lons(lons >= 0);
    neg_lons = lons(lons < 0);
    
    
    if(handles.case > 1)
        % 1 seconds
        for i = 1:length(handles.eddy1.eddies)

            if((handles.eddy1.eddies(i).Lat >= min(lats) &&...
                    handles.eddy1.eddies(i).Lat <= max(lats))...
                    &&...
                    (((handles.eddy1.eddies(i).Lon >= pos_lons(1)) &&...
                    (handles.eddy1.eddies(i).Lon <= pos_lons(end))) ||...
                    ((handles.eddy1.eddies(i).Lon <= neg_lons(end)) &&...
                    (handles.eddy1.eddies(i).Lon >= neg_lons(1)))))

                % The following if statement colors an eddy a different shade if it
                % does not have a lifetime longer than one week, but interacts with
                % a hurricane
                if sum(cyclonic_eddies.EddyIdx(:) == i)
                    handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 1; %cyclonic
                else
                    handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 2; %cyclonic
                end
            end


        end
        for i = 1:length(handles.eddy2.eddies)

            if((handles.eddy2.eddies(i).Lat >= min(lats) &&...
                    handles.eddy2.eddies(i).Lat <= max(lats))...
                    &&...
                    (((handles.eddy2.eddies(i).Lon >= pos_lons(1)) &&...
                    (handles.eddy2.eddies(i).Lon <= pos_lons(end))) ||...
                    ((handles.eddy2.eddies(i).Lon <= neg_lons(end)) &&...
                    (handles.eddy2.eddies(i).Lon >= neg_lons(1)))))

                if sum(anticyc_eddies.EddyIdx(:) == i)
                    handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 3;  %anticyclonic
                else
                    handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 4;
                end
            end

        end
    else
        for i = 1:length(handles.eddy1.eddies)

            if((handles.eddy1.eddies(i).Lat >= min(lats) &&...
                    handles.eddy1.eddies(i).Lat <= max(lats))...
                    &&...
                    (handles.eddy1.eddies(i).Lon >= min(lons) &&...
                    handles.eddy1.eddies(i).Lon <= max(lons)))

                % The following if statement colors an eddy a different shade if it
                % does not have a lifetime longer than one week, but interacts with
                % a hurricane
                if sum(cyclonic_eddies.EddyIdx(:) == i)
                    handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 1; %cyclonic
                else
                    handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 2; %cyclonic
                end
            end


        end
        for i = 1:length(handles.eddy2.eddies)

            if((handles.eddy2.eddies(i).Lat >= min(lats) &&...
                    handles.eddy2.eddies(i).Lat <= max(lats))...
                    &&...
                    (handles.eddy2.eddies(i).Lon >= min(lons) &&...
                    handles.eddy2.eddies(i).Lon <= max(lons)))

                if sum(anticyc_eddies.EddyIdx(:) == i)
                    handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 3;  %anticyclonic
                else
                    handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 4;
                end
            end

        end
    end
    %--------------------------------------------------%
   
    pcolorm(handles.ssh.lat(a), handles.ssh.lon(b), handles.canvas(a,b));
%     handles.pcolor_h = 1;
%       pcolorm(handles.ssh.lat, handles.ssh.lon,...
%           handles.canvas)
    
    guidata(hObject,handles);
end


function getEddyTimeslice_Callback(hObject, eventdata, handles)
    handles.timeSlice = num2str(get(hObject,'String'));
    guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function getEddyTimeslice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to getEddyTimeslice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function hurr_info1_Callback(hObject, eventdata, handles)
% hObject    handle to hurr_info1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hurr_info1 as text
%        str2double(get(hObject,'String')) returns contents of hurr_info1 as a double
%     indexString = num2str(handles.stepPlace);
%     set(handles.displayIndex, 'String', indexString);
    idx = handles.stepPlace;
    info1_str = sprintf(strcat('Hurricane Name: %s \n Timeslice: %d \n',...
        'Basin of origin: %s \n Index in dataset: %d \n'),...
        handles.ibtracs.Name{idx}, handles.ibtracs.TimeSlice(idx),...
        handles.ibtracs.Basin{idx}, idx);
    set(handles.hurr_info1, 'String', info1_str);
    
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function hurr_info1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hurr_info1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function hurr_info2_Callback(hObject, eventdata, handles)
% hObject    handle to hurr_info2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hurr_info2 as text
%        str2double(get(hObject,'String')) returns contents of hurr_info2 as a double
end

% --- Executes during object creation, after setting all properties.
function hurr_info2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hurr_info2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function clickMap_Callback(hObject, eventdata, handles)
    
    age = handles.hurr_age;
    time_str = handles.ibtracs.ISO_time{handles.stepPlace};
    
    axes(handles.axes2); %show current step on windspeed plot
    ylims = get(handles.axes2,'YLim');
    wind_current = line([age age],ylims,...
        'Color',[0.94 0.35 .5]);
    axes(handles.axes5); %show current step on pressure plot
    ylims = get(handles.axes5,'YLim');
    pres_current = line([age age],ylims,...
        'Color',[0.94 0.35 .5]);
    axes(handles.axes6); %show current step on d plot
    ylims = get(handles.axes6,'YLim');
    disp_current = line([age age],ylims,...
        'Color',[0.94 0.35 .5]);
    
    to_print = sprintf('Age: %d time-steps\nISO_time: %s',age,time_str);
    waitfor(msgbox(to_print));
    delete(wind_current)
    delete(pres_current)
    delete(disp_current)
    
    axes(handles.axes1);
    
    
    %guidata(hObject, handles);

end
