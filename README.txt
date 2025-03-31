# Package for bit integer precision remapping and bubble filling pipeline for regionally segmented mouse brain volumes

## Master script: wrapperVoxRemapReassign.m

This script is divided into 3 sections, as follows:
1. Allen segmentation IDs remapped from very large values (>2^32) to uint16
2. Reassignment of isolated bubbles to other ID values
3. Analysis of uncorrected and corrected segmented volumes to see degree or completeness of correction via reassignment of isolated bubbles

## Block 1: Allen segmentation IDs remapped from very large values (>2^32) to uint16

This block has the user set the inputs and then call the function for remapping integer values for segmentation IDs as found in Allen volumes (and Daniel's vtk files) from values that can be >2^32 to values that are <2^16. The function called is "allen_segid_remap.m" with inputs and outputs explained as below.

Note, I only recommend running this block in the wrapper script once. The process of reassigning integer precision level to the IDs in the volume is a process that does not need to be repeated in order to run the isolated voxel reassignment and analysis blocks of the wrapper scripts below. Once the new volume with uint16 values is generated, this uint16 uncorrected Allen volume file can be called repeatedly within the ID reassignment and analysis sections without having to regenerate the volume. The uint16 volume is automatically saved to the user specified filetype via running this block. 

### Inputs to declare:
1. segname: filename of segmentation volume to read in
2. outname: filename of new uint16 valued segmentation volume
3. outext: file extention of new uint16 valued segmentation volume. Permitted options include .mat, .vtk, .nii (NIFTI format)
4. is2bg: binary flag defining whether original volume has 2 values for background (1 = yes 2 values, 0 = no 1 value)
5. bgvals: values assigned as background labels, 1 element long if is2bg == 0, 2 elements long if is2bg == 1
6. addval: value to add to new uint16 set to denote hemisphere split

Note, I do not recommend user changes to any of the above variable values already declared in the wrapper script for use with Allen Institute volumes, with the necessary exceptions of segname, outname, and outext. 

Note, is2bg and bgvals can only be determined by opening and examining the segmented volume contained within the file denoted by segname. For Allen volumes from the Mitra Lab, I have already done this exercise and the values set in these variables in the wrapper script come following manual examination. For a new volume type, this manual examination would need to be repeated before the script is run. 

### Workspace outputs:
1. newI: new uint16 segmented volume

### Saved file outputs:
1. new uint16 segmented volume, can be saved as .mat, .vtk, .nii, depending on the user set "outext" variable and is named as per the "outname" variable
2. BAP2Allen_segids_hash.csv: csv file that denotes equivalence between the region ID labels in the original volume and the new uint16 volume
3. slicecheck_new/old.fig: two .fig files showing the good quality mapping using the new uint16 volume and the bad quality mapping due to misplaced bits using the old uint32 or uint64 volume

## Block 2: Reassign isolated bubbles

Isolated bubbles are defined as continuous groups of voxels with the samesegmentation ID below a certain size threshold, with that threshold being set by the user as a variable. The user can therefore experiment with the size threshold they wish to set. The function called by this block of code is: "isolatedVoxReassign.m"

Note, the function called in this section operates on a heuristic principle, so while the number of bubbles is usually cut by 2-3 orders of magnitude, there will generally still be a couple to a few hundred bubbles remaining (down from tens of thousands). The amount of bubbles remaining will depend on the size threshold. 

Note, setting the size threshold too large (e.g. over 5 or 6 voxels even with the highest resolution volumes) can yield the loss of some legitimately very small segmentation IDs/regions. Proceed with caution and check output if setting the bubble size threshold to higher values. 

### Inputs to declare: 

1. segname: name of the segmentation volume file to correct
2. outname: name of the new corrected volume generated to save
3. outext: file extension for saving the new corrected volume
4. csvname: name of the csvfile to save voxel reassignment records
5. szthresh: size threshold defining the cutoff of an isolated bubble, recommend
6. nthresh: threshold for number of components for a regional ID to be skipped, recommend keeping at 1. E.g. if a regionID only has 1 unique connected component, it will be skipped to replacement. 
7. bgvals: background ID value, will be 0 if uint16 volume input generated with the first block from this wrapper script

### Workspace Outputs: 

1. newI: new segmentation volume with bubble voxel IDs reassigned to nearest neighbors
2. replrec: table containing voxel reassignment records

### Saved file outputs: 

1. newI volume: output variable as defined above, saved to the user defined file extension specified using "outext"
2. replrec table: output table as defined above, saved to the csv file named as per user definition using "csvname"

## Block 3: Analyze volumes to see degree/completeness of correction

Note, the correction performed in Block 2, above, is based on a heuristic algorithm and so will not be perfect; instead original and corrected volumes should be analyzed using the function calls below to understand degree of correction by analyzing the degree of the bubble problem in both the original (uncorrected) and bubble reassigned (corrected) volumes. The function called in this block is called "assessBubbleProb.m"

Note, the "assessBubbleProb.m" function is called twice in this block with slightly different input variable filenames called. This is because both the original uncorrected (still with thousands of bubbles) volume and the corrected volume are both analyzed by the same function. 

### Inputs to declare:

1. segname: filename of the segmented volume to assess
2. outname: filenames for the output table and histograms showing degree of bubble (isolated voxel assignment) issues present in input volume
3. basecomp: flag indicating whether volume is symmetric or asymmetric, where 1 = asymmetric and 2 = symmetric. The examples I use and include with this package are all for asymmetric volumes. 

Note, asymmetric volumes are defined as those having different regional ID values between brain hemispheres. Symmetric volumes are defined as those having the same regional ID value for the analogous region in each hemisphere. E.g. in an asymmetric volume, the Medial Entorhinal Cortex will have two region ID values, one for the left hemisphere and one for the right hemisphere, while in a symmetric volume it will only have one region ID which will be the same across both hemispheres. 

### Workspace outputs:

1. regidtab: table showing the degree of bubbling (isolated voxel assignment) per region ID present in volume

### Saved file outputs:

1. regidtab csv: csv file with the same info as in "regidtab" above, saved to a csv file as named by the user via "outname"
2. histogram png: histogram saved as a png showing the frequency of voxel size for every connected component in the segmented volume, saved to a png file as named by the user via "outname

## Final Notes:

There are additional function code files in this package. These are all called internal to other functions, and are generally for reading various formats of 3D volumes, e.g. "read_vtk_image_v3.m" for reading vtk volumes or "nrrdread.m" for reading nrrd format volumes. Others are for writing specialized volume formats, e.g. "write_vtk_image.m" for writing vtk file outputs. These do not need to be directly called by the user.

Additionally, I have example inputs and outputs that correspond to the filenames declared in input variables to the various functions in this example version of the wrapper script. As a best practice, for a user, I recommend saving a copy of this wrapper script, appending the user's own designation, and changing input variables and playing around with the functions there. Otherwise, you will lose the utility of the original wrapper script and the included outputs as an example/standard for what to expect. 

Finally, there is a folder called "oldScripts". This contains the workspace output testing versions of the current wrapper and functions, wrapped up together, that were used to conceive and test out the functionality of this current pipeline. These can be examined by the user if desired, but are not required for use or for understanding of how to run this pipeline and can be removed from downloaded versions, if desired. I keep them to preserve a record of the process and for old file records for upload to Github. 


