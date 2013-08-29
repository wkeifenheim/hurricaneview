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

% Last Modified by GUIDE v2.5 29-Aug-2013 10:35:34

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


    s = load('HurDat_1851_2010.mat');
    handles.hurDat = s.hurDat;
    handles.points = zeros(41198,1);   % store handles to plotted points
    handles.pointsPlotted = zeros(41198,1); %because matlab doesn't like combining
                                            %a bool tracker with handles..


    % Create a 1442x3 matrix containing the indeces of a specific hurricane
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
    
    % Attempting to step repeatedly on the last hurricane
    % coordinate doesn't overwrite the cooresponding original handle
    handles.plotStop = 0;
    
    % used to handle drawing eddy bodies only around the hurricane path
    % Rows: Latitute Longitude
    % Columns: Min Max
    handles.coordLimits = zeros(2);

    % Load up the map (coastlines only)
    worldmap([0 70],[-120,0])
    %axesm
    load coast
    plotm(lat,long)
    whitebg('k')
    %axesm mollweid
    %framem('FEdgeColor','blue','FLineWidth',0.5)
    %plotm(lat,long,'LineWidth',1,'Color','blue')
    
    %Topological Map
    %load topo
    %[lat lon] = meshgrat(topo,topolegend,[90 180]);
    %pcolorm(lat,lon,topo)
    %demcmap(topo)
    %tightmap
    
    % Load ssh lat/lon data
    handles.ssh = load('/project/expeditions/eddies_project_data/ssh_data/data/global_ssh_1992_2011_with_nan.mat',...
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

% --- Updates the choice of hurricane input by the user
function hurChoice_Callback(hObject, eventdata, handles)
    % hObject    handle to hurChoice (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of hurChoice as text
    %        str2double(get(hObject,'String')) returns contents of hurChoice as a double

    user_entry = str2num(get(hObject,'string'));
    if isnan(user_entry) %not effective after str2double -> str2num change..
        errordlg('You must enter a numeric value','Bad Input','modal')
        uicontrol(hObject)
            return
    end
    handles.choice = user_entry;
    %disp(handles.choice)
    guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function hurChoice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hurChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
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

% --- Executes on button press in stepPath.
function stepPath_Callback(hObject, eventdata, handles)
    
    % If the step tracker is outside the range of indices for the current
    % hurricane, set the tracker to the first index for the hurricane
    if(handles.stepPlace < handles.HurricaneIndex(handles.choice,1)...
            || handles.stepPlace > handles.HurricaneIndex(handles.choice,2))

        handles.stepPlace = handles.HurricaneIndex(handles.choice,1);
        handles.plotStop = 0;

        %If first instance of plotting this
        %hurricane, assign; otherwise, append
        if(handles.HurIndexHist == 0) %initial case
            handles.HurIndexHist = handles.choice;
        else
            handles.HurIndexHist = [handles.HurIndexHist,handles.choice];
        end
    end

    %Determine appropriate hurricane category color
    windspeed = handles.hurDat(handles.stepPlace,10);
    if(windspeed <= 95)
        linespec = 'g*'; %category 1
    elseif(windspeed <= 110)
        linespec = 'y*'; %category 2
    elseif(windspeed <= 129)
        linespec = 'c*'; %category 3
    elseif(windspeed <= 156)
        linespec = 'r*'; %category 4
    else
        linespec = 'k*'; %category 5
    end

    % Plot the step, and increment the step tracker
    disp(strcat('plotting point cooresponding to stepPlace:',num2str(handles.stepPlace)))
    if(handles.plotStop == 0)
        handles.points(handles.stepPlace) = plotm(handles.hurDat(handles.stepPlace,6),...
            handles.hurDat(handles.stepPlace,7),linespec,'MarkerSize',8);
        handles.pointsPlotted(handles.stepPlace) = 1; %mark as plotted
    end
    if(handles.stepPlace < handles.HurricaneIndex(handles.choice,2))
        handles.stepPlace = handles.stepPlace + 1;
    else
        disp('Current Hurricane is fully plotted.')
        handles.plotStop = 1; %Step will not plot the last coordinate again
                              %in order to not lose the handle
    end

    guidata(hObject,handles);

end

% --- Executes on button press in plotPath.
function plotPath_Callback(hObject, eventdata, handles)

    if(handles.HurricaneIndex(handles.choice,3) == 0)
        j = handles.HurricaneIndex(handles.choice,1);
        k = handles.HurricaneIndex(handles.choice,2);

        % Append this hurricane to the history "stack"...
        if(handles.HurIndexHist == 0) %initial case
            handles.HurIndexHist = handles.choice;
        else
            handles.HurIndexHist = [handles.HurIndexHist,handles.choice];
        end

        % Iterate over the indeces of hurDat cooresponding to the choice of
        % Hurricane#
        for i=j:k
            %Determine appropriate hurricane category color
            windspeed = handles.hurDat(i,10);
            if(windspeed <= 95)
                linespec = 'g*'; %category 1
            elseif(windspeed <= 110)
                linespec = 'y*'; %category 2
            elseif(windspeed <= 129)
                linespec = 'c*'; %category 3
            elseif(windspeed <= 156)
                linespec = 'r*'; %category 4
            else
                linespec = 'k*'; %category 5
            end

            % Aaaaand plot the coordinate
            handles.points(i) = plotm(handles.hurDat(i,6),handles.hurDat(i,7),...
                linespec,'MarkerSize',8);
            handles.pointsPlotted(i) = 1;
            

        end
        
        % Mark the hurricane as plotted (true) in HurricaneIndex
        handles.HurricaneIndex(handles.choice,3) = 1;
        
    end
    
    guidata(hObject,handles)
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

function inputYear_Callback(hObject, eventdata, handles)

    handles.year = str2double(get(hObject,'String'));
    guidata(hObject,handles);
    
end

% --- Executes during object creation, after setting all properties.
function inputYear_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputYear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end


function inputMonth_Callback(hObject, eventdata, handles)

    handles.month = str2double(get(hObject,'String'));
    guidata(hObject,handles);
    
end

% --- Executes during object creation, after setting all properties.
function inputMonth_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function inputDay_Callback(hObject, eventdata, handles)

    handles.day = str2double(get(hObject,'String'));
    guidata(hObject,handles);

end

% --- Executes during object creation, after setting all properties.
function inputDay_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in dateStep.
function dateStep_Callback(hObject, eventdata, handles)
    
    % Used to decide how specific of a date to start from
    if(isfloat(handles.year))
        yearEntered = true;
    end
    if(isfloat(handles.month))
        monthEntered = true;
    end
    if(isfloat(handles.day))
        dayEntered = true;
    end

    
    
    % TODO: case where only a year or year/month is entered
    if(handles.stepPlace == 0)
        if(yearEntered && monthEntered && dayEntered)
            for i=1:41198 % TODO: Binary Search
                if(handles.hurDat(i,2) == handles.year &&...
                        handles.hurDat(i,3) == handles.month &&...
                        handles.hurDat(i,4) == handles.day)
                    handles.stepPlace = i;
                    handles.choice = handles.hurDat(i,1);
                    %i = 41198; % end the loop
                    break
                end
            end
        %If first instance of plotting this
        %hurricane, assign; otherwise, append
        if(handles.HurIndexHist == 0) %initial case
            handles.HurIndexHist = handles.choice;
        else
            handles.HurIndexHist = [handles.HurIndexHist,handles.choice];
        end    
        % TODO: Case for year/month and only year being entered
        else
            disp('You must enter at least a valid year to use this function')
        end
        
        % Find the lat/lon bounds of the selected hurricane
        currentHurricane = handles.hurDat(handles.stepPlace,1);
        for i=handles.stepPlace + 1:41198
            if(currentHurricane ~= handles.hurDat(i,1))
                handles.coordLimits(1,1) = min(handles.hurDat(handles.stepPlace:i-1, 6));
                handles.coordLimits(1,2) = max(handles.hurDat(handles.stepPlace:i-1, 6));
                handles.coordLimits(2,1) = min(handles.hurDat(handles.stepPlace:i-1, 7));
                handles.coordLimits(2,2) = max(handles.hurDat(handles.stepPlace:i-1, 6));
                break
            end
        end
            
        
        
    end
    
    handles.choice = handles.hurDat(handles.stepPlace);
    


    %Determine appropriate hurricane category color
    
    switch handles.hurDat(handles.stepPlace,12)
        case 5
            color = [0 0 0]; %category 5 (black)
        case 4
            color = [1 0 0]; %category 4 (red)
        case 3
            color = [0 1 0]; %category 3 (green)
        case 2
            color = [0 0 1]; %category 2 (blue)
        case 1
            color = [1 1 0]; %category 1 (yellow)
        case 0
            color = [0 1 1]; %tropical storm (cyan)
        case -1
            color = [1 0 1]; %tropical depression (pink)
        case -2
            color = [0.75 0.75 0.75]; %tropical disturbance (gray)
        case -3
            color = [0 1 1]; %subtropical storm (cyan)
        case -4
            color = [1 0 1]; %subtropical depression (pink)
        case -5
            color = [0 1 1]; %extratropical storm (cyan)
        case -6
            color = [1 0 1]; %extratropical depression (pink)
        case -7
            color = [0.39 0.39 0.78]; %low (purple)
        case -8
            color = [0.9 0.31 0]; %no type specified (orange)
    end

    % Plot the step, and increment the step tracker
    disp(strcat('plotting point cooresponding to stepPlace:',num2str(handles.stepPlace)))
    % some business to create the proper name string for loading eddy
    % bodies
    step = handles.stepPlace;
    year = num2str(handles.hurDat(step,2));
    month = num2str(handles.hurDat(step,3));
    day = num2str(handles.hurDat(step,4));
    [anticycFile, cyclonicFile] = findEddies(year, month, day);

    handles.canvas = zeros(721, 1440, 'uint8');
    
    handles.eddy2 = load(anticycFile);
    handles.eddy1 = load(cyclonicFile);
    
    for i = 1:length(handles.eddy1.eddies)
        handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 1; %cyclonic
    end
    for i = 1:length(handles.eddy2.eddies)
        handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 2;  %anticyclonic
    end

    
    % Function to return min/max value of lat/long, corresponding to current
    % hurricane being plotted, to restrict display of eddy bodies
    [latIndexStart latIndexEnd lonIndexStart lonIndexEnd  ] = findEddyDisplayBoundary(...
    handles.coordLimits, handles.ssh);
    
    tempCanvas = zeros(721,1440, 'uint8');
    
    tempCanvas(latIndexStart:latIndexEnd, lonIndexStart:lonIndexEnd) = ...
        handles.canvas(latIndexStart:latIndexEnd, lonIndexStart:lonIndexEnd);
    
    pcolorm(handles.ssh.lat, handles.ssh.lon, tempCanvas)
    
    if(handles.plotStop == 0)
        handles.points(handles.stepPlace) = plotm(handles.hurDat(handles.stepPlace,6),...
            handles.hurDat(handles.stepPlace,7),'*','MarkerSize',8,'MarkerEdgeColor',...
            color);
        handles.pointsPlotted(handles.stepPlace) = 1; %mark as plotted
    end
    if(handles.stepPlace < handles.HurricaneIndex(handles.choice,2))
        handles.stepPlace = handles.stepPlace + 1;
    else
        disp('Current Hurricane is fully plotted.')
        handles.plotStop = 1; %Step will not plot the last coordinate again
                              %in order to not lose the handle
    end

    guidata(hObject,handles);
    

end

% --- Executes on button press in drawBodies.
function drawBodies_Callback(hObject, eventdata, handles)

    % some business to create the proper name string for loading eddy
    % bodies    
    [anticycFile cyclonicFile] = findEddies(handles.eddyYear, handles.eddyMonth,...
        handles.eddyDay);
    

    handles.canvas = zeros(721, 1440, 'uint8');
    
    handles.eddy2 = load(anticycFile);
    handles.eddy1 = load(cyclonicFile);
    
    for i = 1:length(handles.eddy1.eddies)
        handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 1; %cyclonic
    end
    for i = 1:length(handles.eddy2.eddies)
        handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 2;  %anticyclonic
    end

    
    % Function to return min/max value of lat/long, corresponding to current
    % hurricane being plotted, to restrict display of eddy bodies
    [latIndexStart latIndexEnd lonIndexStart lonIndexEnd  ] = findEddyDisplayBoundary(...
    20, 40, -80, -20, handles.ssh);
    
    tempCanvas = zeros(721,1440, 'uint8');
    
    tempCanvas(latIndexStart:latIndexEnd, lonIndexStart:lonIndexEnd) = ...
        handles.canvas(latIndexStart:latIndexEnd, lonIndexStart:lonIndexEnd);
    
    pcolorm(handles.ssh.lat, handles.ssh.lon, tempCanvas)
    
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

