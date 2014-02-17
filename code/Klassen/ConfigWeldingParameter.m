classdef ConfigWeldingParameter < handle
    %ConfigWeldingParameter beinhaltet alle Schweißparameter
    %   Detailed explanation goes here
    
    properties
        LaserPower = 1000;          %Laserleistung [W]
        WaveLength = 1064e-9;       %Wellenlänge des Lasers [m]
        
        WaistSize = 25e-6;      %Strahlradius im Fokus [m]
        
        Fokus = 0e-6;               %Lage des Fokus [m]
        
        TrueVelocityNorm = NaN;     %Betrag der Bahngeschwindigkeit [m/s]
    end
    
    properties (Dependent = true)
        MaxIntensity                %Maximale Intensität des Lasers [W/m^2]
        
        RayleighLength              %Rayleighlänge [m]
    end
    
    methods
        function this = ConfigWeldingParameter()
            this.LaserPower = this.LaserPower;
        end
        
        function maxInten = get.MaxIntensity(this)
            maxInten = this.LaserPower * 2/(pi*this.WaistSize^2);
        end
        
        function rayLength = get.RayleighLength(this)
            rayLength = pi * this.WaistSize^2 / this.WaveLength;
        end
    end
end

