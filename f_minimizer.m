options = optimset('Display','iter', 'TolX', 1);
%x = fminbnd(@optic_disc_identifier_training,0,50, options);
x = fminbnd(@macula_identifier_training,0,150, options);
disp(x);

% found value of Y for optic disc is 21
% found value of Y for macula is 91
