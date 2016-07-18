#!/usr/bin/python

#Usage: python data_api_test.py ws-url shock-url handle-url token ref id

import sys
import json
import doekbase.data_api
from doekbase.data_api.annotation.genome_annotation.api import GenomeAnnotationAPI , GenomeAnnotationClientAPI
from doekbase.data_api.sequence.assembly.api import AssemblyAPI , AssemblyClientAPI

ga = GenomeAnnotationAPI({
	'workspace_service_url' : sys.argv[1],
	'shock_service_url' : sys.argv[2],
	'handle_service_url' : sys.argv[3] 
},token = sys.argv[4],ref = sys.argv[5]);

gto = {
	'id' : sys.argv[6],
	'scientific_name' : "Unknown species",
	'domain' : "Unknown",
	'genetic_code' : 11,
	'dna_size' : 0,
	'num_contigs' : 0,
	'contig_lengths' : [],
	'contig_ids' : [],
	'source' : "KBase",
	'source_id' : sys.argv[6],
#	'md5' : "",
	'taxonomy' : "Unknown",
	'gc_content' : 0.5,
	'complete' : 1,
	'features' : []
};

taxon = {};
success = 0;
try:
	taxon = ga.get_taxon();
	success = 1;
except Exception, e:
	success = 0
	
if success == 1:
	try:
		gto['scientific_name'] = taxon.get_scientific_name()
	except Exception, e:
		success = 0
	try:
		gto['domain'] = taxon.get_domain()
	except Exception, e:
		success = 0
	try:
		gto['genetic_code'] = taxon.get_genetic_code()
	except Exception, e:
		success = 0
	try:
		gto['taxonomy'] = ",".join(taxon.get_scientific_lineage())
	except Exception, e:
		success = 0

assemb = {};
success = 0;
try:
	assemb = ga.get_assembly();
	success = 1;
except Exception, e:
	success = 0
	
if success == 1:
	try:
		gto['dna_size'] = taxon.get_dna_size()
	except Exception, e:
		success = 0
	try:
		gto['num_contigs'] = taxon.get_number_contigs()
	except Exception, e:
		success = 0
	try:
		gto['contig_lengths'] = taxon.get_contig_lengths()
	except Exception, e:
		success = 0
	try:
		gto['contig_ids'] = taxon.get_contig_ids()
	except Exception, e:
		success = 0
	try:
		gto['gc_content'] = assemb.get_gc_content()
	except Exception, e:
		success = 0
	try:
		extsource = assemb.get_external_source_info()
		gto['source'] = extsource["external_source"]
		gto['source_id'] = extsource["external_source_id"]
	except Exception, e:
		success = 0
		
features = [];
success = 0;
try:
	features = ga.get_features();
	success = 1
except Exception, e:
	success = 0
	
if success == 1:
	for ftrid in features.keys():
		ftrdata = features[ftrid]
		if 'feature_type' in ftrdata.keys():
			newfeature = {'id' : ftrid,'type' : ftrdata['feature_type'],'function' : "Unknown",'location' : []}
			if 'feature_ontology_terms' in ftrdata.keys():
				newfeature['ontology_terms'] = ftrdata['feature_ontology_terms']
			if 'feature_function' in ftrdata.keys():
				newfeature['function'] = ftrdata['feature_function']
			if 'feature_protein_translation' in ftrdata.keys():
				newfeature['protein_translation'] = ftrdata['feature_protein_translation']
			if 'feature_dna_sequence' in ftrdata.keys():
				newfeature['dna_sequence'] = ftrdata['feature_dna_sequence']
			if 'feature_locations' in ftrdata.keys():
				for loc in ftrdata['feature_locations']:
					newfeature['location'].append([loc['contig_id'],loc['start'],loc['strand'],loc['length']])
			#if 'feature_aliases' in ftrdata.keys():
			#newfeature['protein_translation'] = ftrdata['feature_aliases']
			if 'feature_md5' in ftrdata.keys():
				if len(ftrdata['feature_md5']) > 0:
					newfeature['md5'] = ftrdata['feature_md5']
			if 'feature_dna_sequence_length' in ftrdata.keys():
				newfeature['dna_sequence_length'] = ftrdata['feature_dna_sequence_length']		
			gto['features'].append(newfeature);

print json.dumps(gto, ensure_ascii=False)
print "SUCCESS"