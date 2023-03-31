function tfm = rigid_coreg(X0, Y0)
% Computes rigid body transformation matrix from X0 to Y0.
% This code was originally written by Sarang S. Dalal
% Updated by Britta U. Westner

% Check dimensions
if(size(X0, 1) < size(X0, 2) || size(Y0, 1) < size(Y0, 2))
    error('Dimensions do not match.');
end


Y = Y0 - ones(size(Y0, 1), 1) * mean(Y0);
X = X0 - ones(size(X0, 1), 1) * mean(X0);

% Compute SVD
[U, ~, V] = svd(Y' * X);

% construct transformation matrix
R0 = V * U';
if(det(R0) < 0)
    B = eye(3);
    B(3, 3) = det(V * U');
    R0 = V * B * U';
end

t0 = mean(X0, 1) - mean(Y0, 1) * R0';
tfm = inv([R0 t0'; 0 0 0 1]);
