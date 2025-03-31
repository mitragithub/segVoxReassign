%file reading/loading
%addpath('/Users/christophermezias/Desktop/MitraLab/nrrdread/'); %if before 2022b, have to install nrrdread and give path
% segname = 'Allen_to_ccf.vtk'; %Allen segs on CCF
% outname = 'mouse_ccf_segvol_metrics.csv'; %output csv name
% segname = 'annotation_100_bregma_LR.vtk'; %Allen 100um, with hemis
% outname = 'Allen_v3_segvol_metrics.csv'; %output csv name
% segname = 'annotation_50.vtk'; %Allen 50um from lab Dropbox
% outname = 'Allen_v3_segvol_metrics_50um_sym.csv';
% segname = 'annotation_100.nrrd'; %Allen 25um nrrd from Allen site
% outname = 'Allen_v3_nrrd_metrics_25um.csv';
% segname = 'labels_annotation_to_population.vtk';
% outname = 'marmoset_RIKEN_metrics_lowres.csv';
% segname = 'merged_CCFSaleem_SegVol.nii.nii';
% outname = 'marmoset_merged_SaleemRIKEN_metrics.csv';
% segname = 'marmoset_merged_SaleemRIKEN_corrected.mat';
% outname = 'marmoset_SaleemRIKEN_corrected_metrics.csv';
segname = 'annotation_50_bregma_LR_u16_corr.mat';
outname = 'Allen_seg_v3_LRbregma_corrected_metrics.csv';
%ontname = 'merged_CCFSaleem_Ontology_hierarchy.csv';
%ontology = readtable(ontname);
basecomp = 1; %2 for symmetric volumes, 1 for asymmetric volumes

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

%test to make sure segmentation image appears correctly (have to remap
%values, imagesc will not interpret integer values > 2^31-1
slice = squeeze(I(:,100,:));
uslice = unique(slice);
for i = 1:length(uslice)
    curu = uslice(i);
    slice(slice==curu) = i - 1;
end
figure; imagesc(slice); colormap("jet");

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
%writetable(regidtab,outname);

%Visualize overall histogram
figure; bar(1:length(totN),totN);
xticklabels({'1','2','3','4','5','6-10','11-25','26-50','51-100','101+'});

%Choose region ID and visualize per ID histogram
% choid = 753; %region ID
% ontids = table2array(ontology(:,1));
% ontnames = table2array(ontology(:,2));
% curreg = ontnames(ontids==choid);
% curreg = strrep(curreg,'_',' ');
% idind = find(segids==choid);
% visN = globN{idind};
% figure; bar(1:length(visN),visN);
% xticklabels({'1','2','3','4','5','6-10','11-25','26-50','51-100','101+'});
% title(curreg,'FontSize',18);

