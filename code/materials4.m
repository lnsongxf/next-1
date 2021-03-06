% materials 4
% Prepare DW
% 20 Sep 2019
clearvars
close all
clc

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
lw=2; % linewidth
fs_pres = 80;
lw_pres = 6;
fs_prop = 40;
lw_prop = 4;

%% Simulation
T = 40
burnin = 0;

[param, setp] = parameters_next;

bet = param.bet;
sig = param.sig;
alph = param.alph;
kapp = param.kapp;
psi_x = param.psi_x;
psi_pi = param.psi_pi;
w = param.w;
gbar = param.gbar;
thetbar = param.thetbar;
rho_r = param.rho_r;
rho_i = param.rho_i;
rho_u = param.rho_u;
sig_r = param.sig_r;
sig_i = param.sig_i;
sig_u = param.sig_u;
n = 3; % fortunately, this is the dimension of everything
P = eye(n).*[rho_r, rho_i, rho_u]';
SIG = eye(n).*[sig_r, sig_i, sig_u]';


% Sequence of innovations
rng(0)
e = randn(n,T);

% Solve RE model
[fyn, fxn, fypn, fxpn] = model_NK(param);
[gx,hx]=gx_hx_alt(fyn,fxn,fypn,fxpn);
[ny, nx] = size(gx);
[Ap_RE, As_RE, Aa_LR, Ab_LR, As_LR, B1, B2] = matrices_A(param, setp);

% Simulate the three models
% Use Ryan's code to simulate from the RE model
[x_RE, y_RE] = sim_model(gx,hx,SIG,T,burnin,e);

% LR learning (only constant, only for pi) EDIT THIS
anal = 1; % take analytical LR exp
H=0;
[x_LR, y_LR] = sim_learn_LR_constant_pidrift(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal);


% LR learning with anchoring, learning the inflation drift only
anal = 1; % take analytical LR exp
[x_LR_anchor, y_LR_anchor, ~, ~, pibar, kd] = sim_learn_LR_anchoring_pidrift(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal);
kd_inv = 1./kd;


% Gather observables
Y(:,:,1) =y_RE; % let's call em V for a change
Y(:,:,2) =y_LR;
Y(:,:,3) =y_LR_anchor;
%% Analysis plots
% Observables
figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen

titles = {'Inflation','Output gap','Int. rate'};
l=0;
for j=1:ny
    l = l+1;
    subplot(1,ny,l)
    plot(squeeze(Y(j,:,1)),'linewidth', 2); hold on
    plot(squeeze(Y(j,:,2)),'linewidth', 2)
    plot(squeeze(Y(j,:,3)),'k','linewidth', 2)
    ax = gca; % current axes
    ax.FontSize = fs;
    grid on
    grid minor
    legend('RE', 'LR','LR anchor')
    title(titles(l))
end
if print_figs ==1
    figname = ['materials4_observables1']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

% Gain
figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen

subplot(1,2,1)
plot(kd_inv(1,:),'linewidth', 2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
title('Inverse gain')
subplot(1,2,2)
plot(pibar,'linewidth', 2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
title('Inflation drift')
if print_figs ==1
    figname = ['materials4_gain_drift']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

close all

%% Presentation plots
clc

% 1. Role of learning: RE against LR, fully anchored
nameset1 = {'pi','x','i'};
print1 =0
disp("there's no print2")
for j=1:ny
    % Observables
    figure
    set(gcf,'color','w'); % sets white background color
    set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
    plot(squeeze(Y(j,:,1)),'k', 'linewidth', lw_pres); hold on
    plot(squeeze(Y(j,:,2)),'b', 'linewidth', lw_pres);
    plot(squeeze(Y(j,:,3)),'r--', 'linewidth', lw_pres);
    ax = gca; % current axes
    ax.FontSize = fs_pres;
    grid on
    grid minor
    if print1 ==1
        figname = ['dw_role_of_learning_',nameset1{j}]
        cd(figpath)
        export_fig(figname)
        cd(current_dir)
        close
    end
end

% 2. Gain and inflation drift in the fully anchored case
% Gain
figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(kd_inv(1,:),'r--', 'linewidth', lw_pres)
ylim([0,0.15]);
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
if print1 ==1
    figname = ['dw2_gain']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(pibar,'r--', 'linewidth', lw_pres)
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
if print1 ==1
    figname = ['dw2_drift']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

% 3. Unanchored: RE against LR
nameset1 = {'pi','x','i'};
print3 =0
disp("there's no print4")
for j=1:ny
    % Observables
    figure
    set(gcf,'color','w'); % sets white background color
    set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
    plot(squeeze(Y(j,:,1)),'k', 'linewidth', lw_pres); hold on
    plot(squeeze(Y(j,:,2)),'b', 'linewidth', lw_pres);
    plot(squeeze(Y(j,:,3)),'r--', 'linewidth', lw_pres);
    ax = gca; % current axes
    ax.FontSize = fs_pres;
    grid on
    grid minor
    if print3 ==1
        figname = ['dw3_',nameset1{j}]
        cd(figpath)
        export_fig(figname)
        cd(current_dir)
        close
    end
end

% 4. Gain and inflation drift in the unanchored case
% Gain
figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(kd_inv(1,:),'r--', 'linewidth', lw_pres)
ylim([0,0.15]);
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
if print3 ==1
    figname = ['dw4_gain']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(pibar,'r--', 'linewidth', lw_pres)
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
if print3 ==1
    figname = ['dw4_drift']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

% 5. Varying Taylor rule coefficients,  Gain for different TR coefficients
print5 =0
figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(kd_inv(1,:),'r--', 'linewidth', lw_pres)
ylim([0,0.15]);
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
if print5 ==11
    figname = ['dw5_gain_psipi1_1']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
elseif print5 == 3
    figname = ['dw5_gain_psipi3']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
elseif print5 == 5
    figname = ['dw5_gain_psipi5']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

% 6. CEMP's thetbar
print6 = 0
% Gain
figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(kd_inv(1,:),'r--', 'linewidth', lw_pres)
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
if print6 ==1
    figname = ['dw6_gain']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end


figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(pibar,'r--', 'linewidth', lw_pres)
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
if print6 ==1
    figname = ['dw6_drift']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

for j=1:ny
%     Observables - they should explode though
    figure
    set(gcf,'color','w'); % sets white background color
    set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
    plot(squeeze(Y(j,:,1)),'k', 'linewidth', lw_pres); hold on
    plot(squeeze(Y(j,:,2)),'b', 'linewidth', lw_pres);
    plot(squeeze(Y(j,:,3)),'r--', 'linewidth', lw_pres);
    ax = gca; % current axes
    ax.FontSize = fs_pres;
    grid on
    grid minor
    if print6 ==1
        figname = ['dw6_',nameset1{j}]
        cd(figpath)
        export_fig(figname)
        cd(current_dir)
        close
    end
end




%% Read in and plot data
print7=0

series_id = 'UNRATE';
observation_start = '2010-01-01';
observation_end   = datestr(today,'yyyy-mm-dd');
[output] = getFredData(series_id, observation_start, observation_end);
urate = output.Data(:,2);
time_urate = output.Data(:,1);

figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(time_urate,urate, 'k', 'linewidth',lw_pres)
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
datetick('x','yyyy-mm')
if print7 ==1
    figname = ['dw_urate']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

% Fed funds rate target upper limit
series_id = 'DFEDTARU';
observation_start = '2010-01-01';
observation_end   = datestr(today,'yyyy-mm-dd');
[output] = getFredData(series_id, observation_start, observation_end);
ffr_t = output.Data(:,2);
time_fedfunds = output.Data(:,1);


figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(time_fedfunds,ffr_t, 'k', 'linewidth',lw_pres)
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
datetick('x','yyyy-mm')
if print7 ==1
    figname = ['dw_ffr']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

% inflation expectations, market based
url = 'https://fred.stlouisfed.org/';
c = fred(url);
series = 'T10YIE';
d = fetch(c,series);
time_epi  = d.Data(:,1);
epi = d.Data(:,2);
close(c)

obs_start= datenum(observation_start, 'yyyy-mm-dd');
ind = find(time_epi==obs_start);
epi = epi(ind:end);
time_epi = time_epi(ind:end);
% 
% series_id = 'T10YIE';
% observation_start = '2010-01-01';
% observation_end   = datestr(today,'yyyy-mm-dd');
% [output] = getFredData(series_id, observation_start, observation_end);
% Epi10 = output.Data(:,2);
% time_Epi10 = output.Data(:,1);


figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(time_epi,epi, 'k', 'linewidth',lw_pres); hold on
plot(time_epi, 2*ones(length(epi)), 'b--', 'linewidth',lw_pres)
ax = gca; % current axes
ax.FontSize = fs_pres;
grid on
grid minor
datetick('x','yyyy-mm')
if print7 ==1
    figname = ['dw_Epi10']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

%% Read in and plot data for proposals (slightly smaller font)
print8=1

series_id = 'UNRATE';
observation_start = '2010-01-01';
observation_end   = datestr(today,'yyyy-mm-dd');
[output] = getFredData(series_id, observation_start, observation_end);
urate = output.Data(:,2);
time_urate = output.Data(:,1);

figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(time_urate,urate, 'k', 'linewidth',lw_prop)
ax = gca; % current axes
ax.FontSize = fs_prop;
grid on
grid minor
datetick('x','yyyy-mm')
if print8 ==1
    figname = ['proposal_urate']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

% Fed funds rate target upper limit
series_id = 'DFEDTARU';
observation_start = '2010-01-01';
observation_end   = datestr(today,'yyyy-mm-dd');
[output] = getFredData(series_id, observation_start, observation_end);
ffr_t = output.Data(:,2);
time_fedfunds = output.Data(:,1);


figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(time_fedfunds,ffr_t, 'k', 'linewidth',lw_prop)
ax = gca; % current axes
ax.FontSize = fs_prop;
grid on
grid minor
datetick('x','yyyy-mm')
if print8 ==1
    figname = ['proposal_ffr']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

% inflation expectations, market based
url = 'https://fred.stlouisfed.org/';
c = fred(url);
series = 'T10YIE';
d = fetch(c,series);
time_epi  = d.Data(:,1);
epi = d.Data(:,2);
close(c)

obs_start= datenum(observation_start, 'yyyy-mm-dd');
ind = find(time_epi==obs_start);
epi = epi(ind:end);
time_epi = time_epi(ind:end);
% 
% series_id = 'T10YIE';
% observation_start = '2010-01-01';
% observation_end   = datestr(today,'yyyy-mm-dd');
% [output] = getFredData(series_id, observation_start, observation_end);
% Epi10 = output.Data(:,2);
% time_Epi10 = output.Data(:,1);


figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
plot(time_epi,epi, 'k', 'linewidth',lw_prop); hold on
plot(time_epi, 2*ones(length(epi)), 'b--', 'linewidth',lw_prop)
ax = gca; % current axes
ax.FontSize = fs_prop;
grid on
grid minor
datetick('x','yyyy-mm')
if print8 ==1
    figname = ['proposal_Epi10']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end

close all