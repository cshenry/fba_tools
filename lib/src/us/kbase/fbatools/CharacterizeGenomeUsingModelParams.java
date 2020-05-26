
package us.kbase.fbatools;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: CharacterizeGenomeUsingModelParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "genome_id",
    "genome_workspace",
    "fbamodel_output_id",
    "workspace",
    "template_id",
    "template_workspace",
    "use_annotated_functions",
    "merge_all_annotations",
    "source_ontology_list"
})
public class CharacterizeGenomeUsingModelParams {

    @JsonProperty("genome_id")
    private java.lang.String genomeId;
    @JsonProperty("genome_workspace")
    private java.lang.String genomeWorkspace;
    @JsonProperty("fbamodel_output_id")
    private java.lang.String fbamodelOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("template_id")
    private java.lang.String templateId;
    @JsonProperty("template_workspace")
    private java.lang.String templateWorkspace;
    @JsonProperty("use_annotated_functions")
    private Long useAnnotatedFunctions;
    @JsonProperty("merge_all_annotations")
    private Long mergeAllAnnotations;
    @JsonProperty("source_ontology_list")
    private List<String> sourceOntologyList;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("genome_id")
    public java.lang.String getGenomeId() {
        return genomeId;
    }

    @JsonProperty("genome_id")
    public void setGenomeId(java.lang.String genomeId) {
        this.genomeId = genomeId;
    }

    public CharacterizeGenomeUsingModelParams withGenomeId(java.lang.String genomeId) {
        this.genomeId = genomeId;
        return this;
    }

    @JsonProperty("genome_workspace")
    public java.lang.String getGenomeWorkspace() {
        return genomeWorkspace;
    }

    @JsonProperty("genome_workspace")
    public void setGenomeWorkspace(java.lang.String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
    }

    public CharacterizeGenomeUsingModelParams withGenomeWorkspace(java.lang.String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
        return this;
    }

    @JsonProperty("fbamodel_output_id")
    public java.lang.String getFbamodelOutputId() {
        return fbamodelOutputId;
    }

    @JsonProperty("fbamodel_output_id")
    public void setFbamodelOutputId(java.lang.String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
    }

    public CharacterizeGenomeUsingModelParams withFbamodelOutputId(java.lang.String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
        return this;
    }

    @JsonProperty("workspace")
    public java.lang.String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
    }

    public CharacterizeGenomeUsingModelParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("template_id")
    public java.lang.String getTemplateId() {
        return templateId;
    }

    @JsonProperty("template_id")
    public void setTemplateId(java.lang.String templateId) {
        this.templateId = templateId;
    }

    public CharacterizeGenomeUsingModelParams withTemplateId(java.lang.String templateId) {
        this.templateId = templateId;
        return this;
    }

    @JsonProperty("template_workspace")
    public java.lang.String getTemplateWorkspace() {
        return templateWorkspace;
    }

    @JsonProperty("template_workspace")
    public void setTemplateWorkspace(java.lang.String templateWorkspace) {
        this.templateWorkspace = templateWorkspace;
    }

    public CharacterizeGenomeUsingModelParams withTemplateWorkspace(java.lang.String templateWorkspace) {
        this.templateWorkspace = templateWorkspace;
        return this;
    }

    @JsonProperty("use_annotated_functions")
    public Long getUseAnnotatedFunctions() {
        return useAnnotatedFunctions;
    }

    @JsonProperty("use_annotated_functions")
    public void setUseAnnotatedFunctions(Long useAnnotatedFunctions) {
        this.useAnnotatedFunctions = useAnnotatedFunctions;
    }

    public CharacterizeGenomeUsingModelParams withUseAnnotatedFunctions(Long useAnnotatedFunctions) {
        this.useAnnotatedFunctions = useAnnotatedFunctions;
        return this;
    }

    @JsonProperty("merge_all_annotations")
    public Long getMergeAllAnnotations() {
        return mergeAllAnnotations;
    }

    @JsonProperty("merge_all_annotations")
    public void setMergeAllAnnotations(Long mergeAllAnnotations) {
        this.mergeAllAnnotations = mergeAllAnnotations;
    }

    public CharacterizeGenomeUsingModelParams withMergeAllAnnotations(Long mergeAllAnnotations) {
        this.mergeAllAnnotations = mergeAllAnnotations;
        return this;
    }

    @JsonProperty("source_ontology_list")
    public List<String> getSourceOntologyList() {
        return sourceOntologyList;
    }

    @JsonProperty("source_ontology_list")
    public void setSourceOntologyList(List<String> sourceOntologyList) {
        this.sourceOntologyList = sourceOntologyList;
    }

    public CharacterizeGenomeUsingModelParams withSourceOntologyList(List<String> sourceOntologyList) {
        this.sourceOntologyList = sourceOntologyList;
        return this;
    }

    @JsonAnyGetter
    public Map<java.lang.String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(java.lang.String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public java.lang.String toString() {
        return ((((((((((((((((((((("CharacterizeGenomeUsingModelParams"+" [genomeId=")+ genomeId)+", genomeWorkspace=")+ genomeWorkspace)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", templateId=")+ templateId)+", templateWorkspace=")+ templateWorkspace)+", useAnnotatedFunctions=")+ useAnnotatedFunctions)+", mergeAllAnnotations=")+ mergeAllAnnotations)+", sourceOntologyList=")+ sourceOntologyList)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
