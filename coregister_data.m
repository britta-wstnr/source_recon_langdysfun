function [grad_mri] = coregister_data(grad_meg, nuts, orig_coordsys)
    % Coregister the data to MRI space using NutMEG nuts structure
    %
    % INPUT:
    % grad_meg : Fieldtrip .grad substructure from original data (in MEG
    %            head space)
    % nuts : Output from NutMEG coregistration procedure
    % orig_coordsys : string describing original coordinate system,
    %                 should be compatible with ft_headcoordinates
    % 
    % OUTPUT:
    % grad_mri : Fieldtrip .grad substructure with sensor coordinates in 
    %            MRI space.
    %
    % AUTHOR: Britta U. Westner <britta.wstnr[at]gmail.com>
    % LICENCE: GNU General Public License v3.0
    
    
    [mri2meg_tfm, ~] = ft_headcoordinates(nuts.coreg.fiducials_mri_mm(3, :), ...
                                          nuts.coreg.fiducials_mri_mm(1, :), ...
                                          nuts.coreg.fiducials_mri_mm(2, :), ...
                                          orig_coordsys);

    meg2mri_tfm = inv(mri2meg_tfm);

    % convert grad structure to MRI coordinate system, make a copy to not 
    % overwrite and coregister same data twice
    grad_mri = grad_meg;
    grad_mri = ft_convert_units(grad_mri, 'mm');

    grad_mri = ft_transform_sens(meg2mri_tfm, grad_mri);
    grad_mri.coordsys = 'spm';