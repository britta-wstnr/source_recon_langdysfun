%% Forward modelling in FieldTrip

% Segment MRI, make headmodel, make leadfield
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHOR: Britta U. Westner <britta.wstnr[at]gmail.com>
% LICENCE: GNU General Public License v3.0
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script deals with coregistration and the actual forward modelling.

%% Attention!

% This script is still a construction site. I will first have to obtain
% some EEG data from the DCC to finalize this script. The below is just an
% outline of functions, but not tested.

%% Coregistration

% This assumes coregistration with Nutmeg. For coregistration with
% FieldTrip, I'll have to check the resulting data structures and update
% this section

% load coregistration and headmodel
load(path_to_coreg);  % nutmeg structure

% read in the data
load(path_to_data);

elec_eeg = data_raw.elec;
elec_mri = coregister_data(elec_eeg, nuts, 'ctf');  % coreg to MRI space

% The function coregister_data() is a function that is shared in this
% folder

%% Sanity check: plot all together (NEVER SKIP THIS STEP!!!)

figure;
hold all;
ft_plot_headmodel(vol, 'edgecolor', 'none', 'facecolor', 'cortex');
ft_plot_sens(elec_mri, 'coilshape', 'point', 'style', 'r.');
ft_plot_mesh(grid.pos(grid.inside,:));
view([90 0 0])
title(s_name)
set(gca, 'FontSize', 18)
set(gcf, 'color', [1 1 1])

%% Prepare leadfield

% Finally, we can compute the forward model

cfg = [];
cfg.sourcemodel = grid;
cfg.headmodel = vol;
cfg.grad = elec_mri;
cfg.channel = 'EEG';
cfg.reducerank = 'no';
cfg.normalize = 'no';
leadfield = ft_prepare_leadfield(cfg);


