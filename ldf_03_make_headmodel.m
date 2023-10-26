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

clear all  %# ok
ldf_00_setup

%% Load MRI

% First we load the MRI that was aligned to CTF space:
load(projpath.mri_resl);
mri_resl.coordsys = 'spm';

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
seg = ft_volumesegment(cfg, mri_aligned);

save(projpath.seg, 'seg');

%% Check segmentation by plotting

% add anatomical information to the segmentation
seg.transform = mri_aligned.transform;
seg.anatomy   = mri_aligned.anatomy;

% plot all three tissue types:
tissue =  {'brain', 'skull', 'scalp'};
for ii = 1:length(tissue)

    cfg = [];
    cfg.method = 'ortho';
    cfg.funparameter = tissue{ii};
    cfg.colorbar = 'no';  % no functional data
    ft_sourceplot(cfg, seg);
end

%% Fix scalp segmentation

% (ONLY!) If the segmentation plots or the mesh plots have holes, or if the
% headmodelling step fails, circle back here and run the following code.
% Then prepare the mesh again.

if(0)  

    %% Step 1 
    % Use private FieldTrip function to attempt filling holes

    seg_fill = seg;  %#ok % make a copy of seg
    
    % jump directory since the directory that contains the funciton is private 
    % and thus cannot be added to path via addpath
    pw_dir = pwd;
    [~, ft_path] = ft_version;
    cd(fullfile(ft_path, 'private'));
    
    % fill along z axis
    seg_fill.scalp = volumefillholes(seg_fill.scalp, 3);
    
    % now we can jump back to previous directory:
    cd(pw_dir);

    %% Step 2
    % Dilate scalp segmentation

    seg_dil = seg_fill;  % work with filled segmentation

    % dilation:
    se_scalp = strel('cube', 3);
    seg_dil.scalp = imdilate(seg_fill.scalp, se_scalp);

    % NOTE: The segmentations might now be overlapping, creating overlapping 
    % meshes in the end. This could be corrected by subtracting as below,
    % but in practice this did not work amazingly. It seems in tests that
    % the iso2mesh functions in "Downsample and repair the meshes" catch
    % any problems that might arise from NOT subtracting. If problems
    % appear at the headmodelling stage thought, it might be worth getting it
    % back into the mix.
    % seg_dil.scalp(seg_dil.skull) = 0;

    %% Plot results

    figure;
    cfg = [];
    cfg.method = 'ortho';
    cfg.funparameter = 'scalp';
    cfg.colorbar = 'no';  % no functional data
    ft_sourceplot(cfg, seg);
    sgtitle([id, ' before correction'])

    figure;
    cfg = [];
    cfg.method = 'ortho';
    cfg.funparameter = 'scalp';
    cfg.colorbar = 'no';  
    ft_sourceplot(cfg, seg_dil);
    sgtitle([id, ' after dilating'])

    %% Step 3
    % Deislanding

    % ONLY do this if the other two steps above are not fixing the problem.
    % This step can introduce problems if the previous two steps suffice.
    if(0)  

        new_scalp = deislands3d(seg_dil.scalp);
        seg_dil.scalp(new_scalp) = 1; % correct scalp using the deislanding

        % only do below if you are sure, see above.
        %     seg_dil.scalp(seg_dil.skull) = 0; % correct with skull
    
        figure;
        cfg = [];
        cfg.method = 'ortho';
        cfg.funparameter = 'scalp';
        cfg.colorbar = 'no';  % no functional data
        ft_sourceplot(cfg, seg_dil);
        sgtitle([sub, ' after deislanding'])
    
    end

    %% Overwrite seg

    % if you are happy with the output, overwrite seg and save
    seg = seg_dil;
    save(projpath.seg, 'seg');

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

view([0 90 0])

%% Save mesh

% If this all looks good, we save the mesh - we need it again for the
% coregistration step

save(projpath.mesh, 'mesh', '-v7.3');

%% Make the volume conductor model

% This takes time! -- as in: hours!

cfg = [];
cfg.method = 'dipoli';  % dipoli, bemcp, or openmeeg (the latter needs installation)
cfg.conductivity = [0.33 0.0041 0.33];
vol = ft_prepare_headmodel(cfg, mesh);

save(projpath.vol, 'vol', '-v7.3');

%% We can double check again if that aligns well with our MRI

cfg = [];
cfg.intersectmesh = vol.bnd;
ft_sourceplot(cfg, mri_aligned);

%% Create warped MNI grid

% Let's do the grid warp again ....

% This is what you do if you run a group study. This code takes an
% MNI grid that is shipped with FieldTrip, and warps the positions of this
% template grid to the MRI we supply. That way, we do the source
% reconstruction in individual space (since we warp the grid to the indiv.
% MRI) but they all represent the same coordinates in the MNI brain - which
% makes the positions all comparable to each other in a group analysis.
% One thing you have to keep in mind with this approach is that we cannot
% plot the data on the individual MRI anymore. The data is represented in
% that coordinate space - but the source points do not span a regular grid
% here (since it is warped ...) - and our plotting functions only support
% regular spacing. But: we can just plot on a template brain instead! More
% on that in the plotting file after source reconstruction!

template_grid = load(fullfile(toolboxes.fieldtrip, ...
    '/template/sourcemodel/standard_sourcemodel3d10mm.mat'));

cfg = [];
cfg.mri = mri_aligned;
cfg.grid.template = template_grid.sourcemodel;
cfg.warpmni = 'yes';  % this is unlocking the warping step
cfg.nonlinear = 'yes';  % we warp non-linearly
grid = ft_prepare_sourcemodel(cfg);

save(projpath.grid, 'grid');

