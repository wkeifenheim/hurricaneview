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

% Last Modified by GUIDE v2.5 07-Oct-2013 11:03:41

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


    s = load('/panfs/roc/groups/6/kumarv/keifenhe/Documents/Datasets/HurDat_1851_2010.mat');
    handles.hurDat = s.hurDat;
    handles.points = zeros(41198,1);   % store handles to plotted points
    handles.pointsPlotted = zeros(41198,1); %because matlab doesn't like combining
                                            %a bool tracker with handles..
                                            
    handles.hurStepHandles = zeros(200,1);
    handles.hurStepHIndex = 1;
    handles.eddysPlottedHandles = zeros(200,1);
    handles.eddysPlottedHIndex = 1;
    handles.linesPlottedHandles = zeros(200,1);
    handles.linesPlottedHIndex = 1;


    s = load('/panfs/roc/groups/6/kumarv/keifenhe/Documents/Datasets/EBTracks_Atlantic1992-2010v3.mat',...
        'ebtrkatlc1992_2010');
    handles.ebtrack = s.ebtrkatlc1992_2010;

    % Experimental handles for clearing old plotted points..

    % Create a 1442x3 matrix containing the indexes of a specific hurricane
    % in the hurDat matrix -> HurricaneIndex(somehurricane#) =
    % [startindex,endindex,plotted]
    handles.HurricaneIndex = zeros([1442,3]);
    handles.HurricaneIndex(1,1) = 1;
    for i=1:41197
        j = handles.hurDat(i,1);
        if(handles.hurDat(i+1,1) ~= j)
            handles.HurricaneIndex(j,2) = i;
            handles.HurricaneIndex(j+1,1) = i+1;
        end
    end
    handles.HurricaneIndex(1442,2) = 41198;
            
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
    handles.nextEddyDraw = 0;

    % used to handle drawing eddy bodies only around the hurricane path
    % Rows: Latitute Longitude
    % Columns: Min Max
    handles.coordLimits = zeros(2);

    % Current hurricane #
    handles.choice = 0;

    % Establish colorScale for hurricane intensity
    handles.colorScale = jet(181); %for min/max of 10/160 kt

    % Load up the map
    %worldmap([0 70],[-120 0])
    handles.figure = axesm('pcarre', 'MapLatLimit', [0 70], 'MapLonLimit', [-120 0]);
    load coast
    plotm(lat,long)
    whitebg('k')
    handles.land = shaperead('landareas', 'UseGeoCoords', true); %landmask

    % Load ssh lat/lon data
    handles.ssh = load('/project/expeditions/eddies_project_data/ssh_data/data/global_ssh_1992_2011_with_new_landmask.mat',...
        'lat','lon');

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

% --- Executes on button press in clear.
function undo_Callback(hObject, eventdata, handles)

    % Establish which was the last hurricane to be plotted
    n = size(handles.HurIndexHist,2);
        % debugging stuff
        %display('Beginning clear function...')
        %disp(strcat('Current HurIndexHist: ',num2str(handles.HurIndexHist)))
        %disp(strcat('N: ',num2str(n)))

    if(handles.stepPlace ~= 0) % "step back"
        %disp(strcat('attempting backstep from stepPlace: ',num2str(handles.stepPlace)))
        
        
        
        try
            if(handles.pointsPlotted(handles.stepPlace) == 1)
                delete(handles.points(handles.stepPlace));
                handles.pointsPlotted(handles.stepPlace) = 0;
            end
        catch err
            disp('Error: somethin` ain`t right with stepping back..')
        end

        handles.stepPlace = handles.stepPlace - 1;

        % Reset stepPlace if decremented past first index
            %disp(strcat('first index of current hurricane: ',...
            %    num2str(handles.HurricaneIndex(handles.HurIndexHist(n),1))));
            %disp(strcat('stepPlace:',num2str(handles.stepPlace),' < ',num2str(handles.HurricaneIndex(handles.HurIndexHist(n),1))))
        if(handles.stepPlace < handles.HurricaneIndex(handles.HurIndexHist(n),1))
            handles.stepPlace = 0;
            handles.plotStop = 0;
            % And pop this hurricane off the history stack
            if(n == 1)
                handles.HurIndexHist = 0;
            else
                handles.HurIndexHist = handles.HurIndexHist(1:n-1);
            end
        end
    else
        % Use index to find range of handles to delete
        try
            j = handles.HurricaneIndex(handles.HurIndexHist(n),1);
            k = handles.HurricaneIndex(handles.HurIndexHist(n),2);
            for i=j:k
                delete(handles.points(i));
                handles.pointPlotted(i) = 0;
            end
        catch err
            disp('caught it, we`re good')
        end

        % Mark the hurricane as not plotted
        handles.HurricaneIndex(handles.HurIndexHist(n),3) = 0;
        
        % "Pop" the most recent value from the history
        if(n == 1) % Last remaining plotted hurricane
            handles.HurIndexHist = 0;
        else
            handles.HurIndexHist = handles.HurIndexHist(1:n-1);
        end
    end



    guidata(hObject,handles);

end

% --- Executes on button press in clear. Currently problematic, as you 
% cannot replot a point once it has been cleared by this function
function clear_Callback(hObject, eventdata, handles)
   
    for i=1:41198
        try
            if(handles.pointsPlotted(i) == 1)
                handles.pointsPlotted(i) = 0;
                delete(handles.points(i));
            end
        catch
            disp('clear ain`t happy')
        end
    end
    
    guidata(hObject,handles);
end

% --- Executes on button press in drawBodies.
function drawBodies_Callback(hObject, eventdata, handles)

    % some business to create the proper name string for loading eddy
    % bodies    
    [anticycFile cyclonicFile] = findEddies(num2str(handles.Year),...
        num2str(handles.Month), num2str(handles.Day));
    

    handles.canvas = zeros(721, 1440, 'uint8');
    
    handles.eddy2 = load(anticycFile);
    handles.eddy1 = load(cyclonicFile);
    
    for i = 1:length(handles.eddy1.eddies)
        handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 1; %cyclonic
    end
    for i = 1:length(handles.eddy2.eddies)
        handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 2;  %anticyclonic
    end

    pcolorm(handles.ssh.lat, handles.ssh.lon, handles.canvas)
    
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

% --- Executes during object creation, after setting all properties.
function eddyDay_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% Identical to edit20_Callback(....)
function getHurNum_Callback(hObject, eventdata, handles)

    handles.ebtrackID = get(hObject,'String');
    if(handles.stepPlace ~= 0)
        handles.oldStepPlace = handles.stepPlace;
    end
    for i = 1 : size(handles.ebtrack,1)
        if(strcmp(handles.ebtrackID,cellstr(handles.ebtrack(i,1))))
            handles.stepPlace = i;
            break
        end
    end
    handles.plotStop = 0;
    for i = i : size(handles.ebtrack,1)
        if(~strcmp(handles.ebtrackID,cellstr(handles.ebtrack(i,1))))
            handles.lastIndex = i - 1;
            break
        end
    end
    
    guidata(hObject, handles);
    
end

% --- Executes during object creation, after setting all properties.
function getHurNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to getHurNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

% --- Executes on button press in stepFromHurNum.
function stepFromHurNum_Callback(hObject, eventdata, handles)

    if(handles.plotStop == 1)
        errordlg('Current hurricane has been fully plotted');
        return
    end

    handles.Year = double(handles.ebtrack(handles.stepPlace,3));
    handles.Month = double(handles.ebtrack(handles.stepPlace,4));
    handles.Day = double(handles.ebtrack(handles.stepPlace,5));   


    offset = 0;


    % Determine the day of the week
    step = handles.stepPlace;
    year = num2str(handles.Year);
    month = num2str(handles.Month);
    day = num2str(handles.Day);
    offset = double(handles.ebtrack(step,6))/6 + ((weekday(strcat(year,...
        '-', month, '-', day)) - 1) * 4);
    handles.nextEddyDraw = 28;

    % Display eddies
    drawBodies_Callback(hObject,eventdata,handles);
    
    % Keep track of when next to draw eddy bodies
    if(handles.nextEddyDraw == 0)
        handles.nextEddyDraw = 28; % Four time steps per day
     else
         handles.nextEddyDraw = handles.nextEddyDraw - 1 - offset;
    end
    
    % delete old hurricane time steps
    if(handles.hurStepHIndex > 1)
        i = handles.hurStepHIndex - 1;
        while(i > 0)
            delete(handles.hurStepHandles(i));
            i = i - 1;
        end
        handles.hurStepHIndex = 1;
    end
    
    for i=handles.nextEddyDraw:-1:0
        disp(strcat('plotting point cooresponding to stepPlace:',num2str(handles.stepPlace)))
        if(handles.plotStop == 0)
            hurLat = double(handles.ebtrack(handles.stepPlace,7));
            hurLon = double(handles.ebtrack(handles.stepPlace,8));
            color = handles.colorScale((handles.ebtrack(handles.stepPlace,9) - 9), :);
            handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                hurLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                color, 'MarkerFaceColor',color);
            handles.hurStepHIndex = handles.hurStepHIndex + 1;
            
            end
            %handles.pointsPlotted(handles.stepPlace) = 1; %mark as plotted
        if(handles.stepPlace < handles.lastIndex)
            handles.stepPlace = handles.stepPlace + 1;
        else
            disp('Current Hurricane is fully plotted.')
            handles.plotStop = 1; %Step will not plot the last coordinate again
                                  %in order to not lose the handle
        end
    end
    
    
    
    edit16_Callback(hObject, eventdata, handles);
    
    guidata(hObject,handles);
    
end

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



function edit20_Callback(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit20 as text
%        str2double(get(hObject,'String')) returns contents of edit20 as a double
    handles.ebtrackID = get(hObject,'String');
    if(handles.stepPlace ~= 0)
        handles.oldStepPlace = handles.stepPlace;
    end
    for i = 1 : size(handles.ebtrack,1)
        if(strcmp(handles.ebtrackID,cellstr(handles.ebtrack(i,1))))
            handles.stepPlace = i;
            break
        end
    end
    handles.plotStop = 0;
    for i = i : size(handles.ebtrack,1)
        if(~strcmp(handles.ebtrackID,cellstr(handles.ebtrack(i,1))))
            handles.lastIndex = i - 1;
            break
        end
    end
    
    guidata(hObject, handles);

end


% --- Executes during object creation, after setting all properties.
function edit20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end


% --- Executes on button press in pushbutton21.
function pushbutton21_Callback(hObject, eventdata, handles)
    
    if(handles.plotStop == 1)
        errordlg('Current hurricane has been fully plotted');
        return
    end

    handles.Year = double(handles.ebtrack(handles.stepPlace,3));
    handles.Month = double(handles.ebtrack(handles.stepPlace,4));
    handles.Day = double(handles.ebtrack(handles.stepPlace,5));   


    offset = 0;


    % Determine the day of the week
    step = handles.stepPlace;
    year = num2str(handles.Year);
    month = num2str(handles.Month);
    day = num2str(handles.Day);
    offset = double(handles.ebtrack(step,6))/6 + ((weekday(strcat(year,...
        '-', month, '-', day)) - 1) * 4);
    handles.nextEddyDraw = 28;

    % Display eddies
    drawBodies_Callback(hObject,eventdata,handles);
    
    % Keep track of when next to draw eddy bodies
    if(handles.nextEddyDraw == 0)
        handles.nextEddyDraw = 28; % Four time steps per day
     else
         handles.nextEddyDraw = handles.nextEddyDraw - 1 - offset;
    end
    
    % delete old hurricane time steps
    if(handles.hurStepHIndex > 1)
        i = handles.hurStepHIndex - 1;
        while(i > 0)
            delete(handles.hurStepHandles(i));
            i = i - 1;
        end
        handles.hurStepHIndex = 1;
    end
    
    % delete old plotted eddies
    if(handles.eddysPlottedHIndex > 1)
        i = handles.eddysPlottedHIndex - 1;
        while(i > 0)
            delete(handles.eddysPlottedHandles(i));
            i = i - 1;
        end
        handles.eddysPlottedHIndex = 1;
    end
    
    % delete old lines between hurricane steps and eddies
    if(handles.linesPlottedHIndex > 1)
        i = handles.linesPlottedHIndex - 1;
        while(i > 0)
            delete(handles.linesPlottedHandles(i));
            i = i - 1;
        end
        handles.linesPlottedHIndex = 1;
    end
    
    for i=handles.nextEddyDraw:-1:0
        disp(strcat('plotting point cooresponding to stepPlace:',num2str(handles.stepPlace)))
        if(handles.plotStop == 0)
            hurLat = double(handles.ebtrack(handles.stepPlace,7));
            hurLon = double(handles.ebtrack(handles.stepPlace,8));
            eddyLat = double(handles.ebtrack(handles.stepPlace,19));
            eddyLon = double(handles.ebtrack(handles.stepPlace,20));
            if(double(handles.ebtrack(handles.stepPlace,18)) == 1) %associated with anticyclonic eddy
                handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                    hurLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                    [1 0 0], 'MarkerFaceColor',[1 0 0]);
                handles.eddysPlottedHandles(handles.eddysPlottedHIndex) = ...
                    plotm(eddyLat,eddyLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                    [1 0 0]);
                handles.linesPlottedHandles(handles.linesPlottedHIndex) = ...
                    linem([hurLat;eddyLat],[hurLon;eddyLon],'r');
                handles.hurStepHIndex = handles.hurStepHIndex + 1;
                handles.eddysPlottedHIndex = handles.eddysPlottedHIndex + 1;
                handles.linesPlottedHIndex = handles.linesPlottedHIndex + 1;
            elseif(double(handles.ebtrack(handles.stepPlace,18)) == -1) %associated with cyclonic eddy
                handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                    hurLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                    [.25 .75 .25], 'MarkerFaceColor',[.25 .75 .25]);
                handles.eddysPlottedHandles(handles.eddysPlottedHIndex) = ...
                    plotm(eddyLat,eddyLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                    [.25 .75 .25]);
                handles.linesPlottedHandles(handles.linesPlottedHIndex) = ...
                    linem([hurLat;eddyLat],[hurLon;eddyLon],'Color',[.25 .75 .25]);
                handles.hurStepHIndex = handles.hurStepHIndex + 1;
                handles.eddysPlottedHIndex = handles.eddysPlottedHIndex + 1;
                handles.linesPlottedHIndex = handles.linesPlottedHIndex + 1;
            else
                handles.hurStepHandles(handles.hurStepHIndex) = plotm(hurLat,...
                    hurLon,'o','MarkerSize',10,'MarkerEdgeColor',...
                    [0 0 0], 'MarkerFaceColor',[0 0 0]);
                handles.hurStepHIndex = handles.hurStepHIndex + 1;
            end
            %handles.pointsPlotted(handles.stepPlace) = 1; %mark as plotted
        end
        if(handles.stepPlace < handles.lastIndex)
            handles.stepPlace = handles.stepPlace + 1;
        else
            disp('Current Hurricane is fully plotted.')
            handles.plotStop = 1; %Step will not plot the last coordinate again
                                  %in order to not lose the handle
        end
    end
    
    
    
    edit16_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);
end
    
