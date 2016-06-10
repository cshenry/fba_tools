
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
 * <p>Original spec-file type: EditMetabolicModelParams</p>
 * <pre>
 * EditMetabolicModelParams object: arguments for the edit model function
 * </pre>
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace",
    "fbamodel_workspace",
    "fbamodel_id",
    "fbamodel_output_id",
    "data",
    "protcomp_ref",
    "pangenome_ref"
})
public class EditMetabolicModelParams {

    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("fbamodel_workspace")
    private java.lang.String fbamodelWorkspace;
    @JsonProperty("fbamodel_id")
    private java.lang.String fbamodelId;
    @JsonProperty("fbamodel_output_id")
    private java.lang.String fbamodelOutputId;
    @JsonProperty("data")
    private Map<String, List<List<String>>> data;
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

    public EditMetabolicModelParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("fbamodel_workspace")
    public java.lang.String getFbamodelWorkspace() {
        return fbamodelWorkspace;
    }

    @JsonProperty("fbamodel_workspace")
    public void setFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
    }

    public EditMetabolicModelParams withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
        return this;
    }

    @JsonProperty("fbamodel_id")
    public java.lang.String getFbamodelId() {
        return fbamodelId;
    }

    @JsonProperty("fbamodel_id")
    public void setFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
    }

    public EditMetabolicModelParams withFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
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

    public EditMetabolicModelParams withFbamodelOutputId(java.lang.String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
        return this;
    }

    @JsonProperty("data")
    public Map<String, List<List<String>>> getData() {
        return data;
    }

    @JsonProperty("data")
    public void setData(Map<String, List<List<String>>> data) {
        this.data = data;
    }

    public EditMetabolicModelParams withData(Map<String, List<List<String>>> data) {
        this.data = data;
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

    public EditMetabolicModelParams withProtcompRef(java.lang.String protcompRef) {
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

    public EditMetabolicModelParams withPangenomeRef(java.lang.String pangenomeRef) {
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
        return ((((((((((((((((("EditMetabolicModelParams"+" [workspace=")+ workspace)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", fbamodelId=")+ fbamodelId)+", fbamodelOutputId=")+ fbamodelOutputId)+", data=")+ data)+", protcompRef=")+ protcompRef)+", pangenomeRef=")+ pangenomeRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
