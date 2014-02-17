classdef AbstractSolver < handle
    %AbstractSolver beinhaltet allgemeine Informationen für alle Solver
    %Typen --> unterschiedliche Wärmequellen erfordern unterschiedliche
    %Solver
    %   Detailed explanation goes here
    
    properties
        TemperatureField
    end
    
    methods (Abstract)
        HeatSourceIntegration(this)
    end
    
    methods
        function RunSolver(this, varargin)            
            if isempty(varargin)
                choose = 'seq';
            elseif strcmp(varargin{1}, 'seq')
                choose = 'seq';
            elseif strcmp(varargin{1}, 'par')
                choose = 'par';
            else
                error('As second argument only "seq" or "par" allowed.');
            end
            
            % Übertragen des Netzes auf die Auswertung stattfindet
            componentMesh = this.HeatSourceDefinition.TrajectoryInfo.ComponentMesh; %this.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.FieldGrid.Mesh;
            componentMesh = [componentMesh, ones(size(componentMesh, 1),1)];
            
            ambientTemp = this.HeatSourceDefinition.TrajectoryInfo.Config.Material.AmbientTemperature;
            
            % Initialisieren des Temperaturfeldes
            this.TemperatureField = zeros(size(componentMesh, 1), 1);
            
            % Lokale Variablen für weniger Propertie Zugriffe Sliced Loop
            tempTemperatureField = zeros(size(componentMesh, 1), length(this.HeatSourceDefinition.HeatSourceField)+1);
            N = length(this.HeatSourceDefinition.HeatSourceField);
            
            localVeloVecY = zeros(1, length(this.HeatSourceDefinition.HeatSourceField));
            localVeloVecX = zeros(1, length(this.HeatSourceDefinition.HeatSourceField));
            
            for i = 1:length(this.HeatSourceDefinition.HeatSourceField)
                localVeloVecY(i) = this.HeatSourceDefinition.HeatSourceField{i,1}.TrajectoryData.VeloVec(2,1);
                localVeloVecX(i) = this.HeatSourceDefinition.HeatSourceField{i,1}.TrajectoryData.VeloVec(1,1);
            end
            
            % Flush queue --> Pausieren ermöglichen
            drawnow;
            
            % Unterscheidung ob sequentiell oder parallel gerechnet werden
            % soll
            ticID = tic;
            switch choose
                case 'par'
                    % Schleife über alle Wärmequellen --> (Jede Wärmequelle ist nur zu einem Zeitpunkt aktiv)
                    % Anzeige
                    fprintf('Es werden %d Wärmequellen berechnet.\n', N);
                    parfor i = 1:N
                        
                        % Transformation der Koordinaten der
                        % Auswertepunkte ---> Berechnung der
                        % Orientierungswinkel
                        gamma = atan(localVeloVecY(i)/localVeloVecX(i));
                        
                        % Korrektur des Winkels
                        if localVeloVecX(i) < 0
                            gamma = gamma - pi;
                        elseif localVeloVecX(i) > 0 && localVeloVecY(i) > 0
                            gamma = gamma - 2*pi;
                        end
                        
                        transMesh = (componentMesh * translateMat(this, -this.HeatSourceDefinition.HeatSourceField{i,1}.TrajectoryData.Position(1,1), -this.HeatSourceDefinition.HeatSourceField{i,1}.TrajectoryData.Position(2,1), -this.HeatSourceDefinition.HeatSourceField{i,1}.TrajectoryData.Position(3,1))') * (rotateZ(this, -gamma)');
                        
                        % Berechnung des Temperaturfeldes für jede Wärmequelle
                        tempTemperatureField(:,i) = HeatSourceIntegration(this, transMesh, i);
                    end
                case 'seq'
                    n = 0;
                    for i = 1:N
                        % Transformation der Koordinaten der
                        % Auswertepunkte ---> Berechnung der
                        % Orientierungswinkel
                        gamma = atan(localVeloVecY(i)/localVeloVecX(i));
                        
                        % Korrektur des Winkels
                        if localVeloVecX(i) < 0
                            gamma = gamma - pi;
                        elseif localVeloVecX(i) > 0 && localVeloVecY(i) > 0
                            gamma = gamma - 2*pi;
                        end
                        
                        transMesh = (componentMesh * translateMat(this, -this.HeatSourceDefinition.HeatSourceField{i,1}.TrajectoryData.Position(1,1), -this.HeatSourceDefinition.HeatSourceField{i,1}.TrajectoryData.Position(2,1), -this.HeatSourceDefinition.HeatSourceField{i,1}.TrajectoryData.Position(3,1))') * (rotateZ(this, -gamma)');
                        
                        % Berechnung des Temperaturfeldes für jede Wärmequelle
                        tempTemperatureField(:,i) = HeatSourceIntegration(this, transMesh, i);
                        
                        % Anzeige
                        message = sprintf('Wärmequelle %d/%d berechnet.\n', i, N);
                        fprintf([repmat('\b', [1, n]) message]);
                        n = numel(message);
                    end
            end
            elapsedTime = toc(ticID);
            fprintf('Benötigte Zeit: %1.2f min\n', elapsedTime/60);
            
            % Superposition aller Zeitschritte
            tempTemperatureField(:,end) = sum(tempTemperatureField, 2);
            tempTemperatureField(:,end) = tempTemperatureField(:,end) + ambientTemp;
            
            this.TemperatureField = tempTemperatureField(:,end);
        end
    end
    
    methods (Access = private)
        function Rz = rotateZ(~, gamma)
            Rz = [cos(gamma) -sin(gamma) 0 0;
                  sin(gamma) cos(gamma) 0 0
                  0 0 1 0
                  0 0 0 1];
        end
        
        function Tmat = translateMat(~, dx, dy, dz)
            Tmat = [1 0 0 dx;
                    0 1 0 dy;
                    0 0 1 dz;
                    0 0 0 1];
        end
    end
   
    
end