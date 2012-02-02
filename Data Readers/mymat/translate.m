function [h, i] = translate (a,opt)
switch lower(a)
    case 'class'
        if ischar(opt)
            switch opt
                case 'double', h = 0; i = opt;
                case 'single', h = 1; i = opt;
                case 'char' , h = 2; i = opt;
                otherwise 
                    warning('unknown class');
                    h = 255;
                    i = 'double';
            end
        else
            switch opt
                case 0 , h = 'double'; i = h;
                case 1 , h = 'single'; i = h; % mod on 5/25/06 to support float
                case 2 , h = 'char'; i = h;
                case 255 , h = 'unknown on output';    
                otherwise
                    warning('unknown class');
                    h = 'unknown';
                    i = 'double';
            end
        end
    otherwise
        warning('unknown translate option')
        h = nan;
        i = 'double';
end

return
% Adding the CVS LOG
%
% $Log: translate.m,v $
% Revision 1.3  2006/07/17 19:29:11  stroudjs
% Somehow an exit statement had crept in where a return was warranted.
%
% Revision 1.2  2006/07/17 18:16:12  stroudjs
% Modified the files to accept single precision and when such variables are encountered, to treat them as stored r0,i0,r1,i1,...,rN,iN instead of r0,r1,...rN,i0,i1,...,iN.
% This is known to fail if the embedded code ever uses doubles rather than floats for sas_real.
% Added cvs log keyword to the files already modified.
%
%
%