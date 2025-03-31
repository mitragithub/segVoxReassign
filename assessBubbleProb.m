function regidtab = assessBubbleProb(segname,outname,basecomp)
%assessBubbleProb: Function to assess the degree of bubbles (isolated
%region ID voxel assignments) present in a given segmented volume
%
%Inputs: 
%   segname: filename of the segmented volume to assess
%   outname: filenames for the output table and histograms showing degree
%   of bubble (isolated voxel assignment) issues present in input volume
%   basecomp: flag indicating whether volume is symmetric or asymmetric,
%   where 1 = asymmetric and 2 = symmetric
%
%Outputs: 
%   regidtab: table showing the degree of bubbling (isolated voxel
%   assignment) per region ID present in volume
%
%File Outputs:
%   regidtab csv: csv file with the same info as in "regidtab" above, saved
%   to a csv file as named by the user via "outname"
%   histogram png: histogram saved as a png showing the frequency of voxel
%   size for every connected component in the segmented volume, saved to a
%   png file as named by the user via "outname

%Read in volume
extname = split(segname,'.');
extname = extname{end};
if strcmpi(extname,'vtk')
    [x1,x2,x3,I] = read_vtk_image_v3(segname,'b'); %read in vtk file
elseif strcmpi(extname,'nrrd')
    I = nrrdread(segname);
elseif strcmpi(extname,'nii') || strcmpi(extname,'gz')
    I = niftiread(segname);
elseif strcmpi(extname,'mat')
    load(segname);
    I = newI; clear newI
else
    errmsg = "unrecognized volume file format";
    error(errmsg);
end

%test to make sure segmentation image appears correctly, look for bubbles
slice = squeeze(I(:,100,:));
uslice = unique(slice);
for i = 1:length(uslice)
    curu = uslice(i);
    slice(slice==curu) = i - 1;
end
figure; imagesc(slice); colormap("jet"); daspect([1 1 1]);
saveas(gcf,[outname 'slice.png']);
close;

%Get number of voxels and connected components for segs
segids = unique(I); %unique label set
ncomp = zeros(length(segids),1);
nvox = cell(length(segids),1);
globN = cell(length(segids),1);
%globE = cell(length(segids),1);
baseE = [0.5 1.5 2.5 3.5 4.5 5.5 10.5 25.5 50.5 100.5 Inf];
totN = zeros(1,length(baseE)-1);
for i = 1:length(segids)
    bwseg = zeros(size(I));
    curseg = segids(i);
    bwseg(I==curseg) = 1;
    concomp = bwconncomp(bwseg,6); %6 defines connectivity as touching faces, excluding corner and edges links
    ncomp(i) = concomp.NumObjects; %number of components
    complens = zeros(length(concomp.PixelIdxList),1);
    for j = 1:length(concomp.PixelIdxList)
        curcomp = concomp.PixelIdxList{j};
        complens(j) = length(curcomp);
    end
    nvox{i} = join(string(complens),';'); %number of vox per component
    if length(complens) > basecomp && curseg > 0
        complens = sort(complens,'descend');
        complens(1:basecomp) = [];
        [curN,curE] = histcounts(complens,baseE);
        totN = totN + curN;
        globN{i} = curN;
    end
end

%Write out segmentation vol metrics to table
regidtab = table(segids,ncomp,nvox); %writing seg metrics to table
writetable(regidtab,[outname '.csv']);

%Visualize overall histogram
figure; bar(1:length(totN),totN);
xticklabels({'1','2','3','4','5','6-10','11-25','26-50','51-100','101+'});
saveas(gcf,[outname '_hist.png']);
close;

end


