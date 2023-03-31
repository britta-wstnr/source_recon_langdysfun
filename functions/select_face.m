function face_points = select_face(scan_mesh)
%
% Function to plot the structural scan. Prompts the user to identify points
% to define the face.
%
% Parameters:
% scan_mesh: the mesh from the structural scan
%
% AUTHOR: Britta U. Westner <britta.wstnr@gmail.com>
% CREDIT: Based on code from Sarang S. Dalal
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% figure init
fig = figure(1);

% plot structural scan
trisurf(scan_mesh.faces, ...
    scan_mesh.vertices_0(:, 1), ...
    scan_mesh.vertices_0(:, 2), ...
    scan_mesh.vertices_0(:,3), ...
    'EdgeColor', 'none', 'FaceColor', 'red');

ax = gca;
ax.Interactions = dataTipInteraction;
disableDefaultInteractivity(ax); % turn off irritating data tips

axis equal
view([90, 0])
lightangle(45,-50);

fid_prompts = {'Select point anterior to left ear.',...
    'Select point in the middle of forehead.',...
    'Select point in the middle of chin or above mouth.',...
    'Select point anterior to right ear.'};

% iterate over the points to identify
face_points = zeros(length(fid_prompts), 3);
for ii=1:length(fid_prompts)
    axes(ax);  %#ok
    h_title = title(fid_prompts{ii});
    pause
    face_points(ii, :) = select3d;
    delete(h_title);
end

pause(1);  % make closing less promptly
close(fig);