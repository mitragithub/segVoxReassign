function [x1,x2,x3,I] = read_vtk_image_v3(fname,etype)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

%Default endian type big = 'b'
if nargin < 2
    etype = 'b';
end

%Define read type with endian and read vtk file
%readtype = ['r' etype];
readtype = 'rb';
fid = fopen(fname,readtype);

% this line says: vtk DataFile Version 3.0
line = fgetl(fid);
display(line)

% this line says the name of the dataset: labels_annotation_to_population
line = fgetl(fid);
display(line)

% this says the type of data: BINARY
line = fgetl(fid);
display(line)

% this says the type of geometry: DATASET STRUCTURED_POINTS
line = fgetl(fid);
display(line)

% this says the number of voxels: 200 200 200
line = fgetl(fid);
display(line)
linesplit = strsplit(line);
n = [str2double(linesplit{2}), str2double(linesplit{3}), str2double(linesplit{4})];

% this says the origin
line = fgetl(fid);
display(line)
linesplit = strsplit(line);
o = [str2double(linesplit{2}), str2double(linesplit{3}), str2double(linesplit{4})];

% this says the pixel size
line = fgetl(fid);
display(line)
linesplit = strsplit(line);
d = [str2double(linesplit{2}), str2double(linesplit{3}), str2double(linesplit{4})];

% this says how many points: POINT_DATA 8000000
line = fgetl(fid);
display(line)
linesplit = strsplit(line);
number = str2double(linesplit{2});

% this says 'SCALARS data_000(b) int'
% SCALARS means this is not vector data
% data_000(b) is the name of this dataset.  The (b) is our convention for
% saying this is big endian
% int means the datatype is int32
% vtk supports bit, unsigned_char, char, unsigned_short, short,
% unsigned_int, int, unsigned_long, long, float, double
% in general, you'd have to conver this string to one of the strings matlab
% supports
line = fgetl(fid);
display(line)
linesplit = strsplit(line);
datatype = linesplit{3};
if strcmpi(datatype,'unsigned_char')
    datatype = 'unsigned char';
elseif contains(datatype,'char')
    datatype = 'char';
elseif contains(datatype,'int')
    if contains(datatype,'un')
        datatype = 'uint32';
    else
        datatype = 'int32';
    end
end
    
% if contains(datatype,'char')
%     datatype = 'char';
% elseif strcm
% end

% this says: LOOKUP_TABLE default
% it means we can use a default colormap to display the data
line = fgetl(fid);
display(line)

% now we can start reading the binary data
% note that the file type does not specify the endian
% all vtk files should be b
% but some of our old data used machine default, which was l
I = fread(fid,number,[datatype '=>' datatype],etype);

%Close the file
line = fgetl(fid);
display(line)
line = fgetl(fid);
display(line)
fclose(fid);

% reshape the data
I = reshape(I,n);

% get the pixel locations
% NOTE I don't know matlab conventions about the ordering of these axes
% you will have to double check by making sure the origin is in the
% location we expect
x1 = o(1):d(1):o(1)+(n(1)-1)*d(1);
x2 = o(2):d(2):o(2)+(n(2)-1)*d(2);
x3 = o(3):d(3):o(3)+(n(3)-1)*d(3);

end