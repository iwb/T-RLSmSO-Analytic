classdef ConfigComponentGeo < handle
    %ConfigComponentGeo beinhaltet die Abmessungen des Bauteils
    %   Detailed explanation goes here
    
    properties
        Dx = 0.05e-3;   %Örtliche Diskretisierung in x-Richtung [m]
        Dy = 0.04e-3;   %Örtliche Diskretisierung in y-Richtung [m]
        Dz = 0.03e-3;   %Örtliche Diskretisierung in z-Richtung [m]
        
        Xstart = 0e-3;
        Ystart = 0e-3;
        Zstart = 0e-3;
        
        Xend = 4e-3;       %Länge des Bauteils (x-Richtung) [m]
        Yend = 3e-3;       %Breite des Bauteils (y-Richtung) [m]
        Zend = 2e-3;       %Dicke des Bauteils (z-Richtung) [m]
    end
    
    properties (Dependent = true)
        FieldGrid = struct(); %Enthält das Diskretisierungsnetz für das Bauteil
    end
    
    methods
        function this = ConfigComponentGeo()
        end
        
        function fieldGrid = get.FieldGrid(this)
            % Test ob *end > *start
            if this.Xstart > this.Xend || this.Ystart > this.Yend || this.Zstart > this.Zend
                warning('Work piece definition might be wrong. Please check again!');
                createLog('\nWork piece definition might be wrong. Please check again!\n', 'a');
            end
            
            % Diskretisierung der Abmessungen als Vektoren [m]
            fieldGrid.X = this.Xstart:this.Dx:this.Xend;
            fieldGrid.Y = this.Ystart:this.Dy:this.Yend;
            fieldGrid.Z = this.Zstart:this.Dz:this.Zend;
            
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