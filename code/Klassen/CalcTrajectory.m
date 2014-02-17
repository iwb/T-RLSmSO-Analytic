classdef CalcTrajectory < handle
    %CalcTrajectory ermöglicht die Berechnung der Schweißtrajektorie
    %   Detailed explanation goes here
    
    properties
        WeldingTrajectory = struct; %Enthält die Schweißtrajektorie
        
        ComponentMesh = [];         %Enthält das Netz auf die Wärmequelle bewegt bzw. ausgewertet wird
        
        DebugPlot = struct();
    end
    
    properties
        Config@Config;
        DiscreteTimeStep;           %Zeitschrittweite [s]
        DiscreteTimeVector;         %Vektor der die Zeitschritte enthält
    end
    
    methods
        function this = CalcTrajectory(config)
            this.Config = config;
        end
        
        function CalcOscillation(this)
            %% Übertragung des ComponentMesh aus dem Config-Objekt
            this.ComponentMesh = this.Config.ComponentGeo.FieldGrid.Mesh;
            
            %% Berechnung des Passenden Zeitvektors
            this.DiscreteTimeStep = 1/(this.Config.Oscillation.Discretization * ...
                max(this.Config.Oscillation.FrequencyX, this.Config.Oscillation.FrequencyY));
            
            this.DiscreteTimeVector = (this.DiscreteTimeStep:this.DiscreteTimeStep:this.Config.Oscillation.WeldingTime)';
            
            %% Berechnung der Koordinatenpunkte
            this.WeldingTrajectory.X = this.Config.Oscillation.Velocity .* ...
                this.DiscreteTimeVector + this.Config.Oscillation.AmplitudeX * ...
                sin(2 * pi * this.Config.Oscillation.FrequencyX .* this.DiscreteTimeVector + ...
                this.Config.Oscillation.PhiX);   %x-Komponenten [m]
            
            this.WeldingTrajectory.Y = this.Config.Oscillation.AmplitudeY * ...
                sin(2 * pi * this.Config.Oscillation.FrequencyY .* this.DiscreteTimeVector + ...
                this.Config.Oscillation.PhiY);   %y-Komponente [m]
            
            this.WeldingTrajectory.Z = ones(length(this.WeldingTrajectory.X),1) .* this.Config.WeldingParameter.Fokus;    %Auslesen der z-Ebene [m]
            
            % Verschiebung des Koordinatenursprungs nach (0, 0)
            this.WeldingTrajectory.X = this.WeldingTrajectory.X + ...
                abs(min(this.WeldingTrajectory.X));
            this.WeldingTrajectory.Y = this.WeldingTrajectory.Y + ...
                abs(min(this.WeldingTrajectory.Y));
            
            % Verschieben in die Mitte des Bauteils falls dies groß genug ist
            if this.Config.ComponentGeo.L > max(this.WeldingTrajectory.X) && this.Config.ComponentGeo.B > max(this.WeldingTrajectory.Y)
                disX = max(this.WeldingTrajectory.X);
                this.WeldingTrajectory.X = this.WeldingTrajectory.X + (this.Config.ComponentGeo.L - disX)/2;
                disY = max(this.WeldingTrajectory.Y);
                this.WeldingTrajectory.Y = this.WeldingTrajectory.Y + (this.Config.ComponentGeo.B - disY)/2;
            else
                warning('work piece is too small for selected trajectory.');
                createLog('\nwork piece is too small for selected trajectory.\n', 'a');
                
                disX = max(this.WeldingTrajectory.X);
                this.WeldingTrajectory.X = this.WeldingTrajectory.X + (this.Config.ComponentGeo.L - disX)/2;
                disY = max(this.WeldingTrajectory.Y);
                this.WeldingTrajectory.Y = this.WeldingTrajectory.Y + (this.Config.ComponentGeo.B - disY)/2;
            end
            
            %% Berechnung der Bahngeschwindigkeiten
            this.WeldingTrajectory.TrueVeloX = this.Config.Oscillation.Velocity + 2 * ...
                pi * this.Config.Oscillation.FrequencyX * this.Config.Oscillation.AmplitudeX * ...
                cos(2 * pi * this.Config.Oscillation.FrequencyX .* this.DiscreteTimeVector + ...
                this.Config.Oscillation.PhiX);   %x-Geschwindigkeit
            
            this.WeldingTrajectory.TrueVeloY = 2 * pi * this.Config.Oscillation.FrequencyY * ...
                this.Config.Oscillation.AmplitudeY * cos(2 * pi * this.Config.Oscillation.FrequencyY .* ...
                this.DiscreteTimeVector + this.Config.Oscillation.PhiY); %y-Geschwindigkeit
            
            this.WeldingTrajectory.TrueVeloNorm = sqrt(sum([this.WeldingTrajectory.TrueVeloX.^2, this.WeldingTrajectory.TrueVeloY.^2], 2));
            
            % Übertragung der Bahngeschwindigkeit in Config-Klasse
            this.Config.WeldingParameter.TrueVelocityNorm = this.WeldingTrajectory.TrueVeloNorm;
        end
        
        function CalcManualTraj(this)
            % Übertragung des ComponentMesh aus dem Config-Objekt
            this.ComponentMesh = this.Config.ComponentGeo.FieldGrid.Mesh;
            
            % Aufruf der GUI zum Zeichnen der Trajektorie
            [lineCoords, seamLength, discretisation, velocity] = ...
                DrawTrajectory(this.Config.ComponentGeo.L, this.Config.ComponentGeo.B);
            
            lineCoords = cell2mat(lineCoords);
            
            % Speicherung der Koordinaten
            this.WeldingTrajectory.X = [];
            this.WeldingTrajectory.Y = [];
            for i = 1:length(lineCoords)/2
                tempX = linspace(lineCoords(2*i-1,1), lineCoords(2*i,1), discretisation)';
                tempY = linspace(lineCoords(2*i-1,2), lineCoords(2*i,2), discretisation)';
                
                this.WeldingTrajectory.X = [this.WeldingTrajectory.X; tempX];
                this.WeldingTrajectory.Y = [this.WeldingTrajectory.Y; tempY];
            end
            this.WeldingTrajectory.Z = zeros(length(this.WeldingTrajectory.X),1);
            
            % Berechnung des zugehörigen Zeitschrittes
            this.DiscreteTimeStep = (seamLength/velocity)/length(this.WeldingTrajectory.X);
            
            % Berechnung des Passenden Zeitvektors
            this.DiscreteTimeVector = (this.DiscreteTimeStep:this.DiscreteTimeStep:seamLength/velocity)';
            
            % Berechnung der Bahngeschwindigkeiten
            this.WeldingTrajectory.TrueVeloX = zeros(length(this.WeldingTrajectory.X),1);
            this.WeldingTrajectory.TrueVeloY = zeros(length(this.WeldingTrajectory.X),1);
            for i = 1:length(this.WeldingTrajectory.X) - 1
                this.WeldingTrajectory.TrueVeloX(i,1) = (this.WeldingTrajectory.X(i+1) - this.WeldingTrajectory.X(i))/this.DiscreteTimeStep;
                this.WeldingTrajectory.TrueVeloY(i,1) = (this.WeldingTrajectory.Y(i+1) - this.WeldingTrajectory.Y(i))/this.DiscreteTimeStep;
            end
            % Letzte Geschwindigkeit wird gleich der vorletzten gesetzt
            this.WeldingTrajectory.TrueVeloX(end,1) = this.WeldingTrajectory.TrueVeloX(end-1,1);
            this.WeldingTrajectory.TrueVeloY(end,1) = this.WeldingTrajectory.TrueVeloY(end-1,1);
            
            % Betrag der Geschwindigkeit
            this.WeldingTrajectory.TrueVeloNorm = sqrt(sum([this.WeldingTrajectory.TrueVeloX.^2, this.WeldingTrajectory.TrueVeloY.^2], 2));
            % Übertragung der Bahngeschwindigkeit in Config-Klasse
            this.Config.WeldingParameter.TrueVelocityNorm = this.WeldingTrajectory.TrueVeloNorm;
        end
        
        function CalibrationTraj(this, settings, currentVelo, posKeyhole)            
            % Trajectorie der WQ fängt vor dem auszuwertenden T-Feld an
            prev = 1.5;
            
            % Bestimmung der Anzahl der WQ aufgrund der Länge der
            % Trajektorie
            n = floor((abs(settings.X(posKeyhole) - settings.X(1)*prev)*15e3));
            
            [x, y, z] = meshgrid(settings.X, settings.Y, settings.Z);
            
            this.ComponentMesh = horzcat(reshape(x, numel(x), 1), ...
                reshape(y, numel(y), 1), ...
                reshape(z, numel(z), 1));
            
            % Übertragung der Ortsvektoren
            this.WeldingTrajectory.X = linspace(settings.X(1)*prev, settings.X(posKeyhole), n)';
            this.WeldingTrajectory.Y = zeros(length(this.WeldingTrajectory.X), 1);
            this.WeldingTrajectory.Z = zeros(length(this.WeldingTrajectory.X), 1);
            
            % Übertragung der Geschwindigkeitsvektoren
            this.WeldingTrajectory.TrueVeloX = repmat(currentVelo, length(this.WeldingTrajectory.X), 1);
            this.WeldingTrajectory.TrueVeloY = zeros(length(this.WeldingTrajectory.X), 1);
            this.WeldingTrajectory.TrueVeloNorm = this.WeldingTrajectory.TrueVeloX;
            
            trip = abs(settings.X(posKeyhole) - settings.X(1)*prev);
            
            % Übertragung des Zeitvektors            
            this.DiscreteTimeStep = (trip/currentVelo)/n;
            this.DiscreteTimeVector = (this.DiscreteTimeStep:this.DiscreteTimeStep:trip/currentVelo)';
        end
    end
    
    
end