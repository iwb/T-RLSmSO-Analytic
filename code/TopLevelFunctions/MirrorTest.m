function MirrorTest( HS )
%TestSpiegel Testfunktion zur Überprüfung der Spiegelungen
%   Detailed explanation goes here

count = 1;
check = true;
while check
    if strcmp(HS.HeatSourceField{count,1}.Type, 'WQ') || strcmp(HS.HeatSourceField{count,1}.Type, 'WS')
        count = count + 1;
    else
        check = false;
    end
end

PlotMainTraj = zeros(count - 1, 3);
PlotMirrorTraj = zeros(length(HS.HeatSourceField) - count, 3);


for i = 1:length(HS.HeatSourceField)
    if strcmp(HS.HeatSourceField{i,1}.Type, 'WQ') || strcmp(HS.HeatSourceField{i,1}.Type, 'WS')
        PlotMainTraj(i,:) = HS.HeatSourceField{i,1}.TrajectoryData.Position;
    else
        PlotMirrorTraj(i,:) = HS.HeatSourceField{i,1}.TrajectoryData.Position;
    end
end

PlotMirrorTraj(PlotMirrorTraj(:,1) == 0, :) = [];

h = figure;
plot([0;0;HS.TrajectoryInfo.Config.ComponentGeo.L;HS.TrajectoryInfo.Config.ComponentGeo.L;0], ...
    [0;HS.TrajectoryInfo.Config.ComponentGeo.B;HS.TrajectoryInfo.Config.ComponentGeo.B;0;0], 'r')
hold on
plot(PlotMainTraj(:,1), PlotMainTraj(:,2), '--g')
plot(PlotMirrorTraj(:,1), PlotMirrorTraj(:,2), 'X')
xlim([-max(max(PlotMirrorTraj)),max(max(PlotMirrorTraj))+0.002])
ylim([-max(max(PlotMirrorTraj)),max(max(PlotMirrorTraj))+0.002])
hold off

end

