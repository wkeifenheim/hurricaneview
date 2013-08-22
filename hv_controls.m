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

% Last Modified by GUIDE v2.5 22-Aug-2013 11:27:44

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

%Contents from HurricaneView_init.m
s = load('HurDat_1851_2010.mat');
handles.hurDat = s.hurDat;
handles.points = zeros(1,41198);   % using handles attaches
                                   % negligable performance hit
                                  

%Create a 1442x2 matrix containing the indeces of a specific hurricane
%in the hurDat matrix

handles.HurricaneIndex = zeros([1442,2]);

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

%Load up the map
load coast
axesm mollweid
framem('FEdgeColor','blue','FLineWidth',0.5)
plotm(lat,long,'LineWidth',1,'Color','blue')

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

function hurChoice_Callback(hObject, eventdata, handles)
% hObject    handle to hurChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hurChoice as text
%        str2double(get(hObject,'String')) returns contents of hurChoice as a double

user_entry = str2double(get(hObject,'string'));
if isnan(user_entry)
    errordlg('You must enter a numeric value','Bad Input','modal')
    uicontrol(hObject)
        return
end
handles.choice = user_entry;
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

% --- Executes on button press in clearMap.
function clearMap_Callback(hObject, eventdata, handles)
% hObject    handle to clearMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Establish which was the last hurricane to be plotted
n = size(handles.HurIndexHist,2);
mostRecentPlot = handles.HurIndexHist(n);

% Use index to find range of handles to delete
try
    j = handles.HurricaneIndex(mostRecentPlot,1);
    k = handles.HurricaneIndex(mostRecentPlot,2);
    for i=j:k
        delete(handles.points(i));
    end
catch err
    disp('caught it, we`re good')
end
    
% "Pop" the most recent value from the history
if(n == 1) % Last remaining plotted hurricane
    handles.HurIndexHist = 0;
else
    handles.HurIndexHist = handles.HurIndexHist(1:n-1);
end

guidata(hObject,handles);

end

% --- Executes on button press in stepPath.
function stepPath_Callback(hObject, eventdata, handles)
% hObject    handle to stepPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --- Executes on button press in plotPath.
function plotPath_Callback(hObject, eventdata, handles)
% hObject    handle to plotPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
    handles.points(i) = plotm(handles.hurDat(i,6),handles.hurDat(i,7),linespec);
    
end
guidata(hObject,handles)
end
