figure('Renderer','zbuffer', 'units','normalized','outerposition',[0.2 0.2 0.35 0.7]);
axis tight manual;

vers = 17;
intAnz = 50;
stepAnz = length(assignment.FinishedTFields{vers,2});

writerObj = VideoWriter(['Versuch' int2str(vers) '.avi']);
writerObj.FrameRate = 7;
writerObj.Quality = 100;
open(writerObj);

for i = stepAnz:-1:1
    % Interpolation
    newxLin = linspace(assignment.TimeStepDiscretisation{vers,1}{1,i}{1,1}(1,1), assignment.TimeStepDiscretisation{vers,1}{1,i}{1,1}(1,end), intAnz);
    newyLin = linspace(assignment.TimeStepDiscretisation{vers,1}{1,i}{1,2}(1,1), assignment.TimeStepDiscretisation{vers,1}{1,i}{1,2}(1,end), intAnz);
    newzLin = linspace(assignment.TimeStepDiscretisation{vers,1}{1,i}{1,3}(1,1), assignment.TimeStepDiscretisation{vers,1}{1,i}{1,3}(1,end), intAnz);
    
    [newx, newy, newz] = meshgrid(newxLin, newyLin, newzLin);
    
    newx = reshape(newx, [numel(newx), 1]);
    newy = reshape(newy, [numel(newy), 1]);
    newz = reshape(newz, [numel(newz), 1]);
    
    [oldx, oldy, oldz] = meshgrid(assignment.TimeStepDiscretisation{vers,1}{1,i}{1,1}, assignment.TimeStepDiscretisation{vers,1}{1,i}{1,2}, assignment.TimeStepDiscretisation{vers,1}{1,i}{1,3});
    oldx = reshape(oldx, [numel(oldx), 1]);
    oldy = reshape(oldy, [numel(oldy), 1]);
    oldz = reshape(oldz, [numel(oldz), 1]);
    
    Finterp = scatteredInterpolant(oldx, oldy, oldz, assignment.FinishedTFields{vers, 2}{1,i}, 'linear', 'linear');
    TFieldInterp = Finterp(newx, newy, newz);
    
    
    timeST = TFieldInterp;
    timeST = reshape(timeST, [intAnz, intAnz, intAnz]);
    
    [Nx, Ny, Nz, Nv] = subvolume(newxLin, newyLin, newzLin, timeST, [newxLin(1),newxLin(end), newyLin(ceil(end/2)),newyLin(end), newzLin(1),newzLin(end)]);
    
    slice(Nx, Ny, Nz, Nv, [nan nan], [newyLin(ceil(end/2)) nan], [newzLin(1) nan]);
    %slice(newxLin, newyLin, newzLin, timeST, [nan nan], [newyLin(1) nan], [newzLin(1,1) nan]);
    cb = colorbar;
    set(gca, 'CLim', [300, 3133]);
    set(cb, 'YTick', [500, 1000, 1500, 2000, 2500, 3000]);
    set(cb, 'YTickLabel', {'500', '1000', '1500', '2000', 'K', '3000'});
    colormap(hot)
    caxis([300 3133])
    shading interp
    set(gca, 'ZDir', 'reverse')
    daspect([1 1 1])
    %view(-45, 84)
    axis off
    set(gca,'FontSize',18)
    xlim([newxLin(1) newxLin(end)]);
    
    frame = getframe(gcf);
    writeVideo(writerObj, frame);
end
close(writerObj);














