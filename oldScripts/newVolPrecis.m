function [newI,segidhash] = newVolPrecis(I,csvoutname,newids,segids,outvolnm,precis)
%newVolPrecis Remaps categorical array from one precision to another by
%changing ID values or precisions or both and remapping into new array.
%   Inputs:
%       I: old categorical array/volume
%       csvoutname: filename for hash table between new and old categorical
%       arrays/volumes
%       newids: new ID list, should be at correct precision/bit depth and
%       variable type already
%       segids: old ID list, should match precision/bit depth and variable
%       type of old categorical array/volume, default is unique set of IDs
%       from old array/volume
%       outvolnm: desired new output volume filetype extension
%       precis: desired precision/bit depth/variable type of new set of ID
%       labels for mapping into new categorical array/volume
%   Outputs:
%       newI: new, remapped categorical array/volume
%       segidhash: has table translating between new and old IDs; only
%       contains values, does not contain variable type/precision info

if nargin < 5
    precis = 'uint16';
    if nargin < 4
        segids = unique(I); %unique label set
    end
end

%Make has table relating old IDs to new IDs
segidhash = table(segids,newids);
segidhash.Properties.VariableNames = {'OldIDs','NewIDs'};
writetable(segidhash,csvoutname);

newI = zeros(size(I),precis);
for i = 1:length(segids)
    curold = segids(i);
    curnew = newids(i);
    curinds = find(I==curold);
    newI(curinds) = curnew;
end

%saving volume in newI
outext = split(outvolnm,'.');
outext = outext{end};
if strcmpi(outext,'mat')
    save(outvolnm,"newI");
elseif contains(outext,'nii')
    niftiwrite(newI,outvolnm);
elseif strcmpi(outext,'vtk')
    write_vtk_image(newI,outvolnm);
end

end