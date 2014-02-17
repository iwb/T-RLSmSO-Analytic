tic
close																%Alle Fenster schließen	
clearvars															%Alle Variablen löschen
addpath('./Klassen');
addpath('./TopLevelFunctions');
TestConfig = Config();												%Config Objekt erstellen
TestCalcTraj = CalcTrajectory(TestConfig);							%Trajektorien Objekt erstellen
TestCalcTraj.CalcOscillation();										%Trajektorie berechnen

TestScaledConfig = ScaledConfig(TestConfig);
TestScaledConfig.Scale();
TestReducedModel = ReducedModel(TestScaledConfig, [1]);
TestReducedModel.CalcEntireTFields();

TestCellCalHeatSources = PrepCalibration(TestReducedModel);			%Vorbereitung zur Kalibrierung

TestCalibration = Calibration(TestReducedModel, TestCellCalHeatSources); %Erstellen eines Kalibrierungs Objektes mit einem ReducedModel und den erzeugten HeatSources zum Kalibrieren
TestCalibration.Calibrating();										%Durchführung der Kalibrierung

TestDoppelEllWQ = DoubleEllipHeatSource(TestCalcTraj);				%Doppeltelliptisches Wärmequellen Objekt erstellen --> enthält abhängig von der Trajektorie unterschiedliche WQ in einem HeatSourceField

TestDoppelEllWQ = MatchCaliHS(TestCalibration, TestDoppelEllWQ);    %Die kalibrierten Wärmequelen werden an die gewünschten Positionen in der Trajektorie gesetzt


TestDoppelEllWQ.HeatSourceReflection([0, 0, 0]);					%Kalibrierte Wärmequellen reflektieren und WS erzeugen.

%MirrorTest(TestDoppelEllWQ);

TestDoppelEllSol = DoubleEllipSolver(TestDoppelEllWQ);				%Erzeugen eines Solver Objektes für eine doppelt elliptische Wärmequelle

TestDoppelEllSol.RunSolver();										%Start der Berechnung des Temperaturfeldes
toc














[x,y,z] = meshgrid(TestReducedModel.DiskreteCaliField{1,1}{1,1}, TestReducedModel.DiskreteCaliField{1, 1}{1, 2}, TestReducedModel.DiskreteCaliField{1, 1}{1, 3});

figure
slice(x,y,z,TestReducedModel.EntireFields{1,1}, [x(1), x(end)], [y(1), y(end)], [z(1), z(end)])
daspect([1 1 1])
shading flat
colorbar
caxis([0 1])
set(gca, 'ZDir', 'reverse')

[Nx, Ny, Nz, Nv] = subvolume(TestReducedModel.EntireFields{1,1}, [nan,nan, ceil(size(TestReducedModel.EntireFields{1,1},1)/2),size(TestReducedModel.EntireFields{1,1},1), nan,nan]);
figure
slice(Nx, Ny, Nz, Nv, [1, size(TestReducedModel.EntireFields{1,1},2)], [ceil(size(TestReducedModel.EntireFields{1,1},1)/2),size(TestReducedModel.EntireFields{1,1},1)], [1,size(TestReducedModel.EntireFields{1,1},3)])
daspect([1 1 1])
shading flat
colorbar
caxis([0 1])
set(gca,'ZDir','reverse')









[x, y, z] = size(this.ReducedModel.EntireFields{1,1});

test = zeros(x, y, z);
calitest = zeros(x, y, z);
testse = zeros(x, y, z);

test = reshape(wqTField, [x, y, z]);
calitest = reshape(caliTField, [x, y, z]);
testse = reshape(se, [x, y, z]);

figure
slice(test, [1,size(test,2)], [1,size(test),1], [1,size(test,3)])
daspect([1 1 1])
shading flat
%colorbar
caxis([0 1])
set(gca, 'ZDir', 'reverse')

figure
slice(calitest, [1,size(calitest,2)], [1,size(calitest),1], [1,size(calitest,3)])
daspect([1 1 1])
shading flat
%colorbar
caxis([0 1])
set(gca, 'ZDir', 'reverse')

figure
slice(testse, [1,size(testse,2)], [1,size(testse),1], [1,size(testse,3)])
daspect([1 1 1])
shading flat
%colorbar
caxis([0 0.1])
set(gca, 'ZDir', 'reverse')



[Nx, Ny, Nz, Nv] = subvolume(test, [nan,nan, ceil(size(test,1)/2),size(test,1), nan,nan]);

figure
slice(Nx, Ny, Nz, Nv, [1, size(test,2)], [ceil(size(test,1)/2),size(test,1)], [1,size(test,3)])
daspect([1 1 1])
set(gca,'ZDir','reverse')
shading flat


fId = figure('Renderer','zbuffer', 'units','normalized','outerposition',[0 0 1 1]);
axis tight manual;
set(gca,'NextPlot','replaceChildren');

writerObj = VideoWriter('out.avi');
writerObj.FrameRate = 10;
open(writerObj);

for i = 1:249
	time = assignment.FinishedTFields{1, 2}{1,i};
	time = reshape(time, [length(assignment.TimeStepDiscretisation{1,1}{1, i}{1,2}), length(assignment.TimeStepDiscretisation{1,1}{1, i}{1,1}), length(assignment.TimeStepDiscretisation{1,1}{1, i}{1,3})]);
    
    figure(fId);
	subplot(1,2,1)
	slice(assignment.TimeStepDiscretisation{1,1}{1, i}{1,1}, assignment.TimeStepDiscretisation{1,1}{1, i}{1,2}, assignment.TimeStepDiscretisation{1,1}{1, i}{1,3}, time, [assignment.TimeStepDiscretisation{1,1}{1, 1}{1,1}(1,1) assignment.TimeStepDiscretisation{1,1}{1, 1}{1,1}(1,end)], [assignment.TimeStepDiscretisation{1,1}{1, 1}{1,2}(1,1) assignment.TimeStepDiscretisation{1,1}{1, i}{1,2}(1,end)], [assignment.TimeStepDiscretisation{1,1}{1, i}{1,3}(1,1) assignment.TimeStepDiscretisation{1,1}{1, i}{1,3}(1,end)]);
	colorbar
	caxis([300 3000])
    shading interp
	set(gca, 'ZDir', 'reverse')
	daspect([1 1 1])
	view(-57, 76)
    xlim([min(assignment.TimeStepDiscretisation{1,1}{1, i}{1,1}) max(assignment.TimeStepDiscretisation{1,1}{1, i}{1,1})])
	%drawnow
    
    subplot(1,2,2)
	slice(assignment.TimeStepDiscretisation{1,1}{1, i}{1,1}, assignment.TimeStepDiscretisation{1,1}{1, i}{1,2}, assignment.TimeStepDiscretisation{1,1}{1, i}{1,3}, time, [assignment.TimeStepDiscretisation{1,1}{1, 1}{1,1}(1,1) assignment.TimeStepDiscretisation{1,1}{1, 1}{1,1}(1,end)], [assignment.TimeStepDiscretisation{1,1}{1, 1}{1,2}(1,1) assignment.TimeStepDiscretisation{1,1}{1, i}{1,2}(1,end)], [assignment.TimeStepDiscretisation{1,1}{1, i}{1,3}(1,1) assignment.TimeStepDiscretisation{1,1}{1, i}{1,3}(1,end)]);
	colorbar
	caxis([300 3000])
	set(gca, 'ZDir', 'reverse')
	daspect([1 1 1])
	view(-57, 76)
    xlim([min(assignment.TimeStepDiscretisation{1,1}{1, i}{1,1}) max(assignment.TimeStepDiscretisation{1,1}{1, i}{1,1})])
	%drawnow
    
    frame = getframe(gcf);
    writeVideo(writerObj, frame);
end
close(writerObj);