
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
 * <p>Original spec-file type: CompareFBASolutionsParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fba_id_list",
    "fba_workspace",
    "fbacomparison_output_id",
    "workspace"
})
public class CompareFBASolutionsParams {

    @JsonProperty("fba_id_list")
    private List<String> fbaIdList;
    @JsonProperty("fba_workspace")
    private java.lang.String fbaWorkspace;
    @JsonProperty("fbacomparison_output_id")
    private java.lang.String fbacomparisonOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("fba_id_list")
    public List<String> getFbaIdList() {
        return fbaIdList;
    }

    @JsonProperty("fba_id_list")
    public void setFbaIdList(List<String> fbaIdList) {
        this.fbaIdList = fbaIdList;
    }

    public CompareFBASolutionsParams withFbaIdList(List<String> fbaIdList) {
        this.fbaIdList = fbaIdList;
        return this;
    }

    @JsonProperty("fba_workspace")
    public java.lang.String getFbaWorkspace() {
        return fbaWorkspace;
    }

    @JsonProperty("fba_workspace")
    public void setFbaWorkspace(java.lang.String fbaWorkspace) {
        this.fbaWorkspace = fbaWorkspace;
    }

    public CompareFBASolutionsParams withFbaWorkspace(java.lang.String fbaWorkspace) {
        this.fbaWorkspace = fbaWorkspace;
        return this;
    }

    @JsonProperty("fbacomparison_output_id")
    public java.lang.String getFbacomparisonOutputId() {
        return fbacomparisonOutputId;
    }

    @JsonProperty("fbacomparison_output_id")
    public void setFbacomparisonOutputId(java.lang.String fbacomparisonOutputId) {
        this.fbacomparisonOutputId = fbacomparisonOutputId;
    }

    public CompareFBASolutionsParams withFbacomparisonOutputId(java.lang.String fbacomparisonOutputId) {
        this.fbacomparisonOutputId = fbacomparisonOutputId;
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

    public CompareFBASolutionsParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
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
        return ((((((((((("CompareFBASolutionsParams"+" [fbaIdList=")+ fbaIdList)+", fbaWorkspace=")+ fbaWorkspace)+", fbacomparisonOutputId=")+ fbacomparisonOutputId)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
