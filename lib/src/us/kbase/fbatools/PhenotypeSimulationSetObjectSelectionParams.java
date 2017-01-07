
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
 * <p>Original spec-file type: PhenotypeSimulationSetObjectSelectionParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace_name",
    "phenotype_simulation_set_name",
    "save_to_shock"
})
public class PhenotypeSimulationSetObjectSelectionParams {

    @JsonProperty("workspace_name")
    private String workspaceName;
    @JsonProperty("phenotype_simulation_set_name")
    private String phenotypeSimulationSetName;
    @JsonProperty("save_to_shock")
    private Long saveToShock;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("workspace_name")
    public String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public PhenotypeSimulationSetObjectSelectionParams withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
        return this;
    }

    @JsonProperty("phenotype_simulation_set_name")
    public String getPhenotypeSimulationSetName() {
        return phenotypeSimulationSetName;
    }

    @JsonProperty("phenotype_simulation_set_name")
    public void setPhenotypeSimulationSetName(String phenotypeSimulationSetName) {
        this.phenotypeSimulationSetName = phenotypeSimulationSetName;
    }

    public PhenotypeSimulationSetObjectSelectionParams withPhenotypeSimulationSetName(String phenotypeSimulationSetName) {
        this.phenotypeSimulationSetName = phenotypeSimulationSetName;
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

    public PhenotypeSimulationSetObjectSelectionParams withSaveToShock(Long saveToShock) {
        this.saveToShock = saveToShock;
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
        return ((((((((("PhenotypeSimulationSetObjectSelectionParams"+" [workspaceName=")+ workspaceName)+", phenotypeSimulationSetName=")+ phenotypeSimulationSetName)+", saveToShock=")+ saveToShock)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
