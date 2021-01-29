/*
@author chenry
*/
module KBaseFBA {
    typedef int bool;
    /*
		Reference to a compound object
		@id subws KBaseBiochem.Biochemistry.compounds.[*].id
	*/
    typedef string compound_ref;
    /*
		Reference to a mapping object
		@id ws KBaseOntology.Mapping
	*/
    typedef string mapping_ref;
    /*
		Reference to a classifier object
		@id ws KBaseFBA.Classifier
	*/
    typedef string Classifier_ref;
    /*
		Reference to a training set object
		@id ws KBaseFBA.ClassifierTrainingSet
	*/
    typedef string Trainingset_ref;
    /*
		Reference to a biochemistry object
		@id ws KBaseBiochem.Biochemistry
	*/
    typedef string Biochemistry_ref;
    /*
		Template biomass ID
		@id external
	*/
    typedef string templatebiomass_id;
    /*
		Template biomass compound ID
		@id external
	*/
    typedef string templatebiomasscomponent_id;
	/*
		Template reaction ID
		@id external
	*/
    typedef string templatereaction_id;
    /*
		ModelTemplate ID
		@id kb
	*/
    typedef string modeltemplate_id;
    /*
		Reference to a model template
		@id ws KBaseBiochem.Media
	*/
    typedef string media_ref;
    /*
		Reference to a model template
		@id ws KBaseBiochem.MediaSet
	*/
    typedef string mediaset_ref;
    /*
		Reference to a model template
		@id ws KBaseGenomes.Genome KBaseGenomeAnnotations.GenomeAnnotation
	*/
    typedef string genome_ref;
    /*
		Reference to a model template
		@id ws KBaseFBA.ReactionProbabilities
	*/
    typedef string rxnprob_ref;
    /*
		Reference to a Pangenome object in the workspace
		@id ws KBaseGenomes.Pangenome
    */
    typedef string pangenome_ref;
    /*
    	Reference to a Proteome Comparison object in the workspace
    	@id ws GenomeComparison.ProteomeComparison
    */
    typedef string protcomp_ref;
    /*
		Reference to a model template
	*/
    typedef string template_ref;
    /*
		Reference to an OTU in a metagenome
		@id subws KBaseGenomes.MetagenomeAnnotation.otus.[*].id
	*/
    typedef string metagenome_otu_ref;
    /*
		Reference to a metagenome object
		@id ws KBaseGenomes.MetagenomeAnnotation KBaseMetagenomes.AnnotatedMetagenomeAssembly
	*/
    typedef string metagenome_ref;
    /*
		Reference to a feature of a genome object
		@id subws KBaseGenomes.Genome.features.[*].id
	*/
    typedef string feature_ref;
	/*
		Reference to a gapgen object
		@id ws KBaseFBA.Gapgeneration
	*/
    typedef string gapgen_ref;
    /*
		Reference to a FBA object
		@id ws KBaseFBA.FBA
	*/
    typedef string fba_ref;
	/*
		Reference to a gapfilling object
		@id ws KBaseFBA.Gapfilling
	*/
    typedef string gapfill_ref;
	/*
		Reference to a complex object
		@id subws KBaseOntology.Mapping.complexes.[*].id
	*/
    typedef string complex_ref;
	/*
		Reference to a reaction object in a biochemistry
		@id subws KBaseBiochem.Biochemistry.reactions.[*].id
	*/
    typedef string reaction_ref;
    /*
		Reference to a reaction object in a model
		@id subws KBaseFBA.FBAModel.modelreactions.[*].id
	*/
    typedef string modelreaction_ref;
    /*
		Reference to a biomass object in a model
		@id subws KBaseFBA.FBAModel.biomasses.[*].id
	*/
    typedef string biomass_ref;
	/*
		Reference to a compartment object in a model
		@id subws KBaseFBA.FBAModel.modelcompartments.[*].id
	*/
    typedef string modelcompartment_ref;
	/*
		Reference to a compartment object
		@id subws KBaseBiochem.Biochemistry.compartments.[*].id
	*/
    typedef string compartment_ref;
	/*
		Reference to a compound object in a model
		@id subws KBaseFBA.FBAModel.modelcompounds.[*].id
	*/
    typedef string modelcompound_ref;
    /*
		Reference to regulatory model
		@id ws KBaseRegulation.RegModel
	*/
    typedef string regmodel_ref;
    /*
		Reference to regulome
		@id ws KBaseRegulation.Regulome
	*/
    typedef string regulome_ref;
    /*
		Reference to PROM constraints
		@id ws KBaseFBA.PromConstraint
	*/
    typedef string promconstraint_ref;
    /*
		Reference to expression data
		@id ws KBaseExpression.ExpressionSeries
	*/
    typedef string expression_series_ref;
    /*
		Reference to expression data
		@id ws KBaseFeatureValues.ExpressionMatrix
	*/
    typedef string expression_matrix_ref;
    /*
		Reference to expression data
		@id ws KBaseExpression.ExpressionSample
	*/
    typedef string expression_sample_ref;
    /*
		Reference to probabilistic annotation
		@id ws KBaseProbabilisticAnnotation.ProbAnno
	*/
    typedef string probanno_ref;
    /*
		Reference to a phenotype set object
		@id ws KBasePhenotypes.PhenotypeSet
	*/
    typedef string phenotypeset_ref;
    /*
		Reference to a phenotype simulation set object
		@id ws KBasePhenotypes.PhenotypeSimulationSet
	*/
    typedef string phenotypesimulationset_ref;
    /*
		Reference to metabolic model
		@id ws KBaseFBA.FBAModel
	*/
    typedef string fbamodel_ref;
	/*
		KBase genome ID
		@id kb
	*/
    typedef string genome_id;
    /*
		KBase FBA ID
		@id kb
	*/
    typedef string fba_id;
    /*
		Biomass reaction ID
		@id external
	*/
    typedef string biomass_id;
    /*
		Gapgeneration solution ID
		@id external
	*/
    typedef string gapgensol_id;
    /*
		Model compartment ID
		@id external
	*/
    typedef string modelcompartment_id;
    /*
		Model compound ID
		@id external
	*/
    typedef string modelcompound_id;
    /*
		Model reaction ID
		@id external
	*/
    typedef string modelreaction_id;
    /*
    	Reaction ID
    	@id external
    */
    typedef string reaction_id;
    /*
		Genome feature ID
		@id external
	*/
    typedef string feature_id;
    /*
    	Feature family ID
    	@id external
    */
    typedef string family_id;
    /*
		Source ID
		@id external
	*/
    typedef string source_id;
    /*
		Gapgen ID
		@id kb
	*/
    typedef string gapgen_id;
	/*
		Gapfill ID
		@id kb
	*/
    typedef string gapfill_id;
    /*
		Gapfill solution ID
		@id external
	*/
    typedef string gapfillsol_id;
    /*
		FBAModel ID
		@id kb
	*/
    typedef string fbamodel_id;
    /* 
    	BiomassCompound object
    	
		@searchable ws_subset modelcompound_ref coefficient
		@optional gapfill_data
    */
    typedef structure {
		modelcompound_ref modelcompound_ref;
		float coefficient;
		mapping<gapfill_id,bool integrated> gapfill_data;
    } BiomassCompound;
    
    /* 
    	Biomass object
    	
    	@optional removedcompounds
    */
    typedef structure {
		biomass_id id;
		string name;
		float other;
		float dna;
		float rna;
		float protein;
		float cellwall;
		float lipid;
		float cofactor;
		float energy;
		list<BiomassCompound> biomasscompounds;
		list<BiomassCompound> removedcompounds;
    } Biomass;

    /* 
    	ModelCompartment object
    */
    typedef structure {
		modelcompartment_id id;
		compartment_ref compartment_ref;
		int compartmentIndex;
		string label;
		float pH;
		float potential;
    } ModelCompartment;
    
    /* 
    	ModelCompound object
    	
    	@optional aliases maxuptake dblinks smiles inchikey string_attributes numerical_attributes
    */
    typedef structure {
		modelcompound_id id;
		compound_ref compound_ref;
		mapping<string,list<string>> dblinks;
		mapping<string,string> string_attributes;
		mapping<string,float> numerical_attributes;
		list<string> aliases;
		string name;
		float charge;
		float maxuptake;
		string formula;
		string smiles;
		string inchikey;
		modelcompartment_ref modelcompartment_ref;
    } ModelCompound;
    
    /* 
    	ModelReactionReagent object
    	
		@searchable ws_subset modelcompound_ref coefficient
    */
    typedef structure {
		modelcompound_ref modelcompound_ref;
		float coefficient;
    } ModelReactionReagent;
    
    /* 
    	ModelReactionProteinSubunit object
    	
		@searchable ws_subset role triggering optionalSubunit feature_refs
    */
    typedef structure {
		string role;
		bool triggering;
		bool optionalSubunit;
		string note;
		list<feature_ref> feature_refs;
    } ModelReactionProteinSubunit;
    
    /* 
    	ModelReactionProtein object
    	
    	@optional source complex_ref
    */
    typedef structure {
		complex_ref complex_ref;
		string note;
		list<ModelReactionProteinSubunit> modelReactionProteinSubunits;
		string source;
    } ModelReactionProtein;
    
    /* 
    	ModelReaction object
    	
    	@optional gapfill_data name pathway reference aliases dblinks maxforflux maxrevflux imported_gpr string_attributes numerical_attributes
    */
    typedef structure {
		modelreaction_id id;
		reaction_ref reaction_ref;
		string name;
		mapping<string,list<string>> dblinks;
		list<string> aliases;
		string pathway;
		string reference;
		string direction;
		float protons;
		float maxforflux;
		float maxrevflux;
		string imported_gpr;
		modelcompartment_ref modelcompartment_ref;
		float probability;
		list<ModelReactionReagent> modelReactionReagents;
		list<ModelReactionProtein> modelReactionProteins;
		mapping<string,string> string_attributes;
		mapping<string,float> numerical_attributes;
		mapping<string gapfill_id,mapping<int solution,tuple<string direction,bool integrated,list<ModelReactionProtein> candidateProteins>>> gapfill_data;
    } ModelReaction;

    /* 
    	ModelGapfill object
    	 
    	@optional integrated_solution
    	@optional fba_ref
    	@optional gapfill_ref jobnode
    */
    typedef structure {
		gapfill_id id;
		gapfill_id gapfill_id;
		gapfill_ref gapfill_ref;
		fba_ref fba_ref;
		bool integrated;
		string integrated_solution;
		media_ref media_ref;
		string jobnode;
    } ModelGapfill;
    
    /* 
    	ModelGapgen object
    	
    	@optional integrated_solution
    	@optional fba_ref
    	@optional gapgen_ref jobnode
    */
    typedef structure {
    	gapgen_id id;
    	gapgen_id gapgen_id;
		gapgen_ref gapgen_ref;
		fba_ref fba_ref;
		bool integrated;
		string integrated_solution;
		media_ref media_ref;
		string jobnode;
    } ModelGapgen;
    
    
    typedef structure {
    	bool integrated;
    	list<tuple<string rxnid,float maxbound,bool forward>> ReactionMaxBounds;
    	list<tuple<string cpdid,float maxbound>> UptakeMaxBounds;
    	list<tuple<string bioid,string biocpd,float modifiedcoef>> BiomassChanges; 
    	float ATPSynthase;
    	float ATPMaintenance;
    } QuantOptSolution;
    
    /* 
    	ModelQuantOpt object
    */
    typedef structure {
    	string id;
		fba_ref fba_ref;
		media_ref media_ref;
		bool integrated;
		int integrated_solution;
		list<QuantOptSolution> solutions;
    } ModelQuantOpt;
    
    typedef structure {
    	string compound_name;
    	int reactions_required;
    	int gapfilled_reactions;
    	bool is_auxotrophic;
    } AuxotrophyData;
    
    /* 
    	PathwayData
    	
    	@optional average_coverage_per_reaction stddev_coverage_per_reaction
    */
    typedef structure {
    	string id;
    	string source;
    	string name;
    	list<string> classes;
    	mapping<string id,string type> reactions;
    	int gapfilled_rxn;
    	int functional_rxn;
    	int nonfunctional_rxn;
    	int pathway_size;
    	bool is_present;
    	int gene_count;
    	float average_genes_per_reaction;
    	float stddev_genes_per_reaction;
    	float average_coverage_per_reaction;
    	float stddev_coverage_per_reaction;
    } PathwayData;
    
    typedef structure {
    	float biomass;
    	int Blocked;
    	int Negative;
    	int Positive;
    	int PositiveVariable;
		int NegativeVariable;
		int Variable;
		fba_ref fba_ref;
    } FBAAnalysis;
    
    /* 
    	PathwayData
    	
    	@optional base_rejected_reactions base_gapfilling core_gapfilling auxotrophy_gapfilling auxotroph_count base_atp initial_atp
    */
    typedef structure {
    	mapping<string pathway_id,PathwayData> pathways;
    	mapping<string compound_id,AuxotrophyData> auxotrophy;
    	mapping<string fba_name,FBAAnalysis> fbas;
    		
    	int base_rejected_reactions;
    	int base_gapfilling;
    	int core_gapfilling;
    	int auxotrophy_gapfilling;
    	int gene_count;
    	int auxotroph_count;
    	
    	float base_atp;
    	float initial_atp;
    } ComputedAttributes;
    
    /* 
    	FBAModel object
    	
    	@optional contig_coverages other_genome_refs attributes abstractreactions gapfilledcandidates metagenome_ref genome_ref template_refs ATPSynthaseStoichiometry ATPMaintenance quantopts
		@metadata ws source_id as Source ID
		@metadata ws source as Source
		@metadata ws name as Name
		@metadata ws type as Type
		@metadata ws genome_ref as Genome
		@metadata ws length(biomasses) as Number biomasses
		@metadata ws length(modelcompartments) as Number compartments
		@metadata ws length(modelcompounds) as Number compounds
		@metadata ws length(modelreactions) as Number reactions
		@metadata ws length(gapgens) as Number gapgens
		@metadata ws length(gapfillings) as Number gapfills
    */
    typedef structure {
		fbamodel_id id;
		string source;
		source_id source_id;
		string name;
		string type;
		genome_ref genome_ref;
		metagenome_ref metagenome_ref;
		
		template_ref template_ref;
		float ATPSynthaseStoichiometry;
		float ATPMaintenance;
		
		list<genome_ref> other_genome_refs;
		
		list<template_ref> template_refs;
		list<ModelGapfill> gapfillings;
		list<ModelGapgen> gapgens;
		list<ModelQuantOpt> quantopts;
		
		list<Biomass> biomasses;
		list<ModelCompartment> modelcompartments;
		list<ModelCompound> modelcompounds;
		list<ModelReaction> modelreactions;
		
		list<ModelReaction> abstractreactions;
		
		list<ModelReaction> gapfilledcandidates;
		
		ComputedAttributes attributes;
		mapping<string contigid,float coverage> contig_coverages;
    } FBAModel;
    
    /* 
    	FBAConstraint object
    */
    typedef structure {
    	string name;
    	float rhs;
    	string sign;
    	mapping<modelcompound_id,float> compound_terms;
    	mapping<modelreaction_id,float> reaction_terms;
    	mapping<biomass_id,float> biomass_terms;
	} FBAConstraint;
    
    /* 
    	FBAReactionBound object
    */
    typedef structure {
    	modelreaction_ref modelreaction_ref;
    	string variableType;
    	float upperBound;
    	float lowerBound;
	} FBAReactionBound;
    
    /* 
    	FBACompoundBound object
    */
     typedef structure {
    	modelcompound_ref modelcompound_ref;
    	string variableType;
    	float upperBound;
    	float lowerBound;
	} FBACompoundBound;
    
    /* 
    	FBACompoundVariable object
    	
    	@optional other_values other_max other_min
    	
    */
    typedef structure {
    	modelcompound_ref modelcompound_ref;
    	string variableType;
    	float upperBound;
    	float lowerBound;
    	string class;
    	float min;
    	float max;
    	float value;
    	list<float> other_values;
    	list<float> other_max;
    	list<float> other_min;
	} FBACompoundVariable;
	
	/* 
    	FBAReactionVariable object
    	
    	@optional biomass_dependencies coupled_reactions exp_state expression scaled_exp other_values other_max other_min
    	
    */
	typedef structure {
    	modelreaction_ref modelreaction_ref;
    	string variableType;
    	float upperBound;
    	float lowerBound;
    	string class;
    	float min;
    	float max;
    	float value;
		string exp_state;
		float expression;
		float scaled_exp;
		list<tuple<string biomass_id,string compound_id>> biomass_dependencies;
		list<string> coupled_reactions;
		list<float> other_values;
    	list<float> other_max;
    	list<float> other_min;
	} FBAReactionVariable;
	
	/* 
    	FBABiomassVariable object
    	
    	@optional other_values other_max other_min
    	
    */
	typedef structure {
    	biomass_ref biomass_ref;
    	string variableType;
    	float upperBound;
    	float lowerBound;
    	string class;
    	float min;
    	float max;
    	float value;
    	list<float> other_values;
    	list<float> other_max;
    	list<float> other_min;
	} FBABiomassVariable;
	
	/* 
    	FBAPromResult object
    */
	typedef structure {
    	float objectFraction;
    	float alpha;
    	float beta;
	} FBAPromResult;
    

	/*
	  Either of two values: 
	   - InactiveOn: specified as on, but turns out as inactive
	   - ActiveOff: specified as off, but turns out as active
	 */
	typedef string conflict_state;
	/*
	  FBATintleResult object	 
	*/
	typedef structure {
		float originalGrowth;
		float growth;
		float originalObjective;
		float objective;
		mapping<conflict_state,feature_id> conflicts;		    
	} FBATintleResult;

    /* 
    	FBADeletionResult object
    */
    typedef structure {
    	list<feature_ref> feature_refs;
    	float growthFraction;
	} FBADeletionResult;
	
	/* 
    	FBAMinimalMediaResult object
    */
	typedef structure {
    	list<compound_ref> essentialNutrient_refs;
    	list<compound_ref> optionalNutrient_refs;
	} FBAMinimalMediaResult;
    
    /* 
    	FBAMetaboliteProductionResult object
    */
    typedef structure {
    	modelcompound_ref modelcompound_ref;
    	float maximumProduction;
	} FBAMetaboliteProductionResult;
    
	/* 
    	FBAMinimalReactionsResult object
    */
    typedef structure {
    	string id;
    	bool suboptimal;
    	float totalcost;
    	list<modelreaction_ref> reaction_refs;
    	list<string> reaction_directions;
	} FBAMinimalReactionsResult;  
    

    typedef float probability;
    /*
      collection of tintle probability scores for each feature in a genome,
      representing a single gene probability sample
    */
    typedef structure {
	    mapping<feature_id,probability> tintle_probability;
	    string expression_sample_ref;	    
    } TintleProbabilitySample;

	
	typedef structure {
		string biomass_component;
		float mod_coefficient;
	} QuantOptBiomassMod;
	
	typedef structure {
		modelreaction_ref modelreaction_ref;
		modelcompound_ref modelcompound_ref;
		bool reaction;
		float mod_upperbound;
	} QuantOptBoundMod;
	
	typedef structure {
		float atp_synthase;
		float atp_maintenance;
		list<QuantOptBiomassMod> QuantOptBiomassMods;
		list<QuantOptBoundMod> QuantOptBoundMods;
	} QuantitativeOptimizationSolution;

	/* 
    	GapFillingReaction object holds data on a reaction added by gapfilling analysis
    	
    	@optional compartmentIndex round
    */
    typedef structure {
    	int round;
    	reaction_ref reaction_ref;
    	compartment_ref compartment_ref;
    	string direction;
    	int compartmentIndex;
    	list<feature_ref> candidateFeature_refs;
    } GapfillingReaction;
    
    /* 
    	ActivatedReaction object holds data on a reaction activated by gapfilling analysis
    	
    	@optional round
    */
    typedef structure {
    	int round;
    	modelreaction_ref modelreaction_ref;
    } ActivatedReaction;
    
    /*
    	GapFillingSolution object holds data on a solution generated by gapfilling analysis
    	
    	@optional objective gfscore actscore rejscore candscore rejectedCandidates activatedReactions failedReaction_refs
    	
    	@searchable ws_subset id suboptimal integrated solutionCost koRestore_refs biomassRemoval_refs mediaSupplement_refs
    */
    typedef structure {
    	gapfillsol_id id;
    	float solutionCost;
    	
    	list<modelcompound_ref> biomassRemoval_refs;
    	list<modelcompound_ref> mediaSupplement_refs;
    	list<modelreaction_ref> koRestore_refs;
    	bool integrated;
    	bool suboptimal;
    	
    	float objective;
    	float gfscore;
    	float actscore;
    	float rejscore;
    	float candscore;
    	
    	list<GapfillingReaction> rejectedCandidates;
    	list<modelreaction_ref> failedReaction_refs;
    	list<ActivatedReaction> activatedReactions;
    	list<GapfillingReaction> gapfillingSolutionReactions;
    } GapfillingSolution;

    /* 
    	FBA object holds the formulation and results of a flux balance analysis study
    	
    	@optional other_objectives mediaset_ref media_list_refs MFALog maximizeActiveReactions calculateReactionKnockoutSensitivity biomassRemovals ExpressionKappa ExpressionOmega ExpressionAlpha expression_matrix_ref expression_matrix_column jobnode gapfillingSolutions QuantitativeOptimizationSolutions quantitativeOptimization minimize_reactions minimize_reaction_costs FBATintleResults FBAMinimalReactionsResults PROMKappa phenotypesimulationset_ref objectiveValue phenotypeset_ref promconstraint_ref regulome_ref tintleW tintleKappa massbalance rxnprob_ref
    	@metadata ws maximizeObjective as Maximized
		@metadata ws comboDeletions as Combination deletions
		@metadata ws minimize_reactions as Minimize reactions
		@metadata ws regulome_ref as Regulome
		@metadata ws fbamodel_ref as Model
		@metadata ws promconstraint_ref as PromConstraint
		@metadata ws media_ref as Media
		@metadata ws objectiveValue as Objective
		@metadata ws expression_matrix_ref as ExpressionMatrix
		@metadata ws expression_matrix_column as ExpressionMatrixColumn
		@metadata ws length(biomassflux_objterms) as Number biomass objectives
		@metadata ws length(geneKO_refs) as Number gene KO
		@metadata ws length(reactionKO_refs) as Number reaction KO
		@metadata ws length(additionalCpd_refs) as Number additional compounds
		@metadata ws length(FBAConstraints) as Number constraints
		@metadata ws length(FBAReactionBounds) as Number reaction bounds
		@metadata ws length(FBACompoundBounds) as Number compound bounds
		@metadata ws length(FBACompoundVariables) as Number compound variables
		@metadata ws length(FBAReactionVariables) as Number reaction variables
		
    */
    typedef structure {
		fba_id id;
		bool fva;
		bool fluxMinimization;
		bool findMinimalMedia;
		bool allReversible;
		bool simpleThermoConstraints;
		bool thermodynamicConstraints;
		bool noErrorThermodynamicConstraints;
		bool minimizeErrorThermodynamicConstraints;
		bool quantitativeOptimization;
		
		bool maximizeObjective;
		mapping<modelcompound_id,float> compoundflux_objterms;
    	mapping<modelreaction_id,float> reactionflux_objterms;
		mapping<biomass_id,float> biomassflux_objterms;
		
		int comboDeletions;
		int numberOfSolutions;
		
		float objectiveConstraintFraction;
		float defaultMaxFlux;
		float defaultMaxDrainFlux;
		float defaultMinDrainFlux;
		float PROMKappa;
		float tintleW;
		float tintleKappa;
		float ExpressionAlpha;
		float ExpressionOmega;
		float ExpressionKappa;
		
		bool decomposeReversibleFlux;
		bool decomposeReversibleDrainFlux;
		bool fluxUseVariables;
		bool drainfluxUseVariables;
		bool minimize_reactions;
		bool calculateReactionKnockoutSensitivity;
		bool maximizeActiveReactions;
		
		string jobnode;
		regulome_ref regulome_ref;
		fbamodel_ref fbamodel_ref;
		rxnprob_ref rxnprob_ref;
		promconstraint_ref promconstraint_ref;
		expression_matrix_ref expression_matrix_ref;
		string expression_matrix_column;
		media_ref media_ref;
		list<media_ref> media_list_refs;
		mediaset_ref mediaset_ref;
		phenotypeset_ref phenotypeset_ref;
		list<feature_ref> geneKO_refs;
		list<modelreaction_ref> reactionKO_refs;
		list<modelcompound_ref> additionalCpd_refs;
		mapping<string,float> uptakeLimits;
		mapping<modelreaction_id,float> minimize_reaction_costs;
		string massbalance;
		
		mapping<string,string> parameters;
		mapping<string,list<string>> inputfiles;
		
		list<FBAConstraint> FBAConstraints;
		list<FBAReactionBound> FBAReactionBounds;
		list<FBACompoundBound> FBACompoundBounds;
			
		float objectiveValue;
		list<float> other_objectives;
		mapping<string,list<string>> outputfiles;
		string MFALog;
		phenotypesimulationset_ref phenotypesimulationset_ref;

		mapping<string,list<string>> biomassRemovals;

		list<FBACompoundVariable> FBACompoundVariables;
		list<FBAReactionVariable> FBAReactionVariables;
		list<FBABiomassVariable> FBABiomassVariables;
		list<FBAPromResult> FBAPromResults;
		list<FBATintleResult> FBATintleResults;
		list<FBADeletionResult> FBADeletionResults;
		list<FBAMinimalMediaResult> FBAMinimalMediaResults;
		list<FBAMetaboliteProductionResult> FBAMetaboliteProductionResults;
		list<FBAMinimalReactionsResult> FBAMinimalReactionsResults;
		list<QuantitativeOptimizationSolution> QuantitativeOptimizationSolutions;
		list<GapfillingSolution> gapfillingSolutions;
    } FBA;
    
    /* 
    	GapGenerationSolutionReaction object holds data a reaction proposed to be removed from the model
    */
    typedef structure {
    	modelreaction_ref modelreaction_ref;
    	string direction;
    } GapgenerationSolutionReaction;
    
    /* 
    	GapGenerationSolution object holds data on a solution proposed by the gapgeneration command
    */
    typedef structure {
    	gapgensol_id id;
    	float solutionCost;
    	list<modelcompound_ref> biomassSuppplement_refs;
    	list<modelcompound_ref> mediaRemoval_refs;
    	list<modelreaction_ref> additionalKO_refs;
    	bool integrated;
    	bool suboptimal;
    	list<GapgenerationSolutionReaction> gapgenSolutionReactions;
    } GapgenerationSolution;
    
    /* 
    	GapGeneration object holds data on formulation and solutions from gapgen analysis
    	
    	@optional fba_ref totalTimeLimit timePerSolution media_ref referenceMedia_ref gprHypothesis reactionRemovalHypothesis biomassHypothesis mediaHypothesis
		@metadata ws fba_ref as FBA
		@metadata ws fbamodel_ref as Model
		@metadata ws length(gapgenSolutions) as Number solutions
    */
    typedef structure {
    	gapgen_id id;
    	fba_ref fba_ref;
    	fbamodel_ref fbamodel_ref;
    	
    	bool mediaHypothesis;
    	bool biomassHypothesis;
    	bool gprHypothesis;
    	bool reactionRemovalHypothesis;
    	
    	media_ref media_ref;
    	media_ref referenceMedia_ref;
    	
    	int timePerSolution;
    	int totalTimeLimit;
    	
    	list<GapgenerationSolution> gapgenSolutions;
    } Gapgeneration;
    
    /* 
    	GapFilling object holds data on the formulations and solutions of a gapfilling analysis
    	
    	@optional simultaneousGapfill totalTimeLimit timePerSolution transporterMultiplier singleTransporterMultiplier biomassTransporterMultiplier noDeltaGMultiplier noStructureMultiplier deltaGMultiplier directionalityMultiplier drainFluxMultiplier reactionActivationBonus allowableCompartment_refs blacklistedReaction_refs targetedreaction_refs guaranteedReaction_refs completeGapfill balancedReactionsOnly reactionAdditionHypothesis gprHypothesis biomassHypothesis mediaHypothesis fba_ref media_ref rxnprob_ref
    	@metadata ws fba_ref as FBA
		@metadata ws fbamodel_ref as Model
		@metadata ws media_ref as Media
		@metadata ws length(gapfillingSolutions) as Number solutions
    
    */
    typedef structure {
    	gapfill_id id;
    	fba_ref fba_ref;
    	media_ref media_ref;
    	fbamodel_ref fbamodel_ref;
    	rxnprob_ref rxnprob_ref;
    	
    	bool mediaHypothesis;
    	bool biomassHypothesis;
    	bool gprHypothesis;
    	bool reactionAdditionHypothesis;
    	bool balancedReactionsOnly;
    	bool completeGapfill;
    	bool simultaneousGapfill;
    	
    	list<reaction_ref> guaranteedReaction_refs;
    	list<reaction_ref> targetedreaction_refs;
    	list<reaction_ref> blacklistedReaction_refs;
    	list<compartment_ref> allowableCompartment_refs;
    	
    	float reactionActivationBonus;
    	float drainFluxMultiplier;
    	float directionalityMultiplier;
    	float deltaGMultiplier;
    	float noStructureMultiplier;
    	float noDeltaGMultiplier;
    	float biomassTransporterMultiplier;
    	float singleTransporterMultiplier;
    	float transporterMultiplier;
    	
    	int timePerSolution;
    	int totalTimeLimit;
    	
    	mapping<reaction_ref,float> reactionMultipliers;
    	list<GapfillingSolution> gapfillingSolutions;
    } Gapfilling;
	
    /* 
    	TemplateBiomassComponent object holds data on a compound of biomass in template
    */
	typedef structure {
    	templatebiomasscomponent_id id;
    	string class;
    	compound_ref compound_ref;
    	compartment_ref compartment_ref;
    	
    	string coefficientType;
    	float coefficient;
    	
    	list<compound_ref> linked_compound_refs;
    	list<float> link_coefficients;
    } TemplateBiomassComponent;
    
    /* 
    	TemplateBiomass object holds data on biomass in template
    	
    	@searchable ws_subset id name type other dna rna protein lipid cellwall cofactor energy
    */
	typedef structure {
    	templatebiomass_id id;
    	string name;
    	string type;
    	float other;
    	float dna;
    	float rna;
    	float protein;
    	float lipid;
    	float cellwall;
    	float cofactor;
    	float energy;
    	list<TemplateBiomassComponent> templateBiomassComponents;
    } TemplateBiomass;
    
    /* 
    	TemplateReaction object holds data on reaction in template
    	
    	@optional base_cost forward_penalty reverse_penalty GapfillDirection
    */
	typedef structure {
    	templatereaction_id id;
    	reaction_ref reaction_ref;
    	compartment_ref compartment_ref;
    	list<complex_ref> complex_refs;
    	string direction;
    	string GapfillDirection;
    	string type;
    	float base_cost;
    	float forward_penalty;
    	float reverse_penalty;
    } TemplateReaction;
    
    /* 
    	ModelTemplate object holds data on how a model is constructed from an annotation
    	    	
    	@optional name
    	@searchable ws_subset id name modelType domain mapping_ref
    */
	typedef structure {
    	modeltemplate_id id;
    	string name;
    	string modelType;
    	string domain;
    	mapping_ref mapping_ref;
    	Biochemistry_ref biochemistry_ref;
    	
    	list<TemplateReaction> templateReactions;
    	list<TemplateBiomass> templateBiomasses;
    } ModelTemplate;
    
    /* ReactionSensitivityAnalysisCorrectedReaction object
		
		kb_sub_id kbid - KBase ID for reaction knockout corrected reaction
		ws_sub_id model_reaction_wsid - ID of model reaction
		float normalized_required_reaction_count - Normalized count of reactions required for this reaction to function
		list<ws_sub_id> required_reactions - list of reactions required for this reaction to function
		
		@optional
		
	*/
	typedef structure {
		modelreaction_ref modelreaction_ref;
		float normalized_required_reaction_count;
		list<modelreaction_id> required_reactions;
    } ReactionSensitivityAnalysisCorrectedReaction;
	
	/* Object for holding reaction knockout sensitivity reaction data
		
		kb_sub_id kbid - KBase ID for reaction knockout sensitivity reaction
		ws_sub_id model_reaction_wsid - ID of model reaction
		bool delete - indicates if reaction is to be deleted
		bool deleted - indicates if the reaction has been deleted
		float growth_fraction - Fraction of wild-type growth after knockout
		float normalized_activated_reaction_count - Normalized number of activated reactions
		list<ws_sub_id> biomass_compounds  - List of biomass compounds that depend on the reaction
		list<ws_sub_id> new_inactive_rxns - List of new reactions dependant upon reaction KO
		list<ws_sub_id> new_essentials - List of new essential genes with reaction knockout
	
		@optional direction
	*/
	typedef structure {
		string id;
		modelreaction_ref modelreaction_ref;
		float growth_fraction;
		bool delete;
		bool deleted;
		string direction;
		float normalized_activated_reaction_count;
		list<modelcompound_id> biomass_compounds;
		list<modelreaction_id> new_inactive_rxns;
		list<feature_id> new_essentials;
    } ReactionSensitivityAnalysisReaction;
	
	/* Object for holding reaction knockout sensitivity results
	
		kb_id kbid - KBase ID of reaction sensitivity object
		ws_id model_wsid - Workspace reference to associated model
		string type - type of reaction KO sensitivity object
		bool deleted_noncontributing_reactions - boolean indicating if noncontributing reactions were deleted
		bool integrated_deletions_in_model - boolean indicating if deleted reactions were implemented in the model
		list<ReactionSensitivityAnalysisReaction> reactions - list of sensitivity data for tested reactions
		list<ReactionSensitivityAnalysisCorrectedReaction> corrected_reactions - list of reactions dependant upon tested reactions
		
		@searchable ws_subset id fbamodel_ref type deleted_noncontributing_reactions integrated_deletions_in_model
		@optional	
	*/
    typedef structure {
		string id;
		fbamodel_ref fbamodel_ref;
		string type;
		bool deleted_noncontributing_reactions;
		bool integrated_deletions_in_model;
		list<ReactionSensitivityAnalysisReaction> reactions;
		list<ReactionSensitivityAnalysisCorrectedReaction> corrected_reactions;
    } ReactionSensitivityAnalysis;


    /* 
        ETCStep object
    */

    typedef structure {
        list<string> reactions;
    } ETCStep;

    /* 
        ETCPathwayObj object
    */

    typedef structure {
        string electron_acceptor;
        list<ETCStep> steps;
    } ETCPathwayObj;

    /* 
        ElectronTransportChains (ETC) object
    */
    typedef structure {
        list<ETCPathwayObj> pathways;
    } ETC;

    /*
    Object required by the prom_constraints object which defines the computed probabilities for a target gene.  The
    TF regulating this target can be deduced based on the TFtoTGmap object.
    
        string target_gene_ref           - reference to the target gene
        float probTGonGivenTFoff    - PROB(target=ON|TF=OFF)
                                    the probability that the target gene is ON, given that the
                                    transcription factor is not expressed.  Set to null or empty if
                                    this probability has not been calculated yet.
        float probTGonGivenTFon   - PROB(target=ON|TF=ON)
                                    the probability that the transcriptional target is ON, given that the
                                    transcription factor is expressed.    Set to null or empty if
                                    this probability has not been calculated yet.
    */
    typedef structure {
        string target_gene_ref;
        float probTGonGivenTFoff;
        float probTGonGivenTFon;
    } TargetGeneProbabilities;

	/*
    Object required by the prom_constraints object, this maps a transcription factor 
     to a group of regulatory target genes.
    
        string transcriptionFactor_ref                       - reference to the transcription factor
        list<TargetGeneProbabilities> targetGeneProbs        - collection of target genes for the TF
                                                                along with associated joint probabilities for each
                                                                target to be on given that the TF is on or off.
    
    */
    typedef structure {
        string transcriptionFactor_ref;
        list<TargetGeneProbabilities> targetGeneProbs;
    } TFtoTGmap;
    
    /*
    An object that encapsulates the information necessary to apply PROM-based constraints to an FBA model. This
    includes a regulatory network consisting of a set of regulatory interactions (implied by the set of TFtoTGmap
    objects) and interaction probabilities as defined in each TargetGeneProbabilities object.  A link the the annotation
    object is required in order to properly link to an FBA model object.  A reference to the expression_data_collection
    used to compute the interaction probabilities is provided for future reference.
    
        string id                                         - the id of this prom_constraints object in a
                                                                        workspace
        genome_ref									
                                                                        which specfies how TFs and targets are named
        list<TFtoTGmap> transcriptionFactorMaps                                     - the list of TFMaps which specifies both the
                                                                        regulatory network and interaction probabilities
                                                                        between TF and target genes
        expression_series_ref expression_series_ref   - the id of the expresion_data_collection object in
                                                                        the workspace which was used to compute the
                                                                        regulatory interaction probabilities
    
    */
    typedef structure {
        string id;
        genome_ref genome_ref;
        list<TFtoTGmap> transcriptionFactorMaps;
        expression_series_ref expression_series_ref;
		regulome_ref regulome_ref;
    } PromConstraint;
    
    /*
        
    */
    typedef structure {
        string id;
        string description;
        float tp_rate;
        float fb_rate;
        float precision;
        float recall;
        float f_measure;
        float ROC_area;
        mapping<string,int> missclassifications;
    } ClassifierClasses;
    
    /*
        
    */
    typedef structure {
        string id;
        string attribute_type;
        string classifier_type;
        Trainingset_ref trainingset_ref;
        string data;
        string readable;
        int correctly_classified_instances;
        int incorrectly_classified_instances;
        int total_instances;
        float kappa;
        float mean_absolute_error;
        float root_mean_squared_error;
        float relative_absolute_error;
        float relative_squared_error;
        list<ClassifierClasses> classes;
    } Classifier;
    
    typedef tuple<genome_ref genome,string class,list<string> attributes> WorkspaceGenomeClassData;
    typedef tuple<string database,string genome_id,string class,list<string> attributes> ExternalGenomeClassData;
	typedef tuple<string,string> ClassData;
    typedef tuple<genome_ref genome,string class,float probability> WorkspaceGenomeClassPrediction;
    typedef tuple<string database,string genome,string class,float probability> ExternalGenomeClassPrediction;

	    
    /*
        @optional attribute_type source description
    */
    typedef structure {
        string id;
        string description;
        string source;
        string attribute_type;
        list<WorkspaceGenomeClassData> workspace_training_set; 
		list<ExternalGenomeClassData> external_training_set;
		list<ClassData> class_data;
    } ClassifierTrainingSet;
    
    /*
    */
    typedef structure {
        string id;
        Classifier_ref classifier_ref;
        list<WorkspaceGenomeClassPrediction> workspace_genomes; 
		list<ExternalGenomeClassPrediction> external_genomes;
    } ClassifierResult;
    
    /*
	This type represents an element of a FBAModelSet.
	@optional metadata
	*/
	typedef structure {
	  mapping<string, string> metadata;
	  fbamodel_ref ref;
	} FBAModelSetElement;

	/*
		A type describing a set of FBAModels, where each element of the set 
		is an FBAModel object reference.
	*/
	typedef structure {
	  string description;
	  mapping<string, FBAModelSetElement> elements;
	} FBAModelSet;
	
	/*
		Conserved state - indicates a possible state of reaction/compound in FBA with values:
			<NOT_IN_MODEL,INACTIVE,FORWARD,REVERSE,UPTAKE,EXCRETION>
	*/
    typedef string Conserved_state; 
	
	/*
		FBAComparisonFBA object: this object holds information about an FBA in a FBA comparison
	*/
	typedef structure {
		string id;
		fba_ref fba_ref;
		fbamodel_ref fbamodel_ref;
		mapping<string fba_id,tuple<int common_reactions,int common_forward,int common_reverse,int common_inactive,int common_exchange_compounds,int common_uptake,int common_excretion,int common_inactive> > fba_similarity;
		float objective;
		media_ref media_ref;
		int reactions;
		int compounds;
		int forward_reactions;
		int reverse_reactions;
		int uptake_compounds;
		int excretion_compounds;
	} FBAComparisonFBA;

	/*
		FBAComparisonReaction object: this object holds information about a reaction across all compared models
	*/
	typedef structure {
		string id;
		string name;
		list<tuple<float coefficient,string name,string compound>> stoichiometry;
		string direction;
		mapping<Conserved_state,tuple<int count,float fraction,float flux_mean, float flux_stddev>> state_conservation;
		Conserved_state most_common_state;
		mapping<string fba_id,tuple<Conserved_state,float UpperBound,float LowerBound,float Max,float Min,float flux,float expression_score,string expression_class,string ModelReactionID>> reaction_fluxes;
	} FBAComparisonReaction;

	/*
		FBAComparisonCompound object: this object holds information about a compound across a set of FBA simulations
	*/
	typedef structure {
		string id;
		string name;
		float charge;
		string formula;
		mapping<Conserved_state,tuple<int count,float fraction,float flux_mean,float stddev>> state_conservation;
		Conserved_state most_common_state;
		mapping<string fba_id,tuple<Conserved_state,float UpperBound,float LowerBound,float Max,float Min,float Flux,string class>> exchanges;
	} FBAComparisonCompound;

	/*
		FBAComparison object: this object holds information about a comparison of multiple FBA simulations

		@metadata ws id as ID
		@metadata ws common_reactions as Common reactions
		@metadata ws common_compounds as Common compounds
		@metadata ws length(fbas) as Number FBAs
		@metadata ws length(reactions) as Number reactions
		@metadata ws length(compounds) as Number compounds
	*/
	typedef structure {
		string id;
		int common_reactions;
		int common_compounds;
		list<FBAComparisonFBA> fbas;
		list<FBAComparisonReaction> reactions;
		list<FBAComparisonCompound> compounds;
	} FBAComparison;

	/*
		SubsystemReaction object: this object holds information about individual reactions in a subsystems
	*/
	typedef structure {
		string id;
		string reaction_ref;
		list <string> roles;
		string tooltip;
	} SubsystemReaction;

	/*
		SubsystemAnnotation object: this object holds all reactions in subsystems
	*/
	typedef structure {
		string id;
		Biochemistry_ref biochemistry_ref;
		mapping_ref mapping_ref;
		mapping < string subsystem_id, list < tuple < string reaction_id, SubsystemReaction reaction_info > > > subsystems;
	} SubsystemAnnotation;

    /*
    ModelComparisonModel object: this object holds information about a model in a model comparison
    */
    typedef structure {
		string id;
		fbamodel_ref model_ref;
		genome_ref genome_ref;
		mapping<string model_id,tuple<int common_reactions,int common_compounds,int common_biomasscpds,int common_families,int common_gpr> > model_similarity; 
		string name;
		string taxonomy;
		int reactions;
		int families;
		int compounds;
		int biomasscpds;
		int biomasses;
    } ModelComparisonModel;
    
    /*
    ModelComparisonFamily object: this object holds information about a protein family across a set of models
    */
    typedef structure {
		string id;
		family_id family_id;
		string function;
		int number_models;
		float fraction_models;
		bool core;
		mapping<string model_id,tuple<bool present,list<reaction_id>>> family_model_data;
    } ModelComparisonFamily;

    /*
    ModelComparisonReaction object: this object holds information about a reaction across all compared models
    */
    typedef structure {
		string id;
		reaction_ref reaction_ref;
		string name;
		string equation;
		int number_models;
		float fraction_models;
		bool core;
		mapping<string model_id,tuple<bool present,string direction,list<tuple<feature_id,family_id,float conservation,bool missing>>,string gpr>> reaction_model_data;
    } ModelComparisonReaction;
    
    /*
    ModelComparisonCompound object: this object holds information about a compound across a set of models
    */
    typedef structure {
		string id;
		compound_ref compound_ref;
		string name;
		int number_models;
		float fraction_models;
		bool core;
		mapping<string model_id,list<tuple<compartment_ref,float charge>>> model_compound_compartments;
    } ModelComparisonCompound;
    
    /*
    ModelComparisonBiomassCompound object: this object holds information about a biomass compound across a set of models
    */
    typedef structure {
		string id;
		compound_ref compound_ref;
		string name;
		int number_models;
		float fraction_models;
		bool core;
		mapping<string model_id,list<tuple<compartment_ref,float coefficient>>> model_biomass_compounds;
    } ModelComparisonBiomassCompound;

    /*
    ModelComparisonResult object: this object holds information about a comparison of multiple models

    @optional protcomp_ref pangenome_ref
    @metadata ws core_reactions as Core reactions
    @metadata ws core_compounds as Core compounds
    @metadata ws core_families as Core families
    @metadata ws core_biomass_compounds as Core biomass compounds
    @metadata ws name as Name
    @metadata ws id as ID
    @metadata ws length(models) as Number models
    @metadata ws length(reactions) as Number reactions
    @metadata ws length(compounds) as Number compounds
    @metadata ws length(families) as Number families
    @metadata ws length(biomasscpds) as Number biomass compounds
    */
    typedef structure {
		string id;
		string name;
		int core_reactions;
		int core_compounds;
		int core_families;
		int core_biomass_compounds;
		protcomp_ref protcomp_ref;
		pangenome_ref pangenome_ref;

		list<ModelComparisonModel> models;
		list<ModelComparisonReaction> reactions;
		list<ModelComparisonCompound> compounds;
		list<ModelComparisonFamily> families;
		list<ModelComparisonBiomassCompound> biomasscpds;
    } ModelComparison;
    
    /*
		FBAPathwayAnalysis object: this object holds the analysis of FBA, expression and gapfilling data
	*/
	typedef structure {
	    string pegId;
	    float expression;
	} FBAPathwayAnalysisFeature;

	typedef structure {
	    string id;
	    string name;
	    float flux;
	    int gapfill;
	    int expressed;
	    list<FBAPathwayAnalysisFeature> pegs;
	} FBAPathwayAnalysisReaction;

	typedef structure {
        string pathwayName;
        string pathwayId;
	    int totalModelReactions;
	    int totalKEGGRxns;
	    int totalRxnFlux;
	    int gsrFluxPExpP;
	    int gsrFluxPExpN;
	    int gsrFluxMExpP;
	    int gsrFluxMExpM;
	    int gpRxnsFluxP;
        list<FBAPathwayAnalysisReaction> reaction_list;
    } FBAPathwayAnalysisPathway;

	typedef structure {
	string pathwayType;
	   expression_matrix_ref expression_matrix_ref;
	   string expression_condition;
	   fbamodel_ref fbamodel_ref;
	   fba_ref fba_ref;
	   list<FBAPathwayAnalysisPathway> pathways;
	} FBAPathwayAnalysis;
	
	typedef structure {
	    string pathwayName;
        string pathwayId;
	    int totalModelReactions;
	    int totalabsentRxns;
	    int totalKEGGRxns;
	    int totalRxnFlux;
	    int gsrFluxPExpP;
	    int gsrFluxPExpN;
	    int gsrFluxMExpP;
	    int gsrFluxMExpM;
	    int gpRxnsFluxP;
	} FBAPathwayAnalysisCounts;
	
	typedef structure {
	    expression_matrix_ref expression_matrix_ref;
		string expression_condition;
		fbamodel_ref fbamodel_ref;
		fba_ref fba_ref;
		list<FBAPathwayAnalysisCounts> count_list;
    } FBAPathwayAnalysisPathwayMultiple;
	
	typedef structure {
	    string pathwayType;
        list<FBAPathwayAnalysisPathwayMultiple> fbaexpression;
    } FBAPathwayAnalysisMultiple;
	
	/*
        A string representing a ContigSet id.
    */
    typedef string contigset_id;
    typedef string genome_name;
    /*
        A string representing a workspace name.
    */
    typedef string workspace_name;
    /* description of a role missing in the contigs */
    typedef structure {
        string reaction_id;
        string reaction_name;
    } ReactionItem;
    typedef structure {
        string role_id;
        string role_description;
        string genome_hits;
        string blast_score;
        float perc_identity;
        string hit_location;
        string protein_sequence;
        list<ReactionItem> reactions;
    } MissingRoleItem;
    /* description of a role found in the contigs */
    typedef structure {
        string role_id;
        string role_description;
    } FoundRoleItem;
    /* description of a close genome */
    typedef structure {
        genome_id id;
        int hit_count;
        genome_name name;
    } CloseGenomeItem;
    typedef structure {
        contigset_id contigset_id;
        list<MissingRoleItem> missing_roles;
        list<CloseGenomeItem> close_genomes;
        list<FoundRoleItem> found_roles;
    } MissingRoleData;
    
    /*
		Template complex ID
		@id external
	*/
    typedef string templatecomplex_id;
    /*
		Template role ID
		@id external
	*/
    typedef string templaterole_id;
    /*
		Template compartment compound ID
		@id external
	*/
    typedef string templatecompcompound_id;
    /*
		Template compartment ID
		@id external
	*/
    typedef string templatecompartment_id;
    /*
		Template compound ID
		@id external
	*/
    typedef string templatecompound_id;
    /*
		Template pathway ID
		@id external
	*/
    typedef string templatepathway_id;
    /*
		Reference to compartment in Template Model
		@id subws KBaseFBA.TemplateModel.compartments.[*].id
	*/
    typedef string templatecompartment_ref;
    /*
		Reference to compound in Template Model
		@id subws KBaseFBA.TemplateModel.compounds.[*].id
	*/
    typedef string templatecompound_ref;
    /*
		Reference to compartment compound in Template Model
		@id subws KBaseFBA.TemplateModel.compcompounds.[*].id
	*/
    typedef string templatecompcompound_ref;
    /*
		Reference to reaction in Template Model
		@id subws KBaseFBA.TemplateModel.reactions.[*].id
	*/
    typedef string templatereaction_ref;
    /*
		Reference to role in Template Model
		@id subws KBaseFBA.TemplateModel.roles.[*].id
	*/
    typedef string templaterole_ref;
    /*
		Reference to complex in Template Model
		@id subws KBaseFBA.TemplateModel.complexes.[*].id
	*/
    typedef string templatecomplex_ref;
    
    /* 
    	TemplateCompartment parallel to compartment object in biochemistry
    */
    typedef structure {
    	templatecompartment_id id;
    	string name;
    	list<string> aliases;
    	int hierarchy;
    	float pH;
    } TemplateCompartment;
    
    /* 
    	TemplateCompound parallel to compound object in biochemistry compound_ref
    	
    	@optional compound_ref md5
    	Z25 4437
    */
	typedef structure {
		templatecompound_id id;
		compound_ref compound_ref;
		string name;
		string abbreviation;
		string md5;
		bool isCofactor;
		list<string> aliases;
		float defaultCharge;
		float mass;
    	float deltaG;
    	float deltaGErr;
		string formula;
    } TemplateCompound;
    
    /* 
    	TemplateCompCompound object parallel to compound in model
    	
    	@optional formula
    */
    typedef structure {
		templatecompcompound_id id;
		templatecompound_ref templatecompound_ref;
		float charge;
		float maxuptake;
		string formula;
		templatecompartment_ref templatecompartment_ref;
    } TemplateCompCompound;
    
    /* 
    	TemplateReactionReagent object
    */
    typedef structure {
		templatecompcompound_ref templatecompcompound_ref;
		float coefficient;
    } TemplateReactionReagent;
    
    /* 
    	TemplateRole object representing link to annotations or genes
    */
    typedef structure {
    	templaterole_id id;
    	string name;
    	string source;
    	list<string> aliases;
    	list<feature_id> features;
    } TemplateRole;
    
    /* 
    	TemplateComplexRole object containing data relating to role in complex
    */
    typedef structure {
    	templaterole_ref templaterole_ref;
    	int optional_role;
    	int triggering;
    } TemplateComplexRole;
    
    /* 
    	TemplateComplex object
    */
    typedef structure {
		templatecomplex_id id;
    	string name;
    	string reference;
    	string source;
    	float confidence;
    	list<TemplateComplexRole> complexroles;
    } TemplateComplex;
    
    /* 
    	TemplateReaction object holds data on reaction in template
    	
    	@optional reference base_cost forward_penalty reverse_penalty GapfillDirection reaction_ref
    */
	typedef structure {
		templatereaction_id id;
		reaction_ref reaction_ref;
		string name;
		string type;
		string reference;
		string direction;
		string GapfillDirection;
		float maxforflux;
		float maxrevflux;
		templatecompartment_ref templatecompartment_ref;
		float base_cost;
    	float forward_penalty;
    	float reverse_penalty;
		list<TemplateReactionReagent> templateReactionReagents;
		list<templatecomplex_ref> templatecomplex_refs;
    } NewTemplateReaction;
    
    /* 
    	TemplateBiomassComponent object holds data on a compound of biomass in template
    */
	typedef structure {
    	string class;
    	templatecompcompound_ref templatecompcompound_ref;
    	string coefficient_type;
    	float coefficient;
    	list<templatecompcompound_ref> linked_compound_refs;
    	list<float> link_coefficients;
    } NewTemplateBiomassComponent;
    
    /* 
    	TemplateBiomass object holds data on biomass in template
    */
	typedef structure {
    	templatebiomass_id id;
    	string name;
    	string type;
    	float other;
    	float dna;
    	float rna;
    	float protein;
    	float lipid;
    	float cellwall;
    	float cofactor;
    	float energy;
    	list<NewTemplateBiomassComponent> templateBiomassComponents;
    } NewTemplateBiomass;
    
    /* 
    	TemplatePathway object
    */
	typedef structure {
    	templatepathway_id id;
    	string name;
    	string source;
    	string source_id;
    	string broadClassification;
    	string midClassification;
    	list<templatereaction_ref> templatereaction_refs;
    } TemplatePathway;
    
    /* 
    	ModelTemplate object holds data on how a model is constructed from an annotation
    	    	
    	@optional name
    */
	typedef structure {
    	modeltemplate_id id;
    	string name;
    	string type;
    	string domain;
    	Biochemistry_ref biochemistry_ref;
    	
    	list<TemplateRole> roles;
    	list<TemplateComplex> complexes;
    	list<TemplateCompound> compounds;
    	list<TemplateCompCompound> compcompounds;
    	list<TemplateCompartment> compartments;
    	list<NewTemplateReaction> reactions;
    	list<NewTemplateBiomass> biomasses;
    	list<TemplatePathway> pathways;
    } NewModelTemplate;
    
    /* 
    	Complex subobject holds data on probability and annotations for genes in a single complex
    */
    typedef structure{
        string complex_id;
        float complex_probability;
        list<tuple<string feature_id,string role> > features;
    } Complex;

	/* 
    	ReactionInfo subobject contains information on probability and complex annotations for a single reaction
    */
    typedef structure{
        string reaction_id;
        mapping<string complex_id, list<Complex>> complex_map;
        float reaction_probability;
    } ReactionInfo;

	/* 
    	ReactionProbabilities object holds data on probability that a reaction occurs in a genome
    */
    typedef structure {
        mapping<string rxn_id,ReactionInfo> reaction_info_map;
		template_ref template_ref;
		genome_ref genome_ref;
    } ReactionProbabilities;
    
    typedef structure {
    	string feature_ref;
    	float probability;
    	float coverage;
    	mapping<string source,string source_term> sources;
	} FeatureMapping;
	
	typedef structure {
    	mapping<string feature_id,FeatureMapping> features;
    	int hit_count;
    	float non_gene_probability;
    	float non_gene_coverage;
    	mapping<string source,string source_term> sources;
	} FunctionMappingData;
    
    /* 
    	Input to model reconstruction
    */
    typedef structure {
        mapping<string rxn_id,mapping<string compartment,FunctionMappingData> > reaction_hash;
        mapping<string role_id,mapping<string compartment,FunctionMappingData> > function_hash;
    } ModelReconstructionInput;
    
    typedef int boolean;

    typedef structure {
        string map_name;
        string map_id;
        string map_description;
        string homepage;
        string schema; /* default: https://escher.github.io/escher/jsonschema/1-0-0# */
        list<string> authors;
    } EscherMapMetadata;
    
    typedef structure {
        string bigg_id;
        float coefficient;
    } EscherMapLayoutReactionMetabolite;
    
    typedef structure {
        float x;
        float y;
    } EscherMapLayout2DPoint;
    
    /*
        @optional b1 b2
    */
    typedef structure {
        string from_node_id;
        string to_node_id;
        EscherMapLayout2DPoint b1;
        EscherMapLayout2DPoint b2;
    } EscherMapLayoutReactionSegment;
    
    typedef structure {
        string bigg_id;
        string name;
        float label_x;
        float label_y;
        boolean reversibility;
        string gene_reaction_rule;
        list<EscherMapLayoutReactionMetabolite> metabolites;
        mapping<string, EscherMapLayoutReactionSegment> segments;
        list<string> genes;
    } EscherMapLayoutReaction;
    
    /*
        @optional bigg_id name label_x label_y node_is_primary
    */
    typedef structure {
        string node_type;
        float x;
        float y;
        string bigg_id;
        string name;
        float label_x;
        float label_y;
        boolean node_is_primary;
    } EscherMapLayoutNode;
    
    typedef structure {
        float x;
        float y;
        string text;
    } EscherMapLayoutLabel;
    
    typedef structure {
        float x;
        float y;
        float width;
        float height;
    } EscherMapLayoutCanvas;
    
    typedef structure {
        mapping<string, EscherMapLayoutReaction> reactions;
        mapping<string, EscherMapLayoutNode> nodes;
        mapping<string, EscherMapLayoutLabel> text_labels;
        EscherMapLayoutCanvas canvas;
    } EscherMapLayout;
    
    typedef structure {
        EscherMapMetadata metadata;
        EscherMapLayout layout;
    } EscherMap;
};
