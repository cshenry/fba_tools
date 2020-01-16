
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
 * <p>Original spec-file type: RunModelCharacterizationParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fbamodel_id",
    "fbamodel_workspace",
    "fbamodel_output_id",
    "workspace"
})
public class RunModelCharacterizationParams {

    @JsonProperty("fbamodel_id")
    private String fbamodelId;
    @JsonProperty("fbamodel_workspace")
    private String fbamodelWorkspace;
    @JsonProperty("fbamodel_output_id")
    private String fbamodelOutputId;
    @JsonProperty("workspace")
    private String workspace;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("fbamodel_id")
    public String getFbamodelId() {
        return fbamodelId;
    }

    @JsonProperty("fbamodel_id")
    public void setFbamodelId(String fbamodelId) {
        this.fbamodelId = fbamodelId;
    }

    public RunModelCharacterizationParams withFbamodelId(String fbamodelId) {
        this.fbamodelId = fbamodelId;
        return this;
    }

    @JsonProperty("fbamodel_workspace")
    public String getFbamodelWorkspace() {
        return fbamodelWorkspace;
    }

    @JsonProperty("fbamodel_workspace")
    public void setFbamodelWorkspace(String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
    }

    public RunModelCharacterizationParams withFbamodelWorkspace(String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
        return this;
    }

    @JsonProperty("fbamodel_output_id")
    public String getFbamodelOutputId() {
        return fbamodelOutputId;
    }

    @JsonProperty("fbamodel_output_id")
    public void setFbamodelOutputId(String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
    }

    public RunModelCharacterizationParams withFbamodelOutputId(String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
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

    public RunModelCharacterizationParams withWorkspace(String workspace) {
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
        return ((((((((((("RunModelCharacterizationParams"+" [fbamodelId=")+ fbamodelId)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
