
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
 * <p>Original spec-file type: FilterContigsParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace",
    "contigset_id",
    "min_length"
})
public class FilterContigsParams {

    @JsonProperty("workspace")
    private String workspace;
    @JsonProperty("contigset_id")
    private String contigsetId;
    @JsonProperty("min_length")
    private Long minLength;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("workspace")
    public String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(String workspace) {
        this.workspace = workspace;
    }

    public FilterContigsParams withWorkspace(String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("contigset_id")
    public String getContigsetId() {
        return contigsetId;
    }

    @JsonProperty("contigset_id")
    public void setContigsetId(String contigsetId) {
        this.contigsetId = contigsetId;
    }

    public FilterContigsParams withContigsetId(String contigsetId) {
        this.contigsetId = contigsetId;
        return this;
    }

    @JsonProperty("min_length")
    public Long getMinLength() {
        return minLength;
    }

    @JsonProperty("min_length")
    public void setMinLength(Long minLength) {
        this.minLength = minLength;
    }

    public FilterContigsParams withMinLength(Long minLength) {
        this.minLength = minLength;
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
        return ((((((((("FilterContigsParams"+" [workspace=")+ workspace)+", contigsetId=")+ contigsetId)+", minLength=")+ minLength)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
