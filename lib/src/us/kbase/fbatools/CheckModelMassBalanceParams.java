
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
 * <p>Original spec-file type: CheckModelMassBalanceParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fbamodel_id",
    "fbamodel_workspace",
    "workspace"
})
public class CheckModelMassBalanceParams {

    @JsonProperty("fbamodel_id")
    private String fbamodelId;
    @JsonProperty("fbamodel_workspace")
    private String fbamodelWorkspace;
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

    public CheckModelMassBalanceParams withFbamodelId(String fbamodelId) {
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

    public CheckModelMassBalanceParams withFbamodelWorkspace(String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
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

    public CheckModelMassBalanceParams withWorkspace(String workspace) {
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
        return ((((((((("CheckModelMassBalanceParams"+" [fbamodelId=")+ fbamodelId)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
