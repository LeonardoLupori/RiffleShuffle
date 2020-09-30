# RiffleShuffle
A Supervised, **Symmetry-Driven**, GUI Toolkit for Mouse Brain Stack Registration and Plane Assignment

## Installation:

1. **Copy** the files of this repository to your local folder of choice. You can do this in at least two ways:
    * manually:  
    click the *download code* button in the GitHub page of this project, and download it as a .zip in your local drive.
    Then, unzip it.

    * automatically with git:  
    If you have git installed, open Git Bash and navigate to where you would like to install RiffleShuffle

            cd .../folderOfChoiche 
    
        then clone the repository to your local machine
            
            git clone https://github.com/hms-idac/RiffleShuffle

2. From MATLAB, navigate in your local folder and add it (with subfolders) to the path.

3. **All done!**. Now you can start to use the Riffle Shuffle pipeline.


## Pipeline:

    rsPreProcessing
    rsStackRegistration
    rsPlaneAssignment


## Auxiliary scripts:

    rsTrainContour
    rsTrainMask

## Instructions:

The code is designed to make use of Matlab's *code cells*,
where a cell is a section of code delimited by lines starting with '%%',
which can be executed using CTRL+Enter.


Parameters that need to be set are indicated like so:

    %\\\SET
        parameter = x;
    %///


Developed by Marcelo Cicconet & Daniel R. Hochbaum

-----
## Sample Data

Some sample data is available for demo purposes at
https://www.dropbox.com/s/wta56buh23nvz4c/RiffleShuffle.zip?dl=0

It contains 3 folders:

* **Stacks**  
    Here, subfolder Dataset_B_1.55_2.45_Downsized contains the output
    of step 1 (rsPreProcessing), which serves as input of step 2 (rsStackRegistration).
    The original data is not released due to the file size being very large.
    Furthermore, it's very likely that the user's preprocessing will be different.
    
* **SupportFiles**  
    Contains Atlas data used in rsPlaneAssignment.
    This was obtained form https://mouse.brain-map.org/

* **DataForPC**  
    Sample data for rsTrainContour and rsTrainMask.
    If the user wants to train machine learning models to generate contour likelihoods
    and slice masks for step 1 (rsPreProcessing), this data can be used in conjunction
    with rsTrainContour and rsTrainMask as a guideline.

-----
## References:

* M. Cicconet and D. R. Hochbaum.
Interactive, Symmetry Guided Registration to the Allen Mouse Brain Atlas.
BioImage Informatics 2019. Seattle, WA.

* M. Cicconet and D. R. Hochbaum.
Riffle Shuffle: A Supervised, Symmetry-Driven, GUI Toolkit for Mouse Brain Stack Registration and Plane Assignment.
bioRxiv. Sep 25 2019. https://www.biorxiv.org/content/10.1101/781880v1

-----

For questions, contact marcelo_cicconet [at] hms [dot] harvard [dot] edu
