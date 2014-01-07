function varargout = hv_controls(varargin)
% HV_CONTROLS MATLAB code for hv_controls.fig
%      HV_CONTROLS, by itself, creates a new HV_CONTROLS or raises the existing
%      singleton*.
%
%      H = HV_CONTROLS returns the handle to a new HV_CONTROLS or the handle to
%      the existing singleton*.
%
%      HV_CONTROLS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HV_CONTROLS.M with the given input arguments.
%
%      HV_CONTROLS('Property','Value',...) creates a new HV_CONTROLS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before hv_controls_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to hv_controls_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help hv_controls

% Last Modified by GUIDE v2.5 07-Jan-2014 13:14:43

% Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @hv_controls_OpeningFcn, ...
                       'gui_OutputFcn',  @hv_controls_OutputFcn, ...
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
    

% --- Executes just before hv_controls is made visible.
function hv_controls_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to hv_controls (see VARARGIN)

    s = load('/panfs/roc/groups/6/kumarv/keifenhe/Documents/Datasets/IBTrACS_20140106.mat');
    handles.ibtracs = s.IBTrACS_1992_2010;
    
    s = load('/panfs/roc/groups/6/kumarv/keifenhe/Documents/Datasets/IBTrACS_indices_v1.mat');
    handles.ibtracs_idx = s.IBTrACS_indices;
    
    %Used for tracking and deleting plotted stuff
    handles.hurStepHandles = zeros(200,1);
    handles.hurStepHIndex = 1;
    handles.eddysPlottedHandles = zeros(200,1);
    handles.eddysPlottedHIndex = 1;
    handles.linesPlottedHandles = zeros(200,1);
    handles.linesPlottedHIndex = 1;
    handles.tracksPlottedHandles = zeros(2000,1);
    handles.tracksPlottedHIndex = 1;
    %-----------------------------------------------

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
    handles.OldStepPlace = 0;

    % Attempting to step repeatedly on the last hurricane
    % coordinate doesn't overwrite the cooresponding original handle
    handles.plotStop = 0;

    % Counter used so that every step does not need the eddy bodies to be 
    % redrawn (a serious slowdown issue).
    %handles.nextEddyDraw = 0;

    % used to handle drawing eddy bodies only around the hurricane path
    % Rows: Latitute Longitude
    % Columns: Min Max
    handles.coordLimits = zeros(2,2);

    % Current hurricane #
    handles.choice = 0;

    % Establish colorScale for hurricane intensity
    handles.colorScale = jet(181); %for min/max of 10/160 kt

    % Load up the map
    %worldmap([0 70],[-120 0])
    handles.figure = axesm('pcarre');%, 'MapLatLimit', [0 70], 'MapLonLimit', [-120 0]);
    load coast
    plotm(lat,long)
    whitebg('k')
%     handles.land = shaperead('landareas', 'UseGeoCoords', true); %landmask

    % Load ssh lat/lon data
    handles.ssh = load('/project/expeditions/eddies_project_data/ssh_data/data/global_ssh_1992_2011_with_new_landmask.mat',...
        'lat','lon');
    
    %lets try storing a handle for the surface object created by pcolorm..
    handles.pcolor_h = NaN;

    % Choose default command line output for hv_controls
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes hv_controls wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = hv_controls_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;

end

% --- Executes on button press in drawBodies.
function drawBodies_Callback(hObject, eventdata, handles)

    %Experiment to delete old eddy bodies..
%     if(~isnan(handles.pcolor_h))
%         delete(gca)
%         axesm('pcarre')
%         load coast
%         plotm(lat,long)
%         whitebg('k')
%         handles.pcolor_h = NaN;
%     end
    
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
    subset = subset(double(subset(:,23)) ~= 0,:);
    cyclonic_eddies = subset(double(subset(:,17)) == -1,:); %cyclonic
    anticyc_eddies = subset(double(subset(:,17)) == 1,:); %anticyclonic
    %--------------------------------------------------%
    
    % 1 seconds
    for i = 1:length(handles.eddy1.eddies)
        
        if((handles.eddy1.eddies(i).Lat >= handles.coordlimits(1,1) &&...
                handles.eddy1.eddies(i).Lat <= handles.coordlimits(1,2))...
                &&...
                handles.eddy1.eddies(i).Lon >= handles.coordlimits(2,1) &&...
                handles.eddy1.eddies(i).Lon <= handles.coordlimits(2,2))
            
            % The following if statement colors an eddy a different shade if it
            % does not have a lifetime longer than one week, but interacts with
            % a hurricane
            if sum(double(cyclonic_eddies(:,22)) == i)
                handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 1; %cyclonic
            else
                handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 2; %cyclonic
            end
        end
    end
    for i = 1:length(handles.eddy2.eddies)
        
        if((handles.eddy2.eddies(i).Lat >= handles.coordlimits(1,1) &&...
                handles.eddy2.eddies(i).Lat <= handles.coordlimits(1,2))...
                &&...
                handles.eddy2.eddies(i).Lon >= handles.coordlimits(2,1) &&...
                handles.eddy2.eddies(i).Lon <= handles.coordlimits(2,2))
        
            if sum(double(anticyc_eddies(:,22)) == i)
                handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 3;  %anticyclonic
            else
                handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 4;
            end
        end
        
    end
    %--------------------------------------------------%

    %find indices cooresponding to coordlimits..
    
    a = find(handles.ssh.lat == handles.coordlimits(1,1));
    b = find(handles.ssh.lat == handles.coordlimits(2,1));
    c = find(handles.ssh.lon == handles.coordlimits(1,2));
    d = find(handles.ssh.lon == handles.coordlimits(2,2));
    
    pcolorm(handles.ssh.lat(a:b), handles.ssh.lon(c:d),...
        handles.canvas(a:b,c:d));
    handles.pcolor_h = 1;
%       pcolorm(handles.ssh.lat, handles.ssh.lon,...
%           handles.canvas)
    
    guidata(hObject,handles);
end

function eddyYear_Callback(hObject, eventdata, handles)

    handles.eddyYear = get(hObject,'String');
    guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function eddyYear_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function eddyMonth_Callback(hObject, eventdata, handles)

    handles.eddyMonth = get(hObject,'String');
    guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function eddyMonth_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function eddyDay_Callback(hObject, eventdata, handles)


    handles.eddyDay = get(hObject,'String');
    guidata(hObject,handles);
end

function eddyDay_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

%Displays the current week being displayed (Wednesday date)
function edit16_Callback(hObject, eventdata, handles)

    dateString = sprintf('%d/%d/%d', handles.Year,handles.Month,handles.Day);
    set(handles.edit16, 'String', dateString);
    
    guidata(hObject,handles);
    
end

% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function edit18_Callback(hObject, eventdata, handles)
    handles.lat = str2double(get(hObject,'String'));
    guidata(hObject,handles);

end

% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function edit19_Callback(hObject, eventdata, handles)
    handles.lon = str2double(get(hObject,'String'));
    guidata(hObject,handles);
    
end

% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in pushbutton20.
function pushbutton20_Callback(hObject, eventdata, handles)
    plotm(handles.lat, handles.lon, 'o');
    
    guidta(hObject, handles);

end

% --- Executes during object creation, after setting all properties.
function pushbutton20_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function hurID_Callback(hObject, eventdata, handles) %#ok<*INUSL>
% hObject    handle to hurID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hurID as text
%        str2double(get(hObject,'String')) returns contents of hurID as a double
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

    %find bounds for which to color map with eddy bodies..
    lats = handles.ibtracs.EddyLat(handles.stepPlace:handles.lastIndex);
    lons = handles.ibtracs.EddyLon(handles.stepPlace:handles.lastIndex);
    
    % Rows: Latitute Longitude
    % Columns: Min Max
    handles.coordlimits(1,1) = floor(min(lats)/0.25)*0.25 - 5;
    handles.coordlimits(2,1) = floor(max(lats)/0.25)*0.25 + 5;
    handles.coordlimits(1,2) = floor(min(lons)/0.25)*0.25 - 5;
    handles.coordlimits(2,2) = floor(max(lons)/0.25)*0.25 + 5;
    
    guidata(hObject, handles);

end


% --- Executes during object creation, after setting all properties.
function hurID_CreateFcn(hObject, eventdata, handles) %#ok<*DEFNU,*INUSD>
% hObject    handle to hurID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end


% --- Method for drawing weekly hurricane track segment with eddies
function pushbutton21_Callback(hObject, eventdata, handles) %#ok<DEFNU>
    
    tic
    
    if(handles.plotStop == 1)
        errordlg('Current hurricane has been fully plotted');
        return
    end
    
    %extract date information
    isovec = datevec(handles.ibtracs.ISO_time(handles.stepPlace));
    handles.Year = isovec(1);
    handles.Month = isovec(2);
    handles.Day = isovec(3);
    
    %Clear the map
    cla
    handles.figure = axesm('pcarre');%, 'MapLatLimit', [0 70], 'MapLonLimit', [-120 0]);
    load coast
    plotm(lat,long)
    whitebg('k')
   
%     % Display eddies
    disp('about to draw eddies..')
    toc
    drawBodies_Callback(hObject,eventdata,handles);
    disp('done drawing eddies..') %currently takes about 6 seconds to complete
    toc
%     
%     % delete old hurricane time steps
%     if(handles.hurStepHIndex > 1)
%         i = handles.hurStepHIndex - 1;
%         while(i > 0)
%             delete(handles.hurStepHandles(i));
%             i = i - 1;
%         end
%         handles.hurStepHIndex = 1;
%     end
%     
%     % delete old plotted eddies
%     if(handles.eddysPlottedHIndex > 1)
%         i = handles.eddysPlottedHIndex - 1;
%         while(i > 0)
%             delete(handles.eddysPlottedHandles(i));
%             i = i - 1;
%         end
%         handles.eddysPlottedHIndex = 1;
%     end
%     
%     % delete old lines between hurricane steps and eddies
%     if(handles.linesPlottedHIndex > 1)
%         i = handles.linesPlottedHIndex - 1;
%         while(i > 0)
%             delete(handles.linesPlottedHandles(i));
%             i = i - 1;
%         end
%         handles.linesPlottedHIndex = 1;
%     end
%     
%     %delete old eddy tracks
%     if(handles.tracksPlottedHIndex > 1)
%         i = handles.tracksPlottedHIndex - 1;
%         while(i > 0)
%             delete(handles.tracksPlottedHandles(i));
%             i = i - 1;
%         end
%         handles.tracksPlottedHIndex = 1;
%     end
    
    
    %Draw hurricane time-steps and any associated eddy
    %Also draw the track for each eddy that is associated with a hurricane
    %time-step..
    
    %Used so a track isn't plotted multiple time
    type_toggle = NaN;
    idx_toggle = NaN;
    
    disp('beginning to plot hurricane..')
    toc
    
%     plot_wait = waitbar(0,'plotting hurricane time-steps..');
%     plot_complete = 0;

    %toggle to mark first instance of a weeks track...
    first_plot_hurr = 1;

    %Plot hurricane time-steps and eddy interactions..
    while(handles.TimeSlice == handles.ibtracs.TimeSlice(handles.stepPlace))
        
        disp(strcat('plotting point cooresponding to stepPlace:',num2str(handles.stepPlace)))
        
        if(handles.plotStop == 0)
            e_index = handles.stepPlace;
            
            hurLat = handles.ibtracs.Latitude_for_mapping(handles.stepPlace);
            hurLon = handles.ibtracs.Longitude_for_mapping(handles.stepPlace);
            eddyLat = handles.ibtracs.EddyLat(handles.stepPlace);
            eddyLon = handles.ibtracs.EddyLon(handles.stepPlace);
            
            if(handles.ibtracs.EddyClass(handles.stepPlace) == 1) %associated with anticyclonic eddy
                
                if(first_plot_hurr)
                    handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                        hurLon,'d','MarkerSize',10,'MarkerEdgeColor',...
                        [1 0 0], 'MarkerFaceColor',[1 0 0]);
                    first_plot_hurr = 0;
                else
                    handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                        hurLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                        [1 0 0], 'MarkerFaceColor',[1 0 0]);
                end
                
                handles.eddysPlottedHandles(handles.eddysPlottedHIndex) = ...
                    plotm(eddyLat,eddyLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                    [1 0 0]);
                
                handles.linesPlottedHandles(handles.linesPlottedHIndex) = ...
                    linem([hurLat;eddyLat],[hurLon;eddyLon],'r');
                
                handles.hurStepHIndex = handles.hurStepHIndex + 1;
                handles.eddysPlottedHIndex = handles.eddysPlottedHIndex + 1;
                handles.linesPlottedHIndex = handles.linesPlottedHIndex + 1;
                
                %plot eddy track, if not already plotted..
                if(handles.ibtracs.EddyClass(e_index) ~= type_toggle || ...
                        handles.ibtracs.TrackIdx(e_index) ~= idx_toggle)
                    
                    disp('attempting to find and plot a track..')
                    type_toggle = handles.ibtracs.EddyClass(e_index);
                    idx_toggle = handles.ibtracs.EddyIdx(e_index);
                    
                    k = handles.ibtracs.TrackIdx(e_index);
                    if(~isnan(k))
                        track = cell2mat(handles.bu_anti_tracks(k));
                        disp('displaying anti-cyclonic track..')
                        handles.tracksPlottedHandles(handles.tracksPlottedHIndex)...
                            = linem(track(:,1), track(:,2), 'ro-', 'LineWidth',...
                            1.5);
                        handles.tracksPlottedHIndex = handles.tracksPlottedHIndex...
                            + 1;
                        handles.tracksPlottedHandles(handles.tracksPlottedHIndex)...
                            = plotm(track(1,1), track(1,2), 'rd-');
                        handles.tracksPlottedHIndex = handles.tracksPlottedHIndex...
                            + 1;
                    end
                    
                end
                
            elseif(handles.ibtracs.EddyClass(handles.stepPlace) == -1) %associated with cyclonic eddy
                
                if(first_plot_hurr)
                    handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                        hurLon,'d','MarkerSize',10,'MarkerEdgeColor',...
                        [.25 .75 .25], 'MarkerFaceColor',[.25 .75 .25]);
                    first_plot_hurr = 0;
                else
                    handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                        hurLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                        [.25 .75 .25], 'MarkerFaceColor',[.25 .75 .25]);
                end
                
                handles.eddysPlottedHandles(handles.eddysPlottedHIndex) = ...
                    plotm(eddyLat,eddyLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                    [.25 .75 .25]);
                
                handles.linesPlottedHandles(handles.linesPlottedHIndex) = ...
                    linem([hurLat;eddyLat],[hurLon;eddyLon],'Color',[.25 .75 .25]);
                
                handles.hurStepHIndex = handles.hurStepHIndex + 1;
                handles.eddysPlottedHIndex = handles.eddysPlottedHIndex + 1;
                handles.linesPlottedHIndex = handles.linesPlottedHIndex + 1;
                
                %plot eddy track, if not already plotted..
                if(handles.ibtracs.EddyClass(e_index) ~= type_toggle || ...
                        handles.ibtracs.EddyIdx(e_index) ~= idx_toggle)
                    
                    disp('attempting to find and plot a track..')
                    type_toggle = handles.ibtracs.EddyClass(e_index);
                    idx_toggle = handles.ibtracs.EddyIdx(e_index);
                   
                    k = handles.ibtracs.TrackIdx(e_index);
                    if(~isnan(k))
                        track = cell2mat(handles.bu_cyc_tracks(k));
                        disp('displaying cyclonic track..')
                        handles.tracksPlottedHandles(handles.tracksPlottedHIndex)...
                            = linem(track(:,1), track(:,2), 'o-', 'LineWidth',...
                            1.5, 'Color', [0.25 .75 0.25]);
                        handles.tracksPlottedHIndex = handles.tracksPlottedHIndex...
                            + 1;
                        handles.tracksPlottedHandles(handles.tracksPlottedHIndex)...
                            = plotm(track(1,1), track(1,2), 'd',...
                            'Color', [0.25 .75 0.25]);
                        handles.tracksPlottedHIndex = handles.tracksPlottedHIndex...
                            + 1;
                    end
                    
                end
                
            else
                if(first_plot_hurr)
                    handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                        hurLon,'d','MarkerSize',10,'MarkerEdgeColor',...
                        [0 0 0], 'MarkerFaceColor',[0 0 0]);
                    first_plot_hurr = 0;
                else
                    handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                        hurLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                        [0 0 0], 'MarkerFaceColor',[0 0 0]);
                end
                
                handles.hurStepHIndex = handles.hurStepHIndex + 1;
                
            end
            
        end
        
        if(handles.stepPlace < handles.lastIndex)
            
            handles.stepPlace = handles.stepPlace + 1;
        
        else
            
            disp('Current Hurricane is fully plotted.')
            handles.plotStop = 1; %Step will not plot the last coordinate again
                                  %in order to not lose any handles
            break
        end
        
        %waitbar(plot_complete/handles.nextEddyDraw)
        
    end
    disp('done plotting hurricane and eddy tracks..')
    handles.TimeSlice = handles.ibtracs.TimeSlice(handles.stepPlace);
    toc
    
    
    edit16_Callback(hObject, eventdata, handles); %updates date display..
    guidata(hObject, handles);
end
