function newI = allen_segid_remap(segname,outname,outext,...
    is2bg,bgvals,addval)
%allen_segid_remap: a function for remapping large Allen IDs (usually
%uint32 or uint64) to a more manageable uint16 range
%
%Inputs:
%   segname: filename of segmentation volume to read in
%   outname: filename of new uint16 valued segmentation volume
%   outext: file extention of new uint16 valued segmentation volume
%   is2bg: binary flag defining whether original volume has 2 values for
%   background (1 = yes 2 values, 0 = no 1 value)
%   bgvals: values assigned as background labels, 1 element long if is2bg
%   == 0, 2 elements long if is2bg == 1
%   addval: value to add to new uint16 set to denote hemisphere split
%
%Outputs:
%   newI: new uint16 segmented volume
%
%Output Files:
%   newI: new segmented volume, can be saved as .mat, .vtk, .nii, depending
%   on the user set "outext" variable
%   BAP2Allen_segids_hash.csv: csv file that denotes equivalence between
%   the region ID labels in the original volume and the new uint16 volume
%   slicecheck_new/old.fig: two .fig files showing the good quality mapping
%   using the new uint16 volume and the bad quality mapping due to
%   misplaced bits using the old uint32 or uint64 volume

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
elseif length(half1) < length(half2)
    badvals = find(~ismember(half2,half1));
    segids(badvals+length(half1)) = [];
else
    badvals = [];
end

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
figure; imagesc(squeeze(newI(size(newI,1)/2,:,:))); colormap("lines");
savefig("slicecheck_new.fig");
close;
figure; imagesc(squeeze(I(size(I,1)/2,:,:))); colormap("lines");
savefig("slicecheck_old.fig");
close;

%Write out new volume as file type given in outext
outvolnm = [outname outext];
if strcmpi(outext,'.mat')
    save(outvolnm,"newI");
elseif contains(outext,'.nii')
    niftiwrite(newI,outvolnm);
elseif strcmpi(outext,'.vtk')
    write_vtk_image(newI,outvolnm);
end

end