% GUI die Start- und Stopzeit vom Benutzer erfragt
function [startTime, stopTime, vecTime] = AskSimTime(data)
%% Layout der GUI
% Größe der GUI festlegen
guisize = [400 250];
% Auslesen der Bildschirmauflösung
scrsz = get(0,'ScreenSize');

MainWindow = figure('MenuBar','none', ...
    'Name','Simulationszeit festlegen', ...
    'ToolBar','none','NumberTitle','off', ...
    'Resize', 'Off', ...
    'Position',[.5*(scrsz(3) - guisize(1)),.5*(scrsz(4) - guisize(2)), ...
    guisize(1), guisize(2)]);

h.fig = MainWindow;

h.MainPanel = uipanel('Parent', MainWindow, ...
    'Units', 'normalized',...
    'Position', [0.0, 0.0, 1, 1]);

h.OkButton = uicontrol('Parent', h.MainPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Übernehmen', ...
    'FontSize', 10, ...
    'Units', 'normalized', ...
    'Position', [0.68, 0.05, 0.3, 0.2*0.5], ...
    'Callback', @OkButton);

h.TxtBoxStartTime = uicontrol('Parent', h.MainPanel, ...
    'FontSize', 10, ...
    'Style', 'text', ...
    'String', 'Startzeit der Simulation:', ...
    'Units', 'normalized', ...
    'Position', [0, 0.6, 0.4, 0.1]);

h.TxtDiscretisation = uicontrol('Parent', h.MainPanel, ...
    'FontSize', 10, ...
    'Style', 'text', ...
    'String', 'Anzahl der Zeitschritte:', ...
    'Units', 'normalized', ...
    'Position', [0 0.8 0.4, 0.1]);

h.TxtFieldStartTime = uicontrol('Parent', h.MainPanel, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'Position', [0.4, 0.615, 0.4, 0.15*0.6], ...
    'BackgroundColor', 'w', ...
    'Callback', @CheckStartTime);

h.EnterDiscretesation = uicontrol('Parent', h.MainPanel, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'Position', [0.4, 0.81, 0.4, 0.15*0.6], ...
    'BackgroundColor', 'w');

h.TxtStopTime = uicontrol('Parent', h.MainPanel, ...
    'FontSize', 10, ...
    'Style', 'text', ...
    'String', 'Stopzeit der Simulation:', ...
    'Units', 'normalized', ...
    'Position', [0, 0.38, 0.4, 0.1]);

h.TxtFieldStopTime = uicontrol('Parent', h.MainPanel, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'Position', [0.4, 0.4, 0.4, 0.15*0.6], ...
    'BackgroundColor', 'w', ...
    'Callback', @CheckStopTime);

h.ShowDefault = uicontrol('Parent', h.MainPanel, ...
    'Style', 'pushbutton', ...
    'String', 'Default anzeigen', ...
    'Units', 'normalized', ...
    'Position', [0.01, 0.05, 0.3, 0.2], ...
    'Callback', @showDefault);

% Default Werte für Start und Stop
set(h.TxtFieldStartTime, 'String', num2str(0))
set(h.TxtFieldStopTime, 'String', num2str(data.HeatSourceDefinition.TrajectoryInfo.Config.WeldingParameter.SimulationTime, '%g'))
set(h.EnterDiscretesation, 'String', num2str(1))
h.DefaultStartTime = 0;
h.DefaultStopTime = data.HeatSourceDefinition.TrajectoryInfo.Config.WeldingParameter.SimulationTime;

guidata(MainWindow, h);

uiwait(h.fig)

startTime = h.start;
stopTime = h.stop;
vecTime = h.timeVec;

close(h.fig)

%% Hilfsfunktionen
    function CheckStartTime(hObject, ~)
        h = guidata(hObject);
        
        if str2double(get(h.TxtFieldStartTime, 'String')) < 0
            set(h.TxtFieldStartTime, 'Backgroundcolor', 'r')
            set(h.TxtFieldStartTime, 'String', 'Nur Werte > 0 einsetzen.')
            set(h.OkButton, 'enable', 'off')
        elseif str2double(get(h.TxtFieldStartTime, 'String')) > h.DefaultStopTime
            set(h.TxtFieldStartTime, 'Backgroundcolor', 'r')
            set(h.TxtFieldStartTime, 'String', ['Nur Werte < ' num2str(h.DefaultStopTime) ' einsetzen.'])
            set(h.OkButton, 'enable', 'off')
        elseif isnan(str2double(get(h.TxtFieldStartTime, 'String')))
            set(h.TxtFieldStartTime, 'Backgroundcolor', 'r')
            set(h.TxtFieldStartTime, 'String', 'Nur Zahlen einsetzen.')
            set(h.OkButton, 'enable', 'off')
        else
            set(h.TxtFieldStartTime, 'Backgroundcolor', 'w')
            set(h.TxtFieldStartTime, 'String', get(h.TxtFieldStartTime, 'String'))
            if isequal(get(h.TxtFieldStopTime, 'Backgroundcolor'), [1 1 1])
                set(h.OkButton, 'enable', 'on')
            end
        end
        
        guidata(hObject, h)
        uiwait(h.fig)
    end

    function CheckStopTime(hObject, ~)
        h = guidata(hObject);
        
        if str2double(get(h.TxtFieldStopTime, 'String')) < 0
            set(h.TxtFieldStopTime, 'Backgroundcolor', 'r')
            set(h.TxtFieldStopTime, 'String', 'Nur Werte > 0 einsetzen.')
            set(h.OkButton, 'enable', 'off')
        elseif str2double(get(h.TxtFieldStopTime, 'String')) > h.DefaultStopTime
            set(h.TxtFieldStopTime, 'Backgroundcolor', 'r')
            set(h.TxtFieldStopTime, 'String', ['Nur Werte < ' num2str(h.DefaultStopTime) ' einsetzen.'])
            set(h.OkButton, 'enable', 'off')
        elseif isnan(str2double(get(h.TxtFieldStopTime, 'String')))
            set(h.TxtFieldStopTime, 'Backgroundcolor', 'r')
            set(h.TxtFieldStopTime, 'String', 'Nur Zahlen einsetzen.')
        elseif str2double(get(h.TxtFieldStopTime, 'String')) < str2double(get(h.TxtFieldStartTime, 'String'))
            set(h.OkButton, 'enable', 'off')
            set(h.TxtFieldStopTime, 'Backgroundcolor', 'r')
            set(h.TxtFieldStopTime, 'String', 'Stopzeit >= Startzeit eingeben.')
            set(h.OkButton, 'enable', 'off')
        else
            set(h.TxtFieldStopTime, 'Backgroundcolor', 'w')
            set(h.TxtFieldStopTime, 'String', get(h.TxtFieldStopTime, 'String'))
            if isequal(get(h.TxtFieldStartTime, 'Backgroundcolor'), [1 1 1])
                set(h.OkButton, 'enable', 'on')
            end
        end
        
        guidata(hObject, h)
    end

    function showDefault(hObject, ~)
        h = guidata(hObject);
        
        set(h.TxtFieldStartTime, 'Backgroundcolor', 'w', 'String', num2str(h.DefaultStartTime))
        set(h.TxtFieldStopTime, 'Backgroundcolor', 'w', 'String', num2str(h.DefaultStopTime))
        set(h.OkButton, 'enable', 'on')
        
        guidata(hObject, h)
    end

    function OkButton(hObject, ~)
        h = guidata(hObject);
        
        h.start = str2double(get(h.TxtFieldStartTime, 'String'));
        h.stop = str2double(get(h.TxtFieldStopTime, 'String'));
        
        if strcmp(get(h.EnterDiscretesation, 'String'), '')
            error('Es muss eine Diskretisierung festgelegt werden!')
        else
            discretisation = str2double(get(h.EnterDiscretesation, 'String'));
        end
        
        h.timeVec = linspace(h.start, h.stop, discretisation)';
        
        guidata(hObject, h)
        
        uiresume(h.fig)
    end
end