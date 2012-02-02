function hout = myload (fn, varargin)
%MYLOAD Load workspace variables from disk in documented format.
%

%   John S. Stroud, Ph.D.
%   CSS Code R21
%   x4540
%   03 June 2003

if ~exist('fn','var')
    fn = default('name');
end
errsource = 'mymat:myload';
dfn = 'uint8';

[path, name, ext] = fileparts(fn);
if isempty(ext)
    ext = default('ext');
end
fn = fullfile(path, [name ext]);

n = nargin - 1;
if n < 1
    s = {'*'};
else
    s = cell(n, 1);
    for index = [1 : n]
        s{index} = varargin{index};
    end
end

fid = fopen(fn, 'rb', default('format'));
if fid == -1
    error ([errsource ':fopen'], 'Could not open file "%s" for reading', fn);
end

h = header(fid, 'read');
if (h)
    fclose(fid);
    error ([errsource ':NotMyMatFile'],'"%s" is not a valid mymat file', fn);
end


loopcontrol = 1;
nextdir = ftell(fid);
while loopcontrol
    nextdir = location(fid, 'read', nextdir);
    its = struct(...
        'name', [], ...
        'size', [], ...
        'real', [], ...
        'global', [], ...
        'class', [], ...
        'realval', [], ...
        'imagval', []);

    if feof(fid)
        loopcontrol = 0;
        break;
    end
    namelength = fread(fid, 1, dfn);
    numdims = fread(fid, 1, dfn);
    its.real = fread(fid, 1, dfn);
    its.global  = fread(fid, 1, dfn);
    its.class = fread(fid, 1, dfn);
    its.name = fread(fid, namelength, 'char');
    its.name = char(its.name(:)');

    matched = 0;
    for index = 1 : length(s)
        target = s{index};
        if isempty(target)
            error([errsource ':EmptyTarget'], 'An empty target has been specified')
        end
        if ~ischar(target)
            error([errsource ':NoNameTarget'], 'You must specify a name for the target')
        end

        if target(end) == '*'
            if length(target) == 1
                matched = 1;
            elseif strncmp(its.name, target, length(target) - 1)
                matched = 1;
            end
        elseif strcmp(its.name, target)
            matched = 1;
        else
            dotlocs = findstr(its.name, '.');
            if ~isempty(dotlocs)
                if strcmp(its.name(1:dotlocs(1)-1), target)
                    matched = 1;
                end
            end
        end

        if matched
            break;
        end
    end
    if  matched
%         disp (['Matched a variable named : ' its.name]);
        its.size = fread(fid, numdims, 'uint32');
        [code, ofn] = translate('class', its.class);


        its.realval = fread(fid, prod(its.size), ofn);
        if ~its.real
            its.imagval = fread(fid, prod(its.size), ofn);
            % 17 July 2006
            % the code in flexible is writing the data out in
            % r0,i0,r1,i1,...,rN,iN format while this code is expecting
            % r0,r1,...rN,i0,i1,...iN
            if its.class == 1
                its.val = [complex(its.realval(1:2:end), its.realval(2:2:end)) ...
                    complex(its.imagval(1:2:end), its.imagval(2:2:end))];
            else
                its.val = complex(its.realval, its.imagval);
            end % its.class hack
            % 03 March 2004
            % the complex values are coming in wrong
            % I don't know for certain that the following is correct
            % for all cases, but it seems to work
            % J Stroud x4540

            % was
            % its.val = (reshape(its.val,its.size(:)'));
            % now is
            its.val = (reshape(its.val, its.size(end:-1:1)').');
        else
            % was
            % its.val = (reshape(its.realval,its.size(:)'));
            % now is
            its.val = (reshape(its.realval, its.size(end:-1:1)').');
        end


        switch code
            case 'double'
            case 'single' % added 05/25/06 to support single
            case 'char'
                % 07 April 2004
                % char values weren't coming in as chars
                % we were still using the realval, rather
                % than the val
                % J Stroud x4540

                % was
                % its.realval = char(its.realval(:)');
                % now is
                its.val = char(its.val);
            otherwise
                warning('unrecognized code found');
        end

        dotlocs = findstr(its.name, '.');
        if isempty(dotlocs)
            if nargout > 0
                hout.(its.name) = its.val;
            else
                assignin('caller',its.name, its.val);
            end
        else
            switch length(dotlocs)
                case 1
                    out.(its.name(dotlocs+1:end)) = its.val;
                case 2
                    out.(its.name(dotlocs(1)+1:dotlocs(2)-1)).(its.name(dotlocs(2)+1:end)) = its.val;
                case 3
                    out.(its.name(dotlocs(1)+1:dotlocs(2)-1)).(its.name(dotlocs(2)+1:dotlocs(3)-1)).(its.name(dotlocs(3)+1:end)) = its.val;
                otherwise
                    error([errsource ':NestedStructure'], 'Too deeply nested structure')
            end
            if nargout > 0
                hout.(its.name(1:dotlocs(1)-1)) = out;
            else
                assignin('caller', its.name(1:dotlocs(1)-1), out);
                % if length(dotlocs) > 1
                %    %error('can''t handle structs of structs')
                % end
                % out.(its.name(dotlocs+1:end)) = its.val;
                % assignin('caller', its.name(1:dotlocs-1), out);
            end
        end
    end
end
fclose(fid);

return
% Adding the CVS LOG
%
% $Log: myload.m,v $
% Revision 1.3  2006/07/17 18:16:12  stroudjs
% Modified the files to accept single precision and when such variables are encountered, to treat them as stored r0,i0,r1,i1,...,rN,iN instead of r0,r1,...rN,i0,i1,...,iN.
% This is known to fail if the embedded code ever uses doubles rather than floats for sas_real.
% Added cvs log keyword to the files already modified.
%
%
%