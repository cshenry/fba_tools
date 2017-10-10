
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
 * <p>Original spec-file type: ViewFluxNetworkResults</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "new_report_ref"
})
public class ViewFluxNetworkResults {

    @JsonProperty("new_report_ref")
    private String newReportRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("new_report_ref")
    public String getNewReportRef() {
        return newReportRef;
    }

    @JsonProperty("new_report_ref")
    public void setNewReportRef(String newReportRef) {
        this.newReportRef = newReportRef;
    }

    public ViewFluxNetworkResults withNewReportRef(String newReportRef) {
        this.newReportRef = newReportRef;
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
        return ((((("ViewFluxNetworkResults"+" [newReportRef=")+ newReportRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
