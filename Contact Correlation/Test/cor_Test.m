function sel_ecdata = cor_Test(contacts, sel_ecdata)

for q = 1:length(sel_ecdata)
    sel_ecdata(q).groupnum = 1;
    sel_ecdata(q).groupclass = 1;
    sel_ecdata(q).groupclassconf = rand;
    sel_ecdata(q).groupconf = rand;
    sel_ecdata(q).grouplat = 0;
    sel_ecdata(q).grouplong = 0;
    sel_ecdata(q).groupcovmat = [1,0;0,1];
end

end
