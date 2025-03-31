%% Allen segmentation IDs remapped from very large values (>2^32) to uint16
%Set filenames/extensions and other inputs for read-in, write-out
segname = 'annotation_25_bregma_LR.vtk'; %Allen segmentation file
outname = 'annotation_25_bregma_LR_u16'; %new name for segmentation file
outext = '.mat'; %new file extension
is2bg = 1; %binary flag for whether there are 2 background indices in orig file
bgvals = [0 2^31]; %value of background values in file
addval = 2^13; %new value to add to denote hemisphere split

%Call function to remap to uint16 from uint32 or uint64
newI = allen_segid_remap(segname,outname,outext,...
    is2bg,bgvals,addval);

%% Reassign isolated bubbles
%Isolated bubbles defined as continuous groups of voxels with the same
%segmentation ID below a certain size threshold 

%Set inputs for isolated vox/bubble reassignment
segname = 'annotation_25_bregma_LR_u16.mat';
outname = 'corrected_volume_LR_u16';
outext = '.nii';
csvname = 'corrected_allen_mouse_records_50um_LR.csv';
szthresh = 5;
nthresh = 1;
bgvals = 0;

%Call function to reassign isolated voxels/bubbles
[newI,replrec] = isolatedVoxReassign(segname,outname,outext,...
    csvname,szthresh,nthresh,bgvals);

%% Analyze volumes to see degree/completeness of correction
%Correction is based on a heuristic algorithm and so will not be perfect;
%instead original and corrected volumes should be analyzed using the
%function below to understand degree of correction

%Set inputs for assessing original volume and call function
segname = 'annotation_25_bregma_LR_u16.mat';
outname = 'orig_annotation_25_bregma_LR';
basecomp = 1; %2 for symmetric volumes, 1 for asymmetric volumes
regidtab_orig = assessBubbleProb(segname,outname,basecomp);

%Set inputs for assessing corrected volume and call function
segname = 'corrected_volume_LR_u16.nii';
outname = 'corrected_annotation_25_bregma_LR';
basecomp = 1; %2 for symmetric volumes, 1 for asymmetric volumes
regidtab_corr = assessBubbleProb(segname,outname,basecomp);

