
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
 * <p>Original spec-file type: ModelCreationParams</p>
 * <pre>
 * compounds_file is not used for excel file creations
 * </pre>
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "model_file",
    "model_name",
    "workspace_name",
    "genome",
    "biomass",
    "compounds_file"
})
public class ModelCreationParams {

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("model_file")
    private File modelFile;
    @JsonProperty("model_name")
    private java.lang.String modelName;
    @JsonProperty("workspace_name")
    private java.lang.String workspaceName;
    @JsonProperty("genome")
    private java.lang.String genome;
    @JsonProperty("biomass")
    private List<String> biomass;
    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("compounds_file")
    private File compoundsFile;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("model_file")
    public File getModelFile() {
        return modelFile;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("model_file")
    public void setModelFile(File modelFile) {
        this.modelFile = modelFile;
    }

    public ModelCreationParams withModelFile(File modelFile) {
        this.modelFile = modelFile;
        return this;
    }

    @JsonProperty("model_name")
    public java.lang.String getModelName() {
        return modelName;
    }

    @JsonProperty("model_name")
    public void setModelName(java.lang.String modelName) {
        this.modelName = modelName;
    }

    public ModelCreationParams withModelName(java.lang.String modelName) {
        this.modelName = modelName;
        return this;
    }

    @JsonProperty("workspace_name")
    public java.lang.String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(java.lang.String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public ModelCreationParams withWorkspaceName(java.lang.String workspaceName) {
        this.workspaceName = workspaceName;
        return this;
    }

    @JsonProperty("genome")
    public java.lang.String getGenome() {
        return genome;
    }

    @JsonProperty("genome")
    public void setGenome(java.lang.String genome) {
        this.genome = genome;
    }

    public ModelCreationParams withGenome(java.lang.String genome) {
        this.genome = genome;
        return this;
    }

    @JsonProperty("biomass")
    public List<String> getBiomass() {
        return biomass;
    }

    @JsonProperty("biomass")
    public void setBiomass(List<String> biomass) {
        this.biomass = biomass;
    }

    public ModelCreationParams withBiomass(List<String> biomass) {
        this.biomass = biomass;
        return this;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("compounds_file")
    public File getCompoundsFile() {
        return compoundsFile;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("compounds_file")
    public void setCompoundsFile(File compoundsFile) {
        this.compoundsFile = compoundsFile;
    }

    public ModelCreationParams withCompoundsFile(File compoundsFile) {
        this.compoundsFile = compoundsFile;
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
        return ((((((((((((((("ModelCreationParams"+" [modelFile=")+ modelFile)+", modelName=")+ modelName)+", workspaceName=")+ workspaceName)+", genome=")+ genome)+", biomass=")+ biomass)+", compoundsFile=")+ compoundsFile)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
