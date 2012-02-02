function [port_on, stbd_on, k_mod_p, k_mod_s, k_inc] = ...
    load_prep(side_a, side_b, port_tag, stbd_tag)
% side_a/b = part of file name that would indicate what side this file is
% port/stbd_tag = what side_a/b would be if that file was a port/stbd file
%
% port/stbd_on = whether the port/stbd side is active in this pairing
% k_mod_p/s = index shift for the port/stbd image
% k_inc = total amount the index will shift after processing this pairing.
%   Note that the second image may not be processed, even though it exists

k_mod_p = []; k_mod_s = [];
if strcmpi(side_a, port_tag) == 1     % (PORT, ????)
    port_on = 1;
    k_mod_p = 0;    % use k for index
    if strcmpi(side_b, stbd_tag) == 1 % (PORT, STBD)
        stbd_on = 1;
        k_mod_s = 1;% use k+1 for index
        k_inc = 2;  % 2 files proc'd
    else                            % (PORT, PORT)
        stbd_on = 0;
        k_inc = 1;  % 1 file proc'd (first = PORT)
    end
else                                % (STBD, ????)
    port_on = 0;
    stbd_on = 1;
    k_mod_s = 0;
    k_inc = 1;      % 1 file proc'd (first = STBD)
end
end