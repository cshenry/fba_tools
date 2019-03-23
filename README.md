[![Build Status](https://travis-ci.org/cshenry/fba_tools.svg?branch=master)](https://travis-ci.org/cshenry/fba_tools)

# fba_tools

## OVERVIEW
-----------------------------------------
This SDK Module contains methods relating to the reconstruction and analysis of
metabolic models in KBase. Check out the [Developer Guide](developer_guide.md)
for an overview on the module structure and help getting started. 

## Release notes
------------------------------------------
### VERSION: 1.7.8 (Released 10/16/2018)
------------------------------------------
#### UPDATED FEATURES
- improving the model reconstruction pipeline to prevent the overproduction of ATP by draft metabolic models
------------------------------------------
### VERSION: 1.7.7 (Released 10/15/2018)
------------------------------------------
- added KBase paper citation in PLOS format to utilities, added citations to Gapfill Metabolic Model, and created RELEASE_NOTES.md file 
------------------------------------------
### VERSION: 1.7.6 (Released 9/28/2018)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Refinements to auxotrophy method
- Patch for _check_job failures
- Make sure GAAPI does not provide CDSs in feature list
- Fixes for media importer
- Correcting unit scale in SBML export
- Update app citations

------------------------------------------
### VERSION: 1.7.4 (Released 3/2/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Refinements to auxotrophy method
- Fix Propagate Model with full genome refs
- Fix GC content calculation for community models
- Phenotype simulation will not fail if gapfilling is unsuccessful

------------------------------------------
### VERSION: 1.7.3 (Released 1/12/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Fixed PUBLIC-290 check mass balance report name
- Switched to use of genome apis for compatibility with new object types (SCT-932)
- Switched to resolved refs (#/#/#) for input objects
- Ensured all compound information is copied into community models
- Correct faulty reference for custom media compounds
- Auxotropy local method

------------------------------------------
### VERSION: 1.7.2 (Released 1/2/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Hotfix: remove link which was breaking UI for propagate models app

------------------------------------------
### VERSION: 1.7.1 (Released 12/19/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Fixed PUBLIC-256 build multiple metabolic saving to same name
- Fixed metabolic model upload for compounds with dashes and spaces
- Fixed Gapfilling drops compounds from biomass to grow

------------------------------------------
### VERSION: 1.7.0 (Released 10/20/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Added View Flux Network app which visualises a FBA solution in an interactive
 diagram
- Removed View FBA Expression Comparison app which is no longer needed due to
 the report from Compare FLux with Expression App
- Refactored all apps to accept IDs as permanent numerical references (eg. 133/124/1)
 and updated tests & UI accordingly
- Use reference chains to ensure that a model does not become uneditable if
 its genome is inaccessible.
- Updated table parseing to accept '\r' line delimination and error if uploaded
 phenotype set is empty
- Updated SBML parsing to address compound duplication bug and prefix all
 ids in SBML export to be compliant with SBML schema.
- Update Edit Media and Edit Model UI to ensure that users provide all needed
 parameters when loading a new compound
 
------------------------------------------
### VERSION: 1.6.7 (Released 9/19/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Added the ability to specify custom bounds on additional compounds and 
reactions in a phenotype set
- Model download now includes many additional information types like 
thermodynamics, pathways and chemical structure
- Flux information from phenotype sets are retained for inspection
- Fixed duplicate compartments in propagate model
- Fixed Genome ID not being updated for propagate model

------------------------------------------
### VERSION: 1.6.6 (Released 9/6/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Corrected bugs in media editing and SBML model upload
- Adding internal functional support for batch FBA (no UI yet)
- Inchikey and SMILES may be uploaded to models

------------------------------------------
### VERSION: 1.6.5 (Released 8/23/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
- Makes TSV & Excel importers case insensitive
- Clarified media parameter on Build and Gapfill Metabolic Model
- Updated compare metabolic model to accept model references(not names)
- Updated build multiple metabolic models to accept model references(not names)
- Allowing different solvers to be passed into FBA object
- Adding sink to activate Biotin biosynthesis in SBML export
- Allowing gapfilled compartmentalized reactions to be added to model
- Fixing issue with genome client in KBase
- Supporting generic media
- Update Travis file

------------------------------------------
### VERSION: 1.6.3 (Released 6/12/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
-Fixing R_ bug in model import

------------------------------------------
### VERSION: 1.6.1 (Released 6/12/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
-Updated service to support new authentication procedure
-Added batch version of model reconstruction 

------------------------------------------
### VERSION: 1.5.1 (Released 2/24/2017)
------------------------------------------
#### UPDATED FEATURES / MAJOR BUG FIXES:
-Fixing minor bug in SBML exporter

------------------------------------------
### VERSION: 1.5.0 (Released 2/3/2017)
------------------------------------------
#### NEW FEATURES:
-New model editor
-New media editor
-New bulk export tool

#### UPDATED FEATURES / MAJOR BUG FIXES:
-Improved reports generated by most methods
-Moved all upload and download code for model objects into this repository
-Fixed model comparison tool

------------------------------------------
### VERSION: 1.0.0 (Released 4/21/2016)
------------------------------------------
#### NEW FEATURES:
-Ability to gapfill a model on all phenotype conditions either cumulatively or iteratively

#### UPDATED FEATURES / MAJOR BUG FIXES:
-Fixed a bug in the numbering of gapfill solution objects when a model is consecutively gapfilled multiple times

#### ANTICIPATED FUTURE DEVELOPMENTS:
-Integration of probabilistic gapfilling
-Improved multiple-model comparison
-Improved model and media editors
-Improved error handling in methods
-Support for large-scale analysis of many models, media, or genomes at once

### VERSION: 0.0.2 (Released 3/4/2016)
------------------------------------------
This was the initial public release of the modeling tools as an SDK module. For release notes before this time, see https://github.com/kbase/KBaseFBAModeling.
