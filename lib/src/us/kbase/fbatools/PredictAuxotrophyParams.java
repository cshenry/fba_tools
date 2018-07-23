
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
 * <p>Original spec-file type: PredictAuxotrophyParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "genome_ids",
    "genome_workspace",
    "workspace"
})
public class PredictAuxotrophyParams {

    @JsonProperty("genome_ids")
    private List<String> genomeIds;
    @JsonProperty("genome_workspace")
    private java.lang.String genomeWorkspace;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("genome_ids")
    public List<String> getGenomeIds() {
        return genomeIds;
    }

    @JsonProperty("genome_ids")
    public void setGenomeIds(List<String> genomeIds) {
        this.genomeIds = genomeIds;
    }

    public PredictAuxotrophyParams withGenomeIds(List<String> genomeIds) {
        this.genomeIds = genomeIds;
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

    public PredictAuxotrophyParams withGenomeWorkspace(java.lang.String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
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

    public PredictAuxotrophyParams withWorkspace(java.lang.String workspace) {
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
        return ((((((((("PredictAuxotrophyParams"+" [genomeIds=")+ genomeIds)+", genomeWorkspace=")+ genomeWorkspace)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
