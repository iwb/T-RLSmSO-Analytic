classdef ReducedModel < handle
    %REDUCEDMODEL berechnet das 3D Temperaturfeld nach dem reduzierten
    %Modell von Pfeiffer/Jansen
    %   Detailed explanation goes here
    
    properties
        Scaled@ScaledConfig;
        
        KeyDz = 0.5e-5;             % z-Diskretisierung für die Berechnung des Keyholes [m]
        
        DiskreteCaliField = [];     % Diskretisierung des auszuwertenden Bereichs für die Kalibrierung
        
        NumTFields = [];            % Array mit Indizes, für welche Geschwindigkeit ein T-Feld berechnet werden soll --> für Kalibrierung
        
        EntireFields = [];          % Cell-Array, das alle 3D Matritzen mit den T-Feldern enthält
        
        KeyholeGeo                  % Enthält den Radius und den Vorheitzpunkt des Keyholes
        
        ElementCount = 1e4;      % Anzahl der Elemente für die Diskretisierung des Kalibrierungs-T-Feldes
        
        ErrorOccurrence = [];       % Speichert Fehler in der Bereichsanpassung
    end
    
    properties (Access = private)
        nDx = [];                   % Anzahl der Diskretisierungselemente in x-Richtung (Kalibrierungs-T-Feld)
        nDy = [];                   % Anzahl der Diskretisierungselemente in y-Richtung (Kalibrierungs-T-Feld)
        nDz = [];                   % Anzahl der Diskretisierungselemente in z-Richtung (Kalibrierungs-T-Feld)
    end
    
    methods
        function this = ReducedModel(scaled, num)
            this.Scaled = scaled;
            
            % Es darf nur für einmal auftretende Bahngeschwindigkeiten ein
            % T-Feld berechnet werden
            check = hist(num, max(num));
            if (min(num) < 0 || max(num) > min(this.Scaled.Config.Oscillation.Discretization, length(this.Scaled.Config.WeldingParameter.TrueVelocityNorm)) || max(check) > 1)
                error('Es gibt nur %d unterschiedliche Wärmequellen die kalibriet werden können.', this.Scaled.Config.Oscillation.Discretization);
            else
                this.NumTFields = sort(num);
                this.EntireFields = cell(length(num), 1);
            end
        end
        %%
        function CalcEntireTFields(this)
            % Überführen in lokale Variable
            numKey = this.NumTFields;
            waistSize = this.Scaled.Config.WeldingParameter.WaistSize;
            
            % Speichern der Relevanten Geschwindigkeiten in lokaler
            % Variable
            PeArray = this.Scaled.PecletNumber(numKey);
            
            % Berechnung der Anzahl der Diskretisierungselemente des
            % Kalibrierungs-T-Feldes --> Verhältnis = nDx:nDy:nDz --- 1:1:1
            this.nDx = floor(1*nthroot((this.ElementCount)/1, 3));
            this.nDy = floor(1*nthroot((this.ElementCount)/1, 3));
            this.nDz = floor(1*nthroot((this.ElementCount)/1, 3));
            
            % Erzeugen eines Keyhole-Objects
            KeyholeModel = Keyhole(this.Scaled, this.KeyDz);
            
            % Anzeige
            fprintf('Berechnung der Kapillaren: \n');
            
            % Berechnung der Keyholegeometrie für jede gewünschte Geschwindigkeit
            this.KeyholeGeo = cell(length(numKey), 1);
            for i = 1:length(numKey)
                [this.KeyholeGeo{i,1}(1,:), this.KeyholeGeo{i,1}(2,:)] = KeyholeModel.CalcKeyhole(numKey(i));
            end
            
            % Überführen der Keyhole Geometrie in lokale Variable
            keyholeGeo = this.KeyholeGeo;
            
            this.ErrorOccurrence = false(length(numKey), 1);
            
            % Berechnung der Temperaturfelder für jede Keyhole Geometrie
            tempTGeoFields = cell(length(numKey), 1);
            for i = 1:length(numKey)
                % Funtion zur Berechnung des Bereichs der mit Hilfe der
                % Zylinderquellenlösung ausgewertet werden soll
                try
                    [x, y, x_range, y_range, ~] = this.CalcEvalueRange(keyholeGeo, PeArray, i);
                catch rangeError
                    warning([rangeError.message '--> dummy Bereich verwendet.'])
                    
                    % Eintrag ins Log
                    createLog([rangeError.message '--> dummy Bereich verwendet.'], 'a');
                    
                    minX = -keyholeGeo{i,1}(1,1)*10;
                    maxX = keyholeGeo{i,1}(1,1)*10;
                    minY = 0; %-keyholeGeo{i,1}(1,1)*10;
                    maxY = keyholeGeo{i,1}(1,1)*10;
                    
                    %Koordinatentransformation für die Berechnung des T-Feldes
                    x_range = linspace(minX, maxX, this.nDx);
                    y_range = linspace(minY, maxY, this.nDy);
                    %Netz erstellen an dem ausgewertet werden soll
                    [x, y] = meshgrid(x_range, y_range);
                    x = reshape(x, [1, numel(x)]);
                    y = reshape(y, [1, numel(y)]);
                    
                    this.ErrorOccurrence(i) = true;
                end
                
                % Funtion zur Verfeinerung der Diskretisierung um das
                % Keyhole herum
                %[x, y, x_range, y_range] = this.AlterMesh(x_range, y_range, firstTField);
                
                % Interpolation der neuen Radien und Scheitelpunkte für
                % Array mit der Länge this.nDz
                interA = interp1(linspace(0, length(keyholeGeo{i,1}), length(keyholeGeo{i,1})), ...
                    keyholeGeo{i,1}(1,:), linspace(0, length(keyholeGeo{i,1}), this.nDz));
                interAlpha = interp1(linspace(0, length(keyholeGeo{i,1}), length(keyholeGeo{i,1})), ...
                    keyholeGeo{i,1}(2,:), linspace(0, length(keyholeGeo{i,1}), this.nDz));
                
                % Berechnung des einzelnen Temperaturfeldes pro Schicht
                for j = 1:length(interA)
                    x_temp = x + (interAlpha(j) - interA(j)); %Verschiebung des Mittelpunktes um Alpha-A
                    [phi, rho] = cart2pol(x_temp, y); %Umrechnung in Polarkoordinaten
                    
                    out = (rho < interAlpha(j)); %Finden der Punkte innerhalb des Keyholes
                    out = reshape(out, [length(y_range), length(x_range)]);
                    
                    temp = this.CalcTempField(phi, rho, interAlpha(j), PeArray(i,1));
                    temp = reshape(temp, [length(y_range), length(x_range)]);
                    
                    temp(out) = 1; %Punkte innerhalb des Keyholes besitzen Tv
                    temp(temp < 0) = 0;
                    
                    tempTGeoFields{i,1}(:,:,j) = temp;
                end
                
                % Überführen der Informationen über den auszuwertenden Bereich
                % in die entsprechenden Felder
                z_range = linspace(0, length(keyholeGeo{i,1}(1,:))*this.KeyDz, this.nDz);
                this.DiskreteCaliField{i} = {x_range.*waistSize, y_range.*waistSize, z_range};
            end
            
            % Überführen des T-Feldes in ein Feld der Klasse
            this.EntireFields = tempTGeoFields;
        end
    end
    
    methods (Access = private)
        %%
        function tempField = CalcTempField( ~, winkel, abstand, alpha, Pe )
            %CALCTEMPFIELD Berechnet das Temperaturfeld mit Hilfe der
            %Zylinderquellenlösung nach Pfeiffer --> Reduziertes Modell
            %   Detailed explanation goes here
            
            % Aufteilen der Zylinderquellenlösung in drei Formeln
            factor1 = @(abstand, winkel) exp((-Pe/2) .* abstand .* cos(winkel));
            factor2 = @(abstand) (besseli(0, Pe.*alpha/2) ./ besselk(0, Pe.*alpha/2)) .* besselk(0, Pe.*abstand/2);
            factor3 = @(abstand, winkel, n) (besseli(n, Pe.*alpha/2) ./ besselk(n, Pe.*alpha/2)) .* besselk(n, Pe.*abstand/2) .* cos(n.*winkel);
            
            % Berechnung der ersten beiden Formeln
            theta1 = factor1(abstand, winkel);
            theta2 = factor2(abstand);
            
            % Die dritte Formel ist eine Reihe --> Abbruch der Summation wenn
            % zusätzlicher Term < 1e-9 ist
            theta3 = zeros(1, length(abstand));
            i = 1;
            while true
                lasttheta3 = theta3;
                temptheta3 = factor3(abstand, winkel, i);
                theta3 = sum([temptheta3; theta3]);
                i = i + 1;
                
                if max((lasttheta3 - theta3).^2) == 0
                    break;
                end
            end
            
            % Zusammensetzen der drei Formeln zur gesamt Berechnung des
            % Temperaturfeldes
            tempField = theta1 .* (theta2 + 2.*theta3);
        end
        %%
        function [x, y, x_range, y_range, temp] = CalcEvalueRange(this, keyholeGeo, PeArray, i)
            % Funtion zur Berechnung des Bereichs der mit Hilfe der
            % Zylinderquellenlösung ausgewertet werden soll
            
            diskretX = this.nDx;
            diskretY = this.nDy;
            
            % Startwerte für den auszuwertenden Bereich
            minX = -keyholeGeo{i,1}(1,1)*10;
            maxX = keyholeGeo{i,1}(1,1)*10;
            minY = 0; %-keyholeGeo{i,1}(1,1)*10;
            maxY = keyholeGeo{i,1}(1,1)*10;
            
            loop = 0;
            change = 1;
            while (true)
                loop = loop + 1;
                %Koordinatentransformation für die Berechnung des T-Feldes
                x_range = linspace(minX, maxX, diskretX);
                y_range = linspace(minY, maxY, diskretY);
                %Netz erstellen an dem ausgewertet werden soll
                [x, y] = meshgrid(x_range, y_range);
                x = reshape(x, [1, numel(x)]);
                y = reshape(y, [1, numel(y)]);
                
                % Berechnung der ersten Schicht des T-Feldes
                x_temp = x + (keyholeGeo{i,1}(2,1) - keyholeGeo{i,1}(1,1)); %Verschiebung des Mittelpunktes um Alpha-A
                [phi, rho] = cart2pol(x_temp, y); %Umrechnung in Polarkoordinaten
                
                out = (rho < keyholeGeo{i,1}(2,1)); %Finden der Punkte innerhalb des Keyholes
                out = reshape(out, [length(y_range), length(x_range)]);
                
                temp = this.CalcTempField(phi, rho, keyholeGeo{i,1}(2,1), PeArray(i,1)); %Berechnung des T-Feldes
                temp = reshape(temp, [length(y_range), length(x_range)]);
                
                temp(out) = 1; %Punkte innerhalb des Keyholes besitzen Tv
                
                % Zählen wie viele Nullspalten und Nullzeilen es gibt
                countFront = (temp <= 1e-4);
                countBack = (temp <= 0.19+0.015*PeArray(i,1));
                countSide = (temp <= 0.05);
                
                countH(1,:) = sum(countFront);
                %countV(:,1) = sum(countFront, 2);
                
                countH(2,:) = sum(countBack);
                %countV(:,2) = sum(countBack, 2);
                
                %countH(3,:) = sum(countSide);
                countV(:,3) = sum(countSide, 2);
                % Vollständige Nullzeilen und -spalten werden mit 1
                % gekennzeichnet alle anderen mit 0
                anzH(1,:) = (countH(1,:) == diskretY);
                %anzV(:,1) = (countV(:,1) == diskretY);
                
                anzH(2,:) = (countH(2,:) == diskretY);
                %anzV(:,2) = (countV(:,2) == diskretY);
                
                %anzH(3,:) = (countH(3,:) == diskretX);
                anzV(:,3) = (countV(:,3) == diskretX);
                
                % Finde alle Änderungen von 1 auf 0 und vice versa
                oneZeroH = find(diff(anzH(2,:)) == -1);
                zeroOneH = diskretX - find(diff(anzH(1,:)) == 1);
                %oneZeroV = find(diff(anzV) == -1);
                zeroOneV = diskretY - find(diff(anzV(:,3)) == 1);
                
                % Test ob eine Variable leer ist
                if isempty(oneZeroH)
                    oneZeroH = 0;
                end
                if isempty(zeroOneH)
                    zeroOneH = 0;
                end
%                 if isempty(oneZeroV)
%                     oneZeroV = 0;
%                 end
                if isempty(zeroOneV)
                    zeroOneV = 0;
                end
                
                % Abbruchbedingung erfüllt, wenn in der ersten Schicht
                % mindestens 5 und maximal 10 vollständige Nullzeilen und
                % -reihen existieren
                if (oneZeroH <= 4 && oneZeroH >= 1) && (zeroOneH <= 4 && zeroOneH >= 1) && (zeroOneV <= 4 && zeroOneV >= 1) %&& (oneZeroV <= 5 && oneZeroV >= 1)
                    break;
                elseif loop == 400
                    %Abstufung ändern
                    change = 0.5;
                elseif loop == 600 || any(temp(:) < 0)
                    error('no boundaries for calibration area found!');
                end
                
                % Falls zu wenige oder zu viele Nullzeilen bzw. -spalten
                % existieren wird der Auswertebereich angepasst
                if oneZeroH > 4
                    minX = minX + ((change)*(oneZeroH-4)); %Pro zu vieler Nullst. wird w0/change abgezogen
                elseif oneZeroH < 1
                    minX = minX - ((change)*(1-oneZeroH));
                end
                
                if zeroOneH > 4
                    maxX = maxX - ((change)*(zeroOneH-4));
                elseif zeroOneH < 1
                    maxX = maxX + ((change)*(1-zeroOneH));
                end
                
%                 if oneZeroV > 5
%                     minY = minY + ((change)*(oneZeroV-5));
%                 elseif oneZeroV < 1
%                     minY = minY - ((change)*(1-oneZeroV));
%                 end
                
                if zeroOneV > 4
                    maxY = maxY - ((change)*(zeroOneV-4));
                elseif zeroOneV < 1
                    maxY = maxY + ((change)*(1-zeroOneV));
                end
            end
        end
        %%
        function [new_x, new_y, newx_range, newy_range] = AlterMesh(~, x_range, y_range, firstTField)
            % Funktion zur Anpassung des Netzes --> Verfeinert die
            % Diskretisierung um das Keyhole herum
            
            % Zur Verfügung stehende Elemente
            nx = length(x_range);
            ny = length(y_range);
            
            % Berechnung der gesamt Steigung in x und y
            sx = (max(x_range) - min(x_range)) ./ nx;
            sy = (max(y_range) - min(y_range)) ./ ny;
            
            % Bestimmung der Keyhole Position
            PosWQ = find(firstTField(1,:) == max(firstTField(1,:)), 1, 'first');
            
            % Umrechnung von PosWQ in nWQ
            nWQx = PosWQ;
            nWQy = 1;
            
            ccX = [0, 0, 1; ...
                   nx^2, nx, 1; ...
                   2*nWQx, 1, 0] \ [min(x_range); max(x_range); sx*0.5];
            
            ccY = [0, 0, 1; ...
                   ny^2, ny, 1; ...
                   2*nWQy, 1, 0] \ [min(y_range); max(y_range); sy*0.15];
               
           newx_range = polyval(ccX, 0:1:nx);
           newy_range = polyval(ccY, 0:1:ny);
           
           [new_x, new_y] = meshgrid(newx_range, newy_range);
           new_x = reshape(new_x, [1, numel(new_x)]);
           new_y = reshape(new_y, [1, numel(new_y)]);
        end
    end
    
    
end