
package us.kbase.fbatools;

import java.util.HashMap;
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
    "genome_id",
    "media_output_id",
    "genome_workspace",
    "workspace"
})
public class PredictAuxotrophyParams {

    @JsonProperty("genome_id")
    private String genomeId;
    @JsonProperty("media_output_id")
    private String mediaOutputId;
    @JsonProperty("genome_workspace")
    private String genomeWorkspace;
    @JsonProperty("workspace")
    private String workspace;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("genome_id")
    public String getGenomeId() {
        return genomeId;
    }

    @JsonProperty("genome_id")
    public void setGenomeId(String genomeId) {
        this.genomeId = genomeId;
    }

    public PredictAuxotrophyParams withGenomeId(String genomeId) {
        this.genomeId = genomeId;
        return this;
    }

    @JsonProperty("media_output_id")
    public String getMediaOutputId() {
        return mediaOutputId;
    }

    @JsonProperty("media_output_id")
    public void setMediaOutputId(String mediaOutputId) {
        this.mediaOutputId = mediaOutputId;
    }

    public PredictAuxotrophyParams withMediaOutputId(String mediaOutputId) {
        this.mediaOutputId = mediaOutputId;
        return this;
    }

    @JsonProperty("genome_workspace")
    public String getGenomeWorkspace() {
        return genomeWorkspace;
    }

    @JsonProperty("genome_workspace")
    public void setGenomeWorkspace(String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
    }

    public PredictAuxotrophyParams withGenomeWorkspace(String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
        return this;
    }

    @JsonProperty("workspace")
    public String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(String workspace) {
        this.workspace = workspace;
    }

    public PredictAuxotrophyParams withWorkspace(String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonAnyGetter
    public Map<String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public String toString() {
        return ((((((((((("PredictAuxotrophyParams"+" [genomeId=")+ genomeId)+", mediaOutputId=")+ mediaOutputId)+", genomeWorkspace=")+ genomeWorkspace)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
