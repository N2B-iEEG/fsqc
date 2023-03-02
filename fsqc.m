clearvars, clc, close all

fsqc_path       = mfilename('fullpath');
fsqc_path_parts = split(fsqc_path, {'/', '\'});
fsqc_dir        = strjoin(fsqc_path_parts(1:end-1), '/');

cd(fsqc_dir)
addpath(genpath('wave_clus'))
addpath(genpath('Nlx2Mat'))

%% GUI inputs
nlx_dir    = uigetdir([], 'Select Neuralynx data directory');
patient_id = inputdlg( ...
    'Enter patient ID (TWH***)', ...
    'Patient ID', ...
    1, ...
    {'TWH'});
patient_id = char(patient_id);

%% Create result folder
result_dir = fullfile(fsqc_dir, 'results', patient_id);
mkdir(result_dir)
cd(result_dir)

%% Find .ncs files
ncs_files = dir(fullfile(nlx_dir, ...
    '*u*.ncs'));
ncs_files([ncs_files.bytes] == 16384) = [];
ncs_name_list = {ncs_files.name};
ncs_path_list = fullfile(nlx_dir, ncs_name_list);

%% Get recording length
if isunix
    nlx_time_stamp = ...
        Nlx2MatCSC_v3(ncs_path_list{1}, [1 0 0 0 0], 0, 1, []);
elseif ispc
    nlx_time_stamp = ...
        Nlx2MatCSC(   ncs_path_list{1}, [1 0 0 0 0], 0, 1, []);
else
    error(['MATLAB is unable to determine operating system \n' ...
        'Nlx2Mat supports only Windows/Linux/MacOS \n'])
end
rec_length = length(nlx_time_stamp) * 520 / 32000;

%% Detect spikes
% wave_clus parameters
par_input.detection = 'both';                 % Detection both pos and neg
par_input.sr = 32000;                         % Sampling rate
par_input.w_pre  = 1   * 1e-3 * par_input.sr; % Extract 1ms pre-spike data
par_input.w_post = 1.5 * 1e-3 * par_input.sr; % Extract 1.5ms post-spike data

fprintf([ ...
    '==================================================\n' ...
    '%s FAST SPIKE QUALITY CHECK\n' ...
    'Spike detection using wave_clus\n\n'], ...
    string(datetime))

Get_spikes(ncs_path_list, 'par', par_input)

%% Find bundles
for i_ncs = 1:length(ncs_name_list)
    ncs_name = ncs_name_list{i_ncs};
    ncs_name_parts_u = strsplit(ncs_name, 'u');
    bd_name_list(i_ncs) = ncs_name_parts_u(1);
end

bd_unique = unique(bd_name_list);
n_bd = length(bd_unique);

%% Figure
fprintf([ ...
    '==================================================\n' ...
    '%s FAST SPIKE QUALITY CHECK\n' ...
    'Generating figure\n\n'], ...
    string(datetime))

fig = figure('units','normalized','position',[0 0 1 1]);
times = linspace(-1, 1.5, par_input.w_pre + par_input.w_post);

for i_bd = 1:n_bd

    bd_name = bd_unique{i_bd};
    spike_info = dir(sprintf('%su*_spikes.mat', bd_name));

    for i_wire = 1:length(spike_info)
        subplot(n_bd, 8, (i_bd-1)*8 + i_wire), hold on

        % Load spikes detected from the wire
        wire_spike_file = fullfile(spike_info(i_wire).folder, spike_info(i_wire).name);
        clearvars('spikes')
        load(wire_spike_file, 'spikes')
        n_spike = size(spikes, 1);

        if n_spike <= 2000
            spike_to_plot = 1:n_spike;
        else
            spike_to_plot = randperm(n_spike, 2000);
        end

        if n_spike > 0
            ind_wf = plot(times, spikes(spike_to_plot,:)', ...
                'Color', '#25355A', ...
                'LineWidth', 0.2);
            for i_line = 1:length(ind_wf)
                ind_wf(i_line).Color(4) = 0.1;
            end
        end

        xline(0, '--', '', 'Color', 'k', 'Alpha', 0.3)

        xlim([-1 1.5])
        title(spike_info(i_wire).name(1:end-11), ...
            sprintf('Avg. FR=%.2fHz', n_spike/rec_length), 'FontSize', 8)

        if i_bd == n_bd
            xticks(-1:0.5:1.5)
        else
            xticks([])
            xticklabels({})
        end

    end
end

han = axes(fig,'visible','off');
han.Title.Visible = 'on'; han.XLabel.Visible='on';
xlabel(han, 'Time relative to spike (ms)');
title(han, sprintf('%s FSQC', patient_id));

%% Save figure
figure_name = fullfile(result_dir, sprintf('%s_fsqc.jpg', patient_id));
if exist('exportgraphics', 'file')
    exportgraphics(fig, figure_name, "Resolution", 200);
else
    saveas(fig, figure_name)
end
