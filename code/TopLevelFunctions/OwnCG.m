function output = OwnCG(this, caliSolver, caliTField)
% Funktion zur Anpassung der geometrischen Parameter der WQ

%PARALLELISIERBAR: Aufruf des Optimierers für jeden Solver/WQ
for i = 1:size(caliSolver, 1)
    % Überführen von Temperaturen zur Skallierung in lokale Var
    local = struct();
    local.ambientT = caliSolver{i,1}.HeatSourceDefinition.TrajectoryInfo.Config.Material.AmbientTemperature;
    local.vaporT = caliSolver{i,1}.HeatSourceDefinition.TrajectoryInfo.Config.Material.VaporTemperature;
    local.w0 = caliSolver{i,1}.HeatSourceDefinition.TrajectoryInfo.Config.WeldingParameter.WaistSize;
    local.lambda = caliSolver{i,1}.HeatSourceDefinition.TrajectoryInfo.Config.Material.ThermalConductivity;
    % Initialisierung der Kalibrierung für neue WQ
    gradDirectionArray = zeros(2,length(fieldnames(caliSolver{i,2})));
    direcDecent = zeros(length(fieldnames(caliSolver{i,2})),2);
    paramArray = zeros(length(fieldnames(caliSolver{i,2})),3);
    changeParam = zeros(length(fieldnames(caliSolver{i,2})),2);
    wqTField = zeros(size(caliTField{i,1}));
    oldwqTField = cell(1,2);
    oldwqTField{1,1} = zeros(size(caliTField{i,1}));
    oldwqTField{1,2} = zeros(size(caliTField{i,1}));
    j = 0;
    % Übertragen der geometrischen Parameter der WQ in eine
    % Variable und Skallierung
    paramArray(:,1) = [caliSolver{i,2}.q/((local.vaporT-local.ambientT)*local.lambda*local.w0); ...
        caliSolver{i,2}.Cxf/local.w0; ...
        caliSolver{i,2}.Cxb/local.w0; ...
        caliSolver{i,2}.Cy/local.w0; ...
        caliSolver{i,2}.Cz/local.w0];
    
    while(true)
        j = j + 1;
        % Speichern & shiften der letzten beiden wqTFields
        oldwqTField{1,2} = oldwqTField{1,1};
        oldwqTField{1,1} = wqTField;
        
        % Setzen der Startwerte für alle WQ HS-Felder
        caliSolver = this.SetHSGeoData(caliSolver, paramArray(:,1), local, i);
        
        % Entfernen des alten T-Feldes aus dem Solver-Object
        caliSolver{i,1}.TemperatureField = [];
        
        % Berechnung des T-Feldes mit Hilfe der Parameter aus geoHS
        caliSolver{i,1}.RunSolver();
        
        % Übertragung und Skallierung des T-Feldes
        wqTField = caliSolver{i,1}.TemperatureField(:,end);
        wqTField = (wqTField - local.ambientT) ./ (local.vaporT - local.ambientT);
        
        % Für Abbruchbedingung werden Bereiche über
        % Verdampfungstemperatur nicht betrachtet
        wqTField(wqTField > 1) = 1;
        
        % Berechnung der Summe der Fehlerquadrate
        sse = sum((wqTField - caliTField{i,1}).^2);
        disp(sse)
        
        % Berechnung des R^2
        rsquared = 1 - ((sum((caliTField{i,1} - wqTField).^2))/(sum((caliTField{i,1} - mean(caliTField{i,1})).^2)));
        disp(rsquared)
        
        % Überprüfung des Abbruchkriteriums
        if rsquared > 0.9
            break;
        end
        
        % Berechnung der Gradienten Richtung (gradDirectionArray)
        changeTField = wqTField - oldwqTField{1,1};
        changeTField = repmat(changeTField, [1, size(changeParam,1)]);
        changeParam(:,1) = paramArray(:,1) - paramArray(:,2);
        for anzParam = 1:size(changeParam, 1)
            changeTField(:,anzParam) = changeTField(:,anzParam) ./ changeParam(anzParam,1);
            gradDirectionArray(1,anzParam) = -2.*sum(changeTField(:,anzParam) .* (caliTField{i,1} - wqTField));
        end
        
        %In der ersten Iteration ist der conjugation
        %coefficient (conjuCoeff) gleich 0
        if j == 1
            conjuCoeff = 0;
        else
            % Berechnung der Gradienten Richtung für die
            % vorherige Iteration
            changeTFieldOld = oldwqTField{1,1} - oldwqTField{1,2};
            changeTFieldOld = repmat(changeTFieldOld, [1, size(changeParam,1)]);
            changeParam(:,2) = paramArray(:,2) - paramArray(:,3);
            for anzParam = 1:size(changeParam, 1)
                changeTFieldOld(:,anzParam) = changeTFieldOld(:,anzParam) ./ changeParam(anzParam,2);
                gradDirectionArray(2,anzParam) = -2.*sum(changeTFieldOld(:,anzParam) .* (caliTField{i,1} - oldwqTField{1,1}));
            end
            
            % Berechnung des conjuggation coefficient
            conjuCoeff = sum(gradDirectionArray(:,1).^2) / sum(gradDirectionArray(:,2).^2);
        end
        
        % Berechnung der decent direcction
        direcDecent(:,1) = gradDirectionArray(1,:)' + conjuCoeff .* direcDecent(:,2);
        
        % Berechnung der Suchschrittweite
        numerator = sum((changeTField*direcDecent(:,1)) .* (wqTField - caliTField{i,1}));
        denominator = sum((changeTField*direcDecent(:,1)).^2);
        searchStepSize = numerator / denominator;
        
        % Berechnung der neuen Parameter (paramArray)
        %Speichern und shiften der letzten beiden
        %Parametersätze
        paramArray(:,3) = paramArray(:,2);
        paramArray(:,2) = paramArray(:,1);
        paramArray(:,1) = paramArray(:,2) - searchStepSize .* direcDecent(:,1);
        
        % Shiften der direcDecent Variable
        direcDecent(:,2) = direcDecent(:,1);
        
    end
    
    output = paramArray(:,1);
end
end