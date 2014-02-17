function CheckHeatSourceField( object, Tfield, anzq, anzt )
%CheckHeatSourceField speichert figures für jedes T-Feld der einzelnen WQ
%   Detailed explanation goes here

Tfield = 293 + Tfield;

x = object.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.FieldGrid.X;
y = object.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.FieldGrid.Y;
z = object.HeatSourceDefinition.TrajectoryInfo.Config.ComponentGeo.FieldGrid.Z;

RestructuredTField = cell(1, size(Tfield,2));
for j = 1:size(Tfield, 2)
    for i = 1:length(z)
        RestructuredTField{1,j}{i,1} = reshape(Tfield(length(x)*length(y)*(i-1)+1: ...
            length(x)*length(y)*i, j), length(y), length(x));
    end
end

maxT = max(max(Tfield));
minT = min(min(Tfield));
h = figure;
contourf(x, y, RestructuredTField{1,1}{1,1}, linspace(maxT, minT, 100))
shading flat
colorbar
title([num2str(anzq) '_' num2str(anzt)])

save(['D:\Debugging\HS' num2str(anzq) '_' num2str(anzt)], 'RestructuredTField')
saveas(h, ['D:\Debugging\HS' num2str(anzq) '_' num2str(anzt)], 'fig')
close(h)

end

