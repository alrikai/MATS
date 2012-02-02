clc
numimages = input('Number of Images: ');
numimages = 1+numimages;
leg = input('Leg: ','s');
more = 1;
numpings = 400;
pingoverlap = 200;
for i = 1:numimages
    pings(:,i) = (i-1)*pingoverlap+1:(i-1)*pingoverlap+numpings;
end

while more == 1
    
    ping = input('Ping: ');
    side = input('1 Port / 0 Stbd: ');
    
    [r,c] = find(pings == ping);
    if isempty(c)
        break
    end
    c = c - [1;1];
    tmp = find(c == 0); c(tmp) = 1;
    c = unique(c);
    if side == 1
        if length(c) == 1
            numzeros1 = 6 - length(num2str(c(1)));
            numzeros2 = 0;
            stzero1 = [];
        else
            numzeros1 = 6 - length(num2str(c(1)));
            numzeros2 = 6 - length(num2str(c(2)));
            stzero1 = [];
            stzero2 = [];
        end
        for i = 1:numzeros1
            stzero1 = [stzero1 '0'];
        end
        for i = 1:numzeros2
            stzero2 = [stzero2 '0'];
        end
        if length(c) == 1
            hiname1 = ['PHi00-' leg '-' stzero1 num2str(c(1)) '.mymat'];
            liname1 = ['PLi00-' leg '-' stzero1 num2str(c(1)) '.mymat'];
            hiname1o = ['PHi00-' leg '-Pings' num2str(pings(1,c(1))) '-' num2str(pings(end,c(1))) '.mymat'];
            liname1o = ['PLi00-' leg '-Pings' num2str(pings(1,c(1))) '-' num2str(pings(end,c(1))) '.mymat'];
        else
            hiname1 = ['PHi00-' leg '-' stzero1 num2str(c(1)) '.mymat'];
            hiname2 = ['PHi00-' leg '-' stzero2 num2str(c(2)) '.mymat'];
            liname1 = ['PLi00-' leg '-' stzero1 num2str(c(1)) '.mymat'];
            liname2 = ['PLi00-' leg '-' stzero2 num2str(c(2)) '.mymat'];
            hiname1o = ['PHi00-' leg '-Pings' num2str(pings(1,c(1))) '-' num2str(pings(end,c(1))) '.mymat'];
            hiname2o = ['PHi00-' leg '-Pings' num2str(pings(1,c(2))) '-' num2str(pings(end,c(2))) '.mymat'];
            liname1o = ['PLi00-' leg '-Pings' num2str(pings(1,c(1))) '-' num2str(pings(end,c(1))) '.mymat'];
            liname2o = ['PLi00-' leg '-Pings' num2str(pings(1,c(2))) '-' num2str(pings(end,c(2))) '.mymat'];
        end
    elseif side == 0
        if length(c) == 1
            numzeros1 = 6 - length(num2str(c(1)));
            numzeros2 = 0;
            stzero1 = [];
        else
            numzeros1 = 6 - length(num2str(c(1)));
            numzeros2 = 6 - length(num2str(c(2)));
            stzero1 = [];
            stzero2 = [];
        end
        for i = 1:numzeros1
            stzero1 = [stzero1 '0'];
        end
        for i = 1:numzeros2
            stzero2 = [stzero2 '0'];
        end
        if length(c) == 1
            hiname1 = ['SHi00-' leg '-' stzero1 num2str(c(1)) '.mymat'];
            liname1 = ['SLi00-' leg '-' stzero1 num2str(c(1)) '.mymat'];
            hiname1o = ['SHi00-' leg '-Pings' num2str(pings(1,c(1))) '-' num2str(pings(end,c(1))) '.mymat'];
            liname1o = ['SLi00-' leg '-Pings' num2str(pings(1,c(1))) '-' num2str(pings(end,c(1))) '.mymat'];
        else
            hiname1 = ['SHi00-' leg '-' stzero1 num2str(c(1)) '.mymat'];
            hiname2 = ['SHi00-' leg '-' stzero2 num2str(c(2)) '.mymat'];
            liname1 = ['SLi00-' leg '-' stzero1 num2str(c(1)) '.mymat'];
            liname2 = ['SLi00-' leg '-' stzero2 num2str(c(2)) '.mymat'];
            hiname1o = ['SHi00-' leg '-Pings' num2str(pings(1,c(1))) '-' num2str(pings(end,c(1))) '.mymat'];
            hiname2o = ['SHi00-' leg '-Pings' num2str(pings(1,c(2))) '-' num2str(pings(end,c(2))) '.mymat'];
            liname1o = ['SLi00-' leg '-Pings' num2str(pings(1,c(1))) '-' num2str(pings(end,c(1))) '.mymat'];
            liname2o = ['SLi00-' leg '-Pings' num2str(pings(1,c(2))) '-' num2str(pings(end,c(2))) '.mymat'];
        end
    else
        disp('Error!')
    end
    if length(c) == 1
        copyfile(hiname1,hiname1o);
        copyfile(liname1,liname1o);
    else
        copyfile(hiname1,hiname1o);
        copyfile(hiname2,hiname2o);
        copyfile(liname1,liname1o);
        copyfile(liname2,liname2o);
    end
    more = input('More Targets (1/0): ');
end
delete(['PHi00-' leg '-' '0*.mymat'])
delete(['PLi00-' leg '-' '0*.mymat'])
delete(['SHi00-' leg '-' '0*.mymat'])
delete(['SLi00-' leg '-' '0*.mymat'])
clear all