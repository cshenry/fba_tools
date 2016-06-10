
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
 * <p>Original spec-file type: ModelComparisonParams</p>
 * <pre>
 * ModelComparisonParams object: a list of models and optional pangenome and protein comparison; mc_name is the name for the new object.
 * @optional protcomp_ref pangenome_ref
 * </pre>
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace",
    "mc_name",
    "model_refs",
    "protcomp_ref",
    "pangenome_ref"
})
public class ModelComparisonParams {

    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("mc_name")
    private java.lang.String mcName;
    @JsonProperty("model_refs")
    private List<String> modelRefs;
    @JsonProperty("protcomp_ref")
    private java.lang.String protcompRef;
    @JsonProperty("pangenome_ref")
    private java.lang.String pangenomeRef;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("workspace")
    public java.lang.String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
    }

    public ModelComparisonParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("mc_name")
    public java.lang.String getMcName() {
        return mcName;
    }

    @JsonProperty("mc_name")
    public void setMcName(java.lang.String mcName) {
        this.mcName = mcName;
    }

    public ModelComparisonParams withMcName(java.lang.String mcName) {
        this.mcName = mcName;
        return this;
    }

    @JsonProperty("model_refs")
    public List<String> getModelRefs() {
        return modelRefs;
    }

    @JsonProperty("model_refs")
    public void setModelRefs(List<String> modelRefs) {
        this.modelRefs = modelRefs;
    }

    public ModelComparisonParams withModelRefs(List<String> modelRefs) {
        this.modelRefs = modelRefs;
        return this;
    }

    @JsonProperty("protcomp_ref")
    public java.lang.String getProtcompRef() {
        return protcompRef;
    }

    @JsonProperty("protcomp_ref")
    public void setProtcompRef(java.lang.String protcompRef) {
        this.protcompRef = protcompRef;
    }

    public ModelComparisonParams withProtcompRef(java.lang.String protcompRef) {
        this.protcompRef = protcompRef;
        return this;
    }

    @JsonProperty("pangenome_ref")
    public java.lang.String getPangenomeRef() {
        return pangenomeRef;
    }

    @JsonProperty("pangenome_ref")
    public void setPangenomeRef(java.lang.String pangenomeRef) {
        this.pangenomeRef = pangenomeRef;
    }

    public ModelComparisonParams withPangenomeRef(java.lang.String pangenomeRef) {
        this.pangenomeRef = pangenomeRef;
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
        return ((((((((((((("ModelComparisonParams"+" [workspace=")+ workspace)+", mcName=")+ mcName)+", modelRefs=")+ modelRefs)+", protcompRef=")+ protcompRef)+", pangenomeRef=")+ pangenomeRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
