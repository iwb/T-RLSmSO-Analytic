classdef AbstractHeatSource < handle
    %AbstractHeatSource beinhaltet Funktionen und Felder die jede
    %HeatSource ben�tigt z.B.: Spiegelung
    %   Detailed explanation goes here
    
    properties
        TrajectoryInfo@CalcTrajectory;          %Objekt das Informationen �ber die Trajektorien enth�lt
        
        % struct das alle Informationen der W�rmequelle beinhaltet
        HeatSource = struct('TrajectoryData', struct( ...      %Enth�lt Informationen �ber die aktuelle Position der WQ
            'VeloVec', [], ...                %v:        3 x 1 Vektor der Geschwindigkeitkomponenten [m/s]
            'VeloNorm', [], ...               %v_res:    reslutierende Geschwindigkeit [m/s]
            'Position', []), ...          %p_s:      3 x 1 Vektor der Startkoordinaten der WQ [m]
            ...
            'ActivationTime', [], ...            %Zeitpunkt an dem Simulation begonnen wird [s]
            'HeatEmission', [], ...           %q W�rmeleistung der WQ [W]
            'Type', [] ...                    %Typ der WQ [ WQ | WS | SpWQ | SpWS ]
            );
        
        % Cell Array das alle W�rmequellen structs beinhaltet
        HeatSourceField = cell(1,1);
    end
    
    methods (Abstract)
        Calibration(this)
    end
    
    methods
        function this = AbstractHeatSource(trajInfo)
            this.TrajectoryInfo = trajInfo;
            this.HeatSource = this.HeatSource;
        end
        
        function HeatSourceReflection(this, reflectionVector, varargin)
            %% F�r jeden W�rmequelle wird eine W�rmesenke angelegt
            % Die letzte W�rmequelle besitzt keine W�rmesenke
            count = 0;
            for i = length(this.HeatSourceField)+1:2*length(this.HeatSourceField)-1
                count = count + 1;
                %Kopieren der zugeh�rigen WQ
                this.HeatSourceField{i,1} = this.HeatSourceField{count,1};
                %Anpassen des Typs
                this.HeatSourceField{i,1}.Type = 'WS';
                % Umstellung von Quelle auf Senke durch Vorzeichenver�nderung
                this.HeatSourceField{i,1}.HeatEmission = (-1)*this.HeatSourceField{i,1}.HeatEmission;
                %Anpassen der Startzeit
                this.HeatSourceField{i,1}.ActivationTime = this.HeatSourceField{count,1}.ActivationTime - this.TrajectoryInfo.DiscreteTimeStep; %this.TrajectoryInfo.DiscreteTimeVector(length(this.TrajectoryInfo.DiscreteTimeVector) - count); %this.TrajectoryInfo.DiscreteTimeStep * (length(this.TrajectoryInfo.DiscreteTimeVector)-count-1);
            end
            %% Alle W�rmequellen und W�rmesenken werden gespiegelt
            % Test ob reflectionVector die richtige Form besitzt
            if isequal(size(reflectionVector), [1, 3])
                % Aufruf der Funktion zum Spiegeln der W�rmequellen 
                if ~isempty(varargin)
                    %F�r Kalibrierungszwecke
                    this.MirrorHeatSourceField(reflectionVector, varargin{1})
                else
                    %Anderweitig
                    this.MirrorHeatSourceField(reflectionVector)
                end
            else
                error('for the reflection a 1x3 vector is required.')
            end
        end
    end
    
    methods (Access = private)
        function MirrorHeatSourceField(this, reflectionVector, varargin)          %Funktion zur Spiegelung der W�rmequellen
            %Lokale Variable die die Normalenvektoren enth�lt
            N = eye(3);
            for face = 1:length(reflectionVector)                       %Spiegelung um drei Ebenen:yz, xz, xy
                if reflectionVector(face) ~= 0                          %Spiegelung nur durchf�hren falls erforderlich
                    % Anlegen eines Cell-Arrays f�r die sp�tere Verkettung
                    SpWQ = cell(numel(this.HeatSourceField)*reflectionVector(face)*2,1);
                    
                    z = 1;
                    for act = 1:numel(this.HeatSourceField)             %Jede bestehende WQ/WS soll gespiegelt werden
                        for i = 1:reflectionVector(face)                %Anzahl der Spiegelungen ist in reflectionVector enthalten
                            SpWQ{z} = this.HeatSourceField{act,1};
                            
                            distance1 = abs(this.TrajectoryInfo.ComponentMesh(end,face)*((i-1)*(-1))*0.5 - SpWQ{z}.TrajectoryData.Position(face,1));
                            distance2 = abs(this.TrajectoryInfo.ComponentMesh(end,face)*(i-(i-1)*0.5) - SpWQ{z}.TrajectoryData.Position(face,1));
                            
                            if distance1 == 0
                                SpWQ{z}.TrajectoryData.Position(face,1) = -this.TrajectoryInfo.ComponentMesh(end,face);
                            else
                                SpWQ{z}.TrajectoryData.Position(face,1) = SpWQ{z,1}.TrajectoryData.Position(face,1) - abs(2*distance1);
                            end
                            SpWQ{z}.TrajectoryData.VeloVec = SpWQ{z}.TrajectoryData.VeloVec - 2 .* N(face) .* SpWQ{z}.TrajectoryData.VeloVec;
                            SpWQ{z}.Type = ['Sp', SpWQ{z}.Type];
                            
                            z = z + 1;
                            
                            % F�r die Kalibrierung wird ein halbunendlicher
                            % K�rper ben�tigt --> nur einfache Spiegelung
                            % um die z-Achse
                            if isempty(varargin)
                                SpWQ{z} = this.HeatSourceField{act,1};
                                if distance2 == 0
                                    SpWQ{z}.TrajectoryData.Position(face,1) = this.TrajectoryInfo.ComponentMesh(end,face);
                                else
                                    SpWQ{z}.TrajectoryData.Position(face,1) = SpWQ{z,1}.TrajectoryData.Position(face,1) + abs(2*distance2);
                                end
                                SpWQ{z}.TrajectoryData.VeloVec = SpWQ{z}.TrajectoryData.VeloVec - 2 .* N(face) .* SpWQ{z}.TrajectoryData.VeloVec;
                                SpWQ{z}.Type = ['Sp', SpWQ{z}.Type];
                                
                                z = z + 1;
                            end
                        end
                    end
                    this.HeatSourceField = [this.HeatSourceField; SpWQ];
                end
            end
        end
    end
    
end

























