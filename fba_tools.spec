/*
A KBase module: fba_tools
This module contains the implementation for the primary methods in KBase for metabolic model reconstruction, gapfilling, and analysis
*/

module fba_tools {
    /*
        A binary boolean
    */
    typedef int bool;
    /*
        A string representing a Genome id.
    */
    typedef string genome_id;
    /*
        A string representing a Media id.
    */
    typedef string media_id;
    /*
        A string representing a NewModelTemplate id.
    */
    typedef string template_id;
    /*
        A string representing a FBAModel id.
    */
    typedef string fbamodel_id;
    /*
        A string representing a protein comparison id.
    */
    typedef string proteincomparison_id;
    /*
        A string representing a FBA id.
    */
    typedef string fba_id;
    /*
        A string representing a FBAPathwayAnalysis id.
    */
    typedef string fbapathwayanalysis_id;
    /*
        A string representing a FBA comparison id.
    */
    typedef string fbacomparison_id;
    /*
        A string representing a phenotype set id.
    */
    typedef string phenotypeset_id;
    /*
        A string representing a phenotype simulation id.
    */
    typedef string phenotypesim_id;
	/*
        A string representing an expression matrix id.
    */
    typedef string expseries_id;
    /*
        A string representing a metabolome matrix id.
    */
    typedef string metabolome_id;
    /*
        A string representing a reaction id.
    */
    typedef string reaction_id;
    /*
        A string representing a feature id.
    */
    typedef string feature_id;
    /*
        A string representing a compound id.
    */
    typedef string compound_id;
    /*
        A string representing a workspace name.
    */
    typedef string workspace_name;
	/* 
        The workspace ID for a FBAModel data object.
        @id ws KBaseFBA.FBAModel
    */
    typedef string ws_fbamodel_id;
    /* 
        The workspace ID for a FBA data object.
        @id ws KBaseFBA.FBA
    */
    typedef string ws_fba_id;
    /* 
        The workspace ID for a FBA data object.
        @id ws KBaseFBA.FBA
    */
    typedef string ws_fbacomparison_id;
	/* 
        The workspace ID for a phenotype set simulation object.
        @id ws KBasePhenotypes.PhenotypeSimulationSet
    */
	typedef string ws_phenotypesim_id;
	/* 
        The workspace ID for a FBA pathway analysis object
        @id ws KBaseFBA.FBAPathwayAnalysis
    */
	typedef string ws_fbapathwayanalysis_id;
	/* 
        The workspace ID for a Report object
        @id ws KBaseReport.Report
    */
	typedef string ws_report_id;
	/*
    	Reference to a Pangenome object in the workspace
    	@id ws KBaseGenomes.Pangenome
    */
    typedef string ws_pangenome_id;
    /*
    	Reference to a Proteome Comparison object in the workspace
    	@id ws GenomeComparison.ProteomeComparison
    */
    typedef string ws_proteomecomparison_id;

    typedef structure {
		genome_id genome_id;
		workspace_name genome_workspace;
		media_id media_id;
		workspace_name media_workspace;
		fbamodel_id fbamodel_output_id;
		workspace_name workspace;
		template_id template_id;
		workspace_name template_workspace;
		bool coremodel;
		bool gapfill_model;
		bool thermodynamic_constraints;
		bool comprehensive_gapfill;
		
		list<string> custom_bound_list;
		list<compound_id> media_supplement_list;
		
		expseries_id expseries_id;
		workspace_name expseries_workspace;
		string expression_condition;
		float exp_threshold_percentile;
		float exp_threshold_margin;
		float activation_coefficient;
		float omega;
		float objective_fraction;
		float minimum_target_flux;
		int number_of_solutions;
    } BuildMetabolicModelParams;
    
    typedef structure {
        ws_fbamodel_id new_fbamodel_ref;
        ws_fba_id new_fba_ref;
        int number_gapfilled_reactions;
        int number_removed_biomass_compounds;
    } BuildMetabolicModelResults;
    /*
        Build a genome-scale metabolic model based on annotations in an input genome typed object
    */
    funcdef build_metabolic_model(BuildMetabolicModelParams params) returns (BuildMetabolicModelResults) authentication required;

    typedef structure {
		genome_id genome_id;
		workspace_name genome_workspace;
		fbamodel_id fbamodel_output_id;
		workspace_name workspace;
		template_id template_id;
		workspace_name template_workspace;
    } BuildPlantMetabolicModelParams;
    
    typedef structure {
        ws_fbamodel_id new_fbamodel_ref;
    } BuildPlantMetabolicModelResults;
    /*
        Build a genome-scale metabolic model based on annotations in an input genome typed object
    */
    funcdef build_plant_metabolic_model(BuildPlantMetabolicModelParams params) returns (BuildPlantMetabolicModelResults) authentication required;
        
    typedef structure {
		list<genome_id> genome_ids;
		string genome_text;
		workspace_name genome_workspace;
		media_id media_id;
		workspace_name media_workspace;
		fbamodel_id fbamodel_output_id;
		workspace_name workspace;
		template_id template_id;
		workspace_name template_workspace;
		bool coremodel;
		bool gapfill_model;
		bool thermodynamic_constraints;
		bool comprehensive_gapfill;
		
		list<string> custom_bound_list;
		list<compound_id> media_supplement_list;
		
		expseries_id expseries_id;
		workspace_name expseries_workspace;
		string expression_condition;
		float exp_threshold_percentile;
		float exp_threshold_margin;
		float activation_coefficient;
		float omega;
		float objective_fraction;
		float minimum_target_flux;
		int number_of_solutions;
    } BuildMultipleMetabolicModelsParams;
    
    typedef structure {
        ws_fbamodel_id new_fbamodel_ref;
        ws_fba_id new_fba_ref;
    } BuildMultipleMetabolicModelsResults;
    
    /*
        Build multiple genome-scale metabolic models based on annotations in an input genome typed object
    */
    funcdef build_multiple_metabolic_models(BuildMultipleMetabolicModelsParams params) returns (BuildMultipleMetabolicModelsResults) authentication required;
    
    typedef structure {
		fbamodel_id fbamodel_id;
		workspace_name fbamodel_workspace;
		media_id media_id;
		workspace_name media_workspace;
		reaction_id target_reaction;
		fbamodel_id fbamodel_output_id;
		workspace_name workspace;
		bool thermodynamic_constraints;
		bool comprehensive_gapfill;
		fbamodel_id source_fbamodel_id;
		workspace_name source_fbamodel_workspace;
		
		list<feature_id> feature_ko_list;
		list<reaction_id> reaction_ko_list;
		list<string> custom_bound_list;
		list<compound_id> media_supplement_list;
		
		expseries_id expseries_id;
		workspace_name expseries_workspace;
		string expression_condition;
		float exp_threshold_percentile;
		float exp_threshold_margin;
		float activation_coefficient;
		float omega;
		float objective_fraction;
		float minimum_target_flux;
		int number_of_solutions;
    } GapfillMetabolicModelParams;
    
    typedef structure {
        ws_fbamodel_id new_fbamodel_ref;
        ws_fba_id new_fba_ref;
        int number_gapfilled_reactions;
        int number_removed_biomass_compounds;
    } GapfillMetabolicModelResults;
    /*
        Gapfills a metabolic model to induce flux in a specified reaction
    */
    funcdef gapfill_metabolic_model(GapfillMetabolicModelParams params) returns (GapfillMetabolicModelResults results) authentication required;
    
    typedef structure {
		fbamodel_id fbamodel_id;
		workspace_name fbamodel_workspace;
		media_id media_id;
		workspace_name media_workspace;
		reaction_id target_reaction;
		fba_id fba_output_id;
		workspace_name workspace;
		
		bool thermodynamic_constraints;
		bool fva;
		bool minimize_flux;
		bool simulate_ko;
		bool find_min_media;
		bool all_reversible;
		
		list<feature_id> feature_ko_list;
		list<reaction_id> reaction_ko_list;
		list<string> custom_bound_list;
		list<compound_id> media_supplement_list;
		
		expseries_id expseries_id;
		workspace_name expseries_workspace;
		string expression_condition;
		float exp_threshold_percentile;
		float exp_threshold_margin;
		float activation_coefficient;
		float omega;
		float objective_fraction;
		
		float max_c_uptake;
		float max_n_uptake;
		float max_p_uptake;
		float max_s_uptake;
		float max_o_uptake;
		float default_max_uptake;
		
		string notes;
		string massbalance;
    } RunFluxBalanceAnalysisParams;
    
    typedef structure {
        ws_fba_id new_fba_ref;
        int objective;
        string report_name;
		ws_report_id report_ref;
    } RunFluxBalanceAnalysisResults;
    /*
        Run flux balance analysis and return ID of FBA object with results 
    */
    funcdef run_flux_balance_analysis(RunFluxBalanceAnalysisParams params) returns (RunFluxBalanceAnalysisResults results) authentication required;
 
    typedef structure {
		list<fba_id> fba_id_list;
		workspace_name fba_workspace;
		fbacomparison_id fbacomparison_output_id;
		workspace_name workspace;
    } CompareFBASolutionsParams;
    
    typedef structure {
        ws_fbacomparison_id new_fbacomparison_ref;
    } CompareFBASolutionsResults;
    /*
        Compares multiple FBA solutions and saves comparison as a new object in the workspace
    */
    funcdef compare_fba_solutions(CompareFBASolutionsParams params) returns (CompareFBASolutionsResults results) authentication required;
	
	typedef structure {
		fbamodel_id fbamodel_id;
		workspace_name fbamodel_workspace;
		proteincomparison_id proteincomparison_id;
		workspace_name proteincomparison_workspace;
		fbamodel_id fbamodel_output_id;
		workspace_name workspace;
		bool keep_nogene_rxn;
		bool gapfill_model;
		media_id media_id;
		workspace_name media_workspace;
		
		bool thermodynamic_constraints;
		bool comprehensive_gapfill;
		
		list<string> custom_bound_list;
		list<compound_id> media_supplement_list;
		
		expseries_id expseries_id;
		workspace_name expseries_workspace;
		string expression_condition;
		string translation_policy;
		float exp_threshold_percentile;
		float exp_threshold_margin;
		float activation_coefficient;
		float omega;
		float objective_fraction;
		float minimum_target_flux;
		int number_of_solutions;
    } PropagateModelToNewGenomeParams;
    
    typedef structure {
        ws_fbamodel_id new_fbamodel_ref;
        ws_fba_id new_fba_ref;
        int number_gapfilled_reactions;
        int number_removed_biomass_compounds;
    } PropagateModelToNewGenomeResults;
	/*
        Translate the metabolic model of one organism to another, using a mapping of similar proteins between their genomes
    */
	funcdef propagate_model_to_new_genome(PropagateModelToNewGenomeParams params) returns (PropagateModelToNewGenomeResults results) authentication required;
	
	typedef structure {
		fbamodel_id fbamodel_id;
		workspace_name fbamodel_workspace;
		phenotypeset_id phenotypeset_id;
		workspace_name phenotypeset_workspace;
		phenotypesim_id phenotypesim_output_id;
		workspace_name workspace;
		bool all_reversible;
		bool gapfill_phenotypes;
		bool fit_phenotype_data;
		bool save_fluxes;
		bool add_all_transporters;
		bool add_positive_transporters;
		reaction_id target_reaction;
		list<feature_id> feature_ko_list;
		list<reaction_id> reaction_ko_list;
		list<string> custom_bound_list;
		list<compound_id> media_supplement_list;
    } SimulateGrowthOnPhenotypeDataParams;
    
    typedef structure {
        ws_phenotypesim_id new_phenotypesim_ref;
    } SimulateGrowthOnPhenotypeDataResults;	
	/*
         Use Flux Balance Analysis (FBA) to simulate multiple growth phenotypes.
    */
	funcdef simulate_growth_on_phenotype_data(SimulateGrowthOnPhenotypeDataParams params) returns (SimulateGrowthOnPhenotypeDataResults results) authentication required;
	
	typedef structure {
		list<fbamodel_id> fbamodel_id_list;
		workspace_name fbamodel_workspace;
		fbamodel_id fbamodel_output_id;
		workspace_name workspace;
		bool mixed_bag_model;
    } MergeMetabolicModelsIntoCommunityModelParams;
    
    typedef structure {
        ws_fbamodel_id new_fbamodel_ref;
    } MergeMetabolicModelsIntoCommunityModelResults;
    /*
         Merge two or more metabolic models into a compartmentalized community model
    */
	funcdef merge_metabolic_models_into_community_model(MergeMetabolicModelsIntoCommunityModelParams params) returns (MergeMetabolicModelsIntoCommunityModelResults results) authentication required;

	typedef structure {
		fba_id fba_id;
		workspace_name fba_workspace;
		workspace_name workspace;
    } ViewFluxNetworkParams;
    
    typedef structure {
        ws_report_id new_report_ref;
    } ViewFluxNetworkResults;
    /*
         Merge two or more metabolic models into a compartmentalized community model
    */
	funcdef view_flux_network(ViewFluxNetworkParams params) returns (ViewFluxNetworkResults results) authentication required;
	
	typedef structure {
		fba_id fba_id;
		workspace_name fba_workspace;
		expseries_id expseries_id;
		workspace_name expseries_workspace;
		string expression_condition;
		float exp_threshold_percentile;
		bool estimate_threshold;
		bool maximize_agreement;
		fbapathwayanalysis_id fbapathwayanalysis_output_id;
		workspace_name workspace;
    } CompareFluxWithExpressionParams;
    
    typedef structure {
        ws_fbapathwayanalysis_id new_fbapathwayanalysis_ref;
    } CompareFluxWithExpressionResults;
    /*
         Merge two or more metabolic models into a compartmentalized community model
    */
	funcdef compare_flux_with_expression(CompareFluxWithExpressionParams params) returns (CompareFluxWithExpressionResults results) authentication required;

	typedef structure {
		fbamodel_id fbamodel_id;
		workspace_name fbamodel_workspace;
		workspace_name workspace;
    } CheckModelMassBalanceParams;
    
    typedef structure {
        ws_report_id new_report_ref;
    } CheckModelMassBalanceResults;
    /*
         Identifies reactions in the model that are not mass balanced
    */
	funcdef check_model_mass_balance(CheckModelMassBalanceParams params) returns (CheckModelMassBalanceResults results) authentication required;
	
	typedef structure {
		list<genome_id> genome_ids;
		workspace_name genome_workspace;
		workspace_name workspace;
    } PredictAuxotrophyParams;
    
    typedef structure {
        ws_report_id new_report_ref;
    } PredictAuxotrophyResults;
    /*
         Identifies reactions in the model that are not mass balanced
    */
	funcdef predict_auxotrophy(PredictAuxotrophyParams params) returns (PredictAuxotrophyResults results) authentication required;
	
	typedef structure {
       fbamodel_id fbamodel_id;
		workspace_name fbamodel_workspace;
		media_id media_id;
		workspace_name media_workspace;
		list<compound_id> target_metabolite_list;
		list<compound_id> source_metabolite_list;
		fba_id fba_output_id;
		workspace_name workspace;
		
		bool thermodynamic_constraints;
		
		list<feature_id> feature_ko_list;
		list<reaction_id> reaction_ko_list;
		
		expseries_id expseries_id;
		workspace_name expseries_workspace;
		string expression_condition;
		float exp_threshold_percentile;
		float exp_threshold_margin;
		float activation_coefficient;
		float omega;
    } PredictMetaboliteBiosynthesisPathwayInput;
    
    typedef structure {
        string report_name;
		ws_report_id report_ref;
    } PredictMetaboliteBiosynthesisPathwayResults;
    /*
         Identifies reactions in the model that are not mass balanced
    */
	funcdef predict_metabolite_biosynthesis_pathway(PredictMetaboliteBiosynthesisPathwayInput params) returns (PredictMetaboliteBiosynthesisPathwayResults results) authentication required;

	typedef structure {
		string input_ref;
		workspace_name input_workspace;
		media_id media_id;
		workspace_name media_workspace;
		fbamodel_id fbamodel_output_id;
		workspace_name workspace;
		bool gapfill_model;
    } BuildMetagenomeMetabolicModelParams;
    
    /*
        Build a genome-scale metabolic model based on annotations in an input genome typed object
    */
    funcdef build_metagenome_metabolic_model(BuildMetagenomeMetabolicModelParams params) returns (BuildMetabolicModelResults) authentication required;

	typedef structure {
		fbamodel_id fbamodel_id;
		workspace_name fbamodel_workspace;
		fbamodel_id source_fbamodel_id;
		workspace_name source_fbamodel_workspace;
		media_id media_id;
		workspace_name media_workspace;
		metabolome_id metabolome_id;
		workspace_name metabolome_workspace;
		string metabolome_condition;
		fbamodel_id fbamodel_output_id;
		workspace_name workspace;
		
		float minimum_target_flux;
		bool omnidirectional;
		reaction_id target_reaction;
		
		list<feature_id> feature_ko_list;
		list<reaction_id> reaction_ko_list;
		list<compound_id> media_supplement_list;
    } FitExometaboliteDataParams;
    
    typedef structure {
        ws_fbamodel_id new_fbamodel_ref;
        ws_fba_id new_fba_ref;
        int number_gapfilled_reactions;
    } FitExometaboliteDataResults;
    /*
        Gapfills a metabolic model to fit input exometabolite data
    */
    funcdef fit_exometabolite_data(FitExometaboliteDataParams params) returns (FitExometaboliteDataResults results) authentication required;

    /*
    ModelComparisonParams object: a list of models and optional pangenome and protein comparison; mc_name is the name for the new object.

    @optional protcomp_ref pangenome_ref
    */
    typedef structure {
		workspace_name workspace;
		string mc_name;
		list<ws_fbamodel_id> model_refs;
		ws_proteomecomparison_id protcomp_ref;
		ws_pangenome_id pangenome_ref;
    } ModelComparisonParams;
    
    typedef structure {
		string report_name;
		ws_report_id report_ref;
		string mc_ref;
    } ModelComparisonResult;

    /*
    Compare models
    */
    funcdef compare_models(ModelComparisonParams params) returns (ModelComparisonResult) authentication required;

	/*
    EditMetabolicModelParams object: arguments for the edit model function
    */
    typedef structure {
		workspace_name workspace;
		workspace_name fbamodel_workspace;
		ws_fbamodel_id fbamodel_id;
		ws_fbamodel_id fbamodel_output_id;
		list<mapping<string, string>> compounds_to_add;
		list<mapping<string, string>> compounds_to_change;
		list<mapping<string, string>> biomasses_to_add;
		list<mapping<string, string>> biomass_compounds_to_change;
		list<mapping<string, string>> reactions_to_remove;
		list<mapping<string, string>> reactions_to_change;
		list<mapping<string, string>> reactions_to_add;
		list<mapping<string, string>> edit_compound_stoichiometry;
    } EditMetabolicModelParams;
    
    typedef structure {
		string report_name;
		ws_report_id report_ref;
		ws_fbamodel_id new_fbamodel_ref;
    } EditMetabolicModelResult;

    /*
    Edit models
    */
    funcdef edit_metabolic_model(EditMetabolicModelParams params) returns (EditMetabolicModelResult) authentication required;

	/*
    EditMediaParams object: arguments for the edit model function
    */
    typedef structure {
		workspace_name workspace;
		media_id media_id;
		workspace_name media_workspace;
		list<compound_id> compounds_to_remove;
		list<tuple<compound_id,float concentration,float min_flux,float max_flux>> compounds_to_change;
		list<tuple<compound_id,float concentration,float min_flux,float max_flux>> compounds_to_add;
		string pH_data;
		float temperature;
		bool isDefined;
		string type;
		media_id media_output_id;
    } EditMediaParams;
    
    typedef structure {
		string report_name;
		ws_report_id report_ref;
		media_id new_media_id;
    } EditMediaResult;

    /*
    Edit models
    */
    funcdef edit_media(EditMediaParams params) returns (EditMediaResult) authentication required;

	/* A boolean - 0 for false, 1 for true.
       @range (0, 1)
    */
    typedef int boolean;

    typedef structure {
        string path;
        string shock_id;
    } File;

    typedef structure {
        string ref;
    } WorkspaceRef;


    /*  input and output structure functions for standard downloaders */
    typedef structure {
        string input_ref;
    } ExportParams;

    typedef structure {
        string shock_id;
    } ExportOutput;


    /****** FBA Model Converters ********/

    /* compounds_file is not used for excel file creations */
    typedef structure {
        File model_file;

        string model_name;
        string workspace_name;

        string genome;
        list <string> biomass;
        File compounds_file;

    } ModelCreationParams;

    funcdef excel_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;
    funcdef sbml_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;
    funcdef tsv_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;


    typedef structure {
        string workspace_name;
        string model_name;
        boolean save_to_shock;
        bool fulldb;
    } ModelObjectSelectionParams;

    funcdef model_to_excel_file(ModelObjectSelectionParams model) returns(File f) authentication required;
    funcdef model_to_sbml_file(ModelObjectSelectionParams model) returns(File f) authentication required;

    typedef structure {
        File compounds_file;
        File reactions_file;
    } ModelTsvFiles;
    funcdef model_to_tsv_file(ModelObjectSelectionParams model) returns(ModelTsvFiles files) authentication required;

    funcdef export_model_as_excel_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_model_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_model_as_sbml_file(ExportParams params) returns (ExportOutput output) authentication required;



    /******* FBA Result Converters *******/

    typedef structure {
        string workspace_name;
        string fba_name;
        boolean save_to_shock;
    } FBAObjectSelectionParams;

    funcdef fba_to_excel_file(FBAObjectSelectionParams fba) returns(File f) authentication required;

    typedef structure {
        File compounds_file;
        File reactions_file;
    } FBATsvFiles;
    funcdef fba_to_tsv_file(FBAObjectSelectionParams fba) returns(FBATsvFiles files) authentication required;

    funcdef export_fba_as_excel_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_fba_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
   

    /******* Media Converters **********/

    typedef structure {
        File media_file;
        string media_name;
        string workspace_name;
    } MediaCreationParams;

    funcdef tsv_file_to_media(MediaCreationParams p) returns(WorkspaceRef) authentication required;
    funcdef excel_file_to_media(MediaCreationParams p) returns(WorkspaceRef) authentication required;


    typedef structure {
        string workspace_name;
        string media_name;
        boolean save_to_shock;
    } MediaObjectSelectionParams;

    funcdef media_to_tsv_file(MediaObjectSelectionParams media) returns(File f) authentication required;
    funcdef media_to_excel_file(MediaObjectSelectionParams media) returns(File f) authentication required;

    funcdef export_media_as_excel_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_media_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
   

    /******* Phenotype Data Converters ********/

    typedef structure {
        File phenotype_set_file;
        string phenotype_set_name;
        string workspace_name;
        string genome;
    } PhenotypeSetCreationParams;

    funcdef tsv_file_to_phenotype_set(PhenotypeSetCreationParams p) returns (WorkspaceRef) authentication required;

    typedef structure {
        string workspace_name;
        string phenotype_set_name;
        boolean save_to_shock;
    } PhenotypeSetObjectSelectionParams;

    funcdef phenotype_set_to_tsv_file(PhenotypeSetObjectSelectionParams phenotype_set) returns (File f) authentication required;

    funcdef export_phenotype_set_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
    

    typedef structure {
        string workspace_name;
        string phenotype_simulation_set_name;
        boolean save_to_shock;
    } PhenotypeSimulationSetObjectSelectionParams;

    funcdef phenotype_simulation_set_to_excel_file(PhenotypeSimulationSetObjectSelectionParams pss) returns (File f) authentication required;
    funcdef phenotype_simulation_set_to_tsv_file(PhenotypeSimulationSetObjectSelectionParams pss) returns (File f) authentication required;

    funcdef export_phenotype_simulation_set_as_excel_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_phenotype_simulation_set_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
    
	typedef structure {
        list<string> refs;
        bool all_models;
        bool all_fba;
        bool all_media;
        bool all_phenotypes;
        bool all_phenosims;
        string model_format;
        string fba_format;
        string media_format;
        string phenotype_format;
        string phenosim_format;
        string workspace;
        string report_workspace;
    } BulkExportObjectsParams;
    
    typedef structure {
		string report_name;
		ws_report_id report_ref;
		string ref;
    } BulkExportObjectsResult;
    
    funcdef bulk_export_objects(BulkExportObjectsParams params) returns (BulkExportObjectsResult output) authentication required;
    
};