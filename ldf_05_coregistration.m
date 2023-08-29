%% Coregister MRI and electrodes using surface matching

% Align MRI and structural scan using surface matching
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHOR: Britta U. Westner <britta.wstnr[at]gmail.com>
% CREDIT: based on code by Sarang S. Dalal
% LICENCE: GNU General Public License v3.0
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Add some necessary extra paths

% We need NutMEG on our path for several functions:
addpath(toolboxes.nutmeg);
addpath(fullfile(toolboxes.nutmeg, 'external'));

%% Load the structural scan

% we read the structural scan as a "headshape"
projpath.struct_scan = fullfile(projpath.base, sprintf('%s_model.obj', id));
head_surface = ft_read_headshape(projpath.struct_scan);

% make sure things are in millimeters:
head_surface = ft_convert_units(head_surface, 'mm'); 

% copy the mesh over:
scan_mesh.vertices = head_surface.pos;
scan_mesh.faces = head_surface.tri;

%% Load the MRI mesh

load(projpath.mesh);

% copy the scalp mesh over: -- NOTE: this is the right index for the scalp
% mesh if you followed the rest of the pipeline. If you got your mesh from
% somewhere else, you might have to adjust the index.
mri_mesh.vertices = mesh(3).pos;
mri_mesh.faces = mesh(3).tri;

% save some memory:
clear head_surface 

%% First, we roughly align the two models

% For the iterative process to work, we need to roughly align the
% structural scan and the MRI mesh. For that, please identify the points
% the figure prompts you to select. You click on the point and press ENTER.
% This is not the coregistration step yet - that one will be done fully
% automated.

[mri_fids, surface_fids] = identify_points(mri_mesh, scan_mesh);

% define initial rigid transform based on identified fiducials
tfm_0 = rigid_coreg(surface_fids, mri_fids);

% apply this transform on the structural scan
scan_mesh.vertices_0 = nut_coordtfm(scan_mesh.vertices, tfm_0);

%% Next, we select the face for automatic coregistration

% We want to use the face only for automatic coregistration: the top and 
% back of the head will contain the electrodes for the structural scan and 
% thus not perfectly align with the MRI head surface (i.e., this would
% introduce coregistration error).
% If the MRI has signal cancellations (e.g. because of metal in the mouth),
% select a point above that region when prompted to select the chin or
% above the mouth. 

face_points = select_face(scan_mesh);

%% Run the automatic coregistration via ICP

% Coregister the two meshes via the iterative closest point algorithm. Use
% only the face points for that.
[tfm, scan_mesh] = make_icp_coreg(mri_mesh, scan_mesh, face_points, tfm_0);

%% Visualize the coregistration agreement

% We plot the coregistration result. The MRI in blue and the structural
% scan in red. Both are plotting semi-transparent, so you should be able to
% make out both.
% The will not perfectly 100% align (that is not possible), but the should
% clearly share the same space and orientation, sometimes the MRI
% overlapping the structural scan and sometimes the other way around.

figure;

% view angle 1
subplot(1, 2, 1)
trisurf(mri_mesh.faces, ...
    mri_mesh.vertices(:, 1), ...
    mri_mesh.vertices(:, 2), ...
    mri_mesh.vertices(:, 3), ...
    'EdgeColor', 'none', 'FaceColor', 'blue', 'FaceAlpha', 0.65)
hold on
trisurf(scan_mesh.faces, ...
    scan_mesh.vertices_1(:, 1), ...
    scan_mesh.vertices_1(:, 2), ...
    scan_mesh.vertices_1(:, 3), ...
    'EdgeColor', 'none', 'FaceColor', 'red', 'FaceAlpha', 0.65)
view([90 0])
axis equal
lightangle(240,45);
lightangle(-240,45);

% view angle 2
subplot(1, 2, 2)
trisurf(mri_mesh.faces, ...
    mri_mesh.vertices(:, 1), ...
    mri_mesh.vertices(:, 2), ...
    mri_mesh.vertices(:, 3), ...
    'EdgeColor', 'none', 'FaceColor', 'blue', 'FaceAlpha', 0.65)
hold on
trisurf(scan_mesh.faces, ...
    scan_mesh.vertices_1(:, 1), ...
    scan_mesh.vertices_1(:, 2), ...
    scan_mesh.vertices_1(:, 3), ...
    'EdgeColor', 'none', 'FaceColor', 'red', 'FaceAlpha', 0.65)
view([10 0])
axis equal
lightangle(240,45);
lightangle(-240,45);

%% Check that the electrodes are aligned with our structural scan

% If the electrodes do not match the structural scan, something went wrong
% when identifying the electrodes in step 4.
% Note for lab: if you identified electrodes using the old routine, you
% will unfortunately have to do this step again since this routine needs to use
% a different coordinate system in that step.

load(projpath.elec);

figure;
ft_plot_mesh(scan_mesh);
hold on
ft_plot_sens(elec)


%% Apply the coregistration to the electrodes

if ~strcmp(elec.unit, 'mm')
    elec = ft_convert_units(elec, 'mm');
end

elec_aligned = elec;
elec_aligned.elecpos = nut_coordtfm(elec.elecpos, tfm);
elec_aligned.chanpos = nut_coordtfm(elec.chanpos, tfm);

%% Visualize the electrodes together with the MRI

figure;
ft_plot_mesh(mri_mesh);
hold on
ft_plot_sens(elec_aligned)

%% Project the electrodes to the skin surface

cfg = [];
cfg.method = 'project';
cfg.headshape = mesh(3);
elec_aligned = ft_electroderealign(cfg, elec_aligned);

%% Double check the labelling as well

figure;
ft_plot_headshape(mesh(3))
ft_plot_sens(elec_aligned, 'label', 'on', 'fontsize', 15, 'elecshape', 'disc', 'elecsize', 10)

%% Save the aligned electrodes

save(projpath.elec_aligned, 'elec_aligned');
