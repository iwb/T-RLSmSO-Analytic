classdef TimeSteps < handle
    %CalcTimeSteps Berechnet die einzelnen Zeitschritte
    
    properties
        OriConfig@Config;
        
        WQTraj@DoubleEllipHeatSource;
        
        CaliWQ@Calibration;
        
        TimeStepArray = [];
        
        TFieldTimeStep = [];
        
        AdaptMeshDiscretisation = [];
    end
    
    methods
        function this = TimeSteps(confi, traj, cali, timeSteps)
            if isempty(traj.DiscreteTimeVector)
                error('Oscillation trajectory required.');
            else
                this.WQTraj = DoubleEllipHeatSource(traj);
                
                % Überprüfen ob timeSteps gültig sind
                if max(timeSteps) >= length(this.WQTraj.HeatSourceField)
                    error('Max number of time steps was exceeded. Only %d allowed', length(this.WQTraj.HeatSourceField)-1);
                elseif min(timeSteps) <= 0
                    error('Only positiv values are allowed for time steps.');
                else
                    this.TimeStepArray = timeSteps;
                end
            end
            
            this.CaliWQ = cali;
            this.OriConfig = confi;
        end
        
        function Calc(this, meshType)
            % Lokale Variablen
            oriConfig = this.OriConfig;
            wqTraj = this.WQTraj;
            cali = this.CaliWQ;
            timeSteps = this.TimeStepArray;
            timeSteps = sort(timeSteps, 'descend');
            
            wqTrajCopies = cell(1, length(timeSteps));
            % Erzeugen von Kopien des WQTraj Objektes
            loop = 0;
            for i = timeSteps
                loop = loop + 1;
                % Erstellen eines Config Objektes
                copyConfig = Config();
                
                % Anpassen des Config Objektes
                copyConfig.Oscillation.AmplitudeX = oriConfig.Oscillation.AmplitudeX;
                copyConfig.Oscillation.AmplitudeY = oriConfig.Oscillation.AmplitudeY;
                
                copyConfig.Oscillation.FrequencyX = oriConfig.Oscillation.FrequencyX;
                copyConfig.Oscillation.FrequencyY = oriConfig.Oscillation.FrequencyY;
                
                copyConfig.Oscillation.Velocity = oriConfig.Oscillation.Velocity;
                
                copyConfig.WeldingParameter.LaserPower = oriConfig.WeldingParameter.LaserPower;
                
                copyConfig.WeldingParameter.Fokus = oriConfig.WeldingParameter.Fokus;
                
                copyConfig.Oscillation.SeamLength = oriConfig.Oscillation.SeamLength;
                copyConfig.Oscillation.Discretization = oriConfig.Oscillation.Discretization;
                
                copyConfig.Material.ThermalConductivity = oriConfig.Material.ThermalConductivity;
                copyConfig.Material.Density = oriConfig.Material.Density;
                copyConfig.Material.HeatCapacity = oriConfig.Material.HeatCapacity;
                copyConfig.Material.FresnelEpsilon = oriConfig.Material.FresnelEpsilon;
                copyConfig.Material.FusionEnthalpy = oriConfig.Material.FusionEnthalpy;
                copyConfig.Material.MeltingTemperature = oriConfig.Material.MeltingTemperature;
                copyConfig.Material.VaporTemperature = oriConfig.Material.VaporTemperature;
                copyConfig.Material.AmbientTemperature = oriConfig.Material.AmbientTemperature;
                
                copyConfig.ComponentGeo.Xstart = oriConfig.ComponentGeo.Xstart;
                copyConfig.ComponentGeo.Ystart = oriConfig.ComponentGeo.Ystart;
                copyConfig.ComponentGeo.Zstart = oriConfig.ComponentGeo.Zstart;
                
                copyConfig.ComponentGeo.Dx = oriConfig.ComponentGeo.Dx;
                copyConfig.ComponentGeo.Dy = oriConfig.ComponentGeo.Dy;
                copyConfig.ComponentGeo.Dz = oriConfig.ComponentGeo.Dz;
                
                copyConfig.ComponentGeo.Xend = oriConfig.ComponentGeo.Xend;
                copyConfig.ComponentGeo.Yend = oriConfig.ComponentGeo.Yend;
                copyConfig.ComponentGeo.Zend = oriConfig.ComponentGeo.Zend;
                
                copyConfig.WeldingParameter.WaveLength = oriConfig.WeldingParameter.WaveLength;
                copyConfig.WeldingParameter.WaistSize = oriConfig.WeldingParameter.WaistSize;
                
                % Erzeugen des Trajektorien Objektes
                copyTraj = CalcTrajectory(copyConfig);
                copyTraj.CalcOscillation();
                
                % Erzeugen des WQ Objektes
                wqTrajCopies{loop} = DoubleEllipHeatSource(copyTraj);
                
                % Entfernen der nicht benötigten WQ für den jeweiligen
                % Zeitschritt
                wqTrajCopies{loop}.HeatSourceField(i+1:end) = [];
                emptyidx = cellfun(@isempty, wqTrajCopies{loop}.HeatSourceField);
                wqTrajCopies{loop}.HeatSourceField(emptyidx) = [];
                
                % Anpassung der ActivationTime der verbliebenen WQs
                for j = 1:length(wqTrajCopies{loop}.HeatSourceField)
                    wqTrajCopies{loop}.HeatSourceField{j}.ActivationTime = wqTraj.TrajectoryInfo.DiscreteTimeVector(length(wqTrajCopies{loop}.HeatSourceField)+1 - j);
                end
            end
            
            % Übertragen der Kalibrierten WQ
            this.TFieldTimeStep = cell(1, length(wqTrajCopies));
            for i = 1:length(wqTrajCopies)
                wqTrajCopies{i} = MatchCaliHS(cali, wqTrajCopies{i});
                
                % Anpassung des Netzes
                switch meshType
                    case 'normal'
                        wqTrajCopies{i}.TrajectoryInfo.ComponentMesh = wqTraj.TrajectoryInfo.ComponentMesh;
                        this.AdaptMeshDiscretisation{i} = {linspace(min(wqTraj.TrajectoryInfo.ComponentMesh(:,1)), max(wqTraj.TrajectoryInfo.ComponentMesh(:,1)), length(wqTraj.TrajectoryInfo.Config.ComponentGeo.FieldGrid.X)), ...
                            linspace(min(wqTraj.TrajectoryInfo.ComponentMesh(:,2)), max(wqTraj.TrajectoryInfo.ComponentMesh(:,2)), length(wqTraj.TrajectoryInfo.Config.ComponentGeo.FieldGrid.Y)), ...
                            linspace(min(wqTraj.TrajectoryInfo.ComponentMesh(:,3)), max(wqTraj.TrajectoryInfo.ComponentMesh(:,3)), length(wqTraj.TrajectoryInfo.Config.ComponentGeo.FieldGrid.Z))};
                    case 'adapted'
                        [wqTrajCopies{i}.TrajectoryInfo.ComponentMesh, this.AdaptMeshDiscretisation{i}] = adaptMesh( ...
                            wqTrajCopies{i}.HeatSourceField{end,1}.TrajectoryData.Position', ...
                            linspace(min(wqTraj.TrajectoryInfo.ComponentMesh(:,1)), max(wqTraj.TrajectoryInfo.ComponentMesh(:,1)), length(wqTraj.TrajectoryInfo.Config.ComponentGeo.FieldGrid.X)), ...
                            linspace(min(wqTraj.TrajectoryInfo.ComponentMesh(:,2)), max(wqTraj.TrajectoryInfo.ComponentMesh(:,2)), length(wqTraj.TrajectoryInfo.Config.ComponentGeo.FieldGrid.Y)), ...
                            linspace(min(wqTraj.TrajectoryInfo.ComponentMesh(:,3)), max(wqTraj.TrajectoryInfo.ComponentMesh(:,3)), length(wqTraj.TrajectoryInfo.Config.ComponentGeo.FieldGrid.Z)));
                end
                
                wqTrajCopies{i}.HeatSourceReflection([0, 0, 2]);
                
                % Zeitmessen für Tweet
                ticID = tic;
                
                % Solver Objekte erstellen
                wqTrajSolver = DoubleEllipSolver(wqTrajCopies{i});
                wqTrajSolver.RunSolver('seq');
                
                twitterTime = toc(ticID);
                
                % Anzeige
                fprintf('Zeitschritt %d/%d abgeschlossen.\n\n', i, length(wqTrajCopies));
                
                % Twitter Nachricht
                if twitterTime >= 15*60
                    twitterMSG = sprintf('Zeitschritt %d/%d abgeschlossen.\n\n', i, length(wqTrajCopies));
                    tweet(twitterMSG);
                end
                
                this.TFieldTimeStep{i} = wqTrajSolver.TemperatureField(:,end);
            end
        end
    end
    
    
end

