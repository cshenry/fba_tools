
package us.kbase.fbatools;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: PredictMetaboliteBiosynthesisPathwayInput</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fbamodel_id",
    "fbamodel_workspace",
    "media_id",
    "media_workspace",
    "target_metabolite_list",
    "source_metabolite_list",
    "fba_output_id",
    "workspace",
    "thermodynamic_constraints",
    "feature_ko_list",
    "reaction_ko_list",
    "expseries_id",
    "expseries_workspace",
    "expression_condition",
    "exp_threshold_percentile",
    "exp_threshold_margin",
    "activation_coefficient",
    "omega"
})
public class PredictMetaboliteBiosynthesisPathwayInput {

    @JsonProperty("fbamodel_id")
    private java.lang.String fbamodelId;
    @JsonProperty("fbamodel_workspace")
    private java.lang.String fbamodelWorkspace;
    @JsonProperty("media_id")
    private java.lang.String mediaId;
    @JsonProperty("media_workspace")
    private java.lang.String mediaWorkspace;
    @JsonProperty("target_metabolite_list")
    private List<String> targetMetaboliteList;
    @JsonProperty("source_metabolite_list")
    private List<String> sourceMetaboliteList;
    @JsonProperty("fba_output_id")
    private java.lang.String fbaOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("thermodynamic_constraints")
    private Long thermodynamicConstraints;
    @JsonProperty("feature_ko_list")
    private List<String> featureKoList;
    @JsonProperty("reaction_ko_list")
    private List<String> reactionKoList;
    @JsonProperty("expseries_id")
    private java.lang.String expseriesId;
    @JsonProperty("expseries_workspace")
    private java.lang.String expseriesWorkspace;
    @JsonProperty("expression_condition")
    private java.lang.String expressionCondition;
    @JsonProperty("exp_threshold_percentile")
    private Double expThresholdPercentile;
    @JsonProperty("exp_threshold_margin")
    private Double expThresholdMargin;
    @JsonProperty("activation_coefficient")
    private Double activationCoefficient;
    @JsonProperty("omega")
    private Double omega;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("fbamodel_id")
    public java.lang.String getFbamodelId() {
        return fbamodelId;
    }

    @JsonProperty("fbamodel_id")
    public void setFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
        return this;
    }

    @JsonProperty("fbamodel_workspace")
    public java.lang.String getFbamodelWorkspace() {
        return fbamodelWorkspace;
    }

    @JsonProperty("fbamodel_workspace")
    public void setFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
        return this;
    }

    @JsonProperty("media_id")
    public java.lang.String getMediaId() {
        return mediaId;
    }

    @JsonProperty("media_id")
    public void setMediaId(java.lang.String mediaId) {
        this.mediaId = mediaId;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withMediaId(java.lang.String mediaId) {
        this.mediaId = mediaId;
        return this;
    }

    @JsonProperty("media_workspace")
    public java.lang.String getMediaWorkspace() {
        return mediaWorkspace;
    }

    @JsonProperty("media_workspace")
    public void setMediaWorkspace(java.lang.String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withMediaWorkspace(java.lang.String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
        return this;
    }

    @JsonProperty("target_metabolite_list")
    public List<String> getTargetMetaboliteList() {
        return targetMetaboliteList;
    }

    @JsonProperty("target_metabolite_list")
    public void setTargetMetaboliteList(List<String> targetMetaboliteList) {
        this.targetMetaboliteList = targetMetaboliteList;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withTargetMetaboliteList(List<String> targetMetaboliteList) {
        this.targetMetaboliteList = targetMetaboliteList;
        return this;
    }

    @JsonProperty("source_metabolite_list")
    public List<String> getSourceMetaboliteList() {
        return sourceMetaboliteList;
    }

    @JsonProperty("source_metabolite_list")
    public void setSourceMetaboliteList(List<String> sourceMetaboliteList) {
        this.sourceMetaboliteList = sourceMetaboliteList;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withSourceMetaboliteList(List<String> sourceMetaboliteList) {
        this.sourceMetaboliteList = sourceMetaboliteList;
        return this;
    }

    @JsonProperty("fba_output_id")
    public java.lang.String getFbaOutputId() {
        return fbaOutputId;
    }

    @JsonProperty("fba_output_id")
    public void setFbaOutputId(java.lang.String fbaOutputId) {
        this.fbaOutputId = fbaOutputId;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withFbaOutputId(java.lang.String fbaOutputId) {
        this.fbaOutputId = fbaOutputId;
        return this;
    }

    @JsonProperty("workspace")
    public java.lang.String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("thermodynamic_constraints")
    public Long getThermodynamicConstraints() {
        return thermodynamicConstraints;
    }

    @JsonProperty("thermodynamic_constraints")
    public void setThermodynamicConstraints(Long thermodynamicConstraints) {
        this.thermodynamicConstraints = thermodynamicConstraints;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withThermodynamicConstraints(Long thermodynamicConstraints) {
        this.thermodynamicConstraints = thermodynamicConstraints;
        return this;
    }

    @JsonProperty("feature_ko_list")
    public List<String> getFeatureKoList() {
        return featureKoList;
    }

    @JsonProperty("feature_ko_list")
    public void setFeatureKoList(List<String> featureKoList) {
        this.featureKoList = featureKoList;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withFeatureKoList(List<String> featureKoList) {
        this.featureKoList = featureKoList;
        return this;
    }

    @JsonProperty("reaction_ko_list")
    public List<String> getReactionKoList() {
        return reactionKoList;
    }

    @JsonProperty("reaction_ko_list")
    public void setReactionKoList(List<String> reactionKoList) {
        this.reactionKoList = reactionKoList;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withReactionKoList(List<String> reactionKoList) {
        this.reactionKoList = reactionKoList;
        return this;
    }

    @JsonProperty("expseries_id")
    public java.lang.String getExpseriesId() {
        return expseriesId;
    }

    @JsonProperty("expseries_id")
    public void setExpseriesId(java.lang.String expseriesId) {
        this.expseriesId = expseriesId;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withExpseriesId(java.lang.String expseriesId) {
        this.expseriesId = expseriesId;
        return this;
    }

    @JsonProperty("expseries_workspace")
    public java.lang.String getExpseriesWorkspace() {
        return expseriesWorkspace;
    }

    @JsonProperty("expseries_workspace")
    public void setExpseriesWorkspace(java.lang.String expseriesWorkspace) {
        this.expseriesWorkspace = expseriesWorkspace;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withExpseriesWorkspace(java.lang.String expseriesWorkspace) {
        this.expseriesWorkspace = expseriesWorkspace;
        return this;
    }

    @JsonProperty("expression_condition")
    public java.lang.String getExpressionCondition() {
        return expressionCondition;
    }

    @JsonProperty("expression_condition")
    public void setExpressionCondition(java.lang.String expressionCondition) {
        this.expressionCondition = expressionCondition;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withExpressionCondition(java.lang.String expressionCondition) {
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

    public PredictMetaboliteBiosynthesisPathwayInput withExpThresholdPercentile(Double expThresholdPercentile) {
        this.expThresholdPercentile = expThresholdPercentile;
        return this;
    }

    @JsonProperty("exp_threshold_margin")
    public Double getExpThresholdMargin() {
        return expThresholdMargin;
    }

    @JsonProperty("exp_threshold_margin")
    public void setExpThresholdMargin(Double expThresholdMargin) {
        this.expThresholdMargin = expThresholdMargin;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withExpThresholdMargin(Double expThresholdMargin) {
        this.expThresholdMargin = expThresholdMargin;
        return this;
    }

    @JsonProperty("activation_coefficient")
    public Double getActivationCoefficient() {
        return activationCoefficient;
    }

    @JsonProperty("activation_coefficient")
    public void setActivationCoefficient(Double activationCoefficient) {
        this.activationCoefficient = activationCoefficient;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withActivationCoefficient(Double activationCoefficient) {
        this.activationCoefficient = activationCoefficient;
        return this;
    }

    @JsonProperty("omega")
    public Double getOmega() {
        return omega;
    }

    @JsonProperty("omega")
    public void setOmega(Double omega) {
        this.omega = omega;
    }

    public PredictMetaboliteBiosynthesisPathwayInput withOmega(Double omega) {
        this.omega = omega;
        return this;
    }

    @JsonAnyGetter
    public Map<java.lang.String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(java.lang.String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public java.lang.String toString() {
        return ((((((((((((((((((((((((((((((((((((((("PredictMetaboliteBiosynthesisPathwayInput"+" [fbamodelId=")+ fbamodelId)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", mediaId=")+ mediaId)+", mediaWorkspace=")+ mediaWorkspace)+", targetMetaboliteList=")+ targetMetaboliteList)+", sourceMetaboliteList=")+ sourceMetaboliteList)+", fbaOutputId=")+ fbaOutputId)+", workspace=")+ workspace)+", thermodynamicConstraints=")+ thermodynamicConstraints)+", featureKoList=")+ featureKoList)+", reactionKoList=")+ reactionKoList)+", expseriesId=")+ expseriesId)+", expseriesWorkspace=")+ expseriesWorkspace)+", expressionCondition=")+ expressionCondition)+", expThresholdPercentile=")+ expThresholdPercentile)+", expThresholdMargin=")+ expThresholdMargin)+", activationCoefficient=")+ activationCoefficient)+", omega=")+ omega)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
