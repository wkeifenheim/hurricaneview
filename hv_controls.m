
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

% Last Modified by GUIDE v2.5 03-Sep-2013 12:22:07

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
    
    
    % Counter used so that every step does not need the eddy bodies to be 
    % redrawn (a serious slowdown issue).
    handles.nextEddyDraw = 0;
    
    % used to handle drawing eddy bodies only around the hurricane path
    % Rows: Latitute Longitude
    % Columns: Min Max
    handles.coordLimits = zeros(2);
    
    % Current hurricane #
    handles.choice = 0;

    % Load up the map (coastlines only)
    %worldmap([0 70],[-120 0])
    axesm('pcarre', 'MapLatLimit', [0 70], 'MapLonLimit', [-120 0])
    %load coast
    %plotm(lat,long)
    whitebg('k')
    handles.land = shaperead('landareas', 'UseGeoCoords', true);
    
    % Load ssh lat/lon data
    handles.ssh = load('/project/expeditions/eddies_project_data/ssh_data/data/global_ssh_1992_2011_with_nan.mat',...
        'lat','lon');

    % Choose default command line output for hv_controls
    handles.output = hObject;
    
    % Displays the current X,Y coordinates of the mouse cursor when active
    set(gcf, 'WindowButtonMotionFcn', @mouseMove);

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
    
    if(handles.plotStop == 1)
        errordlg('Current hurricane has been fully plotted');
        return
    end

    offset = 0;
        
    
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
                    break
                end
            end
        
            % If first instance of plotting a
            % hurricane, assign; otherwise append
            if(handles.HurIndexHist == 0) %initial case
                handles.HurIndexHist = handles.choice;
            else
                handles.HurIndexHist = [handles.HurIndexHist,handles.choice];
            end
            
            % Determine the day of the week and draw the first eddy bodies
            step = handles.stepPlace;
            year = num2str(handles.hurDat(step,2));
            month = num2str(handles.hurDat(step,3));
            day = num2str(handles.hurDat(step,4));
            offset = handles.hurDat(step,5)/6 + ((weekday(strcat(year, '-',...
                month, '-', day)) - 1) * 4);
            handles.nextEddyDraw = 28;
            
        % TODO: Case for year/month and only year being entered
        else
            disp('You must enter at least a valid year to use this function')
        end
        
        % Find the lat/lon bounds of the selected hurricane
        currentHurricane = handles.hurDat(handles.stepPlace,1);
        hurricaneIndeces = handles.HurricaneIndex(currentHurricane,:);
        handles.coordLimits = getHurricaneBounds(hurricaneIndeces, handles.hurDat);
        drawEddies()
           
    end
    
    handles.choice = handles.hurDat(handles.stepPlace); % Is the vestigial?
    
    % Keep track of when next to draw eddy bodies
    if(handles.nextEddyDraw == 0)
        drawEddies()
        handles.nextEddyDraw = 28; % Four time steps per day
    else
        handles.nextEddyDraw = handles.nextEddyDraw - 1 - offset;
    end
    
    function drawEddies()

        
        disp('Drawing eddy bodies. This will take a few seconds')
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
            handles.canvas(handles.eddy1.eddies(i).Stats.PixelIdxList) = 1; %cyclonic green
        end
        for i = 1:length(handles.eddy2.eddies)
            handles.canvas(handles.eddy2.eddies(i).Stats.PixelIdxList) = 2;  %anticyclonic red
        end


        % Function to return min/max value of lat/long, corresponding to current
        % hurricane being plotted, to restrict display of eddy bodies
        [latIndexStart latIndexEnd lonIndexStart lonIndexEnd  ] = findEddyDisplayBoundary(...
        handles.coordLimits, handles.ssh);

        tempCanvas = zeros(721,1440, 'uint8');

        tempCanvas(latIndexStart:latIndexEnd, lonIndexStart:lonIndexEnd) = ...
            handles.canvas(latIndexStart:latIndexEnd, lonIndexStart:lonIndexEnd);

        pcolorm(handles.ssh.lat, handles.ssh.lon, tempCanvas)
    end


    %Determine appropriate hurricane category color and plot it
    color = chooseRGB(handles.hurDat(handles.stepPlace,12));
    disp(strcat('plotting point cooresponding to stepPlace:',num2str(handles.stepPlace)))
    if(handles.plotStop == 0)
        handles.points(handles.stepPlace) = plotm(handles.hurDat(handles.stepPlace,6),...
            handles.hurDat(handles.stepPlace,7),'*','MarkerSize',10,'MarkerEdgeColor',...
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
    [anticycFile cyclonicFile] = findEddies(num2str(handles.eddyYear),...
        num2str(handles.eddyMonth), num2str(handles.eddyDay));
    

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


function getHurNum_Callback(hObject, eventdata, handles)

    handles.choice = str2double(get(hObject,'String'));
    guidata(hObject,handles);
    
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

    offset = 0;
    
    
    % If this is the first call to this method..
    if (handles.stepPlace == 0)

        % Get beginning index and retrieve date
        tempIndex = handles.HurricaneIndex(handles.choice,1);
        handles.year = handles.hurDat(tempIndex,2);
        handles.month = handles.hurDat(tempIndex,3);
        handles.day = handles.hurDat(tempIndex,4);
        handles.stepPlace = tempIndex;
        
        % If first instance of plotting a
        % hurricane, assign; otherwise append
        if(handles.HurIndexHist == 0) %initial case
            handles.HurIndexHist = handles.choice;
        else
            handles.HurIndexHist = [handles.HurIndexHist,handles.choice];
        end

        % Determine the day of the week and draw the first eddy bodies
         step = handles.stepPlace;
         year = num2str(handles.hurDat(step,2));
         month = num2str(handles.hurDat(step,3));
         day = num2str(handles.hurDat(step,4));
         offset = handles.hurDat(tempIndex,5)/6 + ((weekday(strcat(year,...
             '-', month, '-', day)) - 1) * 4);
        handles.nextEddyDraw = 28;
        
        % Find the lat/lon bounds of the selected hurricane
        currentHurricane = handles.hurDat(handles.stepPlace,1);
        hurricaneIndeces = handles.HurricaneIndex(currentHurricane,:);
        handles.coordLimits = getHurricaneBounds(hurricaneIndeces, handles.hurDat);
        drawEddies()
        
    end
    
    % Keep track of when next to draw eddy bodies
    if(handles.nextEddyDraw == 0)
        drawEddies()
        handles.nextEddyDraw = 28; % Four time steps per day
    else
        handles.nextEddyDraw = handles.nextEddyDraw - 1 - offset;
    end
    
    function drawEddies()

        
        disp('Drawing eddy bodies. This will take a few seconds')
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

%         tempCanvas = zeros(721,1440, 'uint8');
% 
%         tempCanvas(latIndexStart:latIndexEnd, lonIndexStart:lonIndexEnd) = ...
%             handles.canvas(latIndexStart:latIndexEnd, lonIndexStart:lonIndexEnd);

        pcolorm(handles.ssh.lat, handles.ssh.lon, handles.canvas)
        geoshow(gca, handles.land, 'FaceColor', [1 1 1]);
    end
  
        %Determine appropriate hurricane category color and plot it
    color = chooseRGB(handles.hurDat(handles.stepPlace,12));
    disp(strcat('plotting point cooresponding to stepPlace:',num2str(handles.stepPlace)))
    if(handles.plotStop == 0)
        handles.points(handles.stepPlace) = plotm(handles.hurDat(handles.stepPlace,6),...
            handles.hurDat(handles.stepPlace,7),'o','MarkerSize',10,'MarkerEdgeColor',...
            color, 'MarkerFaceColor',color);
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
