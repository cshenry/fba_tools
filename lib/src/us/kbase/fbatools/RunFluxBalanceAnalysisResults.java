
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
 * <p>Original spec-file type: RunFluxBalanceAnalysisResults</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "new_fba_ref",
    "objective"
})
public class RunFluxBalanceAnalysisResults {

    @JsonProperty("new_fba_ref")
    private String newFbaRef;
    @JsonProperty("objective")
    private Long objective;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("new_fba_ref")
    public String getNewFbaRef() {
        return newFbaRef;
    }

    @JsonProperty("new_fba_ref")
    public void setNewFbaRef(String newFbaRef) {
        this.newFbaRef = newFbaRef;
    }

    public RunFluxBalanceAnalysisResults withNewFbaRef(String newFbaRef) {
        this.newFbaRef = newFbaRef;
        return this;
    }

    @JsonProperty("objective")
    public Long getObjective() {
        return objective;
    }

    @JsonProperty("objective")
    public void setObjective(Long objective) {
        this.objective = objective;
    }

    public RunFluxBalanceAnalysisResults withObjective(Long objective) {
        this.objective = objective;
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
        return ((((((("RunFluxBalanceAnalysisResults"+" [newFbaRef=")+ newFbaRef)+", objective=")+ objective)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
