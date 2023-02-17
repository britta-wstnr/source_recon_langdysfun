%% Identifying the electrodes on a structural scan

% Identify the fiducials on the MRI for coregistration
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHOR: Britta U. Westner <britta.wstnr[at]gmail.com>
% LICENCE: GNU General Public License v3.0
% script is based on:
% https://www.fieldtriptoolbox.org/tutorial/electrode/
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is the procedure to follow in case you work with a structural scan
% of your participant and the EEG cap.
% It is strongly recommended to also read:
% https://www.fieldtriptoolbox.org/tutorial/electrode/

%% Set paths

% Since this might be a step not everyone follows, we set the path to the
% necessary ingredients here. If you will use this script, you might
% consider moving this to your setup file (your ldf_00_setup.m or wherever you 
% store the paths in your project).

% this is the path to your structural scan:
projpath.struct_scan = fullfile(projpath.base, sprintf('%s_model.obj', id));

% path to the template for the EEG cap layout
% IMPORTANT: if you work at the DCC, then there is a specific layout 
% "ActiCap_64Ch_DCC_customized.mat" that you can find in our common
% folders.
template_grid = load(fullfile(toolboxes.fieldtrip, ...
    '/template/layout/acticap-64ch-standard2.mat'));

%% Load the data and convert units

% we read the structural scan as a "headshape"
head_surface = ft_read_headshape(projpath.struct_scan);

% make sure things are in millimeters:
head_surface = ft_convert_units(head_surface, 'mm'); 

%% Look at the model surface

figure;
ft_plot_mesh(head_surface); 

%% Identify the fiducials 

% Now we want to identify the fiducials (nasion, LPA, and RPA) on the 
% structural scan.
% If you get prompted asking if you want to change the anatomical labels
% for the axes, you can answer "n" for no.
% Then follow the instructions in the command window and identify all three
% points.

cfg = [];
cfg.method = 'headshape';
cfg.channel = {'nas', 'lpa', 'rpa'}; 
fiducials = ft_electrodeplacement(cfg, head_surface);

%% Realign the surface to CTF space

% We realign the structural model to CTF space - which is our common space
% that we also aligned the MRI to - there our data can "meet" in a shared
% coordinate system. 
% Once we have transformed the surface to this coordinate system, the
% electrodes we identify on the surface will also be in CTF space - and
% thus match our head model!

% Find the right indices for the fiducial positions:
idx_nas = find(strcmp(fiducials.label, 'nas'));
idx_lpa = find(strcmp(fiducials.label, 'lpa'));
idx_rpa = find(strcmp(fiducials.label, 'rpa'));

% Now use the fiducials to realign the surface to CTF space
cfg = [];
cfg.method  = 'fiducial';
cfg.coordsys = 'ctf'; % ctf or 4d
cfg.fiducial.nas = fiducials.elecpos(idx_nas, :); 
cfg.fiducial.lpa = fiducials.elecpos(idx_lpa, :); 
cfg.fiducial.rpa = fiducials.elecpos(idx_rpa, :); 
head_surface = ft_meshrealign(cfg, head_surface);

%% Identify electrode locations

% Now we identify the electrodes on the structural scan. That will supply the
% electrode coordinates in CTF space (which, in turn, we need to compute
% the leadfield). 
% Here it is important to match the electrodes identified and the electrode
% names correctly (otherwise you will end up with electrodes that have the
% coordinates of other electrodes!). 
% The function get_electrode_order() supplies you with an order that you
% can follow in the identification process. You can also create your own
% order - but you have to be careful that you supply this order as channel
% names as well then!

% This function to get the electrode order is shared in the subfolder
% /functions
elec_order = get_electrode_order('acticap_dcc');

cfg = [];
cfg.method = 'headshape';
cfg.channel = elec_order;
elec = ft_electrodeplacement(cfg, head_surface);

%% Visualize the electrodes together with the surface

figure;
ft_plot_mesh(head_surface);
hold on
ft_plot_sens(elec)

%% Double check the labelling as well

ft_plot_headshape(head_surface)
ft_plot_sens(elec, 'label', 'on', 'fontsize', 15, 'elecshape', 'disc', 'elecsize', 10)

%% Projecting to scalp

% You could move the electrodes inwards if they are not sitting on the
% scalp (due to our procedure, they might be hovering in the air a little).
% You can check the tutorial https://www.fieldtriptoolbox.org/tutorial/electrode/
% how to do this, using the funciton ft_electroderealign. However, the
% leadfield computation will project all electrodes down to the scalp as
% well.

%% Save File

save(projpath.elec, 'elec');
