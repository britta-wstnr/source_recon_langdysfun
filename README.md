# Forward and inverse modelling of EEG data using FieldTrip

This repository contains demo scripts for forward modelling and inverse modelling of EEG data using FieldTrip. 
The scripts are created in the context of the Language Function and Dysfunction Lab at the Donders Institute for Brain, Cognition and Behaviour.
They are meant to be verbose with respect to comments in the scripts, but are not supposed to be a full tutorial of the different source modelling steps.

## A note on coregistration
These scripts feature _automatic_ coregistration using a ["3D structural scan"](https://www.fieldtriptoolbox.org/tutorial/electrode/) from the EEG lab (by matching the head surface from the structural scan to the head surface of the MRI). If your data does not have such structural scans you can hop to the branch `traditional_coreg`  of this repository, which features fiducial-based coregistration instead.

## How to use this

The scripts are numbered - start with the first one `ldf_00_setup.m` and work your way through from there!

### Dependencies
[FieldTrip](https://www.fieldtriptoolbox.org/download/)

[SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/download/)

For the automatic coregistration only:
[NutMEG](https://github.com/UCSFBiomagneticImagingLab/nutmeg)