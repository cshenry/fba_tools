
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
 * <p>Original spec-file type: ViewFluxNetworkParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fba_id",
    "fba_workspace",
    "workspace"
})
public class ViewFluxNetworkParams {

    @JsonProperty("fba_id")
    private String fbaId;
    @JsonProperty("fba_workspace")
    private String fbaWorkspace;
    @JsonProperty("workspace")
    private String workspace;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("fba_id")
    public String getFbaId() {
        return fbaId;
    }

    @JsonProperty("fba_id")
    public void setFbaId(String fbaId) {
        this.fbaId = fbaId;
    }

    public ViewFluxNetworkParams withFbaId(String fbaId) {
        this.fbaId = fbaId;
        return this;
    }

    @JsonProperty("fba_workspace")
    public String getFbaWorkspace() {
        return fbaWorkspace;
    }

    @JsonProperty("fba_workspace")
    public void setFbaWorkspace(String fbaWorkspace) {
        this.fbaWorkspace = fbaWorkspace;
    }

    public ViewFluxNetworkParams withFbaWorkspace(String fbaWorkspace) {
        this.fbaWorkspace = fbaWorkspace;
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

    public ViewFluxNetworkParams withWorkspace(String workspace) {
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
        return ((((((((("ViewFluxNetworkParams"+" [fbaId=")+ fbaId)+", fbaWorkspace=")+ fbaWorkspace)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
