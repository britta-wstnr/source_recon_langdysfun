function elec_order = get_electrode_order(system)

% Function to create an electrode order to use in electrode identification.

% Parameters:
% system: 'acticap_dcc'

% This is an electrode order that has been identified to work well for the
% caps used at the DCC. Other electrode orders are not supported yet.

if ~strcmp(system, 'acticap_dcc')
    error( ...
        'Do not know system "%s", can only supply order for "acticap_dcc".', ...
        system);
else
    elec_order = {
        'Ref'  % TP9, behind left ear
        'lpa'
        'nas'
        'rpa'
        'Gnd'  % 5
        'Fz'
        'FCz'
        'Cz'
        'CPz'
        'Pz'
        'POz'
        'Oz'
        'O1'  % 13
        'PO3'
        'P1'
        'CP1'
        'C1'
        'FC1'
        'F1'
        'AF3'
        'Fp1'  % 21
        'F3'
        'FC3'
        'C3'
        'CP3'
        'P3'
        'PO7'  % 27
        'PO9'
        'P5'
        'CP5'
        'C5'
        'FC5'
        'F5'  % 33
        'AF7'
        'F7'
        'FT9'
        'FT7'
        'T7'
        'TP7'
        'P7'  % 40
        'O2'
        'PO4'  % 42
        'P2'
        'CP2'
        'C2'
        'FC2'
        'F2'
        'AF4'
        'Fp2'
        'F4'  % 50
        'FC4'
        'C4'
        'CP4'
        'P4'
        'PO8'
        'PO10'  % 56
        'P6'
        'CP6'
        'C6'
        'FC6'
        'F6'
        'AF8'  % 62
        'F8'
        'FT10'
        'FT8'
        'T8'
        'TP10'  % 67
        'TP8'
        'P8'
        };
end