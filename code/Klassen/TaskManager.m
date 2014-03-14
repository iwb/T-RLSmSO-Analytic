classdef TaskManager < handle
    %TASKMANAGER Organisiert die Auswertung verschiedener
    %Oscillationskonfigurationen
    %   Speichert bereits Parameter von kalibrierten WQ, damit diese evtl.
    %   nicht neu berechnet werden müssen
    
    properties
        InputVariParam = [];            % Beinhaltet den zu varierenden Bereich der Parameter
                                        % 6x3 Matrix --> 
                                        % [Amplitude(min), Amplitude(max), Diskretisierung;
                                        % Frequenz(min), Frequenz(max), Diskretisierung;
                                        % Vorschub(min), Vorschub(max), Diskretisierung;
                                        % Leistung(min), Leistung(max), Diskretisierung;
                                        % Fokuslage(min), Fokuslage(max), Diskretisierung]
                                        % Einschweißtiefe(min), Einschweißtiefe(max), Diskretisierung;
        InputComponent = [];            % Beinhaltet die Abmessungen des Bauteils 3x2 --> nicht variable
        InputOscillation = [];          % Beinhaltet Informationen über die Oszillationsparameter, die nicht variiert werden
        InputMaterial = [];             % Beinhaltet die Materialkennwerte 1x8 --> nicht variable
        InputWelding = [];              % Beinhaltet alle Informationen über die Schweißeinstellungen 1x2 --> nicht variable
        FinishedTFields = [];           % Beinhaltet die fertig gerechneten T-Felder
        ComponentDiscretisation = [];   % Beinhaltet die Bauteil Diskretisierung für das reshapen der T-Felder
        TimeStepDiscretisation = [];    % Beinhaltet die Diskretisierung für jeden Zeitschritt
        CalibrationStorage = [];        % Speichert alle bisherigen kalibrierten Parameter
        ElapsedTime = [];               % Speichert die verstrichene Zeit pro Versuch
        
        Fmins = [];                     % Speichert minimale Frequenzen
        
        Fpattern = [];                  % Speichert pattern der minimalen Frequenz
        
        LogPath = [];
    end
    
    methods
        %% Constructor
        function this = TaskManager(userInputPath, logpath)
            
            % Aufrufen der Pausen GUI
            PauseButton;
            
            [~, ~, inputMode] = fileparts(userInputPath);
            
            switch inputMode
                case '.mat'
                    inputData = load(userInputPath, '-mat');
                    this.InputVariParam = inputData.VariParam;
                    this.InputComponent = inputData.Comp;
                    this.InputMaterial = inputData.Mat;
                    this.InputWelding = inputData.Weld;
                    this.InputOscillation = inputData.Osci;
                case {'.xlsx', '.xls'}
                    [~, sheets] = xlsfinfo(userInputPath);
                    this.InputVariParam = xlsread(userInputPath, sheets{1});
                    this.InputComponent = xlsread(userInputPath, sheets{2});
                    this.InputMaterial = xlsread(userInputPath, sheets{3});
                    this.InputWelding = xlsread(userInputPath, sheets{4});
                    this.InputOscillation = xlsread(userInputPath, sheets{5});
                otherwise
                    error('supported formats are: *.mat, *.xls, *.xlsx');
            end
            
            this.LogPath = logpath;
            
            if exist(logpath, 'file')
                writeOrAppend = input('Logfile überschreiben (w) oder erweitern (a): ', 's');
                
                switch writeOrAppend
                    case 'w'
                        createLog(datestr(now,'mmmm dd, yyyy HH:MM\n\n'), 'w', logpath);
                    case 'a'
                        createLog(datestr(now,'mmmm dd, yyyy HH:MM\n\n'), 'a', logpath);
                end
            else
                createLog(datestr(now,'mmmm dd, yyyy HH:MM\n\n'), 'w', logpath);
            end            
        end
        %% RunTask
        function RunTask(this, varargin)
            % Funktion startet die einzelnen Simulationen und Speichert die
            % Ergebnisse daraus
            
            % Überprüfen der Eingabeparameter varargin
            if length(varargin) > 2
                error('only two extra input parameters allowed.');
            elseif length(varargin) == 1
                timeStep = cell(1,1);
                if strcmp(varargin{1}, 'last')
                    timeStep{1} = varargin{1};
                elseif isfloat(varargin{1})
                    timeStep{1} = varargin{1};
                elseif strcmp(varargin{1}, 'all')
                    timeStep = cell(1,2);
                    timeStep{1} = 'last';
                else
                    error('only keyword "last", "all" or time steps of type <double> allowed.');
                end
            elseif length(varargin) == 2
                timeStep = cell(1,2);
                if strcmp(varargin{1}, 'last')
                    timeStep{1} = varargin{1};
                elseif isfloat(varargin{1})
                    timeStep{2} = varargin{1};
                elseif strcmp(varargin{1}, 'osci')
                    timeStep{2} = 'osci';
                else
                    error('only keyword "last" or time steps of type <double> allowed.');
                end
                
                if strcmp(varargin{2}, 'last')
                    timeStep{1} = varargin{2};
                elseif isfloat(varargin{2})
                    timeStep{2} = varargin{2};
                elseif strcmp(varargin{2}, 'osci')
                    timeStep{2} = varargin{2};
                else
                    error('only keyword "last" or time steps of type <double> allowed.');
                end
            elseif isempty(varargin)
                timeStep{1} = 'last';
            else
                error('no idea what you did but it is not allowed...try again :-).');
            end
            
            % Übertragen in lokale Variablen
            vari = this.InputVariParam;
            mat = this.InputMaterial;
            comp = this.InputComponent;
            weld = this.InputWelding;
            osci = this.InputOscillation;
            
            nOscillations = 3.5;
            
            % Erstellen der benötigten Config-Objekte
            configObjects = cell(1, size(vari, 1));
            for i = 1:size(vari, 1)
                configObjects{i} = Config();
                
                % Anpassen der Config-Objekte
                configObjects{i}.Oscillation.AmplitudeX = vari(i, 1);
                configObjects{i}.Oscillation.AmplitudeY = vari(i, 1);
                
                configObjects{i}.Oscillation.FrequencyX = vari(i, 2);
                configObjects{i}.Oscillation.FrequencyY = vari(i, 2);
                
                configObjects{i}.Oscillation.Velocity = vari(i, 3);
                
                configObjects{i}.WeldingParameter.LaserPower = vari(i, 4);
                
                configObjects{i}.WeldingParameter.Fokus = vari(i, 5);
                
                configObjects{i}.Oscillation.SeamLength = (nOscillations*vari(i, 3))/vari(i, 2);
                configObjects{i}.Oscillation.Discretization = osci(i, 2);
                
                configObjects{i}.Material.ThermalConductivity = mat(i, 1);
                configObjects{i}.Material.Density = mat(i, 2);
                configObjects{i}.Material.HeatCapacity = mat(i, 3);
                configObjects{i}.Material.FresnelEpsilon = mat(i, 4);
                configObjects{i}.Material.FusionEnthalpy = mat(i, 5);
                configObjects{i}.Material.MeltingTemperature = mat(i, 6);
                configObjects{i}.Material.VaporTemperature = mat(i, 7);
                configObjects{i}.Material.AmbientTemperature = mat(i, 8);
                
                configObjects{i}.ComponentGeo.Xstart = comp(i, 1);           %((nOscillations*vari(i, 3))/vari(i, 2))+4*vari(i, 1);
                configObjects{i}.ComponentGeo.Ystart = comp(i, 2);           %(5*vari(i, 1))+0.5e-3;
                configObjects{i}.ComponentGeo.Zstart = comp(i, 3);
                
                configObjects{i}.ComponentGeo.Dx = comp(i, 4);               %configObjects{i}.ComponentGeo.L/nthroot(nElements,3);
                configObjects{i}.ComponentGeo.Dy = comp(i, 5);               %configObjects{i}.ComponentGeo.B/nthroot(nElements,3);
                configObjects{i}.ComponentGeo.Dz = comp(i, 6);               %configObjects{i}.ComponentGeo.D/nthroot(nElements,3);
                
                configObjects{i}.ComponentGeo.Xend = comp(i, 7);
                configObjects{i}.ComponentGeo.Yend = comp(i, 8);
                configObjects{i}.ComponentGeo.Zend = comp(i, 9);
                
                configObjects{i}.WeldingParameter.WaveLength = weld(i, 1);
                configObjects{i}.WeldingParameter.WaistSize = weld(i, 2);
                
                % Speichern der Diskretisierung des Bauteils
                this.ComponentDiscretisation(i,1) = length(configObjects{i}.ComponentGeo.FieldGrid.X);
                this.ComponentDiscretisation(i,2) = length(configObjects{i}.ComponentGeo.FieldGrid.Y);
                this.ComponentDiscretisation(i,3) = length(configObjects{i}.ComponentGeo.FieldGrid.Z);
            end
            
            % Anzeige
            fprintf('Es werden %d Simulationen durchgeführt.\n', length(configObjects));
            fID = fopen(this.LogPath, 'a');
            fprintf(fID, 'Es werden %d Simulationen durchgeführt.\n', length(configObjects));
            fclose(fID);
            
            % Twitter Nachricht
            twitterMSG = sprintf('Es werden %d Simulationen durchgeführt.', size(vari, 1));
            tweet(twitterMSG);
            
            % Funktionsaufruf zum Start der Berechnung
            if length(timeStep) == 1
                % preallocation
                completeSimTime = nan(1, length(configObjects));
                for i = 1:length(configObjects)
                    
                    [this.FinishedTFields{i,1}, this.CalibrationStorage{i}] = this.RunProcedure(configObjects{i}, timeStep, i);
                    
                    % Anzeige
                    fprintf('\n\n%d/%d Simulationen abgeschlossen.\n\n', i, length(configObjects));
                    fID = fopen(this.LogPath, 'a');
                    fprintf(fID, '\n\n%d/%d Simulationen abgeschlossen.\n', i, length(configObjects));
                    
                    if isfield(this.ElapsedTime, 'TField')
                        completeSimTime(i) = sum(cell2mat(this.ElapsedTime.Calibration(i,:)));
                        completeSimTime(i) = completeSimTime(i) + sum(cell2mat(this.ElapsedTime.TField(i,:)));
                    elseif isfield(this.ElapsedTime, 'TimeSteps')
                        completeSimTime(i) = sum(cell2mat(this.ElapsedTime.Calibration(i,:)));
                        completeSimTime(i) = completeSimTime(i) + sum(cell2mat(this.ElapsedTime.TimeSteps(i,:)));
                    else
                        warning('estimated remaining time could not be calculated.');
                    end
                    
                    % Berechnung der Zeit
                    myTime = (nanmean(completeSimTime)*size(vari, 1))-nansum(completeSimTime);
                    
                    fprintf(fID, 'Benötigte Zeit in Stunden für letzte Simulation: %.2f\n', completeSimTime(i)/(60*60));
                    fprintf(fID, 'Verbleibende Zeit in Stunden: %.2f\n', myTime/(60*60));
                    fprintf(fID, ['Geschätztes Ende der Simulation: ' datestr((myTime/(60*60*24))+now, 'mmmm dd, yyyy HH:MM:SS') '\n\n']);
                    fclose(fID);
                    
                    % Twitter Nachricht
                    twitterMSG = sprintf(['%d/%d abgeschlossen.'...
                        '\nBenötigte Zeit für letzte Simulation: %.2fh\n'...
                        'Ende aller Simulationen: ' ...
                        datestr((myTime/(60*60*24))+now, 'mmmm dd, yyyy HH:MM:SS')], ...
                        i, size(vari, 1), completeSimTime(i)/(60*60));
                    
                    tweet(twitterMSG);
                    
                    % Nach jeder Iteration den Workspace sichern
                    save('..\storage\BackupWS');
                end
            else
                if isfloat(timeStep{2})
                    % preallocation
                    completeSimTime = nan(1, length(configObjects));
                    for i = 1:length(configObjects)
                        
                        [this.FinishedTFields{i,1}, this.CalibrationStorage{i}, this.FinishedTFields{i,2}] = this.RunProcedure(configObjects{i}, timeStep, i);
                        
                        % Anzeige
                        fprintf('\n\n%d/%d Simulationen abgeschlossen.\n\n', i, length(configObjects));
                        fID = fopen(this.LogPath, 'a');
                        fprintf(fID, '\n\n%d/%d Simulationen abgeschlossen.\n', i, length(configObjects));
                        
                        completeSimTime(i) = sum(cell2mat(this.ElapsedTime.Calibration(i,:)));
                        completeSimTime(i) = completeSimTime(i) + sum(cell2mat(this.ElapsedTime.TField(i,:)));
                        completeSimTime(i) = completeSimTime(i) + sum(cell2mat(this.ElapsedTime.TimeSteps(i,:)));
                        
                        % Berechnung der Zeit
                        myTime = (nanmean(completeSimTime)*size(vari, 1))-nansum(completeSimTime);
                        
                        fprintf(fID, 'Benötigte Zeit in Stunden für letzte Simulation: %.2f\n', completeSimTime(i)/(60*60));
                        fprintf(fID, 'Verbleibende Zeit in Stunden: %.2f\n', myTime/(60*60));
                        fprintf(fID, ['Geschätztes Ende der Simulation: ' datestr((myTime/(60*60*24))+now, 'mmmm dd, yyyy HH:MM:SS') '\n\n']);
                        fclose(fID);
                        
                        % Twitter Nachricht
                        twitterMSG = sprintf(['%d/%d abgeschlossen.'...
                            '\nBenötigte Zeit für letzte Simulation: %.2fh\n'...
                            'Ende aller Simulationen: ' ...
                            datestr((myTime/(60*60*24))+now, 'mmmm dd, yyyy HH:MM:SS')], ...
                            i, size(vari, 1), completeSimTime(i)/(60*60));
                        
                        tweet(twitterMSG);
                        
                        % Nach jeder Iteration den Workspace sichern
                        save('..\storage\BackupWS');
                    end
                elseif strcmp(timeStep{2}, 'osci')
                    % preallocation
                    completeSimTime = nan(1, length(configObjects));
                    for i = 1:length(configObjects)
                        tempOsciTrajObj = CalcTrajectory(configObjects{i});
                        tempOsciTrajObj.CalcOscillation();
                        timeStep{2} = this.largerZero(length(tempOsciTrajObj.WeldingTrajectory.X)-(osci(i,2))):1:length(tempOsciTrajObj.WeldingTrajectory.X)-1;
                        clear tempOsciTrajObj
                        
                        [this.FinishedTFields{i,1}, this.CalibrationStorage{i}, this.FinishedTFields{i,2}] = this.RunProcedure(configObjects{i}, timeStep, i);
                        
                        % Anzeige
                        fprintf('\n\n%d/%d Simulationen abgeschlossen.\n\n', i, length(configObjects));
                        fID = fopen(this.LogPath, 'a');
                        fprintf(fID, '\n\n%d/%d Simulationen abgeschlossen.\n', i, length(configObjects));
                        
                        completeSimTime(i) = sum(cell2mat(this.ElapsedTime.Calibration(i,:)));
                        completeSimTime(i) = completeSimTime(i) + sum(cell2mat(this.ElapsedTime.TField(i,:)));
                        completeSimTime(i) = completeSimTime(i) + sum(cell2mat(this.ElapsedTime.TimeSteps(i,:)));
                        
                        % Berechnung der Zeit
                        myTime = (nanmean(completeSimTime)*size(vari, 1))-nansum(completeSimTime);
                        
                        fprintf(fID, 'Benötigte Zeit in Stunden für letzte Simulation: %.2f\n', completeSimTime(i)/(60*60));
                        fprintf(fID, 'Verbleibende Zeit in Stunden: %.2f\n', myTime/(60*60));
                        fprintf(fID, ['Geschätztes Ende der Simulation: ' datestr((myTime/(60*60*24))+now, 'mmmm dd, yyyy HH:MM:SS') '\n\n']);
                        fclose(fID);
                        
                        % Twitter Nachricht
                        twitterMSG = sprintf(['%d/%d abgeschlossen.'...
                            '\nBenötigte Zeit für letzte Simulation: %.2fh\n'...
                            'Ende aller Simulationen: ' ...
                            datestr((myTime/(60*60*24))+now, 'mmmm dd, yyyy HH:MM:SS')], ...
                            i, size(vari, 1), completeSimTime(i)/(60*60));
                        
                        tweet(twitterMSG);
                        
                        % Nach jeder Iteration den Workspace sichern
                        save('..\storage\BackupWS');
                    end
                else
                    error('Only "osci" or time steps allowed as arguments.')
                end
            end
            
        end
        %% Minimale Frequenz
        function Findfmin(this, zlayer, freqBound)            
            % Übertragen in lokale Variablen
            vari = this.InputVariParam;
            mat = this.InputMaterial;
            weld = this.InputWelding;
            osci = this.InputOscillation;
			
			anzIter = 3;
            nOscillations = 50;
            nElements = 4000;
            
            % Anzeige
            fprintf('Es werden %d Simulationen durchgeführt.\n', size(vari, 1));
            fID = fopen(this.LogPath, 'a');
            fprintf(fID, 'Es werden %d Simulationen durchgeführt.\n', size(vari, 1));
            fclose(fID);
            
            % Twitter Nachricht
            twitterMSG = sprintf('Es werden %d Simulationen durchgeführt.', size(vari, 1));
            tweet(twitterMSG);
            
            if ~isequal(size(freqBound), [1 2])
                error('Frequency bound must be a 1x2 Vector.');
            end
            
            freqBound = sort(freqBound);
            
            % preallocation
            completeSimTime = nan(1, size(vari, 1));
            this.Fpattern = cell(size(vari, 1),1);
            %Erstellen der benötigten Config-Objekte
            configObjects = cell(1, size(vari, 1));
            for i = 1:size(vari, 1)
                configObjects{i} = Config();
                
                % Anpassen der Config-Objekte
                configObjects{i}.Oscillation.AmplitudeX = vari(i, 1);
                configObjects{i}.Oscillation.AmplitudeY = vari(i, 1);
                
                configObjects{i}.Oscillation.FrequencyX = vari(i, 2);
                configObjects{i}.Oscillation.FrequencyY = vari(i, 2);
                
                configObjects{i}.Oscillation.Velocity = vari(i, 3);
                
                configObjects{i}.WeldingParameter.LaserPower = vari(i, 4);
                
                configObjects{i}.WeldingParameter.Fokus = vari(i, 5);
                
                configObjects{i}.Oscillation.SeamLength = (nOscillations*vari(i, 3))/freqBound(1);
                configObjects{i}.Oscillation.Discretization = osci(i, 2);
                
                configObjects{i}.Material.ThermalConductivity = mat(i, 1);
                configObjects{i}.Material.Density = mat(i, 2);
                configObjects{i}.Material.HeatCapacity = mat(i, 3);
                configObjects{i}.Material.FresnelEpsilon = mat(i, 4);
                configObjects{i}.Material.FusionEnthalpy = mat(i, 5);
                configObjects{i}.Material.MeltingTemperature = mat(i, 6);
                configObjects{i}.Material.VaporTemperature = mat(i, 7);
                configObjects{i}.Material.AmbientTemperature = mat(i, 8);
                
                configObjects{i}.ComponentGeo.L = ((nOscillations*vari(i, 3))/freqBound(1))+2.5*vari(i, 1);
                configObjects{i}.ComponentGeo.B = (3.5*vari(i, 1))+0.5e-3;
                configObjects{i}.ComponentGeo.D = zlayer;
                
                anzX = floor(sqrt(nElements/(configObjects{i}.ComponentGeo.B/configObjects{i}.ComponentGeo.L)));
                anzY = anzX * (configObjects{i}.ComponentGeo.B/configObjects{i}.ComponentGeo.L);
                
                configObjects{i}.ComponentGeo.Dx = configObjects{i}.ComponentGeo.L/anzX;
                configObjects{i}.ComponentGeo.Dy = configObjects{i}.ComponentGeo.B/anzY;
                configObjects{i}.ComponentGeo.Dz = zlayer;
                configObjects{i}.ComponentGeo.startD = zlayer;
                
                configObjects{i}.WeldingParameter.WaveLength = weld(i, 1);
                configObjects{i}.WeldingParameter.WaistSize = weld(i, 2);
                
                % Speichern der Diskretisierung des Bauteils
                this.ComponentDiscretisation(i,1) = length(configObjects{i}.ComponentGeo.FieldGrid.X);
                this.ComponentDiscretisation(i,2) = length(configObjects{i}.ComponentGeo.FieldGrid.Y);
                this.ComponentDiscretisation(i,3) = length(configObjects{i}.ComponentGeo.FieldGrid.Z);
                
				initI = 1/anzIter * (freqBound(2) - freqBound(1));
                
				% Eigener PatternSearch
				%Startwerte
                meltingTemp = mat(i, 6);
				loopfmin = 0;
				this.Fpattern{i}.points = zeros(anzIter,3);
				this.Fpattern{i}.points(1,:) = [((freqBound(2) + freqBound(1))/2) - (initI/2), (freqBound(2) + freqBound(1))/2, ((freqBound(2) + freqBound(1))/2) + (initI/2)];
				this.Fpattern{i}.checkPoints = false(1,3);
				for ii = 1:anzIter
					if ii >= 2
						newFreqLog = ~ismember(this.Fpattern{i}.points(ii-1,:), this.Fpattern{i}.points(ii,:));
					else
						newFreqLog = true(1,anzIter);
					end
					
					newFreqIdx = 1:1:anzIter;
					newFreqIdx = newFreqIdx(newFreqLog);
					
					for iii = newFreqIdx
						loopfmin = loopfmin + 1;
						
						% Anzeige
						fprintf('\nBerechnung der %d/%d Simulation bei %d. Solver Aufruf\n\n', i, size(vari, 1), loopfmin);
						fID = fopen(this.LogPath, 'a');
						fprintf(fID, '\nBerechnung der %d/%d Simulation bei %d. Solver Aufruf\n\n', i, size(vari, 1), loopfmin);
						fclose(fID);
						
						% Twitter Nachricht
						twitterMSG = sprintf('Berechnung der %d/%d Simulation bei %d. Solver Aufruf', i, size(vari, 1), loopfmin);
						tweet(twitterMSG);
						
						
						% Übertragen der Frequenz
						configObjects{i}.Oscillation.FrequencyX = this.Fpattern{i}.points(ii,iii);
						configObjects{i}.Oscillation.FrequencyY = this.Fpattern{i}.points(ii,iii);
						
						% Anpassen der Schweißnahtlänge auf neue Frequenz
						configObjects{i}.Oscillation.SeamLength = (nOscillations*configObjects{i}.Oscillation.Velocity)/this.Fpattern{i}.points(ii,iii);
						
						% Berechnung aller Zeitschritte
						timeStep = cell(1,2);
						timeStep{1} = 'last';
						tempOsciTrajObj = CalcTrajectory(configObjects{i});
						tempOsciTrajObj.CalcOscillation();
						timeStep{2} = this.largerZero(length(tempOsciTrajObj.WeldingTrajectory.X)-(osci(i,2))):1:length(tempOsciTrajObj.WeldingTrajectory.X)-1;
						clear tempOsciTrajObj
						
						% Berechnen der neuen T-Felder
						[this.FinishedTFields{i,loopfmin,1}, this.CalibrationStorage{i,loopfmin}, this.FinishedTFields{i,loopfmin,2}] = this.RunProcedure(configObjects{i},timeStep,i,loopfmin);
						
						% Interpolation aller Temperaturfelder auf
						% einheitliches Grid
						newxLin = linspace(this.TimeStepDiscretisation{i,loopfmin}{1,1}{1,1}(1,1), this.TimeStepDiscretisation{i,loopfmin}{1,1}{1,1}(1,end), 320);
						newyLin = linspace(this.TimeStepDiscretisation{i,loopfmin}{1,1}{1,2}(1,1), this.TimeStepDiscretisation{i,loopfmin}{1,1}{1,2}(1,end), 320);
						
						[newx, newy] = meshgrid(newxLin, newyLin);
						
						newx = reshape(newx, [numel(newx), 1]);
						newy = reshape(newy, [numel(newy), 1]);
						
						% Interpolation des letzten Zeitschrittes
						[oldx, oldy] = meshgrid(0:configObjects{i}.ComponentGeo.Dx:configObjects{i}.ComponentGeo.L, 0:configObjects{i}.ComponentGeo.Dy:configObjects{i}.ComponentGeo.B);
						oldx = reshape(oldx, [numel(oldx), 1]);
						oldy = reshape(oldy, [numel(oldy), 1]);
						
						Finterp = scatteredInterpolant(oldx, oldy, this.FinishedTFields{i,loopfmin,1}, 'linear', 'linear');
						TFieldInterp = Finterp(newx, newy);
						
						checkMelt = false(length(TFieldInterp), length(this.TimeStepDiscretisation{i,loopfmin})+1);
						checkMelt(:,end) = TFieldInterp > meltingTemp;
						
						% Für Parallelisierung
						stepsDiscParfor = this.TimeStepDiscretisation{i,loopfmin};
						stepsT = this.FinishedTFields{i,loopfmin,2};
						
						for j = 1:length(this.TimeStepDiscretisation{i,loopfmin})
							[oldx, oldy] = meshgrid(stepsDiscParfor{1,j}{1,1}, ...
								stepsDiscParfor{1,j}{1,2}, ...
								stepsDiscParfor{1,j}{1,3});
							
							oldx = reshape(oldx, [numel(oldx), 1]);
							oldy = reshape(oldy, [numel(oldy), 1]);
							
							Finterp = scatteredInterpolant(oldx, oldy, stepsT{j}, 'linear', 'linear');
							TFieldInterp = Finterp(newx, newy);
							
							checkMelt(:,j) = TFieldInterp > meltingTemp;
						end
						
						% Verodern aller Zeitschritte
						checkMelt = any(checkMelt, 2);
						
						checkMelt = reshape(checkMelt, [length(newyLin), length(newxLin)]);
						
						% Übertragen in Feld für Speicherung
						this.Fmins{i, loopfmin} = checkMelt;
						
						% Finden der verbundenen Komponenten
						connectedComp = bwconncomp(checkMelt);
						
						% Weitere Test für Anpassung
						regionStats = regionprops(checkMelt, {'Solidity', 'EulerNumber'});
						
						if connectedComp.NumObjects == 1 && regionStats.Solidity >= 0.9 && regionStats.EulerNumber == 1
							this.Fpattern{i}.checkPoints(ii,iii) = true;
						else
							this.Fpattern{i}.checkPoints(ii,iii) = false;
						end
						
					end
                    
                    % Bestimmung der neuen Frequenzen
                    if sum(this.Fpattern{i}.checkPoints(ii,:)) == 1
                        this.Fpattern{i}.points(ii+1,2) = this.Fpattern{i}.points(ii, this.Fpattern{i}.checkPoints(ii,:));
                        this.Fpattern{i}.points(ii+1,1) = this.Fpattern{i}.points(ii+1,2) - ((this.Fpattern{i}.points(ii,3)-this.Fpattern{i}.points(ii,1))/4);
                        this.Fpattern{i}.points(ii+1,3) = this.Fpattern{i}.points(ii+1,2) + ((this.Fpattern{i}.points(ii,3)-this.Fpattern{i}.points(ii,1))/4);
                    elseif sum(this.Fpattern{i}.checkPoints(ii,:)) == 2
                        this.Fpattern{i}.points(ii+1,2) = sum(this.Fpattern{i}.points(ii, this.Fpattern{i}.checkPoints(ii,:)))/2;
                        this.Fpattern{i}.points(ii+1,1) = this.Fpattern{i}.points(ii+1,2) - ((this.Fpattern{i}.points(ii,2)-this.Fpattern{i}.points(ii,1))*1.25);
                        this.Fpattern{i}.points(ii+1,3) = this.Fpattern{i}.points(ii+1,2) + ((this.Fpattern{i}.points(ii,2)-this.Fpattern{i}.points(ii,1))*1.25);
                    elseif sum(this.Fpattern{i}.checkPoints(ii,:)) == 0 || sum(this.Fpattern{i}.checkPoints(ii,:)) == 3
                        this.Fpattern{i}.points(ii+1,2) = this.Fpattern{i}.points(ii,2);
                        this.Fpattern{i}.points(ii+1,1) = this.Fpattern{i}.points(ii+1,2) - ((this.Fpattern{i}.points(ii,2)-this.Fpattern{i}.points(ii,1))+initI/2);
                        this.Fpattern{i}.points(ii+1,3) = this.Fpattern{i}.points(ii+1,2) + ((this.Fpattern{i}.points(ii,2)-this.Fpattern{i}.points(ii,1))+initI/2);
                    else
                        error('unexpected length of checkPoints');
                    end
                    
                    % Frequenz darf angegebenen Bereich nicht verlassen
                    if this.Fpattern{i}.points(ii+1,1) < freqBound(1)
                        this.Fpattern{i}.points(ii+1,1) = freqBound(1);
                    end
                    
                    if this.Fpattern{i}.points(ii+1,3) > freqBound(2)
                        this.Fpattern{i}.points(ii+1,3) = freqBound(2);
                    end
                    
                    % Übertragen der Pattern Logic
                    this.Fpattern{i}.checkPoints(ii+1,:) = this.Fpattern{i}.checkPoints(ii,:);
				end
                
                % Anzeige
                fprintf('\n\n%d/%d Simulationen abgeschlossen.\n\n', i, size(vari, 1));
                
                fID = fopen(this.LogPath, 'a');
                fprintf(fID, '\n\n%d/%d Simulationen abgeschlossen.\n', i, size(vari, 1));
                
                completeSimTime(i) = sum(cell2mat(this.ElapsedTime.Calibration(i,:)));
                completeSimTime(i) = completeSimTime(i) + sum(cell2mat(this.ElapsedTime.TField(i,:)));
                completeSimTime(i) = completeSimTime(i) + sum(cell2mat(this.ElapsedTime.TimeSteps(i,:)));
                
                % Berechnung der Zeit
                myTime = (nanmean(completeSimTime)*size(vari, 1))-nansum(completeSimTime);
                
                fprintf(fID, 'Benötigte Zeit in Stunden für letzte Simulation: %.2f\n', completeSimTime(i)/(60*60));
                fprintf(fID, 'Verbleibende Zeit in Stunden: %.2f\n', myTime/(60*60));
                fprintf(fID, ['Geschätztes Ende der Simulation: ' datestr((myTime/(60*60*24))+now, 'mmmm dd, yyyy HH:MM:SS') '\n\n']);
                fclose(fID);
                
                % Twitter Nachricht
                twitterMSG = sprintf(['%d/%d abgeschlossen.'...
                    '\nBenötigte Zeit für letzte Simulation: %.2fh\n'...
                    'Ende aller Simulationen: ' ...
                    datestr((myTime/(60*60*24))+now, 'mmmm dd, yyyy HH:MM:SS')], ...
                    i, size(vari, 1), completeSimTime(i)/(60*60));
                
                tweet(twitterMSG);
            end
            
        end
    end
    
    methods (Access = private)
        %% Hilfsfunktion für Minimierung der Frequenz
        function fvalue = runFmin(this, currentFreq, configObjects, meltingTemp, osciCount, freqBound, nOscillations, simQuant, simCount)
            persistent loopfmin simchangefmin;
            
            if isempty(loopfmin) || (simchangefmin - simCount ~= 0)
                loopfmin = 1;
            end
            
            simchangefmin = simCount;
            
            % Anzeige
            fprintf('\nBerechnung der %d/%d Simulation bei %d. Solver Aufruf\n\n', simCount, simQuant, loopfmin);
            fID = fopen(this.LogPath, 'a');
            fprintf(fID, '\nBerechnung der %d/%d Simulation bei %d. Solver Aufruf\n\n', simCount, simQuant, loopfmin);
            fclose(fID);
            
            % Twitter Nachricht
            twitterMSG = sprintf('Berechnung der %d/%d Simulation bei %d. Solver Aufruf', simCount, simQuant, loopfmin);
            tweet(twitterMSG);
            
            % Speichern der minimalen Frequenz
            this.Fmins{simCount, loopfmin, 1} = currentFreq;
            
            % Übertragen der Frequenz
			configObjects{simCount}.Oscillation.FrequencyX = currentFreq;
			configObjects{simCount}.Oscillation.FrequencyY = currentFreq;
            
            % Anpassen der Schweißnahtlänge auf neue Frequenz
            configObjects{simCount}.Oscillation.SeamLength = (nOscillations*configObjects{simCount}.Oscillation.Velocity)/currentFreq;
            
            % Berechnung aller Zeitschritte
            timeStep = cell(1,2);
            timeStep{1} = 'last';
            tempOsciTrajObj = CalcTrajectory(configObjects{simCount});
            tempOsciTrajObj.CalcOscillation();
            timeStep{2} = this.largerZero(length(tempOsciTrajObj.WeldingTrajectory.X)-(osciCount)):1:length(tempOsciTrajObj.WeldingTrajectory.X)-1;
            clear tempOsciTrajObj
            
            % Berechnen der neuen T-Felder
            [this.FinishedTFields{simCount,loopfmin,1}, this.CalibrationStorage{simCount,loopfmin}, this.FinishedTFields{simCount,loopfmin,2}] = this.RunProcedure(configObjects{simCount}, timeStep, simCount, loopfmin);
            
            % Interpolation aller Temperaturfelder auf
            % einheitliches Grid
            newxLin = linspace(this.TimeStepDiscretisation{simCount,loopfmin}{1,1}{1,1}(1,1), this.TimeStepDiscretisation{simCount,loopfmin}{1,1}{1,1}(1,end), 320);
            newyLin = linspace(this.TimeStepDiscretisation{simCount,loopfmin}{1,1}{1,2}(1,1), this.TimeStepDiscretisation{simCount,loopfmin}{1,1}{1,2}(1,end), 320);
            
            [newx, newy] = meshgrid(newxLin, newyLin);
            
            newx = reshape(newx, [numel(newx), 1]);
            newy = reshape(newy, [numel(newy), 1]);
            
            % Interpolation des letzten Zeitschrittes
            [oldx, oldy] = meshgrid(0:configObjects{simCount}.ComponentGeo.Dx:configObjects{simCount}.ComponentGeo.L, 0:configObjects{simCount}.ComponentGeo.Dy:configObjects{simCount}.ComponentGeo.B);
            oldx = reshape(oldx, [numel(oldx), 1]);
            oldy = reshape(oldy, [numel(oldy), 1]);
            
            Finterp = scatteredInterpolant(oldx, oldy, this.FinishedTFields{simCount,loopfmin,1}, 'linear', 'linear');
            TFieldInterp = Finterp(newx, newy);
            
            checkMelt = false(length(TFieldInterp), length(this.TimeStepDiscretisation{simCount,loopfmin})+1);
            checkMelt(:,end) = TFieldInterp > meltingTemp;
            
            % Für Parallelisierung
            stepsDiscParfor = this.TimeStepDiscretisation{simCount,loopfmin};
            stepsT = this.FinishedTFields{simCount,loopfmin,2};
            
            for j = 1:length(this.TimeStepDiscretisation{simCount,loopfmin})
                [oldx, oldy] = meshgrid(stepsDiscParfor{1,j}{1,1}, ...
                    stepsDiscParfor{1,j}{1,2}, ...
                    stepsDiscParfor{1,j}{1,3});
                
                oldx = reshape(oldx, [numel(oldx), 1]);
                oldy = reshape(oldy, [numel(oldy), 1]);
                
                Finterp = scatteredInterpolant(oldx, oldy, stepsT{j}, 'linear', 'linear');
                TFieldInterp = Finterp(newx, newy);
                
                checkMelt(:,j) = TFieldInterp > meltingTemp;
            end
            
            % Verodern aller Zeitschritte
            checkMelt = any(checkMelt, 2);
            
            checkMelt = reshape(checkMelt, [length(newyLin), length(newxLin)]);
            
            % Übertragen in Feld für Speicherung
            this.Fmins{simCount, loopfmin, 2} = checkMelt;
            
            % Finden der verbundenen Komponenten
            connectedComp = bwconncomp(checkMelt);
            
            % Weitere Test für Anpassung
            regionStats = regionprops(checkMelt, {'Solidity', 'EulerNumber'});
            
            if connectedComp.NumObjects == 1 && regionStats.Solidity >= 0.9 && regionStats.EulerNumber == 1
                fvalue = currentFreq;
            else
                fvalue = 2*freqBound(2) - currentFreq;
            end
            
            % Abschluss einer Iteration
            loopfmin = loopfmin + 1;
        end
        
        
        %% Ablauf der Simulation
        function [outputTField, calibrationObj, varargout] = RunProcedure(this, configObject, timeStep, simCount, varargin)
            if isempty(varargin)
                varargin{1} = 1;
            end
            
            % Erzeugen eines Trajektorien-Objekts und der passenden
            % Oszillationstrajektorie
            osciTrajectoryObj = CalcTrajectory(configObject);
            osciTrajectoryObj.CalcOscillation();
            
            % Falls "all" für timeStep gewählt wurde muss timeStep{2}
            % befüllt werden
            if length(timeStep) == 2
                if isempty(timeStep{2})
                    timeStep{2} = 1:1:length(osciTrajectoryObj.WeldingTrajectory.X)-1;
                end
            end
            
            % Erzeugen der skalierten Größen
            scaledConfigObj = ScaledConfig(configObject);
            scaledConfigObj.Scale();
            
            % Erzeugen der T-Felder für die Kalibrierung
            reducedModelObj = ReducedModel(scaledConfigObj, 1:1:configObject.Oscillation.Discretization);
            reducedModelObj.CalcEntireTFields();
            
            % Kalibrierung wird vorbereitet
            caliHScell = PrepCalibration(reducedModelObj);
            
            % Durchführung der Kalibrierung
            calticID = tic;
            
            calibrationObj = Calibration(reducedModelObj, caliHScell);
            calibrationObj.Calibrating();
            
            this.ElapsedTime.Calibration{simCount, varargin{1}} = toc(calticID);
            
            % Evtl Berechnung von Zeitschritten
            if length(timeStep) == 1
                if ischar(timeStep{1})
                    % Kalibrierung wird auf WQ übertragen und anschließend evtl.
                    % gespiegelt
                    doubleEllipHSObj = DoubleEllipHeatSource(osciTrajectoryObj);
                    doubleEllipHSObj = MatchCaliHS(calibrationObj, doubleEllipHSObj);
                    doubleEllipHSObj.HeatSourceReflection([0 0 2]);
                    
                    % Erzeugen des Solver und Berechnung des T-Feldes
                    doubleEllipSolverObj = DoubleEllipSolver(doubleEllipHSObj);
                    
                    tfieldticID = tic;
                    doubleEllipSolverObj.RunSolver('par');
                    this.ElapsedTime.TField{simCount, varargin{1}} = toc(tfieldticID);
                    
                    % Rückgabe
                    outputTField = doubleEllipSolverObj.TemperatureField;
                else
                    % Berechnung der Zeitschritte
                    timeStepObj = TimeSteps(configObject, osciTrajectoryObj, calibrationObj, timeStep{1});
                    
                    timestepsticID = tic;
                    
                    timeStepObj.Calc('adapted');
                    
                    this.ElapsedTime.TimeSteps{simCount, varargin{1}} = toc(timestepsticID);
                    
                    outputTField = timeStepObj.TFieldTimeStep;
                    this.TimeStepDiscretisation{simCount, varargin{1}} = timeStepObj.AdaptMeshDiscretisation;
                end
            else
                % Berechnung des letzten Zeitschrittes
                
                %Kalibrierung wird auf WQ übertragen und anschließend evtl.
                %gespiegelt
                doubleEllipHSObj = DoubleEllipHeatSource(osciTrajectoryObj);
                doubleEllipHSObj = MatchCaliHS(calibrationObj, doubleEllipHSObj);
                doubleEllipHSObj.HeatSourceReflection([0 0 2]);
                
                %Erzeugen des Solver und Berechnung des T-Feldes
                doubleEllipSolverObj = DoubleEllipSolver(doubleEllipHSObj);
                
                tfieldticID = tic;
                doubleEllipSolverObj.RunSolver('par');
                this.ElapsedTime.TField{simCount, varargin{1}} = toc(tfieldticID);
                
                %Rückgabe
                outputTField = doubleEllipSolverObj.TemperatureField;
                
                % Berechnung der Zeitschritte
                timeStepObj = TimeSteps(configObject, osciTrajectoryObj, calibrationObj, timeStep{2});
                
                timestepsticID = tic;
                
                timeStepObj.Calc('adapted');
                
                this.ElapsedTime.TimeSteps{simCount, varargin{1}} = toc(timestepsticID);
                
                varargout{1} = timeStepObj.TFieldTimeStep;
                this.TimeStepDiscretisation{simCount, varargin{1}} = timeStepObj.AdaptMeshDiscretisation;
            end
        end
        
        function value = largerZero(~, input)
            if input <= 0
                value = 1;
            else
                value = input;
            end
        end
    end
    
    
end

