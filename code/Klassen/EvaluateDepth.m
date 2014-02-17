classdef EvaluateDepth < handle
    %EvaluateDepth Berechnet aus den Temperaturfeldern der Zeitschritte die
    %SchweiÃŸnahttiefe
    %   Detailed explanation goes here
    
    properties
        finishedTask@TaskManager;
        
        fineStepsTFields = [];
        
        checkingMelt = [];
    end
    
    methods
        function this = EvaluateDepth(finTask)
            this.finishedTask = finTask;
        end
        
        function CalcDepth(this, interpD)
            % Überführen in lokale Variablen
            stepsTFields = cell(1, size(this.finishedTask.InputVariParam, 1));
            for i = 1:size(this.finishedTask.InputVariParam, 1)
                if length(this.finishedTask.FinishedTFields) == 2
                    stepsTFields{i} = this.finishedTask.FinishedTFields{i,2};
                elseif length(this.finishedTask.FinishedTFields) == 1 && length(this.finishedTask.FinishedTFields{1,1}) > 2
                    stepsTFields{i} = this.finishedTask.FinishedTFields{i,1};
                else
                    error('Time steps are required.');
                end
            end
            
            stepsDiscretization = this.finishedTask.TimeStepDiscretisation;
            
            % Speichern der Schmelztemperaturen
            meltingTemp = zeros(1, size(this.finishedTask.InputVariParam, 1));
            for i = 1:size(this.finishedTask.InputVariParam, 1)
                meltingTemp(i) = this.finishedTask.InputMaterial(i,6);
            end
            
            
            % Logical Arrays mit Schmelztemperatur für jeden Zeitschritt
            % jedes Versuchs
            for i = 1:size(this.finishedTask.InputVariParam, 1)
                % Interpolieren der erhaltenen Zeitschritte -->
                % gleichmäßiges Netz + logical Array für Tm
                
                % Neue Diskretisierung
                newxLin = linspace(stepsDiscretization{1,i}{1,1}{1,1}(1,1), stepsDiscretization{1,i}{1,1}{1,1}(1,end), interpD);
                newyLin = linspace(stepsDiscretization{1,i}{1,1}{1,2}(1,1), stepsDiscretization{1,i}{1,1}{1,2}(1,end), interpD);
                newzLin = linspace(stepsDiscretization{1,i}{1,1}{1,3}(1,1), stepsDiscretization{1,i}{1,1}{1,3}(1,end), interpD);
                
                [newx, newy, newz] = meshgrid(newxLin, newyLin, newzLin);
                
                newx = reshape(newx, [numel(newx), 1]);
                newy = reshape(newy, [numel(newy), 1]);
                newz = reshape(newz, [numel(newz), 1]);
                
                melt = meltingTemp(i);
                stepsT = stepsTFields{i,1};
                
                stepsDiscParfor = stepsDiscretization{1,i};
                
                checkMelt = zeros(length(newx), length(stepsTFields{i}));
                parfor j = 1:length(stepsTFields{i})
                    % Alte Diskretisierung in richtige Form bringen
                    [oldx, oldy, oldz] = meshgrid(stepsDiscParfor{1,j}{1,1}, ...
                        stepsDiscParfor{1,j}{1,2}, ...
                        stepsDiscParfor{1,j}{1,3});
                    
                    oldx = reshape(oldx, [numel(oldx), 1]);
                    oldy = reshape(oldy, [numel(oldy), 1]);
                    oldz = reshape(oldz, [numel(oldz), 1]);
                    
                    % Durchfühung der Interpolation
                    stepsTFieldInterp = griddata(oldx, oldy, oldz, stepsT{j}, newx, newy, newz);
                    
                    if sum(isnan(stepsTFieldInterp)) ~= 0
                        valueNan = isnan(stepsTFieldInterp);
                        secondInterp = griddata(oldx, oldy, oldz, stepsT{j}, newx, newy, newz, 'nearest');
                        stepsTFieldInterp(valueNan) = secondInterp(valueNan);
                    end
                    
                    % Überprüfen auf Schmelztemperatur
                    checkMelt(:,j) = stepsTFieldInterp > melt;
                end
                
                % Verodern aller Zeitschritte
                checkMelt = any(checkMelt, 2);
                
                % Finden aller Punkte über Schmelztemperatur
                nonzerosEntries = find(checkMelt == 1);
                
                s =  [interpD, interpD, interpD];
                
                % Punkte in Indizes umwandeln
                [I, J, K] = ind2sub(s, nonzerosEntries);
                
                % Bereich für erneute Suche festlegen
                xIdx(2) = newxLin(max(J)+2);
                xIdx(1) = newxLin(min(J)-2);
                
                yIdx(2) = newyLin(max(I)+2);
                yIdx(1) = newyLin(min(I)-2);
                
                zIdx(2) = newzLin(max(K)+2);
                zIdx(1) = newzLin(min(K));
                
                % Erneute Berechnung starten
                [fineStepsFields, againFieldDiskretization] = this.RunAgain(xIdx, yIdx, zIdx, i);
                
                checkMeltAgain = zeros(interpD^3, length(fineStepsFields));
                parfor j = 1:length(fineStepsFields)
                    % Alte Diskretisierung in richtige Form bringen
                    [oldx, oldy, oldz] = meshgrid(againFieldDiskretization{j}{1,1}, ...
                        againFieldDiskretization{j}{1,2}, ...
                        againFieldDiskretization{j}{1,3});
                    
                    oldx = reshape(oldx, [numel(oldx), 1]);
                    oldy = reshape(oldy, [numel(oldy), 1]);
                    oldz = reshape(oldz, [numel(oldz), 1]);
                    
                    % Durchfühung der Interpolation
                    stepsTFieldInterp = griddata(oldx, oldy, oldz, fineStepsFields{j}, newx, newy, newz);
                    
                    checkMeltAgain(:,j) = stepsTFieldInterp > melt;
                end
                
                % Verodern der neuen "genaueren" Punkte
                checkMeltAgain = any(checkMeltAgain, 2);
                
                % Speichern der Ergebnisse
                this.checkingMelt{i,1} = checkMelt;
                this.checkingMelt{i,2} = checkMeltAgain;
                
                this.fineStepsTFields{i} = fineStepsFields;
            end
        end
    end
    
    methods (Access = private)
        function [fineStepsTFields, againFieldDiskretization] = RunAgain(this, xIdx, yIdx, zIdx, versNum)
            againConfig = Config();
            
            % Anpassen an zu wiederholenden Versuch
            againConfig.Oscillation.AmplitudeX = this.finishedTask.InputVariParam(versNum, 1);
            againConfig.Oscillation.AmplitudeY = this.finishedTask.InputVariParam(versNum, 1);
            
            againConfig.Oscillation.FrequencyX = this.finishedTask.InputVariParam(versNum, 2);
            againConfig.Oscillation.FrequencyY = this.finishedTask.InputVariParam(versNum, 2);
            
            againConfig.Oscillation.Velocity = this.finishedTask.InputVariParam(versNum, 3);
            
            againConfig.WeldingParameter.LaserPower = this.finishedTask.InputVariParam(versNum, 4);
            
            againConfig.WeldingParameter.Fokus = this.finishedTask.InputVariParam(versNum, 5);
            
            againConfig.Oscillation.SeamLength = this.finishedTask.InputOscillation(versNum, 1);
            againConfig.Oscillation.Discretization = this.finishedTask.InputOscillation(versNum, 2);
            
            againConfig.Material.ThermalConductivity = this.finishedTask.InputMaterial(versNum, 1);
            againConfig.Material.Density = this.finishedTask.InputMaterial(versNum, 2);
            againConfig.Material.HeatCapacity = this.finishedTask.InputMaterial(versNum, 3);
            againConfig.Material.FresnelEpsilon = this.finishedTask.InputMaterial(versNum, 4);
            againConfig.Material.FusionEnthalpy = this.finishedTask.InputMaterial(versNum, 5);
            againConfig.Material.MeltingTemperature = this.finishedTask.InputMaterial(versNum, 6);
            againConfig.Material.VaporTemperature = this.finishedTask.InputMaterial(versNum, 7);
            againConfig.Material.AmbientTemperature = this.finishedTask.InputMaterial(versNum, 8);
            
            againConfig.ComponentGeo.L = this.finishedTask.InputComponent(versNum, 1);
            againConfig.ComponentGeo.B = this.finishedTask.InputComponent(versNum, 2);
            againConfig.ComponentGeo.D = this.finishedTask.InputComponent(versNum, 3);
            againConfig.ComponentGeo.Dx = this.finishedTask.InputComponent(versNum, 4);
            againConfig.ComponentGeo.Dy = this.finishedTask.InputComponent(versNum, 5);
            againConfig.ComponentGeo.Dz = this.finishedTask.InputComponent(versNum, 6);
            
            againConfig.WeldingParameter.WaveLength = this.finishedTask.InputWelding(versNum, 1);
            againConfig.WeldingParameter.WaistSize = this.finishedTask.InputWelding(versNum, 2);
            
            % Neues Trajektorien Objekt
            againTrajObj = CalcTrajectory(againConfig);
            againTrajObj.CalcOscillation();
            
            % Anpassen des auszuwertenden Bereichs
            oldXgrid = againConfig.ComponentGeo.FieldGrid.X;
            oldYgrid = againConfig.ComponentGeo.FieldGrid.Y;
            oldZgrid = againConfig.ComponentGeo.FieldGrid.Z;
            
            xgrid = linspace(xIdx(1), xIdx(2), length(oldXgrid));
            ygrid = linspace(yIdx(1), yIdx(2), length(oldYgrid));
            zgrid = linspace(zIdx(1), zIdx(2), length(oldZgrid));
            
            [x, y, z] = meshgrid(xgrid, ygrid, zgrid);
            
            newCompMesh = horzcat(reshape(x, numel(x) ,1), ...
                reshape(y, numel(y), 1), ...
                reshape(z, numel(z), 1));
            
            % Übertragen des neuen Netzes auf aktuelles Trajektorien Objekt
            againTrajObj.ComponentMesh = newCompMesh;
            
            % Festlegen der zu berechnenden Schritte
            evalueAgainSteps = 1:1:length(againTrajObj.WeldingTrajectory.X)-1;
            
            % Berechnung der Zeitschritte
            againTimeStepObj = TimeSteps(againConfig, againTrajObj, this.finishedTask.CalibrationStorage{versNum}, evalueAgainSteps);
            againTimeStepObj.Calc('normal');
            
            % Rückgabe der berechneten Zeitschritte
            fineStepsTFields = againTimeStepObj.TFieldTimeStep;
            
            % Rückgabe des verwendeten Netzes
            againFieldDiskretization = againTimeStepObj.AdaptMeshDiscretisation;
        end
    end
    
end
























