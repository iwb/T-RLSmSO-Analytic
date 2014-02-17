classdef DoubleEllipHeatSource < AbstractHeatSource
    %DoubleEllipHeatSource beinhaltet die Kalibrierung einer Wärmequelle
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = DoubleEllipHeatSource(trajInfo)
            this = this@AbstractHeatSource(trajInfo);
            
            if ~isfield(this.TrajectoryInfo.WeldingTrajectory, 'X')
                error('one trajectory object is required.')
            end
            
            % Hinzufügen der Geometrischen Beschreibung der Wärmequelle (Standartwerte vor Kalibrierung)
            this.HeatSource.GeoDescription = struct('Cxf', 1e-7, ...
                'Cxb', 1e-7, ...
                'Cy', 1e-7, ...
                'Cz', 1e-3);
            
            % Hinzufügen von "q" (Standartwert vor Kalibrierung)
            this.HeatSource.HeatEmission = 250;
            
            % Die Trajektorieninformationen werden in das HeatSourceField
            % übertragen
            MatchTrajInfo(this)
        end
        
        function Calibration(this)
        end
    end
    
    methods (Access = private)
        function MatchTrajInfo(this)
            %% Initialisieren der HeatSource
            % Speichern der Position
            this.HeatSource.TrajectoryData.Position = ...
                [this.TrajectoryInfo.WeldingTrajectory.X(1,1); this.TrajectoryInfo.WeldingTrajectory.Y(1,1); this.TrajectoryInfo.WeldingTrajectory.Z(1,1)];
            
            % Speichern des Geschwindigkeitsvektors
            this.HeatSource.TrajectoryData.VeloVec = ...
                [this.TrajectoryInfo.WeldingTrajectory.TrueVeloX(1,1); this.TrajectoryInfo.WeldingTrajectory.TrueVeloY(1,1); 0];
            
            % Speichern der resultierenden Geschwindigkeit
            this.HeatSource.TrajectoryData.VeloNorm = ...
                norm([this.TrajectoryInfo.WeldingTrajectory.TrueVeloX(1,1); this.TrajectoryInfo.WeldingTrajectory.TrueVeloY(1,1)]);
            
            % Der Wärmequellentyp wird auf WQ gesetzt
            this.HeatSource.Type = 'WQ';
            
            %% Für jede Position in den Trajektorien Informationen wird eine Wärmequelle der Form HeatSource angelegt
            % Initialisieren des HeatSourceFields
            this.HeatSourceField = cell(length(this.TrajectoryInfo.WeldingTrajectory.X),1);
            
            for i = 1:length(this.TrajectoryInfo.WeldingTrajectory.X)
                % Jedes Feld wird zunächst mit einer HeatSource
                % initialisiert
                this.HeatSourceField{i,1} = this.HeatSource;
                
                % Anpassen des Aktivierungszeitpunktes
                this.HeatSourceField{i,1}.ActivationTime = this.TrajectoryInfo.DiscreteTimeVector((length(this.TrajectoryInfo.DiscreteTimeVector) - i)+1); %this.TrajectoryInfo.DiscreteTimeStep * (length(this.TrajectoryInfo.DiscreteTimeVector)-i);
                
                % Die Trajektorien Informationen werden angepasst
                this.HeatSourceField{i,1}.TrajectoryData.Position = ...
                    [this.TrajectoryInfo.WeldingTrajectory.X(i,1); this.TrajectoryInfo.WeldingTrajectory.Y(i,1); this.TrajectoryInfo.WeldingTrajectory.Z(i,1)];
                
                this.HeatSourceField{i,1}.TrajectoryData.VeloVec = ...
                    [this.TrajectoryInfo.WeldingTrajectory.TrueVeloX(i,1); this.TrajectoryInfo.WeldingTrajectory.TrueVeloY(i,1); 0];
                
                this.HeatSourceField{i,1}.TrajectoryData.VeloNorm = ...
                    norm(this.HeatSourceField{i,1}.TrajectoryData.VeloVec);
            end
        end
    end
    
end

