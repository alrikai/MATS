function out = feature_snippet(in)

%% Tucker MCA Features
X = formchannel( img_trim(in.hfsnippet,6,4), 6, 4); %SSAM
Y = formchannel( img_trim(in.bbsnippet,2,8), 2, 8);
% X = formchannel(in.hfsnippet,6,4); %SSAM
% Y = formchannel(in.bbsnippet,2,8);

[X, meanX] = remmean(X);
[Y, meanY] = remmean(Y);

W{1} = double(Y.');
W{2} = double(X.');

[a,L] = mca(W);
ks = diag(abs(L));
shf = allstats(abs(in.hfsnippet(:))); %F <--make vectors?
sbb = allstats(abs(in.bbsnippet(:))); %F
tucker_features = [ks; shf.mean; shf.var; shf.skew; shf.kurt; sbb.mean; sbb.var; sbb.skew; sbb.kurt];

%% Isaacs Features
FILTERS = 0;  %dummy for Filter bank (default is none)
bins = 20;
method = 1; %dummy for selection (default is all)
ani = double(abs(in.hfsnippet));
LMSFeatVect1 = makeFeatVect1(ani,FILTERS,bins,method)';
ani = double(abs(in.bbsnippet));
LMSFeatVect2 = makeFeatVect1(ani,FILTERS,bins,method)';
out = in;
out.features = [LMSFeatVect1; LMSFeatVect2; tucker_features];

end

function out = img_trim(in, N1, N2)
% trims a little around the edges of an image to make the image k*N1 x m*N2
% for some integers k and m.  ('formchannel' is expecting this and will
% crash from an index-out-of-bounds error)
act_size = size(in);
block_size = floor( act_size ./ [N1, N2] ) .* [N1, N2];
offset1 = floor((act_size - block_size)/2);
offset2 = act_size - block_size - offset1;
out = in( (offset1(1)+1):(end-offset2(1)),(offset1(2)+1):(end-offset2(2)) );

end

function LMSFeatVect = makeFeatVect1(MO,FILTERS,bins,method)
% TrainIMGS = yfaces;
% FILTERS = FILTERSOUT;
% bins = 16;
% FILTERS = FILTER_S;
% TrainIMGS = AppEigenImage;
highorder = 7;
% [v,u] = size(TrainIMGS);
tempFV2 = [];
% method = 1;
ZS = (0:bins-1)/bins;

[m,n] = size(MO);
M = m*n; %number of pixels in image


%     for loop2 = 1:k;
%         tempFILTERS = cat(FILTERS(loop2).FILTERS,loop;
result = MO/max(max(MO));
%     keyboard

tempFV2 = [];
for method = 1:3
    HISTR = imhist(result,bins)/M;
    
    switch method
        case 1 %statistical moments method
            
            
            meanHIST = sum(ZS.*HISTR.');
            [row,col] = size(HISTR);
            %for loop2 = 1:col;
            
            for loopmoment = 2:highorder;
                U(loopmoment-1) = sum(((ZS-meanHIST).^(loopmoment)).*HISTR.');
            end;
            
        case 2 % energy and entropy measure method
            
            VARH = var(HISTR);
            
            %                 subplot(7,8,i);imagesc(temp);axis off;
            FirstOrderProb = (HISTR);%/M
            ENERGYH = sum(FirstOrderProb.*FirstOrderProb);
            [q,r] = size(FirstOrderProb);
            ENTROPYH = 0;
            for k = 1:q;
                if FirstOrderProb(k) ~= 0;
                    LOGH = log2(FirstOrderProb(k));
                else LOGH = 0;
                end;
                ENTROPYH = ENTROPYH + FirstOrderProb(k)*LOGH;
            end;
            MEANSQR = mean(mean(result.*result));
            %ENERGY = sum(sum(temp^2));
            U = [ENERGYH ENTROPYH MEANSQR];
        case 3 %spectral histogram only method
            U = HISTR.';
            
    end;
    tempFV2 = [tempFV2 U];%];%ENERGYH ENTROPYH];MEANSQR
end
%subplot(10,10,loop);stem(tempFV2);
LMSFeatVect = tempFV2;
end