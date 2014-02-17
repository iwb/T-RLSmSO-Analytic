%% Clearup
clear all; clc

%% Daten laden
a = [0.2e-3, 0.375e-3, 0.55e-3];
v = [16e-3, 108e-3, 200e-3];
p = [1000, 2000, 3000];

completeData{1} = xlsread('fminSummary.xlsx', '50Osci', 'B2:F28');
completeData{2} = xlsread('fminSummary.xlsx', '70Osci', 'B2:F28');
completeData{3} = xlsread('fminSummary.xlsx', '100Osci', 'B2:F28');

%% Figure
% choose data
n = 2;

% discretisation of all y-axes
ylimdisc = 5;

% cols & rows
cols = 3;
rows = 3;
ng = 3;

fontsize = 14;

% plotting starts here
figure('name', ['Interactionplot' num2str(n)], 'units', 'normalized', 'outerposition', [0 0 1 1]);

clf;
BigAx = newplot;
hold_state = ishold;
set(BigAx,'Visible','off','color','none');

pos = get(BigAx,'Position');
% width and height for each individual axes
width = pos(3)/(cols+1);
height = pos(4)/rows;
space = 0.02; % 2 percent space between axes
% the position of the big axes is adjusted
pos(1:2) = pos(1:2) - 0.05*[ng*width/2 height];
% this is the x coordinate for the legends
legx = pos(1) + pos(3) - 2*width/ng;

% Set all the limits to be the same and leave
% just a 10% gap between data and axes.
inset = 0.1;
ylimmax = 2000;
ylimmin = 200;

%% Amplitude-Amplitude
axPos = [pos(1)+(1-1)*width, pos(2)+(rows-1)*height, ...
    width*(1-space), height*(1-space)];    % position of each panel axes
ax(1,1) = axes('Position',axPos, 'visible', 'on', 'Box','on');

handles = plot(a, [200, 1100, 2000]);
set(handles, 'visible','off');
set(gca, 'xticklabel', '', 'yticklabel', '', 'xtick', [], 'ytick', []);

xlims = get(gca,'xlim');
ylims = get(gca,'ylim');
h = text(mean(xlims), mean(ylims), 'a', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
set(h, 'fontsize',fontsize);


%% Vorschub-Ampltide
axPos = [pos(1)+(2-1)*width, pos(2)+(rows-1)*height, ...
    width*(1-space), height*(1-space)];    % position of each panel axes
ax(1,2) = axes('Position',axPos, 'visible', 'on', 'Box','on');

completeData{n} = sortrows(completeData{n}, 2);
completeData{n} = sortrows(completeData{n}, 1);

pmean_a = zeros(3,2,3);
count = 1;
for i = 1:3
    for ii = 1:3
        for iii = 1:2
            pmean_a(ii,iii,i) = mean(completeData{n}(3*count-2:3*count, iii+3));
        end
        count = count + 1;
    end
end

a1l = plot(pmean_a(:,1,1), '-*', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold on
a1u = plot(pmean_a(:,2,1), '-', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);

a2l = plot(pmean_a(:,1,2), '--*', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);
a2u = plot(pmean_a(:,2,2), '--', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);

a3l = plot(pmean_a(:,1,3), ':*', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
a3u = plot(pmean_a(:,2,3), ':', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold off

% Set the x axis limit
xlim = [1, ng];
df = diff(xlim)*inset;
set(gca, 'xtick', 1:ng, 'xticklabel', {'16,67', 'mm/s', '200'}, 'xlim', [xlim(1)-df, xlim(2)+df]);

% make the legend
legh = legend([a1u, a1l, a2u, a2l, a3u, a3l], ...
    {sprintf('fmax\n         a = 0,2 mm'), 'fmin', sprintf('fmax\n         a = 0,375 mm'), 'fmin', sprintf('fmax\n         a = 0,55 mm'), 'fmin'}, 'location','northeast');
% place the legend to the very right
legpos = get(legh, 'position');
legpos(1) = legx;
set(legh, 'position', legpos)


%% Leistung-Amplitude
axPos = [pos(1)+(3-1)*width pos(2)+(rows-1)*height ...
    width*(1-space) height*(1-space)];    % position of each panel axes
ax(1,3) = axes('Position',axPos, 'visible', 'on', 'Box','on');

completeData{n} = sortrows(completeData{n}, 3);
completeData{n} = sortrows(completeData{n}, 1);

vmean_a = zeros(3,2,3);
count = 1;
for i = 1:3
    for ii = 1:3
        for iii = 1:2
            vmean_a(ii,iii,i) = mean(completeData{n}(3*count-2:3*count, iii+3));
        end
        count = count + 1;
    end
end

plot(vmean_a(:,1,1), '-*', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold on
plot(vmean_a(:,2,1), '-', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);

plot(vmean_a(:,1,2), '--*', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);
plot(vmean_a(:,2,2), '--', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);

plot(vmean_a(:,1,3), ':*', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
plot(vmean_a(:,2,3), ':', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold off

% Set the x axis limit
xlim = [1, ng];
df = diff(xlim)*inset;
set(gca, 'xtick', 1:ng, 'xticklabel', {'1000', 'W', '3000'}, 'xlim', [xlim(1)-df, xlim(2)+df]);


%% Amplitude-Vorschub
axPos = [pos(1)+(1-1)*width pos(2)+(rows-2)*height ...
    width*(1-space) height*(1-space)];    % position of each panel axes
ax(2,1) = axes('Position',axPos, 'visible', 'on', 'Box','on');

completeData{n} = sortrows(completeData{n}, 1);
completeData{n} = sortrows(completeData{n}, 2);

pmean_v = zeros(3,2,3);
count = 1;
for i = 1:3
    for ii = 1:3
        for iii = 1:2
            pmean_v(ii,iii,i) = mean(completeData{n}(3*count-2:3*count, iii+3));
        end
        count = count + 1;
    end
end

v1l = plot(pmean_v(:,1,1), '-*', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold on
v1u = plot(pmean_v(:,2,1), '-', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);

v2l = plot(pmean_v(:,1,2), '--*', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);
v2u = plot(pmean_v(:,2,2), '--', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);

v3l = plot(pmean_v(:,1,3), ':*', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
v3u = plot(pmean_v(:,2,3), ':', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold off

% Set the x axis limit
xlim = [1, ng];
df = diff(xlim)*inset;
set(gca, 'xtick', 1:ng, 'xticklabel', {'0,2', 'mm', '0,55'}, 'xlim', [xlim(1)-df, xlim(2)+df]);

% make the legend
legh = legend([v1u, v1l, v2u, v2l, v3u, v3l], ...
    {sprintf('fmax\n         v = 16,67 mm/s'), 'fmin', sprintf('fmax\n         v = 108 mm/s'), 'fmin', sprintf('fmax\n         v = 200 mm/s'), 'fmin'}, 'location','northeast');
% place the legend to the very right
legpos = get(legh, 'position');
legpos(1) = legx;
set(legh, 'position', legpos)


%% Vorschub-Vorschub
axPos = [pos(1)+(2-1)*width pos(2)+(rows-2)*height ...
    width*(1-space) height*(1-space)];    % position of each panel axes
ax(2,2) = axes('Position',axPos, 'visible', 'on', 'Box','on');

handles = plot(v, [200, 1100, 2000]);
set(handles, 'visible','off');
set(gca, 'xticklabel', '', 'yticklabel', '', 'xtick', [], 'ytick', []);

xlims = get(gca,'xlim');
ylims = get(gca,'ylim');
h = text(mean(xlims), mean(ylims), 'v', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
set(h, 'fontsize',fontsize);


%% Leistung-Vorschub
axPos = [pos(1)+(3-1)*width pos(2)+(rows-2)*height ...
    width*(1-space) height*(1-space)];    % position of each panel axes
ax(2,3) = axes('Position',axPos, 'visible', 'on', 'Box','on');

completeData{n} = sortrows(completeData{n}, 3);
completeData{n} = sortrows(completeData{n}, 2);

amean_v = zeros(3,2,3);
count = 1;
for i = 1:3
    for ii = 1:3
        for iii = 1:2
            amean_v(ii,iii,i) = mean(completeData{n}(3*count-2:3*count, iii+3));
        end
        count = count + 1;
    end
end

plot(amean_v(:,1,1), '-*', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold on
plot(amean_v(:,2,1), '-', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);

plot(amean_v(:,1,2), '--*', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);
plot(amean_v(:,2,2), '--', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);

plot(amean_v(:,1,3), ':*', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
plot(amean_v(:,2,3), ':', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold off

% Set the x axis limit
xlim = [1, ng];
df = diff(xlim)*inset;
set(gca, 'xtick', 1:ng, 'xticklabel', {'1000', 'W', '3000'}, 'xlim', [xlim(1)-df, xlim(2)+df]);


%% Amplitude-Leistung
axPos = [pos(1)+(1-1)*width pos(2)+(rows-3)*height ...
    width*(1-space) height*(1-space)];    % position of each panel axes
ax(3,1) = axes('Position',axPos, 'visible', 'on', 'Box','on');

completeData{n} = sortrows(completeData{n}, 1);
completeData{n} = sortrows(completeData{n}, 3);

vmean_p = zeros(3,2,3);
count = 1;
for i = 1:3
    for ii = 1:3
        for iii = 1:2
            vmean_p(ii,iii,i) = mean(completeData{n}(3*count-2:3*count, iii+3));
        end
        count = count + 1;
    end
end

p1l = plot(vmean_p(:,1,1), '-*', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold on
p1u = plot(vmean_p(:,2,1), '-', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);

p2l = plot(vmean_p(:,1,2), '--*', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);
p2u = plot(vmean_p(:,2,2), '--', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);

p3l = plot(vmean_p(:,1,3), ':*', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
p3u = plot(vmean_p(:,2,3), ':', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold off

% Set the x axis limit
xlim = [1, ng];
df = diff(xlim)*inset;
set(gca, 'xtick', 1:ng, 'xticklabel', {'0,2', 'mm', '0,55'}, 'xlim', [xlim(1)-df, xlim(2)+df]);

% make the legend
legh = legend([p1u, p1l, p2u, p2l, p3u, p3l], ...
    {sprintf('fmax\n         p = 1000 W'), 'fmin', sprintf('fmax\n         p = 2000 W'), 'fmin', sprintf('fmax\n         p = 3000 W'), 'fmin'}, 'location','northeast');
% place the legend to the very right
legpos = get(legh, 'position');
legpos(1) = legx;
set(legh, 'position', legpos)

%% Vorschub-Leistung
axPos = [pos(1)+(2-1)*width pos(2)+(rows-3)*height ...
    width*(1-space) height*(1-space)];    % position of each panel axes
ax(3,2) = axes('Position',axPos, 'visible', 'on', 'Box','on');

completeData{n} = sortrows(completeData{n}, 2);
completeData{n} = sortrows(completeData{n}, 3);

amean_p = zeros(3,2,3);
count = 1;
for i = 1:3
    for ii = 1:3
        for iii = 1:2
            amean_p(ii,iii,i) = mean(completeData{n}(3*count-2:3*count, iii+3));
        end
        count = count + 1;
    end
end

plot(amean_p(:,1,1), '-*', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold on
plot(amean_p(:,2,1), '-', 'color', [0.22 0.5 0.52], 'LineSmoothing', 'on', 'LineWidth', 1.5);

plot(amean_p(:,1,2), '--*', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);
plot(amean_p(:,2,2), '--', 'color', [0.83 0.53 0.15], 'LineSmoothing', 'on', 'LineWidth', 1.5);

plot(amean_p(:,1,3), ':*', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
plot(amean_p(:,2,3), ':', 'color', [0.6 0.77 0.34], 'LineSmoothing', 'on', 'LineWidth', 1.5);
hold off

% Set the x axis limit
xlim = [1, ng];
df = diff(xlim)*inset;
set(gca, 'xtick', 1:ng, 'xticklabel', {'16,67', 'mm/s', '200'}, 'xlim', [xlim(1)-df, xlim(2)+df]);


%% Leistung-Leistung
axPos = [pos(1)+(3-1)*width pos(2)+(rows-3)*height ...
    width*(1-space) height*(1-space)];    % position of each panel axes
ax(3,3) = axes('Position', axPos, 'visible', 'on', 'Box','on');

handles = plot(p, [200, 1100, 2000]);
set(handles, 'visible','off');
set(gca, 'xticklabel', '', 'yticklabel', '', 'xtick', [], 'ytick', []);

xlims = get(gca,'xlim');
ylims = get(gca,'ylim');
h = text(mean(xlims), mean(ylims), 'p', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
set(h, 'fontsize',fontsize);


%% formatting plot
% put the xticklabel to top in the top-row axes
set(ax(1,:),'XAxisLocation','top');

% put the yticklabel to top in the most right axes
set(ax(:,3),'YAxisLocation','right');

% Set all the limits to be the same and leave
% just a 5% gap between data and axes.
ax_diag = ax;
ax_diag(logical(eye(size(ax_diag)))) = ax(1,2);

dy = (ylimmax - ylimmin)*inset;
set(ax_diag, 'ylim', [ylimmin-dy, ylimmax+dy]);
set(ax_diag, 'ytick', linspace(ylimmin, ylimmax, ylimdisc));
yticklabels = num2cell(linspace(ylimmin, ylimmax, ylimdisc));
yticklabels = cellfun(@num2str, yticklabels, 'UniformOutput', false);
yticklabels{1,end-1} = 'Hz';
set(ax_diag, 'yticklabel', yticklabels);

% Ticks and labels on outer plots only
set(ax(2:rows-1,:),'xticklabel','')
set(ax(:,2:cols-1),'yticklabel','')

set(ax, 'fontsize', fontsize)
set(ax, 'box', 'on')


















