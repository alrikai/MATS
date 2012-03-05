function ofdata = read_ofdata(fn) %#ok<STOUT>
load(fn, '-mat', 'ofdata');
assert( exist('ofdata','var') == 1, 'file %s does not contain optional contact data.', fn);
end