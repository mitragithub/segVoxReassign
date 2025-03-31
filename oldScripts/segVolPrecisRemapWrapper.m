%categorical/segmentation volume filename to read
segname = 'marmoset_merged_SaleemRIKEN_LR.nii';

%output hash table filename (must be & end with .csv)
csvoutname = 'marmoset_test_precis_remap.csv';

%desired precision/variable type and output filetype for new volume
precis = 'uint16';
outvolnm = 'marmoset_merged_SaleemRIKEN_LR_remap.nii';

%reading in volume contained in file "segname"
extname = split(segname,'.');
extname = extname{end};
if strcmpi(extname,'vtk')
    [x1,x2,x3,I] = read_vtk_image_v3(segname,'b'); %read in vtk file
elseif strcmpi(extname,'nrrd')
    I = nrrdread(segname);
elseif strcmpi(extname,'nii') || strcmpi(extname,'gz')
    I = niftiread(segname);
elseif strcmpi(extname,'mat')
    load(extname);
else
    errmsg = "unrecognized volume file format";
    error(errmsg);
end

%get list of unique IDs in old volume & load or generate new list
segids = unique(I); %unique label set
newids = uint16(segids); %new set of IDs, change this line for other methods of creating new ID list

%call fxn to remap segmentation IDs to new variable type/precision
[newI,segidhash] = newVolPrecis(I,csvoutname,newids,segids,outvolnm,precis);

%test remap and save of new volume by reading in and examining ID list
clear newI
extname = split(outvolnm,'.');
extname = extname{end};
if strcmpi(extname,'vtk')
    [x1,x2,x3,newI] = read_vtk_image_v3(outvolnm,'b'); %read in vtk file
elseif strcmpi(extname,'nrrd')
    newI = nrrdread(outvolnm);
elseif strcmpi(extname,'nii') || strcmpi(extname,'gz')
    newI = niftiread(outvolnm);
elseif strcmpi(extname,'mat')
    load(outvolnm);
else
    errmsg = "unrecognized volume file format";
    error(errmsg);
end
newsegs = unique(newI);


