%% Source estimation

% Segment MRI, make headmodel, make leadfield
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHOR: Britta U. Westner <britta.wstnr[at]gmail.com>
% LICENCE: GNU General Public License v3.0
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script shows an example source reconstruction using a beamformer.
% So far, the scripts have been very universal and can be used for many
% different source reconstruction scenarios. This script is where the data
% comes into play, so you will have to make your own decisions on different
% parameters. 
% For demonstration purposes, I assume the following:
% We recorded a dataset with visual stimulation and we want to just see the
% activity after the stimulus was presented.

%% Load files

% the forward model
load(projpath.fwd)

% we also need to supply the headmodel again:
load(projpath.vol)

%% Load the data

% It is assumed the data is cleaned and epoched around stimulus onset - or
% that you have a script that can produce such data.
load('path_to_your_epochs')

% NOTE:
% Some files from the DCC might erroneously have a channel named "FP1",
% while it actually should be named "Fp1". If this is the case, we need to
% fix this here (or even earlier in your pipeline as this will also create
% mismatches for topo-plotting).

if any(strcmp(epochs.label, 'FP1'))
    % find where the channel sits
    idx_fp1 = find(strcmp(epochs.label, 'FP1'));

    % rename it
    epochs.label{idx_fp1} = 'Fp1';
end

% IMPORTANT:
% Remember that this data needs to be average-referenced! 

% We also remove the EOG and EMG channels from the data:
cfg = [];
cfg.channel = {'EEG', '-HEOG', '-VEOG', '-EMG'};
epochs = ft_selectdata(cfg, epochs);

%% Compute the covariance matrix for computing the beamformer

% For your own data, you will likely have to adjust the covariance window
cfg = [];
cfg.covariancewindow = [-0.2 0.2];  
cfg.covariance = 'yes';
cov = ft_timelockanalysis(cfg, epochs);

% we compute the rank of the covariance matrix:
cov_rank = rank(cov.cov);

%% Now we can make the spatial filter

% We compute an LCMV beamformer - that is a beamformer for time domain
% data. 
% We supply the headmodel and the forward model, as well as the electrode
% information.
% OPTIONS:
% We use a weight-normalized beamformer (unit-noise-gain beamformer) and
% compute the dipole orientation (per source point) that maxmimizes output
% power. We handle rank-deficient covariance matrices by using a truncated
% pseudo-inverse (we set kappa to our rank).
% Lastly, we tell the algorithm to save the spatial filter in the output -
% as we want to apply it to different data.

% Referencing Westner et al. 2022, DOI: 10.1016/j.neuroimage.2021.118789 : 
% You can read more about weight normalization in section 2.2, "Weight
% normalization strategies". 
% You can find information about the dipole orienation in section 2.1, "Basic
% beamformer formulations".
% The inversion of rank deficient covariance matrices is discusse in detail
% in 3.1, "Estimation and inversion of covariance matrices".
% Common spatial filters are discussed in 3.7, "Common choices for beamformer
% analysis pipelines".

cfg = [];
cfg.method = 'lcmv';
cfg.headmodel = vol;  % headmodel
cfg.sourcemodel = leadfield;  % forward model
cfg.elec = elec;  % electrode information
cfg.lcmv.weightnorm = 'unitnoisegain';
cfg.lcmv.fixedori = 'yes';
cfg.lcmv.kappa = cov_rank;
cfg.lcmv.keepfilter = 'yes';
spat_filter = ft_sourceanalysis(cfg, cov);

%% Apply spatial filters

% FieldTrip does not have seperate calls for creating and applying a
% spatial filter. The variable spat_filter above in fact contains the
% source reconstruction of the data in cov.
% However, we want to use the spatial filter we created using data from the
% baseline and active window of our data (cfg. the covariance window) and
% apply it to the baseline and active time points *separately* so that we
% can contrast them.
% This approach is also called using a "common spatial filter", since our
% beamformer is not biased toward either the active or baseline activity.

% For this to work, we will have to recompute covariance matrices for both
% the baseline and the active window and the apply the common spatial
% filter to these covariance matrices.

% Compute covaraince matrices for pre- and post-stim
cfg = [];
cfg.covariance = 'yes';
cfg.covariancewindow = [-0.2 -0.05];
cov_prestim = ft_timelockanalysis(cfg, epochs);

cfg.covariancewindow = [0.05 0.2];
cov_poststim = ft_timelockanalysis(cfg, epochs);

% apply pre-computed spatial filter to this
cfg = [];
cfg.method = 'lcmv';
cfg.elec = elec;
cfg.headmodel = vol;
cfg.sourcemodel = leadfield;
cfg.sourcemodel.filter = spat_filter.avg.filter;
source_prestim = ft_sourceanalysis(cfg, cov_prestim);
source_poststim = ft_sourceanalysis(cfg, cov_poststim);

%% Contrast conditions

% now we obtained the source estimates for pre- and post-stim activity.
% Let's contrast them!

% Tip: you can also do this using ft_math()
source_diff = source_prestim;  % make a copy of the source variable
source_diff.avg.pow = (source_poststim.avg.pow - source_prestim.avg.pow);

%% Prepare plotting

% We are almost there! Just the plotting step is missing.
% First, we have to remember that we are working with a warped grid. Go
% back to the end of ldf_04_make_headmodel.m if you need a refresher of
% what that means.
% Thus, we cannot plot the data on the individual MRI, but have to use the
% template MRI in MNI space!
% Let's load it:

template_mri = fullfile(toolboxes.fieldtrip, ...
    '/template/anatomy/single_subj_T1.nii');

temp_mri = ft_read_mri(template_mri);
temp_mri.coordsys = 'mni';

% Now remember that the positions of our source reconstruction are still in 
% individual space (because our headmodel and electrde positions etc are all in
% that individual space, the resulting source estimation is too) - but they
% correspond 1:1 to coordinates in the MNI space (that is what we have
% carefully set up during the warping).
% So we can go ahead, load the template and replace the source grid
% coordinates! (Yep, sounds crazy but works fine)

template_grid = load(fullfile(toolboxes.fieldtrip, ...
    '/template/sourcemodel/standard_sourcemodel3d10mm.mat'));
% Side note: re-loading things you used earlier in the pipeline is when I
% would strongly recommend to use some kind of setup-file and a path tree
% (like our projpath object). That way you minimize the danger of loading a
% *different* file than before (and then chaos ensues ...).
% Here I kept the full path in the scripts to make it very clear to you
% which file we are loading and from where, but for a "real" analysis I
% would move this info to ldf_00_setup.m to keep it constant across
% scripts.

% Just replace the positions!
source_diff.pos = template_grid.sourcemodel.pos;

%% Interpolate the source estimate

% The MRI has a different resolution than our source estimate, so we need
% to interpolate:
cfg = [];
cfg.parameter = 'avg.pow';
cfg.interpmethod = 'nearest';
source_int = ft_sourceinterpolate(cfg, source_diff, temp_mri);

%% And lastly, plot it!

cfg = [];
cfg.method = 'ortho';
cfg.funparameter = 'pow';
cfg.funcolorlim = 'maxabs';
ft_sourceplot(cfg, source_int);

