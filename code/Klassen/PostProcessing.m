classdef PostProcessing < handle
    %PostProcessing beinhaltet Funktionen zur Umwandlug des
    %Temperaturfeldes und zur grafischen Visualisierung
    %   Detailed explanation goes here
    
    properties
        SolverObject@AbstractSolver;
        
        RestructuredTempField
    end
    
    methods
        function this = PostProcessing(solverObj)
            this.SolverObject = solverObj;
            
            if isempty(this.SolverObject.TemperatureField)
                error('Achtung es wurde kein Temperaturfeld gefunden!')
            end            
            
            % Überführen in lokale Variablen
            x = this.SolverObject.HeatSourceDefinition.TrajectoryInfo.DebugPlot.x;
            y = this.SolverObject.HeatSourceDefinition.TrajectoryInfo.DebugPlot.y;
            z = this.SolverObject.HeatSourceDefinition.TrajectoryInfo.DebugPlot.z;
            
            % Für jeden Zeitschritt wird ein Cell angelegt, das für jede Schicht in
            % z-Richtung(xy-Ebene) eine Matrix mit der Temperatur an der x,y Position
            % enthält
            this.RestructuredTempField = cell(1, size(this.SolverObject.TemperatureField,2));
            for j = 1:size(this.SolverObject.TemperatureField, 2)
                for i = 1:length(z)
                    this.RestructuredTempField{1,j}{i,1} = reshape(this.SolverObject.TemperatureField(length(x)*length(y)*(i-1)+1: ...
                        length(x)*length(y)*i, j), length(y), length(x));
                end
            end
        end
        
        function PlotContour(this, sliced)
            % Überführen in lokale Variablen
            x = this.SolverObject.HeatSourceDefinition.TrajectoryInfo.DebugPlot.x;
            y = this.SolverObject.HeatSourceDefinition.TrajectoryInfo.DebugPlot.y;
            l = max(this.SolverObject.HeatSourceDefinition.TrajectoryInfo.DebugPlot.x);
            b = max(this.SolverObject.HeatSourceDefinition.TrajectoryInfo.DebugPlot.y);
            
            maxTemperature = max(max(this.RestructuredTempField{1,end}{sliced,1}));
            minTemperature = min(min(this.RestructuredTempField{1,end}{sliced,1}));
            
            figure('units','normalized','outerposition',[0 0 1 1])
            contourf(x, y, this.RestructuredTempField{1,end}{sliced,1}, linspace(minTemperature, maxTemperature, 100))
            xlim([0 max(l, b)])
            ylim([0 max(l, b)])
            shading flat
            colorbar
            caxis([minTemperature, maxTemperature])
        end
        
        function PlotVolumeSlice(this, sliced)
            % Überführen in lokale Variablen
            l = this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.L;
            b = this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.B;
            d = this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.D;
            
            TempField3D = zeros(size(this.RestructuredTempField{1,1}{1,1},1), size(this.RestructuredTempField{1,1}{1,1},2), size(this.RestructuredTempField{1,1},1));
            for i = 1:size(TempField3D,3)
                TempField3D(:,:,i) = this.RestructuredTempField{1,end}{i,1};
            end
            
            xslice = [this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.L];
            yslice = [this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.B];
            zslice = linspace(0,this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.D, sliced);
            
            [x,y,z] = meshgrid(0:this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.Dx:this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.L, ...
                0:this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.Dy:this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.B, ...
                0:this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.Dz:this.SolverObject.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.D);
            
            for i = 1:length(zslice)
                slice(x, y, z, TempField3D, xslice, yslice, zslice(i))
                xlim([0 max([l,b,d])])
                ylim([0 max([l,b,d])])
                zlim([0 max([l,b,d])])
                set(gca,'zdir','reverse')
                colormap(jet)
                colorbar
                drawnow
                pause(0.1)
            end
        end
    end
    
end

