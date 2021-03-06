% Plot evolution of inflation in some inflation targeting countries
clearvars
close all

% Add all the relevant paths
current_dir = pwd;
cd ../ % go up 1 levels
basepath = pwd;
cd .. % go up another level to BC_Research
BC_researchpath = pwd;
toolpath = [BC_researchpath '/matlab_toolbox'];
export_figpath = [toolpath '/Export_Fig'];
figpath = [basepath '/figures'];
tablepath = [basepath '/tables'];
datapath = [basepath '/data'];

cd(current_dir)

addpath(basepath)
addpath(toolpath)
addpath(export_figpath)
addpath(figpath)
addpath(datapath)

% Variable stuff ---
print_figs    = 0;
do_old_plots  = 0;
if print_figs ==1
    output_table  = 1;
else
    output_table =0;
end

fs=20; % fontsize
%% Read in data

% New Zealand
xls_file = [datapath, '/hm1.xlsx'];
sheetname = 'Data';
[num,txt,raw] = xlsread(xls_file, sheetname);
datenums = x2mdate(num(:,1));

cpi_NZ = num(:,4);
datenums_NZ = datenums;

% Canada
xls_file = [datapath, '/CPI_MONTHLY.xlsx'];
sheetname = 'data';
[num,txt,raw] = xlsread(xls_file, sheetname);
datenums = x2mdate(num(:,1),1);

cpi_CA = num(:,4);
datenums_CA = datenums;

% UK
xls_file = [datapath, '/L55O-270819.xls'];
sheetname = 'data';
[num,txt,raw] = xlsread(xls_file, sheetname);
dates = char(txt(7:end,1));
hyphens = char(ones(size(dates,1),1) * '-');
datestrings = [dates(:,1:4), hyphens, dates(:,6:8)];
datenums = datenum(datestrings,'yyyy-mm');


cpi_UK = num(:,1);
datenums_UK = datenums(3:end);

% Sweden
xls_file = [datapath, '/PR0101C5.xlsx'];
sheetname = 'data';
[num,txt,raw] = xlsread(xls_file, sheetname);
dates = char(txt(3,:));
hyphens = char(ones(size(dates,1),1) * '-');
datestrings = [dates(:,1:4), hyphens, dates(:,6:7)];
datenums = datenum(datestrings,'yyyy-mm');

cpi_SWE = num; 
datenums_SWE = datenums;


%% Plot 'em

figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen

% New Zealand
subplot(2,2,1)
plot(datenums_NZ,cpi_NZ, 'b', 'linewidth',2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
datetick('x','yyyy-mm')
legend('CPI y-o-y % changes, quarterly')
title('New Zealand (1990)')

% Canada
subplot(2,2,2)
plot(datenums_CA,cpi_CA, 'b', 'linewidth',2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
datetick('x','yyyy-mm')
legend('CPI y-o-y % changes, monthly')
title('Canada (1991)')

% UK
subplot(2,2,3)
plot(datenums_UK, cpi_UK, 'b', 'linewidth',2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
datetick('x','yyyy-mm')
legend('CPIH annual % changes, monthly (interpolated)')
title('UK (1992)')

% Sweden
subplot(2,2,4)
plot(datenums_SWE,cpi_SWE, 'b', 'linewidth',2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
datetick('x','yyyy-mm')
legend('CPI monthly % changes, monthly')
title('Sweden (1993)')


if print_figs ==1
    figname = ['materials1_infl_targeting_countries']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end


