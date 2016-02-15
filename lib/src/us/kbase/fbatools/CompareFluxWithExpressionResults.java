
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
 * <p>Original spec-file type: CompareFluxWithExpressionResults</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "new_fbapathwayanalysis_ref"
})
public class CompareFluxWithExpressionResults {

    @JsonProperty("new_fbapathwayanalysis_ref")
    private String newFbapathwayanalysisRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("new_fbapathwayanalysis_ref")
    public String getNewFbapathwayanalysisRef() {
        return newFbapathwayanalysisRef;
    }

    @JsonProperty("new_fbapathwayanalysis_ref")
    public void setNewFbapathwayanalysisRef(String newFbapathwayanalysisRef) {
        this.newFbapathwayanalysisRef = newFbapathwayanalysisRef;
    }

    public CompareFluxWithExpressionResults withNewFbapathwayanalysisRef(String newFbapathwayanalysisRef) {
        this.newFbapathwayanalysisRef = newFbapathwayanalysisRef;
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
        return ((((("CompareFluxWithExpressionResults"+" [newFbapathwayanalysisRef=")+ newFbapathwayanalysisRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
