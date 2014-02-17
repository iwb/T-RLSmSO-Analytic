classdef Calibration < handle
    %CALIBRATION Ermöglicht das Kalibrieren einzelner Wärmequellen
    %   Detailed explanation goes here
    
    properties
        ReducedModel@ReducedModel;      % Reduziertes Model
        
        HeatSources = [];               % Die zu kalibrierenden WQ-Felder
        
        CalibratedHS = [];              % Enthält die kalibrierten WQ
        
        WQoutput = [];                  % Enthält die eingebrachte Leistung der WQ
        
        Rsquared = [];
    end
    
    methods
        function this = Calibration(redModel, hsField)
            this.ReducedModel = redModel;
            this.HeatSources = hsField;
        end
        
        function Calibrating(this)
            % Laden der Datenbank
            load('..\Einstellungen\caliHSDataBase');
            
            % Überführen in lokale Variablen
            hs = this.HeatSources;
            
            % Erzeugen der nötigen Solver-Objects --> zweite Spalte enthält
            % struct mit den zugehörigen geometrischen Parametern
            caliSolver = cell(length(hs), 2);
            for i = 1:size(caliSolver, 1)
                caliSolver{i,1} = DoubleEllipSolver(hs{i});
            end
            
            % Überführen in lokale Variable
            caliTField = this.ReducedModel.EntireFields;
            keyholeGeo = this.ReducedModel.KeyholeGeo;
            w0 = this.ReducedModel.Scaled.Config.WeldingParameter.WaistSize;
            keyDz = this.ReducedModel.KeyDz;
            
            % Anzeige
            fprintf('Beginn der Kalibrierung.\n');
            
            for i = 1:size(caliSolver, 1)
                % Überführen von Temperaturen zur Skallierung in lokale Var
                local = struct();
                local.ambientT = caliSolver{i,1}.HeatSourceDefinition.TrajectoryInfo.Config.Material.AmbientTemperature;
                local.vaporT = caliSolver{i,1}.HeatSourceDefinition.TrajectoryInfo.Config.Material.VaporTemperature;
                local.w0 = caliSolver{i,1}.HeatSourceDefinition.TrajectoryInfo.Config.WeldingParameter.WaistSize;
                local.lambda = caliSolver{i,1}.HeatSourceDefinition.TrajectoryInfo.Config.Material.ThermalConductivity;
                
                % Suchen nach passenden kalibrierten WQ in Datenbank
                matchCaliWQ = find(hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1)-0.001 <= caliHSDataBase(:,7) & ...
                    caliHSDataBase(:,7) <= hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1)+0.001 & ...
                    hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower-5 <= caliHSDataBase(:,6) & ...
                    caliHSDataBase(:,6) <= hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower+5, 2);
                
                if length(matchCaliWQ) == 2
                    if (((caliHSDataBase(matchCaliWQ(1), 7) - hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1))*(caliHSDataBase(matchCaliWQ(2), 7) - hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1)) < 0) || (caliHSDataBase(matchCaliWQ(1), 7) == hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1) || caliHSDataBase(matchCaliWQ(2), 7) == hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1))) && ...
                            (((caliHSDataBase(matchCaliWQ(1), 6) - hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower)*(caliHSDataBase(matchCaliWQ(2), 6) - hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower) < 0) || (caliHSDataBase(matchCaliWQ(1), 6) == hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower || caliHSDataBase(matchCaliWQ(2), 6) == hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower))
                        if caliHSDataBase(matchCaliWQ(1), 7) == caliHSDataBase(matchCaliWQ(2), 7) && caliHSDataBase(matchCaliWQ(1), 6) == caliHSDataBase(matchCaliWQ(2), 6)
                            geoHS.q = (caliHSDataBase(matchCaliWQ(1), 1) + caliHSDataBase(matchCaliWQ(2), 1))/2;
                            geoHS.Cxf = (caliHSDataBase(matchCaliWQ(1), 2) + caliHSDataBase(matchCaliWQ(2), 2))/2;
                            geoHS.Cxb = (caliHSDataBase(matchCaliWQ(1), 3) + caliHSDataBase(matchCaliWQ(2), 3))/2;
                            geoHS.Cy = (caliHSDataBase(matchCaliWQ(1), 4) + caliHSDataBase(matchCaliWQ(2), 4))/2;
                            geoHS.Cz = (caliHSDataBase(matchCaliWQ(1), 5) + caliHSDataBase(matchCaliWQ(2), 5))/2;
                        elseif caliHSDataBase(matchCaliWQ(1), 7) == caliHSDataBase(matchCaliWQ(2), 7) && caliHSDataBase(matchCaliWQ(1), 6) ~= caliHSDataBase(matchCaliWQ(2), 6)
                            geoHS.q = interp1([caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 1), caliHSDataBase(matchCaliWQ(2), 1)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                            geoHS.Cxf = interp1([caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 2), caliHSDataBase(matchCaliWQ(2), 2)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                            geoHS.Cxb = interp1([caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 3), caliHSDataBase(matchCaliWQ(2), 3)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                            geoHS.Cy = interp1([caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 4), caliHSDataBase(matchCaliWQ(2), 4)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                            geoHS.Cz = interp1([caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 5), caliHSDataBase(matchCaliWQ(2), 5)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                        elseif caliHSDataBase(matchCaliWQ(1), 7) ~= caliHSDataBase(matchCaliWQ(2), 7) && caliHSDataBase(matchCaliWQ(1), 6) == caliHSDataBase(matchCaliWQ(2), 6)
                            geoHS.q = interp1([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 1), caliHSDataBase(matchCaliWQ(2), 1)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1));
                            geoHS.Cxf = interp1([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 2), caliHSDataBase(matchCaliWQ(2), 2)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1));
                            geoHS.Cxb = interp1([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 3), caliHSDataBase(matchCaliWQ(2), 3)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1));
                            geoHS.Cy = interp1([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 4), caliHSDataBase(matchCaliWQ(2), 4)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1));
                            geoHS.Cz = interp1([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 5), caliHSDataBase(matchCaliWQ(2), 5)], hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1));
                        else
                            Fq = scatteredInterpolant([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 1), caliHSDataBase(matchCaliWQ(2), 1)], 'linear', 'linear');
                            Fcxf = scatteredInterpolant([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 2), caliHSDataBase(matchCaliWQ(2), 2)], 'linear', 'linear');
                            Fcxb = scatteredInterpolant([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 3), caliHSDataBase(matchCaliWQ(2), 3)], 'linear', 'linear');
                            Fcy = scatteredInterpolant([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 4), caliHSDataBase(matchCaliWQ(2), 4)], 'linear', 'linear');
                            Fcz = scatteredInterpolant([caliHSDataBase(matchCaliWQ(1), 7), caliHSDataBase(matchCaliWQ(2), 7)], [caliHSDataBase(matchCaliWQ(1), 6), caliHSDataBase(matchCaliWQ(2), 6)], [caliHSDataBase(matchCaliWQ(1), 5), caliHSDataBase(matchCaliWQ(2), 5)], 'linear', 'linear');
                            
                            geoHS.q = Fq(hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1), hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                            geoHS.Cxf = Fcxf(hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1), hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                            geoHS.Cxb = Fcxb(hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1), hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                            geoHS.Cy = Fcy(hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1), hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                            geoHS.Cz = Fcz(hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1), hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower);
                        end
                        caliSolver{i,2} = geoHS;
                        this.CalibratedHS{i} = [geoHS.q, geoHS.Cxf, geoHS.Cxb, geoHS.Cy, geoHS.Cz];
                        
                        fprintf('Wärmequelle wurde interpoliert. %d/%d\n', i, size(caliSolver, 1));
                        continue;
                    elseif i >= 2 && exist('output', 'var')
                        geoHS.q = output(1);
                        
                        geoHS.Cxf = output(2);
                        geoHS.Cxb = output(3);
                        geoHS.Cy = output(4);
                        geoHS.Cz = output(5);
                        
                        caliSolver{i,2} = geoHS;
                    else
                        geoHS.q = this.ReducedModel.Scaled.Config.WeldingParameter.LaserPower*0.5;
                        geoHS.Cz = length(keyholeGeo{i,1})*keyDz;
                        geoHS.Cxf = keyholeGeo{i,1}(2,1)*w0;
                        geoHS.Cy = keyholeGeo{i,1}(2,1)*w0;
                        geoHS.Cxb = keyholeGeo{i,1}(2,1)*w0;
                        
                        caliSolver{i,2} = geoHS;
                    end
                elseif length(matchCaliWQ) == 1 && caliHSDataBase(matchCaliWQ(1), 7) == hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1) && caliHSDataBase(matchCaliWQ(1), 6) == hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower
                    geoHS.q = caliHSDataBase(matchCaliWQ(1), 1);
                    geoHS.Cxf = caliHSDataBase(matchCaliWQ(1), 2);
                    geoHS.Cxb = caliHSDataBase(matchCaliWQ(1), 3);
                    geoHS.Cy = caliHSDataBase(matchCaliWQ(1), 4);
                    geoHS.Cz = caliHSDataBase(matchCaliWQ(1), 5);
                    
                    caliSolver{i,2} = geoHS;
                    this.CalibratedHS{i} = [geoHS.q, geoHS.Cxf, geoHS.Cxb, geoHS.Cy, geoHS.Cz];
                    
                    fprintf('Wärmequelle wurde in Datenbank gefunden. %d/%d\n', i, size(caliSolver, 1));
                    continue;
                elseif i >= 2 && exist('output', 'var')
                    % Verwenden der letzten Kalibrierungswerte als
                    % Startwerte
                    geoHS.q = output(1);
                    
                    geoHS.Cxf = output(2);
                    geoHS.Cxb = output(3);
                    geoHS.Cy = output(4);
                    geoHS.Cz = output(5);
                    
                    caliSolver{i,2} = geoHS;
                else
                    % Auslesen der Startwerte aus Keyhole und Keyhole
                    % Temperaturfeld
                    %Festlegung von q mit Hilfe der Laserleistung
                    geoHS.q = this.ReducedModel.Scaled.Config.WeldingParameter.LaserPower*0.5;
                    
                    %Tiefe wird übernommen
                    geoHS.Cz = length(keyholeGeo{i,1})*keyDz;
                    
                    %Laterale und axiale Richtung werden gleich dem
                    %Keyholeradius gesetzt
                    geoHS.Cxf = keyholeGeo{i,1}(2,1)*w0;
                    geoHS.Cy = keyholeGeo{i,1}(2,1)*w0;
                    geoHS.Cxb = keyholeGeo{i,1}(2,1)*w0;
                    
                    caliSolver{i,2} = geoHS;
                end
                
                
                % Umwandlung des KalibrierungsT-Feldes in ein Array --> gleiche
                % Form wie sie bei RunSolver() entsteht
                caliTField{i,1} = reshape(caliTField{i,1}, [numel(caliTField{i,1}), 1]);
                
                
                % Startwerte werden skaliert
                x0 = [geoHS.q/((local.vaporT-local.ambientT)*local.lambda*local.w0), ...
                    geoHS.Cxf/local.w0, ...
                    geoHS.Cxb/local.w0, ...
                    geoHS.Cy/local.w0, ...
                    geoHS.Cz/local.w0];
                
                
                % Function Handle für Ablauf der Minimierungsfunktion
                myOptimize = @(paramArray) this.RunOptimization(paramArray, caliSolver{i,1}, caliTField{i,1}, local);
                
                % Wahl des Optimierers
                choice = 'cg';
                
                switch choice
                    case 'cg'
                        % Optionen für Optimierung
                        myoptions = optimset('TolFun', 1e-4, 'MaxFunEvals', 150, 'Display', 'iter-detailed');
                        
                        % Aufruf der Optimierungs-/Minimierungs-Funktion (von Matlab)
                        output = lsqnonlin(myOptimize, x0, zeros(1,length(x0)), [], myoptions);
                    case 'ps'
                        % Optionen für Optimierung
                        myoptions = psoptimset('Display', 'iter', 'Cache', 'on');
                        % Aufruf der Optimierungs-/Minimierungs-Funktion (von Matlab)
                        output = patternsearch(myOptimize, x0, [], [], [], [], zeros(1,length(x0)), [], [], myoptions);
                    case 'ga'
                        % Optionen für Optimierung
                        myoptions = gaoptimset('Display', 'iter');
                        output = ga(myOptimize, length(x0), [], [], [], [], zeros(1,length(x0)), [], [], myoptions);
                end
                
                % Umwandeln der Parameter in SI-Einheiten
                output(1) = output(1)*(local.lambda*local.w0*(local.vaporT - local.ambientT));
                output(2:end) = output(2:end) .* local.w0;
                
                % Speichern der gefitteten Parameter in Datenbank
                caliHSDataBase(end+1,:) = [output, hs{1,1}.TrajectoryInfo.Config.WeldingParameter.LaserPower, hs{1,1}.TrajectoryInfo.Config.WeldingParameter.TrueVelocityNorm(i,1), this.Rsquared]; %#ok
                
                % Rückgabe der gefitteten Parameter
                this.CalibratedHS{i} = output;
                
                % Anzeige
                fprintf('Es wurden bereits %d/%d Wärmequellen kalibriert.\n', i, size(caliSolver, 1));
            end
            
            % Berechnen der eingetragenen Energie jeder kalibrierten WQ
            %this.calcWQoutput(hs);
            
            save('..\Einstellungen\caliHSDataBase.mat', 'caliHSDataBase');
        end
    end
    
    methods (Access = private)
        % Mit Hilfe einer Matlab Funktion minimieren
        function se = RunOptimization(this, paramArray, caliSolver, caliTField, local)
            caliSolver = this.SetHSGeoData(caliSolver, paramArray, local);
            
            caliSolver.TemperatureField = [];
            
            caliSolver.RunSolver('par');
            
            wqTField = caliSolver.TemperatureField(:,end);
            wqTField = (wqTField - local.ambientT) ./ (local.vaporT - local.ambientT);
            
            % Für Abbruchbedingung werden Bereiche über
            % Verdampfungstemperatur nicht betrachtet
            wqTField(wqTField > 1) = 1;
            
            se = (wqTField - caliTField).^2;
            
            sse = sum((wqTField - caliTField).^2); %#ok
            rsquared = 1 - ((sum((caliTField - wqTField).^2))/(sum((caliTField - mean(caliTField)).^2)));
            disp(rsquared)
            
            this.Rsquared = rsquared;
        end
        
        
        % Hilfsfunktionen
        function composedCaliSolver = SetHSGeoData(~, caliSolver, paramArray, local)
            % Funktion zum setzen der Parameter der WQ für das gesamte
            % WQ-Feld
            %Hinzufügen der Dimensionen für die Berechnung des WQ-T-Feldes
            for j = 1:length(caliSolver.HeatSourceDefinition.HeatSourceField)
                if ~isempty(strfind(caliSolver.HeatSourceDefinition.HeatSourceField{j,1}.Type, 'WQ'))
                    caliSolver.HeatSourceDefinition.HeatSourceField{j,1}.HeatEmission = paramArray(1)*(local.lambda*local.w0*(local.vaporT - local.ambientT));
                elseif ~isempty(strfind(caliSolver.HeatSourceDefinition.HeatSourceField{j,1}.Type, 'WS'))
                    caliSolver.HeatSourceDefinition.HeatSourceField{j,1}.HeatEmission = (-1)*paramArray(1)*(local.lambda*local.w0*(local.vaporT - local.ambientT));
                else
                    error('incorrect heat source definition');
                end
                caliSolver.HeatSourceDefinition.HeatSourceField{j,1}.GeoDescription.Cxf = paramArray(2)*local.w0;
                caliSolver.HeatSourceDefinition.HeatSourceField{j,1}.GeoDescription.Cxb = paramArray(3)*local.w0;
                caliSolver.HeatSourceDefinition.HeatSourceField{j,1}.GeoDescription.Cy = paramArray(4)*local.w0;
                caliSolver.HeatSourceDefinition.HeatSourceField{j,1}.GeoDescription.Cz = paramArray(5)*local.w0;
            end
            
            composedCaliSolver = caliSolver;
        end
        
        function calcWQoutput(this, hs)
            % Berechnung der Leistung jeder kalibrierten WQ
            watt = zeros(1,length(hs));
            for i = 1:length(hs)
                q = this.CalibratedHS{i}(1);
                Cxf = this.CalibratedHS{i}(2);
                Cxb = this.CalibratedHS{i}(3);
                Cy = this.CalibratedHS{i}(4);
                Cz = this.CalibratedHS{i}(5);
                
                %Definition der doppelt elliptischen WQ
                rf = ((2.*Cxf)/(Cxf + Cxb));
                rb = ((2.*Cxb)/(Cxf + Cxb));
                
                funFront = @(x,y,z) ((6.*sqrt(3).*rf.*q)/(Cy.*Cz.*Cxf.*pi.*sqrt(pi))) .* exp(-((3.*x.^2)/(Cxf.^2)) - ((3.*y.^2)/(Cy.^2)) - ((3.*z.^2)/(Cz.^2)));
                funBack = @(x,y,z) ((6.*sqrt(3).*rb.*q)/(Cy.*Cz.*Cxb.*pi.*sqrt(pi))) .* exp(-((3.*x.^2)/(Cxb.^2)) - ((3.*y.^2)/(Cy.^2)) - ((3.*z.^2)/(Cz.^2)));
                
                watt(i) = (integral3(funFront, 0, 0.2e-3, -0.2e-3, 0.2e-3, -0.2e-3, 0.2e-3) + integral3(funBack, -0.2e-3, 0, -0.2e-3, 0.2e-3, -0.2e-3, 0.2e-3));
            end
            
            this.WQoutput = watt;
        end
    end
    
    
end