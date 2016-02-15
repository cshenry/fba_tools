
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
 * <p>Original spec-file type: GapfillMetabolicModelParams</p>
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
    "target_reaction",
    "fbamodel_output_id",
    "workspace",
    "thermodynamic_constraints",
    "comprehensive_gapfill",
    "source_fbamodel_id",
    "source_fbamodel_workspace",
    "feature_ko_list",
    "reaction_ko_list",
    "custom_bound_list",
    "media_supplement_list",
    "expseries_id",
    "expseries_workspace",
    "expression_condition",
    "exp_threshold_percentile",
    "exp_threshold_margin",
    "activation_coefficient",
    "omega",
    "objective_fraction",
    "minimum_target_flux",
    "number_of_solutions"
})
public class GapfillMetabolicModelParams {

    @JsonProperty("fbamodel_id")
    private java.lang.String fbamodelId;
    @JsonProperty("fbamodel_workspace")
    private java.lang.String fbamodelWorkspace;
    @JsonProperty("media_id")
    private java.lang.String mediaId;
    @JsonProperty("media_workspace")
    private java.lang.String mediaWorkspace;
    @JsonProperty("target_reaction")
    private java.lang.String targetReaction;
    @JsonProperty("fbamodel_output_id")
    private java.lang.String fbamodelOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("thermodynamic_constraints")
    private Long thermodynamicConstraints;
    @JsonProperty("comprehensive_gapfill")
    private Long comprehensiveGapfill;
    @JsonProperty("source_fbamodel_id")
    private java.lang.String sourceFbamodelId;
    @JsonProperty("source_fbamodel_workspace")
    private java.lang.String sourceFbamodelWorkspace;
    @JsonProperty("feature_ko_list")
    private List<String> featureKoList;
    @JsonProperty("reaction_ko_list")
    private List<String> reactionKoList;
    @JsonProperty("custom_bound_list")
    private List<String> customBoundList;
    @JsonProperty("media_supplement_list")
    private List<String> mediaSupplementList;
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
    @JsonProperty("objective_fraction")
    private Double objectiveFraction;
    @JsonProperty("minimum_target_flux")
    private Double minimumTargetFlux;
    @JsonProperty("number_of_solutions")
    private Long numberOfSolutions;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("fbamodel_id")
    public java.lang.String getFbamodelId() {
        return fbamodelId;
    }

    @JsonProperty("fbamodel_id")
    public void setFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
    }

    public GapfillMetabolicModelParams withFbamodelId(java.lang.String fbamodelId) {
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

    public GapfillMetabolicModelParams withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
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

    public GapfillMetabolicModelParams withMediaId(java.lang.String mediaId) {
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

    public GapfillMetabolicModelParams withMediaWorkspace(java.lang.String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
        return this;
    }

    @JsonProperty("target_reaction")
    public java.lang.String getTargetReaction() {
        return targetReaction;
    }

    @JsonProperty("target_reaction")
    public void setTargetReaction(java.lang.String targetReaction) {
        this.targetReaction = targetReaction;
    }

    public GapfillMetabolicModelParams withTargetReaction(java.lang.String targetReaction) {
        this.targetReaction = targetReaction;
        return this;
    }

    @JsonProperty("fbamodel_output_id")
    public java.lang.String getFbamodelOutputId() {
        return fbamodelOutputId;
    }

    @JsonProperty("fbamodel_output_id")
    public void setFbamodelOutputId(java.lang.String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
    }

    public GapfillMetabolicModelParams withFbamodelOutputId(java.lang.String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
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

    public GapfillMetabolicModelParams withWorkspace(java.lang.String workspace) {
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

    public GapfillMetabolicModelParams withThermodynamicConstraints(Long thermodynamicConstraints) {
        this.thermodynamicConstraints = thermodynamicConstraints;
        return this;
    }

    @JsonProperty("comprehensive_gapfill")
    public Long getComprehensiveGapfill() {
        return comprehensiveGapfill;
    }

    @JsonProperty("comprehensive_gapfill")
    public void setComprehensiveGapfill(Long comprehensiveGapfill) {
        this.comprehensiveGapfill = comprehensiveGapfill;
    }

    public GapfillMetabolicModelParams withComprehensiveGapfill(Long comprehensiveGapfill) {
        this.comprehensiveGapfill = comprehensiveGapfill;
        return this;
    }

    @JsonProperty("source_fbamodel_id")
    public java.lang.String getSourceFbamodelId() {
        return sourceFbamodelId;
    }

    @JsonProperty("source_fbamodel_id")
    public void setSourceFbamodelId(java.lang.String sourceFbamodelId) {
        this.sourceFbamodelId = sourceFbamodelId;
    }

    public GapfillMetabolicModelParams withSourceFbamodelId(java.lang.String sourceFbamodelId) {
        this.sourceFbamodelId = sourceFbamodelId;
        return this;
    }

    @JsonProperty("source_fbamodel_workspace")
    public java.lang.String getSourceFbamodelWorkspace() {
        return sourceFbamodelWorkspace;
    }

    @JsonProperty("source_fbamodel_workspace")
    public void setSourceFbamodelWorkspace(java.lang.String sourceFbamodelWorkspace) {
        this.sourceFbamodelWorkspace = sourceFbamodelWorkspace;
    }

    public GapfillMetabolicModelParams withSourceFbamodelWorkspace(java.lang.String sourceFbamodelWorkspace) {
        this.sourceFbamodelWorkspace = sourceFbamodelWorkspace;
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

    public GapfillMetabolicModelParams withFeatureKoList(List<String> featureKoList) {
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

    public GapfillMetabolicModelParams withReactionKoList(List<String> reactionKoList) {
        this.reactionKoList = reactionKoList;
        return this;
    }

    @JsonProperty("custom_bound_list")
    public List<String> getCustomBoundList() {
        return customBoundList;
    }

    @JsonProperty("custom_bound_list")
    public void setCustomBoundList(List<String> customBoundList) {
        this.customBoundList = customBoundList;
    }

    public GapfillMetabolicModelParams withCustomBoundList(List<String> customBoundList) {
        this.customBoundList = customBoundList;
        return this;
    }

    @JsonProperty("media_supplement_list")
    public List<String> getMediaSupplementList() {
        return mediaSupplementList;
    }

    @JsonProperty("media_supplement_list")
    public void setMediaSupplementList(List<String> mediaSupplementList) {
        this.mediaSupplementList = mediaSupplementList;
    }

    public GapfillMetabolicModelParams withMediaSupplementList(List<String> mediaSupplementList) {
        this.mediaSupplementList = mediaSupplementList;
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

    public GapfillMetabolicModelParams withExpseriesId(java.lang.String expseriesId) {
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

    public GapfillMetabolicModelParams withExpseriesWorkspace(java.lang.String expseriesWorkspace) {
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

    public GapfillMetabolicModelParams withExpressionCondition(java.lang.String expressionCondition) {
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

    public GapfillMetabolicModelParams withExpThresholdPercentile(Double expThresholdPercentile) {
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

    public GapfillMetabolicModelParams withExpThresholdMargin(Double expThresholdMargin) {
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

    public GapfillMetabolicModelParams withActivationCoefficient(Double activationCoefficient) {
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

    public GapfillMetabolicModelParams withOmega(Double omega) {
        this.omega = omega;
        return this;
    }

    @JsonProperty("objective_fraction")
    public Double getObjectiveFraction() {
        return objectiveFraction;
    }

    @JsonProperty("objective_fraction")
    public void setObjectiveFraction(Double objectiveFraction) {
        this.objectiveFraction = objectiveFraction;
    }

    public GapfillMetabolicModelParams withObjectiveFraction(Double objectiveFraction) {
        this.objectiveFraction = objectiveFraction;
        return this;
    }

    @JsonProperty("minimum_target_flux")
    public Double getMinimumTargetFlux() {
        return minimumTargetFlux;
    }

    @JsonProperty("minimum_target_flux")
    public void setMinimumTargetFlux(Double minimumTargetFlux) {
        this.minimumTargetFlux = minimumTargetFlux;
    }

    public GapfillMetabolicModelParams withMinimumTargetFlux(Double minimumTargetFlux) {
        this.minimumTargetFlux = minimumTargetFlux;
        return this;
    }

    @JsonProperty("number_of_solutions")
    public Long getNumberOfSolutions() {
        return numberOfSolutions;
    }

    @JsonProperty("number_of_solutions")
    public void setNumberOfSolutions(Long numberOfSolutions) {
        this.numberOfSolutions = numberOfSolutions;
    }

    public GapfillMetabolicModelParams withNumberOfSolutions(Long numberOfSolutions) {
        this.numberOfSolutions = numberOfSolutions;
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
        return ((((((((((((((((((((((((((((((((((((((((((((((((((((("GapfillMetabolicModelParams"+" [fbamodelId=")+ fbamodelId)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", mediaId=")+ mediaId)+", mediaWorkspace=")+ mediaWorkspace)+", targetReaction=")+ targetReaction)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", thermodynamicConstraints=")+ thermodynamicConstraints)+", comprehensiveGapfill=")+ comprehensiveGapfill)+", sourceFbamodelId=")+ sourceFbamodelId)+", sourceFbamodelWorkspace=")+ sourceFbamodelWorkspace)+", featureKoList=")+ featureKoList)+", reactionKoList=")+ reactionKoList)+", customBoundList=")+ customBoundList)+", mediaSupplementList=")+ mediaSupplementList)+", expseriesId=")+ expseriesId)+", expseriesWorkspace=")+ expseriesWorkspace)+", expressionCondition=")+ expressionCondition)+", expThresholdPercentile=")+ expThresholdPercentile)+", expThresholdMargin=")+ expThresholdMargin)+", activationCoefficient=")+ activationCoefficient)+", omega=")+ omega)+", objectiveFraction=")+ objectiveFraction)+", minimumTargetFlux=")+ minimumTargetFlux)+", numberOfSolutions=")+ numberOfSolutions)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
