%% MRI Preprocessing for EEG Forward modelling

% Possible preprocessing steps for MRIs prior to EEG forward modelling
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHOR: Britta U. Westner <britta.wstnr[at]gmail.com>
% LICENCE: GNU General Public License v3.0
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script does optional preprocessing on the MRI before segmenting the
% MRI for BEM modelling.

%% Set option

% Two options in this script:
bias_field_corr = 1;  % bias field correction of the MRI
reslicing = 1;  % reslicing the MRI

%% Attention!

% This pipeline assumes nifti files. If your MRI is in DICOM format, you
% can convert it to nifti by reading it in with FieldTrip and
% then writing it out again using ft_write_mri() - see below for an example

% IMPORTANT! SPM cannot deal with zipped nifti files - i.e., the ending
% should be .nii and not .nii.gz

% Example of converting to nifti:
% mri_tmp = ft_read_mri(projpath.mri);
% ft_write_mri('~/MEG/test_mri/001-T1.nii', mri_tmp, 'dataformat', 'nifti')

% NOW MAKE SURE to go and update projpath.mri in ldf_00_setup.m and run
% that again before continuing!

%% Plot the MRI 

% This will also make sure the file actually exists :)

mri = ft_read_mri(projpath.mri);
ft_sourceplot([], mri);

%% Bias field correction

% MRI scans can be corrupted by a bias (introduced by the MRI machine)
% which makes segmentation algorithms fails. The bias field signale basically 
% changes the grey-value of voxels across space, which poses difficulties
% for the segmentation algorithms that rely on the grey value / contrast to
% classify voxels into tissue types.
% Here we correct for this by running a bias field correction in SPM. 
% This should be done if the segmentation fails (visible holes in the scalp 
% layer) or if the scalp mesh does not close.

% This wil take some time, so be prepared to wait!

if bias_field_corr

    addpath(toolboxes.spm12);  %#ok
    
    % set the configurations
    % some of these configuration values are taken over from 
    % https://layerfmri.com/2017/12/21/bias-field-correction/
    spm_config{1}.spm.spatial.preproc.channel.vols = {[projpath.mri, ',1']};
    spm_config{1}.spm.spatial.preproc.channel.biasreg = 0.001;
    % a FWHM of 30 is the lightest option SPM supports. Change this to 40
    % if you still experience problems with segmentation:
    spm_config{1}.spm.spatial.preproc.channel.biasfwhm = 30;  
    spm_config{1}.spm.spatial.preproc.channel.write = [1 1];
    spm_config{1}.spm.spatial.preproc.warp.affreg = 'mni';
    spm_config{1}.spm.spatial.preproc.warp.cleanup = 1;
    spm_config{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
    spm_config{1}.spm.spatial.preproc.warp.fwhm = 0;
    spm_config{1}.spm.spatial.preproc.warp.samp = 3;
    spm_config{1}.spm.spatial.preproc.warp.mrf = 1;
    spm_config{1}.spm.spatial.preproc.warp.write = [0 0];
    
    % run the job - it will automatically save the bias field corrected MRI
    % (and some by-products) to the MRI folder.
    spm('defaults', 'FMRI')
    spm_jobman('initcfg');
    spm_jobman('run', spm_config);

end

%% reslice MRI

% Reslicing an MRI makes sure that the voxels are isotropic - i.e., the
% edges of the voxels have the same length in all directions.

if reslicing

    addpath(toolboxes.nifti)

    if bias_field_corr
        % use bias field corrected MRI
        mri_in = projpath.mri_bfc;
        mri_out = projpath.mri_bfc_resl
    else
        % use original MRI
        mri_in = projpath.mri;
        mri_out = projpath.mri_resl;
    end

    % reslice the MRI and save
    reslice_nii(mri_in, mri_out);

end
