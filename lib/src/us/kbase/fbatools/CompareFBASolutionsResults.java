
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
 * <p>Original spec-file type: CompareFBASolutionsResults</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "new_fbacomparison_ref"
})
public class CompareFBASolutionsResults {

    @JsonProperty("new_fbacomparison_ref")
    private String newFbacomparisonRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("new_fbacomparison_ref")
    public String getNewFbacomparisonRef() {
        return newFbacomparisonRef;
    }

    @JsonProperty("new_fbacomparison_ref")
    public void setNewFbacomparisonRef(String newFbacomparisonRef) {
        this.newFbacomparisonRef = newFbacomparisonRef;
    }

    public CompareFBASolutionsResults withNewFbacomparisonRef(String newFbacomparisonRef) {
        this.newFbacomparisonRef = newFbacomparisonRef;
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
        return ((((("CompareFBASolutionsResults"+" [newFbacomparisonRef=")+ newFbacomparisonRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
