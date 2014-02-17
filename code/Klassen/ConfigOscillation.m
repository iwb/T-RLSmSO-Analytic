classdef ConfigOscillation < handle
    %ConfigTrajectory beinhaltet alle Parameter für die Schweißtrajektorie
    %   Detailed explanation goes here
    
    properties
        AmplitudeX = 0.3e-3;                %Amplitude in x-Richtung [m]
        AmplitudeY = 0.3e-3;                %Amplitude in y-Richtung [m]
        FrequencyX = 300;                   %Frequrnz in x-Richtung [Hz]
        FrequencyY = 300;                   %Frequrnz in y-Richtung [Hz]
        PhiX = -pi/2;                           %x-Phase [rad]
        PhiY = 0;                        %y-Phase [rad]
        
        Discretization = 40;                %Anzahl der zeitlichen Diskretisierungen pro Periodendauer
        
        Velocity = 16e-3;                   %Vorschubgeschwindigkeit der Oszillation [m/s]
        
        SeamLength = 0.3e-3;                %Schweißnahtlänge [m]
    end
    
    properties (Dependent = true)
        WeldingTime = [];                   %Dauer der Schweißung
    end
    
    methods
        function this = ConfigOscillation()
            this.AmplitudeX = this.AmplitudeX;
            this.AmplitudeY = this.AmplitudeY;
            this.FrequencyX = this.FrequencyX;
            this.FrequencyY = this.FrequencyY;
            this.PhiX = this.PhiX;
            this.PhiY = this.PhiY;
            this.Discretization = this.Discretization;
            this.Velocity = this.Velocity;
            this.SeamLength = this.SeamLength;
        end
        
        function weldingTime = get.WeldingTime(this)
            weldingTime = this.SeamLength/this.Velocity;
        end
    end
    
    
end