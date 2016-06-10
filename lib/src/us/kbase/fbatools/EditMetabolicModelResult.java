
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
 * <p>Original spec-file type: EditMetabolicModelResult</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "report_name",
    "report_ref",
    "new_fbamodel_ref"
})
public class EditMetabolicModelResult {

    @JsonProperty("report_name")
    private String reportName;
    @JsonProperty("report_ref")
    private String reportRef;
    @JsonProperty("new_fbamodel_ref")
    private String newFbamodelRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("report_name")
    public String getReportName() {
        return reportName;
    }

    @JsonProperty("report_name")
    public void setReportName(String reportName) {
        this.reportName = reportName;
    }

    public EditMetabolicModelResult withReportName(String reportName) {
        this.reportName = reportName;
        return this;
    }

    @JsonProperty("report_ref")
    public String getReportRef() {
        return reportRef;
    }

    @JsonProperty("report_ref")
    public void setReportRef(String reportRef) {
        this.reportRef = reportRef;
    }

    public EditMetabolicModelResult withReportRef(String reportRef) {
        this.reportRef = reportRef;
        return this;
    }

    @JsonProperty("new_fbamodel_ref")
    public String getNewFbamodelRef() {
        return newFbamodelRef;
    }

    @JsonProperty("new_fbamodel_ref")
    public void setNewFbamodelRef(String newFbamodelRef) {
        this.newFbamodelRef = newFbamodelRef;
    }

    public EditMetabolicModelResult withNewFbamodelRef(String newFbamodelRef) {
        this.newFbamodelRef = newFbamodelRef;
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
        return ((((((((("EditMetabolicModelResult"+" [reportName=")+ reportName)+", reportRef=")+ reportRef)+", newFbamodelRef=")+ newFbamodelRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
