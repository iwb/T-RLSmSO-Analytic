classdef ConfigComponentGeo < handle
    %ConfigComponentGeo beinhaltet die Abmessungen des Bauteils
    %   Detailed explanation goes here
    
    properties
        Dx = 0.05e-3;   %Örtliche Diskretisierung in x-Richtung [m]
        Dy = 0.04e-3;   %Örtliche Diskretisierung in y-Richtung [m]
        Dz = 0.03e-3;   %Örtliche Diskretisierung in z-Richtung [m]
        
        L = 4e-3;       %Länge des Bauteils (x-Richtung) [m]
        B = 3e-3;       %Breite des Bauteils (y-Richtung) [m]
        D = 2e-3;       %Dicke des Bauteils (z-Richtung) [m]
        
        startD = 0;     %Für einzelne z-Schicht
    end
    
    properties (Dependent = true)
        FieldGrid = struct(); %Enthält das Diskretisierungsnetz für das Bauteil
    end
    
    methods
        function this = ConfigComponentGeo()
        end
        
        function fieldGrid = get.FieldGrid(this)
            % Diskretisierung der Abmessungen als Vektoren [m]
            fieldGrid.X = 0:this.Dx:this.L;
            fieldGrid.Y = 0:this.Dy:this.B;
            fieldGrid.Z = this.startD:this.Dz:this.D;
            
            if isempty(fieldGrid.Z)
                fieldGrid.Z = 0;
            end
            
            % Erzeugen des gesamten Netzes [m]
            [x, y, z] = meshgrid(fieldGrid.X, fieldGrid.Y, ...
                                 fieldGrid.Z);
            
            % Umwandeln in 3-spaltige Matrix
            fieldGrid.Mesh = horzcat(reshape(x, numel(x) ,1), ...
                                     reshape(y, numel(y), 1), ...
                                     reshape(z, numel(z), 1));
        end
    end
end