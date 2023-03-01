clearvars, clc, close all
addpath(genpath('wave_clus'))

fsqc_path       = mfilename('fullpath');
fsqc_path_parts = split(fsqc_path, {'/', '\'});
fsqc_dir        = strjoin(fsqc_path_parts(1:end-1), '/');

%% GUI inputs
nlx_dir      = uigetdir([], 'Select Neuralynx data directory');
patient_id = inputdlg( ...
    'Enter patient ID (TWH***)', ...
    'Patient ID', ...
    1, ...
    {'TWH'});
patient_id = char(patient_id);

%% Find .ncs files
nlx_micro_files = dir(fullfile(nlx_dir, ...
    '*u*.ncs'));
nlx_micro_files([nlx_micro_files.bytes] == 16384) = [];
ncs_name_list = string({nlx_micro_files.name});

for i_ncs = 1:length(ncs_name_list)
    ncs_name = ncs_name_list(i_ncs);
    ncs_name_parts_u = strsplit(ncs_name, 'u');
    bd_name_list(i_ncs) = ncs_name_parts_u(1);
end

bd_unique = unique(bd_name_list);
n_bd = length(bd_unique);

%% Create result folder
result_dir = fullfile(fsqc_dir, 'results', patient_id);
mkdir(result_dir)
cd(result_dir)

%% Spike sorting for each bundle
for i_bd = 1:n_bd
    bd_name = bd_unique(i_bd);

    % Find microwires of this bundle
    wire_this_bd = dir(fullfile(nlx_dir, ...
        strcat(bd_name, 'u*.ncs')));
    wire_this_bd([wire_this_bd.bytes] == 16384) = [];
    wire_this_bd_name = string({wire_this_bd.name}');
    polytrode_lines = fullfile(nlx_dir, wire_this_bd_name);

    % Create polytrode<i_bd>.txt for wave_clus
    polytrode_file  = fullfile(result_dir, ...
        strcat('polytrode', string(i_bd), '.txt'));
    writelines(polytrode_lines, polytrode_file)

    % Sampling rate
    par_input.sr = 32000;
    par_input.w_pre  = 1 * 1e-3 * par_input.sr; % 1ms
    par_input.w_post = 2 * 1e-3 * par_input.sr; % 2ms

    fprintf([ ...
        '==================================================\n' ...
        '%s FAST SPIKE QUALITY CHECK (FSQC)\n' ...
        '[%s][%s] Spike detection\n\n'], ...
        string(datetime), patient_id, bd_name)

    Get_spikes_pol(i_bd, 'par', par_input) % Spike detection

end

%% Figure

fig = figure('units','normalized','position',[0 0 1 1]);

for i_bd = 1:n_bd

    bd_name = bd_unique(i_bd);

    clearvars("index", "par", "spikes", "thr")
    spike_info = dir(sprintf('polytrode%d_spikes.mat', i_bd));
    spike_file = fullfile(spike_info.folder, spike_info.name);
    load(spike_file)
    spike_win = par.w_pre + par.w_post;

    for i_wire = 1:par.channels
        subplot(n_bd, 8, (i_bd-1)*8 + i_wire), hold on

        data_range = spike_win * (i_wire-1) + 1 : spike_win * i_wire;
        spike_shape_wire_all = spikes(:,data_range);
        n_spike = size(spikes, 1);

        if n_spike <= 2000
            spike_to_plot = 1:n_spike;
        else
            spike_to_plot = randperm(n_spike, 2000);
        end

        ind_wf = plot(spike_shape_wire_all(spike_to_plot,:)', ...
            'Color', '#FF4500', ...
            'LineWidth', 0.2);
        for i_line = 1:length(ind_wf)
            ind_wf(i_line).Color(4) = 0.2;
        end

        title(sprintf('%su%d', bd_name, i_wire)) 

    end
end

figure_name = fullfile(result_dir, sprintf('%s_fsqc.jpg', patient_id));

if exist('exportgraphics', 'file')
    exportgraphics(fig, figure_name, "Resolution", 300);
else
    saveas(fig, figure_name)
end