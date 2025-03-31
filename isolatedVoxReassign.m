function [newI,replrec] = isolatedVoxReassign(segname,outname,outext,...
    csvname,szthresh,nthresh,bgvals)
%isolatedVoxReassign: a function to reassign voxels in isolated bubbles,
%defined as a set of continuous voxels of the same regional ID below a set
%size threshold, to the nearest neighbor IDs
%
%Inputs:
%   segname: name of the segmentation volume file to correct
%   outname: name of the new corrected volume generated to save
%   outext: file extension for saving the new corrected volume
%   csvname: name of the csvfile to save voxel reassignment records
%   szthresh: size threshold defining the cutoff of an isolated bubble
%   nthresh: threshold for number of components for regional ID
%   bgvals: background ID value, usually 0
%
%Outputs:
%   newI: new segmentation volume with bubble voxel IDs reassigned to
%   nearest neighbors
%   replrec: table containing voxel reassignment records
%
%File Outputs:
%   newI volume: output variable as defined above, saved to the user
%   defined file extension specified using "outext"
%   replrec table: output table as defined above, saved to the csv file
%   named as per user definition using "csvname"

%Read in segmented volume to correct
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
    I = newI;
    clear newI
else
    errmsg = "unrecognized volume file format";
    error(errmsg);
end

%Get number of voxels and connected components for segs
segids = unique(I); %unique label set
segids(ismember(segids,bgvals)) = [];
newI = I;
replvec = [];
replvox = [];
replseg = [];
newrvox = [];
for i = 1:length(segids)
    bwseg = zeros(size(I));
    curseg = segids(i);
    bwseg(I==curseg) = 1;
    concomp = bwconncomp(bwseg,6); %6 defines connectivity as touching faces, excluding corner and edges links
    ncomp = concomp.NumObjects;
    for j = 1:length(concomp.PixelIdxList)
        curcomp = concomp.PixelIdxList{j};
        if length(curcomp) <= szthresh && ncomp > nthresh
            replvec = [replvec;repmat(curseg,length(curcomp),1)];
            replvox = [replvox;curcomp];
            replseg = [replseg;repmat(j,length(curcomp),1)];
            [curx,cury,curz] = ind2sub(size(I),curcomp);
            neighbs = [curx-1 cury curz;curx+1 cury curz;curx cury-1 curz;...
                curx cury+1 curz;curx cury curz-1;curx cury curz+1];
            [xtest,ytest] = find(neighbs==0); %testing for whether any neighbs at edge of volume
            if ~isempty(xtest)
                neighbs(xtest,:) = [];
            end
            neighbs = sub2ind(size(I),neighbs(:,1),neighbs(:,2),neighbs(:,3));
            neighbs(ismember(neighbs,curcomp)) = [];
            curregids = I(neighbs);
            repval = mode(curregids);
            if repval == 0
                curregids(curregids==0) = [];
            end
            newI(curcomp) = mode(curregids);
            newrvox = [newrvox;repmat(mode(curregids),length(curcomp),1)];
%             figure; scatter3(curx,cury,curz,40,'filled','bo'); hold on;
%             scatter3([curx+1 curx-1 curx curx curx curx],...
%                 [cury cury cury+1 cury-1 cury cury],...
%                 [curz curz curz curz curz+1 curz-1],30,'filled','rs');
%             xticks(min(curx(:))-1:max(curx(:))+1); 
%             yticks(min(cury(:))-1:max(cury(:))+1); 
%             zticks(min(curz(:))-1:max(curz(:))+1);
        end
    end
end


%Make table of values & save
% replids = unique(replvec);
% repcounts = sum(replvec(:)==replids(:)')';
% replrec = table(replids,repcounts);
replrec = table(replvec,replvox,replseg,newrvox);
writetable(replrec,csvname);


%Write out new volume as file given in outext
outvolnm = [outname outext];
if strcmpi(outext,'.mat')
    save(outvolnm,"newI");
elseif contains(outext,'nii')
    niftiwrite(newI,outvolnm);
elseif strcmpi(outext,'.vtk')
    write_vtk_image(newI,outvolnm);
end



end