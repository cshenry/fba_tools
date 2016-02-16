
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
 * <p>Original spec-file type: CompareFluxWithExpressionParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fba_id",
    "fba_workspace",
    "expseries_id",
    "expseries_workspace",
    "expression_condition",
    "exp_threshold_percentile",
    "estimate_threshold",
    "maximize_agreement",
    "fbapathwayanalysis_output_id",
    "workspace"
})
public class CompareFluxWithExpressionParams {

    @JsonProperty("fba_id")
    private String fbaId;
    @JsonProperty("fba_workspace")
    private String fbaWorkspace;
    @JsonProperty("expseries_id")
    private String expseriesId;
    @JsonProperty("expseries_workspace")
    private String expseriesWorkspace;
    @JsonProperty("expression_condition")
    private String expressionCondition;
    @JsonProperty("exp_threshold_percentile")
    private Double expThresholdPercentile;
    @JsonProperty("estimate_threshold")
    private Long estimateThreshold;
    @JsonProperty("maximize_agreement")
    private Long maximizeAgreement;
    @JsonProperty("fbapathwayanalysis_output_id")
    private String fbapathwayanalysisOutputId;
    @JsonProperty("workspace")
    private String workspace;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("fba_id")
    public String getFbaId() {
        return fbaId;
    }

    @JsonProperty("fba_id")
    public void setFbaId(String fbaId) {
        this.fbaId = fbaId;
    }

    public CompareFluxWithExpressionParams withFbaId(String fbaId) {
        this.fbaId = fbaId;
        return this;
    }

    @JsonProperty("fba_workspace")
    public String getFbaWorkspace() {
        return fbaWorkspace;
    }

    @JsonProperty("fba_workspace")
    public void setFbaWorkspace(String fbaWorkspace) {
        this.fbaWorkspace = fbaWorkspace;
    }

    public CompareFluxWithExpressionParams withFbaWorkspace(String fbaWorkspace) {
        this.fbaWorkspace = fbaWorkspace;
        return this;
    }

    @JsonProperty("expseries_id")
    public String getExpseriesId() {
        return expseriesId;
    }

    @JsonProperty("expseries_id")
    public void setExpseriesId(String expseriesId) {
        this.expseriesId = expseriesId;
    }

    public CompareFluxWithExpressionParams withExpseriesId(String expseriesId) {
        this.expseriesId = expseriesId;
        return this;
    }

    @JsonProperty("expseries_workspace")
    public String getExpseriesWorkspace() {
        return expseriesWorkspace;
    }

    @JsonProperty("expseries_workspace")
    public void setExpseriesWorkspace(String expseriesWorkspace) {
        this.expseriesWorkspace = expseriesWorkspace;
    }

    public CompareFluxWithExpressionParams withExpseriesWorkspace(String expseriesWorkspace) {
        this.expseriesWorkspace = expseriesWorkspace;
        return this;
    }

    @JsonProperty("expression_condition")
    public String getExpressionCondition() {
        return expressionCondition;
    }

    @JsonProperty("expression_condition")
    public void setExpressionCondition(String expressionCondition) {
        this.expressionCondition = expressionCondition;
    }

    public CompareFluxWithExpressionParams withExpressionCondition(String expressionCondition) {
        this.expressionCondition = expressionCondition;
        return this;
    }

    @JsonProperty("exp_threshold_percentile")
    public Double getExpThresholdPercentile() {
        return expThresholdPercentile;
    }

    @JsonProperty("exp_threshold_percentile")
    public void setExpThresholdPercentile(Double expThresholdPercentile) {
        this.expThresholdPercentile = expThresholdPercentile;
    }

    public CompareFluxWithExpressionParams withExpThresholdPercentile(Double expThresholdPercentile) {
        this.expThresholdPercentile = expThresholdPercentile;
        return this;
    }

    @JsonProperty("estimate_threshold")
    public Long getEstimateThreshold() {
        return estimateThreshold;
    }

    @JsonProperty("estimate_threshold")
    public void setEstimateThreshold(Long estimateThreshold) {
        this.estimateThreshold = estimateThreshold;
    }

    public CompareFluxWithExpressionParams withEstimateThreshold(Long estimateThreshold) {
        this.estimateThreshold = estimateThreshold;
        return this;
    }

    @JsonProperty("maximize_agreement")
    public Long getMaximizeAgreement() {
        return maximizeAgreement;
    }

    @JsonProperty("maximize_agreement")
    public void setMaximizeAgreement(Long maximizeAgreement) {
        this.maximizeAgreement = maximizeAgreement;
    }

    public CompareFluxWithExpressionParams withMaximizeAgreement(Long maximizeAgreement) {
        this.maximizeAgreement = maximizeAgreement;
        return this;
    }

    @JsonProperty("fbapathwayanalysis_output_id")
    public String getFbapathwayanalysisOutputId() {
        return fbapathwayanalysisOutputId;
    }

    @JsonProperty("fbapathwayanalysis_output_id")
    public void setFbapathwayanalysisOutputId(String fbapathwayanalysisOutputId) {
        this.fbapathwayanalysisOutputId = fbapathwayanalysisOutputId;
    }

    public CompareFluxWithExpressionParams withFbapathwayanalysisOutputId(String fbapathwayanalysisOutputId) {
        this.fbapathwayanalysisOutputId = fbapathwayanalysisOutputId;
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

    public CompareFluxWithExpressionParams withWorkspace(String workspace) {
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
        return ((((((((((((((((((((((("CompareFluxWithExpressionParams"+" [fbaId=")+ fbaId)+", fbaWorkspace=")+ fbaWorkspace)+", expseriesId=")+ expseriesId)+", expseriesWorkspace=")+ expseriesWorkspace)+", expressionCondition=")+ expressionCondition)+", expThresholdPercentile=")+ expThresholdPercentile)+", estimateThreshold=")+ estimateThreshold)+", maximizeAgreement=")+ maximizeAgreement)+", fbapathwayanalysisOutputId=")+ fbapathwayanalysisOutputId)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
