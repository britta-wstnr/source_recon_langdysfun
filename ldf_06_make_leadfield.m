%% Forward modelling in FieldTrip

% Segment MRI, make headmodel, make leadfield
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHOR: Britta U. Westner <britta.wstnr[at]gmail.com>
% LICENCE: GNU General Public License v3.0
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script deals with coregistration and the actual forward modelling.

%% Load files

% For the leadfield computation, we need to load the following:
% the electrode information, elec
% the headmodel, vol
% the source grid, grid
% This information will all be combined to compute the forward model, using
% the funciton ft_prepare_leadfield

% read in the headmodel
load(projpath.vol)

% read in the electrodes file
load(projpath.elec);  % loaded structure is here called "elec"

% load the source grid
load(projpath.grid)

%%  Sanity check: plot all together (NEVER SKIP THIS STEP!!!)

% Before we continue, we want to make sure that all our forward model
% "ingredients" are in the same coordinate space and well aligned.
% Thus, we plot them together:

figure;
hold all;
ft_plot_headmodel(vol, 'edgecolor', 'none', 'facecolor', 'cortex')
alpha 0.5
ft_plot_sens(elec, 'coilshape', 'point', 'style', 'r.');
ft_plot_mesh(grid.pos(grid.inside,:));
view([0 90 0])
set(gcf, 'color', [1 1 1])

%% Prepare leadfield

% Finally, we can compute the forward model:
% we supply the source grid, the headmodel (vol) and the electrode
% information (elec).
% We tell the algorithm to not reduce rank (this is EEG data, so we are
% able to see radial and tangential sources, thus we use the full rank of
% the leadfield) and to not normalized the leadfield (if we do want to get
% rid of the center-of-head bias, we prefer to normalize the weights of the
% beamformer - checkout Westner et al. 2022 for more info).s

cfg = [];
cfg.sourcemodel = grid;
cfg.headmodel = vol;
cfg.grad = elec;
cfg.channel = 'EEG';
cfg.reducerank = 'no';
cfg.normalize = 'no';
leadfield = ft_prepare_leadfield(cfg);
