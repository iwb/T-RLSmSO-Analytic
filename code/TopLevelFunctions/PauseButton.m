function PauseButton
%PauseButton Summary of this function goes here
%   Detailed explanation goes here

%% Layout der GUI
% Größe der GUI festlegen
guisize = [250 70];
% Auslesen der Bildschirmauflösung
scrsz = get(0,'ScreenSize');

MainWindow = figure('MenuBar','none', ...
    'Name','Pause Execution', ...
    'ToolBar','none','NumberTitle','off', ...
    'Resize', 'Off', ...
    'Position',[.5*(scrsz(3) - guisize(1)),.5*(scrsz(4) - guisize(2)), ...
    guisize(1), guisize(2)]);

h.fig = MainWindow;

h.MainPanel = uipanel('Parent', h.fig, ...
    'Units', 'normalized',...
    'Position', [0.0, 0.0, 1, 1]);

h.PauseButton = uicontrol('Parent', h.MainPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Pause', ...
    'FontSize', 10, ...
    'Units', 'normalized', ...
    'Position', [0.25, 0.25, 0.5, 0.5], ...
    'Callback', @PauseButton);

drawnow;

guidata(MainWindow, h)

%% Hilfsfunktionen
    function PauseButton(hObject, ~)
        h = guidata(hObject);
        
        set(h.PauseButton, 'Enable', 'off');
        EnterDebugger();
        set(h.PauseButton, 'Enable', 'on');
        drawnow;
        
        guidata(hObject, h)
    end

end

