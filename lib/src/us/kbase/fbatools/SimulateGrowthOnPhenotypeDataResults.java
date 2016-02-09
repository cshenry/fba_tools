
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
 * <p>Original spec-file type: SimulateGrowthOnPhenotypeDataResults</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "new_phenotypesim_ref"
})
public class SimulateGrowthOnPhenotypeDataResults {

    @JsonProperty("new_phenotypesim_ref")
    private String newPhenotypesimRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("new_phenotypesim_ref")
    public String getNewPhenotypesimRef() {
        return newPhenotypesimRef;
    }

    @JsonProperty("new_phenotypesim_ref")
    public void setNewPhenotypesimRef(String newPhenotypesimRef) {
        this.newPhenotypesimRef = newPhenotypesimRef;
    }

    public SimulateGrowthOnPhenotypeDataResults withNewPhenotypesimRef(String newPhenotypesimRef) {
        this.newPhenotypesimRef = newPhenotypesimRef;
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
        return ((((("SimulateGrowthOnPhenotypeDataResults"+" [newPhenotypesimRef=")+ newPhenotypesimRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
