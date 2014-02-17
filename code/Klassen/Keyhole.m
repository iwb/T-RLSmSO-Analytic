classdef Keyhole < handle
    %KEYHOLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Scaled@ScaledConfig;
    end
    
    properties (Access = private)        
        b1 = 1/10;                  % Konstante aus Pfeiffer/Jansen [-]
        b2 = 3/5;                   % Konstante aus Pfeiffer/Jansen [-]

        xOffset = [];               % Offset in Vorschubrichtung (x-Richtung) [m]
        yOffset = [];               % Offset in lateraler Richtung (y-Richtung) [m] --> Berechnung von alpha0

        StartD = 1e-3;              % Startwert für Wärmeeindringtiefe
        StartT = [];                % Startwert für Temperatur an der Oberfläche
        
        Dz = [];                    % Diskretisierung in z-Richtung
    end
    
    methods
        function this = Keyhole(scaledconfig, dz)
            this.Scaled = scaledconfig;
            
            this.Dz = dz;
            
            this.StartT = this.Scaled.Config.Material.AmbientTemperature + 0.01;
        end
        
        function [S_Apex, S_Radius] = CalcKeyhole(this, veloIdx)            
            % Vorheitzpunkte berechnen
            this.yOffset = 0;
            vhp1 = CalcVHP(this, veloIdx);
            
            this.yOffset = this.Scaled.Config.WeldingParameter.WaistSize * 0.5;
            vhp2 = CalcVHP(this, veloIdx);
            
            % Startwerte berechnen
            waistSize = this.Scaled.Config.WeldingParameter.WaistSize;
            A0 = vhp1 / waistSize;
            alpha0 = ((vhp1 - vhp2)^2 + this.yOffset^2) / (2 * (vhp1 - vhp2)) / waistSize;
            
            % Datenverwaltung von Radius und Scheitelpunkt mit Hilfe einer
            % Liste (siehe: List.m)
            apex = List();
            apex.EnsureCapacity(1000);
            apex.Add(A0);
            
            radius = List();
            radius.EnsureCapacity(1000);
            radius.Add(alpha0);
            
            % Diskretisierung der z-Achse
            dz = this.Dz;
            d_zeta = dz / this.Scaled.Config.WeldingParameter.WaistSize;
            
            % Variablen für die Berechnung in der Schleife
            zeta = 0;
            zindex = 0;
            
            currentA = A0;
            currentAlpha = alpha0;
            
            % Festlegung der zuübergebenden Variablen
            param = struct();
            param.epsilon = this.Scaled.Config.Material.FresnelEpsilon;
            param.scaled = struct();
            param.scaled.gamma = this.Scaled.Gamma;
            param.scaled.hm = this.Scaled.FusionEnthalpy;
            param.scaled.Pe = this.Scaled.PecletNumber(veloIdx);
            param.scaled.waveLength = this.Scaled.WaveLength;
            param.scaled.fokus = this.Scaled.Fokus;
            param.scaled.Rl = this.Scaled.RayleighLength;
            
            % Schleife über die Tiefe
            while (true)
                
                zindex = zindex + 1;
                prevZeta = zeta;
                zeta = zeta + d_zeta;
                
                % NUllstellensuche mit MATLAB fzero
                %Variablen für Nullstellensuche
                arguments = struct();
                arguments.prevZeta = prevZeta;
                arguments.zeta = zeta;
                arguments.prevApex = currentA;
                arguments.prevRadius = currentAlpha;
                
                % Berechnung des neuen Scheitelpunktes
                func1 = @(A) khz_func1(A, arguments, param);
                currentA = fzero(func1, currentA);
                
                % Abbruchkriterium
                if(isnan(currentA))
                    fprintf('Abbruch weil Apex = Nan. Endgültige Tiefe: z =%5.0fµm\n', zeta*this.Scaled.Config.WeldingParameter.WaistSize*1e6);
                    break;
                end
                if(currentA < -5)
                    fprintf('Abbruch, weil Apex < -5. Endgültige Tiefe: z =%5.0fµm\n', zeta*this.Scaled.Config.WeldingParameter.WaistSize*1e6);
                    break;
                end
                
                
                % Berechnung des Radius
                func2 = @(alpha) khz_func2(alpha, currentA, arguments, param);
                alpha_interval(1) = 0.5*currentA; % Minimalwert
                alpha_interval(2) = 1.05 * currentAlpha; % Maximalwert
                try
                    currentAlpha = fzero(func2, alpha_interval);
                catch err
                    fprintf([err.message ' Endgültige Tiefe: z =%5.0fµm\n'], zeta*this.Scaled.Config.WeldingParameter.WaistSize*1e6);
                    break;
                end
                
                
                % Abbruchkriterium
                if(isnan(currentAlpha))
                    fprintf('Abbruch weil Radius=Nan. Endgültige Tiefe: z =%5.0fµm\n', zeta*this.Scaled.Config.WeldingParameter.WaistSize*1e6);
                    break;
                end
                if (currentAlpha < 1e-12)
                    fprintf('Abbruch weil Endgültige Tiefe: z =%5.0fµm\n', zeta*this.Scaled.Config.WeldingParameter.WaistSize*1e6);
                    break;
                end
                if (zindex > 10 && currentAlpha > arguments.prevRadius)
                    fprintf('Abbruch weil Radius steigt. Endgültige Tiefe: z =%5.0fµm\n', zeta*this.Scaled.Config.WeldingParameter.WaistSize*1e6);
                    break;
                end
                if (zindex * dz <= -5e-3)
                    fprintf('Abbruch weil Blechtiefe erreicht\n');
                    break;
                end
                
                % Werte übernehmen und sichern
                apex.Add(currentA);
                radius.Add(currentAlpha);
            end
            
            % Umwandlung der Listen in Arrays zur Speicherung
            S_Apex = apex.ToArray();
            S_Radius = radius.ToArray();
        end
    end
    
    methods (Access = private)
        function vhp = CalcVHP(this, veloIdx)
            % Lokale Variablen für weniger Propertiezugriffe
            param = struct;
            param.epsilon = this.Scaled.Config.Material.FresnelEpsilon;
            
            param.scaled = struct();
            param.scaled.waveLength = this.Scaled.WaveLength;
            param.scaled.fokus = this.Scaled.Fokus;
            param.scaled.Rl = this.Scaled.RayleighLength;
            
            thermalDiffusivity = this.Scaled.Config.Material.ThermalDiffusivity;
            thermalConductivity = this.Scaled.Config.Material.ThermalConductivity;
            ambientTemperature = this.Scaled.Config.Material.AmbientTemperature;
            vaporTemperature = this.Scaled.Config.Material.VaporTemperature;
            waistSize = this.Scaled.Config.WeldingParameter.WaistSize;
            maxIntensity = this.Scaled.Config.WeldingParameter.MaxIntensity;
            velocity = this.Scaled.Config.WeldingParameter.TrueVelocityNorm(veloIdx);
            
            % Vorbereitungen
            %Initialer Abstand zum Laser (1D FDM)
            this.xOffset = 5 * waistSize; % [m]
            
            % Diskretisierung der Zeit
            steps_t = 10001;
            t = linspace(0, this.xOffset/velocity, steps_t);
            dt = t(2) - t(1);
            
            % Intensität- und Poynting-Vektor berechnen
            %Vorbereitung der Vektoren
            xVec = (this.xOffset - t*velocity) ./ waistSize; % Normierung mit Strahlradius im Fokus
            yVec = repmat(this.yOffset, 1, steps_t) ./ waistSize; % Normierung mit Strahlradius im Fokus
            zVec = zeros(1, steps_t);
            points = [xVec; yVec; zVec];
            
            % Durchführung der Berechnung
            [pVec, intensity] = calcPoynting(points, param);
            Az = calcFresnel(pVec(:, 1), [0;0;1], param);
            I = maxIntensity .* intensity .* Az;
            
            % Initialisierung
            delta = this.StartD;
            Ts = this.StartT;
            index = 0;
            dTstemp=0;
            
            TempArray = ones(1, steps_t) * ambientTemperature;
            DeltaArray = zeros(1, steps_t);
            
            
            % Berechnung
            for i = 1:steps_t
                dTs = thermalDiffusivity/((1-this.b2)*delta)*(I(i)/thermalConductivity - this.b2*(Ts-ambientTemperature)/delta);
                ddelta = 1/(Ts-ambientTemperature)*(thermalDiffusivity*I(i)/thermalConductivity-dTstemp*delta);
                
                dTstemp = dTs;
                Ts = Ts + dTs * dt;
                delta = delta + ddelta * dt;
                
                TempArray(i) = Ts;
                DeltaArray(i) = delta;
                
                % VHP ausrechnen
                if ~index && Ts > vaporTemperature
                    % VHP gefunden :-)
                    T1 = TempArray(i-1);
                    % Interpolation
                    zeitpunkt = t(i-1) + (vaporTemperature - T1)/(Ts - T1) * dt;
                    
                    vhp = (this.xOffset - zeitpunkt*velocity);
                    return;
                end
            end
        end
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
end

