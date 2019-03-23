
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
 * <p>Original spec-file type: ModelObjectSelectionParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace_name",
    "model_name",
    "save_to_shock",
    "fulldb"
})
public class ModelObjectSelectionParams {

    @JsonProperty("workspace_name")
    private String workspaceName;
    @JsonProperty("model_name")
    private String modelName;
    @JsonProperty("save_to_shock")
    private Long saveToShock;
    @JsonProperty("fulldb")
    private Long fulldb;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("workspace_name")
    public String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public ModelObjectSelectionParams withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
        return this;
    }

    @JsonProperty("model_name")
    public String getModelName() {
        return modelName;
    }

    @JsonProperty("model_name")
    public void setModelName(String modelName) {
        this.modelName = modelName;
    }

    public ModelObjectSelectionParams withModelName(String modelName) {
        this.modelName = modelName;
        return this;
    }

    @JsonProperty("save_to_shock")
    public Long getSaveToShock() {
        return saveToShock;
    }

    @JsonProperty("save_to_shock")
    public void setSaveToShock(Long saveToShock) {
        this.saveToShock = saveToShock;
    }

    public ModelObjectSelectionParams withSaveToShock(Long saveToShock) {
        this.saveToShock = saveToShock;
        return this;
    }

    @JsonProperty("fulldb")
    public Long getFulldb() {
        return fulldb;
    }

    @JsonProperty("fulldb")
    public void setFulldb(Long fulldb) {
        this.fulldb = fulldb;
    }

    public ModelObjectSelectionParams withFulldb(Long fulldb) {
        this.fulldb = fulldb;
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
        return ((((((((((("ModelObjectSelectionParams"+" [workspaceName=")+ workspaceName)+", modelName=")+ modelName)+", saveToShock=")+ saveToShock)+", fulldb=")+ fulldb)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
