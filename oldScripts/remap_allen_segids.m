%Set filenames/extensions and other inputs for read-in, write-out
segname = 'annotation_50_bregma_LR.vtk';
outname = 'annotation_50_bregma_LR_u16';
outext = '.mat';
bgvals = [0 2^31];
addval = 2^13;
%is2bg = length(bgvals)>1;
is2bg = 1;

%read in Allen volume
[x1,x2,x3,I] = read_vtk_image_v3(segname,'b');

%Get list of unique IDs
segids = unique(I); %unique label set

%Get rid of artifactual IDs from hemisphere split
half1 = segids(segids<bgvals(2));
half2 = segids(segids>=bgvals(2)) - bgvals(2);

% if ~is2bg
%     half1 = half1(2:end);
% end

if length(half1) > length(half2)
    badvals = find(~ismember(half1,half2));
    segids(badvals) = [];
    hflag = 1;
elseif length(half1) < length(half2)
    badvals = find(~ismember(half2,half1));
    segids(badvals+length(half1)) = [];
    hflag = 0;
else
    badvals = [];
end

% for i = 1:length(badvals)
%     if hflag
%         badval = half1(badvals(i));
%         test = ismember(I,badval);
%     else
%         badval = half2(badvals(i));
%         test = ismember(I,(badval+bgvals(2)));
%     end
%     figure;
%     surf1 = isosurface(test);
%     p1 = patch(surf1);
%     set(p1,'FaceColor',[0.9 0.9 0.9],'EdgeColor','none','FaceAlpha',0.05);
%     daspect([1,1,1])
%     view(3); 
%     camlight; lighting gouraud
% end

%Generate new list of IDs to replace old set, restruct to uint16
if is2bg
    newids = repmat(uint16(0:length(segids)/2-1)',2,1);
    newids(length(newids)/2+1:end) = newids(length(newids)/2+1:end) + addval;
else
    newids = repmat(uint16(1:length(segids(2:end))/2)',2,1);
    newids(length(newids)/2+1:end) = newids(length(newids)/2+1:end) + addval;
    newids = [0;newids];
end


%Make has table relating Allen IDs to CSHL IDs
if is2bg %If 2 background (null) IDs, replace larger with 0 to harmonize
    newids(newids==addval) = 0;
end
segidhash = table(segids,newids);
segidhash.Properties.VariableNames = {'AllenIDs','BAPIDs'};
writetable(segidhash,'BAP2Allen_segids_hash.csv');

%Generate new volume with Allen IDs replaced with CSHL/BAP IDs
newI = zeros(size(I),'uint16');
for i = 1:length(segids)
    curold = segids(i);
    curnew = newids(i);
    curinds = find(I==curold);
    newI(curinds) = curnew;
end

%verify outputs
figure; imagesc(squeeze(newI(size(newI,1)/2,:,:))); colormap("hsv");
figure; imagesc(squeeze(I(size(I,1)/2,:,:))); colormap("hsv");

%Write out new volume as file type given in outext
outvolnm = [outname outext];
if strcmpi(outext,'.mat')
    save(outvolnm,"newI");
elseif contains(outext,'.nii')
    niftiwrite(newI,outvolnm);
elseif strcmpi(outext,'.vtk')
    write_vtk_image(newI,outvolnm);
end








