/*
@author chenry
*/
module KBaseBiochem {
	typedef int bool;
	/*
		Reference to a reaction object in a biochemistry
		@id subws KBaseBiochem.BiochemistryStructures.structures.[*].id
	*/
    typedef string structure_ref;
	/*
		Reference to a reaction object in a biochemistry
		@id subws KBaseBiochem.Biochemistry.reactions.[*].id
	*/
    typedef string reaction_ref;
	/*
		Reference to a cue object in a biochemistry
		@id subws KBaseBiochem.Biochemistry.cues.[*].id
	*/
    typedef string cue_ref;
	/*
		Reference to a compartment object in a biochemistry
		@id subws KBaseBiochem.Biochemistry.compartments.[*].id
	*/
    typedef string compartment_ref;
	/*
		Reference to a compound object in a biochemistry
		@id subws KBaseBiochem.Biochemistry.compounds.[*].id
	*/
    typedef string compound_ref;
    /*
		Reference to a media object
		@id ws KBaseBiochem.Media
	*/
    typedef string media_ref;
    /*
		Reference to a fbamodel object
	*/
    typedef string fbamodel_ref;
    /*
		Reference to a compound in a fbamodel  object
	*/
    typedef string modelcompound_ref;
    /*
		Reference to a Biochemistry object
		@id ws KBaseBiochem.Biochemistry
	*/
    typedef string biochemistry_ref;
    /*
		Reference to a compound object in a biochemistry
		@id subws KBaseBiochem.Biochemistry.compounds.[*].id
	*/
    typedef string mediacompound_ref;
	/*
		KBase genome ID
		@id kb
	*/
    typedef string genome_id;
    /*
		Reaction set ID
		@id external
	*/
    typedef string reactionset_id;
    /*
		Compound set ID
		@id external
	*/
    typedef string compoundset_id;
    /*
		Genome ID
		@id external
	*/
    typedef string biomass_id;
    /*
		Compound ID
		@id external
	*/
    typedef string compound_id;
    /*
		Reaction ID
		@id external
	*/
    typedef string reaction_id;
    /*
		Reaction ID
		@id external
	*/
    typedef string compartment_id;
    /*
		Reaction ID
		@id external
	*/
    typedef string cue_id;
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
		Source ID
		@id external
	*/
    typedef string source_id;
    /*
		Biochemistry ID
		@id kb
	*/
    typedef string biochem_id;
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
		FBAModel ID
		@id kb
	*/
    typedef string fbamodel_id;
    /*
		Media ID
		@id kb
	*/
    typedef string media_id;
    /*
		Biochemistry structure ID
		@id kb
	*/
    typedef string biochemstruct_id;
	/*
		Compound structure ID
		@id external
	*/
    typedef string structure_id;
    
    /* 
    	Compound object
    	
    	@optional md5 formula unchargedFormula mass deltaG deltaGErr abstractCompound_ref comprisedOfCompound_refs structure_ref cues pkas pkbs
		@searchable ws_subset id isCofactor name abbreviation md5 formula unchargedFormula mass defaultCharge deltaG abstractCompound_ref comprisedOfCompound_refs structure_ref cues
    */
    typedef structure {
    	compound_id id;
    	bool isCofactor;
    	string name;
    	string abbreviation;
    	string md5;
    	string formula;
    	string unchargedFormula;
    	float mass;
    	float defaultCharge;
    	float deltaG;
    	float deltaGErr;
    	compound_ref abstractCompound_ref;
    	list<compound_ref> comprisedOfCompound_refs;
    	structure_ref structure_ref;
    	mapping<cue_ref,float> cues;
    	mapping<int,list<float>> pkas;
    	mapping<int,list<float>> pkbs;
    } Compound;
    
    /* 
    	Reactant object
    	
		@searchable ws_subset compound_ref compartment_ref coefficient isCofactor
    */
    typedef structure {
		compound_ref compound_ref;
		compartment_ref compartment_ref;
		float coefficient;
		bool isCofactor;
	} Reagent;
    
    /* 
    	Reaction object
    	
    	@optional md5 deltaG deltaGErr abstractReaction_ref cues
		@searchable ws_subset id name abbreviation md5 direction thermoReversibility status defaultProtons deltaG abstractReaction_ref cues
		@searchable ws_subset reagents.[*].(compound_ref,compartment_ref,coefficient,isCofactor)
    */
    typedef structure {
    	reaction_id id;
    	string name;
    	string abbreviation;
    	string md5;
    	string direction;
    	string thermoReversibility;
    	string status;
    	float defaultProtons;
    	float deltaG;
    	float deltaGErr;
    	reaction_ref abstractReaction_ref;
    	mapping<cue_ref,float> cues;
    	list<Reagent> reagents; 
    } Reaction;
    
    /* 
    	Compartment object
    	
		@searchable ws_subset id name hierarchy
    */
    typedef structure {
    	compartment_id id;
    	string name;
    	int hierarchy;
    } Compartment;
    
    /* 
    	Cue object
    	
    	@optional mass deltaGErr deltaG defaultCharge structure_key structure_data structure_type
		@searchable ws_subset structure_key id name abbreviation formula unchargedFormula mass defaultCharge deltaG smallMolecule priority structure_key structure_data
    */
    typedef structure {
    	cue_id id;
    	string name;
    	string abbreviation;
    	string formula;
    	string unchargedFormula;
    	float mass;
    	float defaultCharge;
    	float deltaG;
    	float deltaGErr;
    	bool smallMolecule;
    	int priority;
    	string structure_key;
    	string structure_data;
    	string structure_type;
    } Cue;
    
    /* 
    	MediaCompound object
    	
    	@optional id name smiles inchikey
    */
	typedef structure {
		compound_ref compound_ref;
		string id;
		string name;
		string smiles;
		string inchikey;
		float concentration;
		float maxFlux;
		float minFlux;
	} MediaCompound;

	/* 
    	ImportedCompound object
    	
    	@optional deltag deltagerr mass exactmass compound_ref modelcompound_ref charge name
    */
	typedef structure {
		string id;
		string name;
		string smiles;
		string inchikey;
		float charge;
		string formula;
		float mass;
		float exactmass;
		compound_ref compound_ref;
		modelcompound_ref modelcompound_ref;
		mapping<string,list<string>> dblinks;
		mapping<string type,mapping<string fingerprint,float value>> fingerprints;
		float deltag;
		float deltagerr;
	} ImportedCompound;
	
	/* 
    	CompoundSet object
    	
    	@optional description name fbamodel_ref biochemistry_ref
    */ 
	typedef structure {
		list<ImportedCompound> compounds;
		string id;
		string name;
		string description;
		fbamodel_ref fbamodel_ref;
		biochemistry_ref biochemistry_ref;
	} CompoundSet;
	
	/* 
    	MediaReagent object
    	
    	@optional molecular_weight concentration_units concentration associated_compounds
    */
	typedef structure {
		string id;
		string name;
		float concentration;
		string concentration_units;
		float molecular_weight;
		mapping<string,float> associated_compounds;
	} MediaReagent;
	
	/* 
    	Media object
    	
    	@optional reagents atmosphere_addition atmosphere temperature pH_data isAerobic protocol_link source source_id 	
		@metadata ws source_id as Source ID
		@metadata ws source as Source
		@metadata ws name as Name
		@metadata ws temperature as Temperature
		@metadata ws isAerobic as Is Aerobic
		@metadata ws isMinimal as Is Minimal
		@metadata ws isDefined as Is Defined
		@metadata ws length(mediacompounds) as Number compounds
    */
	typedef structure {
		media_id id;
		string name;
		source_id source_id;
		string source;
		string protocol_link;
		bool isDefined;
		bool isMinimal;
		bool isAerobic;
		string type;
		string pH_data;
		float temperature;
		string atmosphere;
		string atmosphere_addition;
		list<MediaReagent> reagents;
		list<MediaCompound> mediacompounds;
	} Media;
	
	
	typedef structure {
		mapping<string,string> string_metadata;
		mapping<string,float> numerial_metadata;
		media_ref ref;
	} MediaSetElement;

	/* 
    	Media set object

    */
	typedef structure {
		string description;
		list<MediaSetElement> elements;
	} MediaSet;
	
	/* 
    	CompoundSet object
    	
    	@searchable ws_subset id name class compound_refs type
    */
	typedef structure {
		compoundset_id id;
		string name;
		string class;
		string type;
		list<compound_ref> compound_refs;
	} SubCompoundSet;
	
	/* 
    	ReactionSet object
    	
    	@searchable ws_subset id name class reaction_refs type
    */
	typedef structure {
		reactionset_id id;
		string name;
		string class;
		string type;
		list<reaction_ref> reaction_refs;
	} SubReactionSet;
    
    /* 
    	Biochemistry object
    	
    	@optional description name
    	@searchable ws_subset compartments.[*].(id,name)
    	@searchable ws_subset compounds.[*].(id,name)
    	@searchable ws_subset reactions.[*].(id)
    	@searchable ws_subset cues.[*].(id,name,smallMolecule)
    	@searchable ws_subset reactionSets.[*].(id,name,class,reaction_refs,type)
    	@searchable ws_subset compoundSets.[*].(id,name,class,compound_refs,type)
    */
    typedef structure {
		biochem_id id;
		string name;
		string description;
		
		list<Compartment> compartments;
		list<Compound> compounds;
		list<Reaction> reactions;
		list<SubReactionSet> reactionSets;
		list<SubCompoundSet> compoundSets;
		list<Cue> cues;
		
		mapping<compound_id,mapping<string,list<string>>> compound_aliases;
		mapping<reaction_id,mapping<string,list<string>>> reaction_aliases;
	} Biochemistry;
	
	/* 
    	ReactionSet object
    	
    	@searchable ws_subset id type
    */
	typedef structure {
		structure_id id;
		string type;
		string data;
	} CompoundStructure;
	
	/* 
    	BiochemistryStructures object
    	
    	@optional description name
    	@searchable ws_subset id name structures
    */
	typedef structure {
		biochemstruct_id id;
		string name;
		string description;
		list<CompoundStructure> structures;
	} BiochemistryStructures;
	
	/*
		Reference to a compound object in a metabolic map
		@id subws KBaseBiochem.MetabolicMap.compounds.[*].id
	*/
    typedef string mapcompound_ref;
    
    /*
		Reference to a compound object in a metabolic map
		@id subws KBaseBiochem.MetabolicMap.linkedmaps.[*].id
	*/
    typedef string maplink_ref;
    
    /*
		Reference to a metabolic map
		@id ws KBaseBiochem.MetabolicMap
	*/
    typedef string map_ref;
    
    /*
		Metabolic map ID
		@id external
	*/
    typedef string map_id;
	
	/* 
    	MapReactionReactant object
    */
	typedef structure {
		int id;
		mapcompound_ref compound_ref;
	} MapReactionReactant;

	/* 
    	ReactionGroup object
    	
    	@optional substrate_path product_path spline dasharray
    */
	typedef structure {
		list<string> rxn_ids;
		int x;
		int y;
		list<tuple<int,int>> substrate_path;
		list<tuple<int,int>> product_path;
		string spline;
		string dasharray;
	} ReactionGroup;
	
	
	/* 
    	MapReaction object
    	
    	@optional link
    */
	typedef structure {
		string id;
		bool reversible;
		string name;
		string ec;
		string shape;
		string link;
		int h;
		int w;
		int y;
		int x;
		list<string> rxns;
		list<MapReactionReactant> substrate_refs;
		list<MapReactionReactant> product_refs;
	} MapReaction;
	
	/* 
    	MapCompound object
    	
    	@optional link label_x label_y
    */
	typedef structure {
		string id;
		string label;
		int label_x;
		int label_y;
		string name;
		string shape;
		string link;
		int h;
		int w;
		int y;
		int x;
		list<string> cpds;
		list<maplink_ref> link_refs;
	} MapCompound;
	
	/* 
    	MapLink object
    	
    	@optional link
    */
	typedef structure {
		string id;
		string map_ref;
		string name;
		string shape;
		string link;
		int h;
		int w;
		int y;
		int x;
		map_id map_id;
	} MapLink;
	
	/* 
    	MetabolicMap object
    	
    	@optional description link
    	@metadata ws source_id as Source ID
		@metadata ws source as Source
		@metadata ws name as Name
		@metadata ws length(reactions) as Number reactions
		@metadata ws length(compounds) as Number compounds
    */
	typedef structure {
		map_id id;
		string name;
		string source_id;
		string source;
		string link;
		string description;
		list<string> reaction_ids;
		list<string> compound_ids;
		list<ReactionGroup> groups;
		list<MapReaction> reactions;
		list<MapCompound> compounds;
		list<MapLink> linkedmaps;
	} MetabolicMap;
};

