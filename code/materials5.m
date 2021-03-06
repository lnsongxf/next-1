% materials 5
% work after DW
% 7 Oct 2019
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
% Some color spectra
% grey color (divide by 255)
grey = [128,128,128]/255;
silver = [192,192,192]/255;
maroon = [138 0 0]/255;
light_coral = [240 128 128]/255;
light_salmon = [255,160,122]/255;
dark_green = [0 100 0]/255;
green = [0 128 0]/255;
light_green = [144 238 144]/255;
light_sky_blue = [135 206 250]/255;

teal = [0,128,128]/255;
purple = [128,0,128]/255;
saddle_brown = [139,69,19]/255;

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

% Simulate models
% Use Ryan's code to simulate from the RE model
[x_RE, y_RE] = sim_model(gx,hx,SIG,T,burnin,e);

% LR learning (only constant, only for pi), decreasing gain
anal = 1; % take analytical LR exp
H=0;
[x_LR, y_LR] = sim_learn_LR_constant_pidrift(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal);

% LR learning with anchoring, learning the inflation drift only
[x_LR_anchor, y_LR_anchor, ~, ~, pibar, kd] = sim_learn_LR_anchoring_pidrift(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal);
kd_inv = 1./kd;

% LR learning (only constant, only for pi), constant gain ('perpetual learning')
[x_LR_perp, y_LR_perp] = sim_learn_LR_constant_pidrift_perpetual(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal);

% LR learning with anchoring, learning the inflation drift only, using
% alternative CUSUM criterion
[x_LR_anchor_cusum, y_LR_anchor_cusum, ~, ~, pibar_cusum, kd_cusum] = sim_learn_LR_anchoring_pidrift_cusum(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal);
kd_inv_cusum = 1./kd_cusum;

% Gather observables
Y(:,:,1) =y_RE;
Y(:,:,2) =y_LR;
Y(:,:,3) =y_LR_anchor;
Y(:,:,4) =y_LR_perp;
Y(:,:,5) =y_LR_anchor_cusum;


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
    plot(squeeze(Y(j,:,1)),'k','linewidth', 2); hold on
    plot(squeeze(Y(j,:,2)),'b','linewidth', 2)
    plot(squeeze(Y(j,:,3)),'r','linewidth', 2)
    plot(squeeze(Y(j,:,4)),'color', dark_green,'linewidth', 2)
    
    ax = gca; % current axes
    ax.FontSize = fs;
    grid on
    grid minor
    legend('RE', 'LR decreasing gain','LR anchor',  'LR constant gain')
    title(titles(l))
end
if print_figs ==1
    figname = ['materials5_observables1']
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
plot(kd_inv(1,:),'r','linewidth', 2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
title('Inverse gain')
subplot(1,2,2)
plot(pibar,'r','linewidth', 2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
title('Inflation drift')
if print_figs ==1
    figname = ['materials5_gain_drift']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end


%% Generate IRFs for RE and anchoring
d = 1; % the innovation, delta
shocknames = {'natrate', 'monpol','costpush'};

% cycle thru the shocks of the model
for s=1:n
    x0 = zeros(1,n);
    x0(s) = d;
    h = 20; % horizon of IRF
    [IR, iry, irx]=ir(gx,hx,x0,h);
    iry = iry';
    
    % For learning, the approach I take is resimulate everything and for each
    % period t, expose the econ to this same shock. Then take an average.
    GIRd = zeros(n,h,T-h); % decreasing gain
    GIRa = zeros(n,h,T-h); % anchoring
    GIRc = zeros(n,h,T-h); % constant gain
    for t=1:T-h
        % 1. create alternative simulations, adding the impulse always at a new time t
        [x_LR_shockd, y_LR_shockd] = sim_learn_LR_constant_pidrift_shockd(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal, t, x0);
        [x_LR_anchor_shockd, y_LR_anchor_shockd] = sim_learn_LR_anchoring_pidrift_shockd(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal, t, x0);
        [x_LR_perp_shockd, y_LR_perp_shockd] = sim_learn_LR_constant_pidrift_perpetual_shockd(gx,hx,SIG,T,burnin,e, Aa_LR, Ab_LR, As_LR, param, setp, H, anal, t, x0);
        % 2. take differences between this and the standard simulation
        GIRd(:,:,t) = y_LR_shockd(:,t:t+h-1) - y_LR(:,t:t+h-1);
        GIRa(:,:,t) = y_LR_anchor_shockd(:,t:t+h-1) - y_LR_anchor(:,t:t+h-1);
        GIRc(:,:,t) = y_LR_perp_shockd(:,t:t+h-1) - y_LR_perp(:,t:t+h-1);
    end
    
    % option 1: take simple averages
    RIRd = mean(GIRd,3);
    RIRa = mean(GIRa,3);
    RIRc = mean(GIRc,3);
    
    
    % Plot IRFs
    figure
    set(gcf,'color','w'); % sets white background color
    set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen
    for i=1:n
        subplot(1,n,i)
        plot(zeros(1,h),'k--','linewidth', 2); hold on
        for j=2:h
            plot(squeeze(GIRd(i,:,j)),'color',light_sky_blue,'linewidth', 2)
            plot(squeeze(GIRa(i,:,j)),'color',light_salmon,'linewidth', 2)
            plot(squeeze(GIRc(i,:,j)),'color',light_green,'linewidth', 2)
        end
        re = plot(iry(i,:),'k','linewidth', 2);
        d_mean = plot(RIRd(i,:),'b','linewidth', 2);
        am_mean = plot(RIRa(i,:),'r','linewidth', 2);
        c_mean = plot(RIRc(i,:),'color', dark_green,'linewidth', 2);
        legend([re,d_mean, am_mean, c_mean],'RE', 'Decreasing gain', 'Anchor', 'Constant gain')
        title(titles(i))
        ax = gca; % current axes
        ax.FontSize = fs;
        grid on
        grid minor
        if s==1
            ylim([-0.015, 0.005])
        elseif s==3
            ylim([-0.2, 0.05])
        end
    end
    if print_figs ==1
        figname = ['materials5_IRFs_', shocknames{s}]
        cd(figpath)
        export_fig(figname)
        cd(current_dir)
        close
    end
end

%% compare the two anchoring mechanisms
close all

% Observables
figure
set(gcf,'color','w'); % sets white background color
set(gcf, 'Position', get(0, 'Screensize')); % sets the figure fullscreen

titles = {'Inflation','Output gap','Int. rate'};
l=0;
for j=1:ny
    l = l+1;
    subplot(1,ny,l)
    plot(squeeze(Y(j,:,3)),'r','linewidth', 2); hold on
    plot(squeeze(Y(j,:,5)),'color', saddle_brown,'linewidth', 2)
    ax = gca; % current axes
    ax.FontSize = fs;
    grid on
    grid minor
    legend('CEMP criterion',  'CUSUM criterion')
    title(titles(l))
end
if print_figs ==1
    figname = ['materials5_observables2']
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
plot(kd_inv(1,:),'r','linewidth', 2); hold on
plot(kd_inv_cusum(1,:),'color', saddle_brown,'linewidth', 2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
legend('CEMP criterion',  'CUSUM criterion')
title('Inverse gain')
subplot(1,2,2)
plot(pibar,'r','linewidth', 2); hold on
plot(pibar_cusum,'color', saddle_brown,'linewidth', 2)
ax = gca; % current axes
ax.FontSize = fs;
grid on
grid minor
legend('CEMP criterion',  'CUSUM criterion')
title('Inflation drift')
if print_figs ==1
    figname = ['materials5_gain_drift2']
    cd(figpath)
    export_fig(figname)
    cd(current_dir)
    close
end