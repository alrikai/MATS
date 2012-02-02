function  drillstruct(varargin)
s = cell(1,nargin);
for index = 1:nargin
    s{index}= varargin{index};
end
for index = 1:nargin
    a = s{index};
    b = evalin('caller', ['whos(''' a ''')']);
    theval = evalin('caller', a);
    
    if ~strcmp(b.class,'struct')
        if ischar(theval)
            disp([a ' is ' theval]);
        else
            disp([a ' is ' num2str(theval)]);
        end
        
    else
        sname = b.name;
        fnames = evalin('caller',['fieldnames(' a ')']);
        for jndex = 1:length(fnames)
            doresolve(sname, fnames{jndex}, theval);
        end
    end
    
end

function  doresolve(strpath, fname, theval)
if isstruct(theval.(fname))
    morefields = fieldnames(theval.(fname));
    for index = 1:length(morefields)
        doresolve([strpath '.' fname], ...
            morefields{index}, theval.(fname));
    end
else
    if ischar(theval.(fname))
        disp ([strpath '.' fname ' is ' theval.(fname)]);
    else
        disp ([strpath '.' fname ' is ' ...
                num2str(theval.(fname))]);
    end
end
return