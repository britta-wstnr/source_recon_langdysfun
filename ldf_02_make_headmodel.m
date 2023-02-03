%% Constructing the Headmodel for EEG forward modelling in FieldTrip

% Segment MRI, make headmodel, make grid
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHOR: Britta U. Westner <britta.wstnr[at]gmail.com>
% LICENCE: GNU General Public License v3.0
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script takes an MRI - possibly preprocessed with ldf_01_preprocess_mri.m
% - and computes a 3-element BEM model for EEG or MEG data source reconstruction.

%% Before we start we clear all and rerun our setup script

clear all  %#ok
ldf_00_setup

%% First decide which MRI to use

% change this path according to which MRI you want to use. Make sure you
% have actually computed that MRI using ldf_01_preprocess_mri.m

% options are:
% projpath.mri_resl = resliced MRI
% projpath.mri_bfc_resl = bias corrected and resliced MRI

% I recommend to always realign and reslice your MRI (as per
% ldf_01_preprocess_mri.m

mri_path = projpath.mri_resl;

% find and load the right MRI
if strcmp(mri_path, projpath.mri)
    warning('You should probably reslice and realign your MRI!')
    mri = ft_read_mri(mri_path);
elseif strcmp(mri_path, projpath.mri_resl)
    load(projpath.mri_resl)
    mri = mri_resl; clear mri_resl
elseif strcmp(mri_path, projpath.mri_bfc_resl)
    load(projpath.mri_resl)
    mri = mri_resl; clear mri_resl
else
    error('Do not know how to load specified MRI');
end

%% Segment the MRI

% Segment the MRI 
% This takes time, so be prepared to wait some time. Go read a paper or
% have a cup of tea :)
% Remember to RECOMPUTE in case you change the input MRI, e.g. by
% reslicing or bias field correcting

% If this freaks out with an "Unrecognized field name 'old'." error,
% then the problem is several spm versions on the path. It might help
% to restore the defaultpath, otherwise restart MATLAB.
% Usually this happens if a full older SPM version was added to the path,
% e.g. for coregistration of data and MRI data via NutMEG.

cfg = [];
cfg.spmversion = 'spm12';
cfg.spmmethod = 'old';
cfg.output = {'brain', 'skull', 'scalp'};
seg = ft_volumesegment(cfg, mri);

save(projpath.seg, 'seg');

%% Check segmentation by plotting

% add anatomical information to the segmentation
seg.transform = mri.transform;
seg.anatomy   = mri.anatomy;

% plot all three tissue types:
tissue =  {'brain', 'skull', 'scalp'};
for ii = 1:length(tissue)

    cfg = [];
    cfg.method = 'ortho';
    cfg.funparameter = tissue{ii};
    cfg.colorbar = 'no';  % no functional data
    ft_sourceplot(cfg, seg);
end

%% Prepare the mesh

% We prepare a densely sampled mesh, which we downsample again below.

cfg = [];
cfg.tissue = {'brain', 'skull', 'scalp'};
cfg.method = 'iso2mesh';  
cfg.spmversion = 'spm12';
cfg.numvertices = 1e4;   
mesh = ft_prepare_mesh(cfg, seg);

%% Downsample and repair the meshes

% Check and repair individual meshes using iso2mesh. 
% This functions are part of the iso2mesh toolbox that ships with FieldTrip. 
% If MATLAB does not find it, try adding 
% insert_your_path_to_fieldtrip/external/iso2mesh 
% to your MATLAB path. 
% And make sure you are using a reasonably new Fieldtrip version (i.e., 
% not years old).
% This is following a routine described here: 
% https://github.com/meeg-cfin/nemolab/blob/master/basics/nemo_mriproc.m

target_sizes = [1000, 1000, 1000];

for ii = 1:length(mesh)
    [mesh(ii).pos, mesh(ii).tri] = meshresample(mesh(ii).pos, ...
                                                 mesh(ii).tri, ...
                                                 target_sizes(ii)/...
                                                 size(mesh(1).pos, 1));
    [mesh(ii).pos, mesh(ii).tri] = meshcheckrepair(mesh(ii).pos, ...
                                                 mesh(ii).tri, 'dup');
    [mesh(ii).pos, mesh(ii).tri] = meshcheckrepair(mesh(ii).pos, ...
                                                 mesh(ii).tri, 'isolated');
    [mesh(ii).pos, mesh(ii).tri] = meshcheckrepair(mesh(ii).pos, ...
                                                 mesh(ii).tri, 'deep');
    [mesh(ii).pos, mesh(ii).tri] = meshcheckrepair(mesh(ii).pos, ...
                                                 mesh(ii).tri, 'meshfix');
end

%% Plot the meshes

% Always remember to plot your meshes - make sure there are no holes in any
% of the meshes by turning the 3D objects. 
% The different layers get plotted one at a time, press any key to add the
% next layer to the plot.

figure;
ft_plot_mesh(mesh(1), 'facecolor', 'red');
hold on; pause
ft_plot_mesh(mesh(2), 'facealpha', 0.25, 'facecolor', 'blue');
hold on; pause          
ft_plot_mesh(mesh(3), 'facealpha', 0.25, 'edgecolor', [0.8, 0.8, 0.8]);

%% Make the volume conductor model

% This takes time! -- as in hours!

cfg = [];
cfg.method = 'dipoli';  % dipoli, bemcp, or openmeeg (the latter needs installation)
cfg.conductivity = [0.33 0.0041 0.33];
vol = ft_prepare_headmodel(cfg, mesh);

%% Create warped MNI grid

% Let's do the grid warp again ....

% This is what you would do if you run a group study. This code takes an
% MNI grid that is shipped with FieldTrip, and warps the positions of this
% template grid to the MRI we supply. That way, we do the source
% reconstruction in individual space (since we warp the grid to the indiv.
% MRI) but they all represent the same coordinates in the MNI brain - which
% makes the positions all comparable to each other in a group analysis.

template_grid = load(fullfile(toolboxes.fieldtrip, ...
    '/template/sourcemodel/standard_sourcemodel3d10mm.mat'));

cfg = [];
cfg.mri = mri;
cfg.grid.template = template_grid.sourcemodel;
cfg.warpmni = 'yes';  % this is unlocking the warping step
cfg.nonlinear = 'yes';  % we warp non-linearly
grid = ft_prepare_sourcemodel(cfg);

save(projpath.grid, 'grid');

