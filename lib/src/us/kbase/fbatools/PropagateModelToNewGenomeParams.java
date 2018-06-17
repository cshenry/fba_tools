
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
 * <p>Original spec-file type: PropagateModelToNewGenomeParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fbamodel_id",
    "fbamodel_workspace",
    "proteincomparison_id",
    "proteincomparison_workspace",
    "fbamodel_output_id",
    "workspace",
    "keep_nogene_rxn",
    "gapfill_model",
    "media_id",
    "media_workspace",
    "thermodynamic_constraints",
    "comprehensive_gapfill",
    "custom_bound_list",
    "media_supplement_list",
    "expseries_id",
    "expseries_workspace",
    "expression_condition",
    "translation_policy",
    "exp_threshold_percentile",
    "exp_threshold_margin",
    "activation_coefficient",
    "omega",
    "objective_fraction",
    "minimum_target_flux",
    "number_of_solutions"
})
public class PropagateModelToNewGenomeParams {

    @JsonProperty("fbamodel_id")
    private java.lang.String fbamodelId;
    @JsonProperty("fbamodel_workspace")
    private java.lang.String fbamodelWorkspace;
    @JsonProperty("proteincomparison_id")
    private java.lang.String proteincomparisonId;
    @JsonProperty("proteincomparison_workspace")
    private java.lang.String proteincomparisonWorkspace;
    @JsonProperty("fbamodel_output_id")
    private java.lang.String fbamodelOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("keep_nogene_rxn")
    private Long keepNogeneRxn;
    @JsonProperty("gapfill_model")
    private Long gapfillModel;
    @JsonProperty("media_id")
    private java.lang.String mediaId;
    @JsonProperty("media_workspace")
    private java.lang.String mediaWorkspace;
    @JsonProperty("thermodynamic_constraints")
    private Long thermodynamicConstraints;
    @JsonProperty("comprehensive_gapfill")
    private Long comprehensiveGapfill;
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
    @JsonProperty("translation_policy")
    private java.lang.String translationPolicy;
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

    public PropagateModelToNewGenomeParams withFbamodelId(java.lang.String fbamodelId) {
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

    public PropagateModelToNewGenomeParams withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
        return this;
    }

    @JsonProperty("proteincomparison_id")
    public java.lang.String getProteincomparisonId() {
        return proteincomparisonId;
    }

    @JsonProperty("proteincomparison_id")
    public void setProteincomparisonId(java.lang.String proteincomparisonId) {
        this.proteincomparisonId = proteincomparisonId;
    }

    public PropagateModelToNewGenomeParams withProteincomparisonId(java.lang.String proteincomparisonId) {
        this.proteincomparisonId = proteincomparisonId;
        return this;
    }

    @JsonProperty("proteincomparison_workspace")
    public java.lang.String getProteincomparisonWorkspace() {
        return proteincomparisonWorkspace;
    }

    @JsonProperty("proteincomparison_workspace")
    public void setProteincomparisonWorkspace(java.lang.String proteincomparisonWorkspace) {
        this.proteincomparisonWorkspace = proteincomparisonWorkspace;
    }

    public PropagateModelToNewGenomeParams withProteincomparisonWorkspace(java.lang.String proteincomparisonWorkspace) {
        this.proteincomparisonWorkspace = proteincomparisonWorkspace;
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

    public PropagateModelToNewGenomeParams withFbamodelOutputId(java.lang.String fbamodelOutputId) {
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

    public PropagateModelToNewGenomeParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("keep_nogene_rxn")
    public Long getKeepNogeneRxn() {
        return keepNogeneRxn;
    }

    @JsonProperty("keep_nogene_rxn")
    public void setKeepNogeneRxn(Long keepNogeneRxn) {
        this.keepNogeneRxn = keepNogeneRxn;
    }

    public PropagateModelToNewGenomeParams withKeepNogeneRxn(Long keepNogeneRxn) {
        this.keepNogeneRxn = keepNogeneRxn;
        return this;
    }

    @JsonProperty("gapfill_model")
    public Long getGapfillModel() {
        return gapfillModel;
    }

    @JsonProperty("gapfill_model")
    public void setGapfillModel(Long gapfillModel) {
        this.gapfillModel = gapfillModel;
    }

    public PropagateModelToNewGenomeParams withGapfillModel(Long gapfillModel) {
        this.gapfillModel = gapfillModel;
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

    public PropagateModelToNewGenomeParams withMediaId(java.lang.String mediaId) {
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

    public PropagateModelToNewGenomeParams withMediaWorkspace(java.lang.String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
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

    public PropagateModelToNewGenomeParams withThermodynamicConstraints(Long thermodynamicConstraints) {
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

    public PropagateModelToNewGenomeParams withComprehensiveGapfill(Long comprehensiveGapfill) {
        this.comprehensiveGapfill = comprehensiveGapfill;
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

    public PropagateModelToNewGenomeParams withCustomBoundList(List<String> customBoundList) {
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

    public PropagateModelToNewGenomeParams withMediaSupplementList(List<String> mediaSupplementList) {
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

    public PropagateModelToNewGenomeParams withExpseriesId(java.lang.String expseriesId) {
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

    public PropagateModelToNewGenomeParams withExpseriesWorkspace(java.lang.String expseriesWorkspace) {
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

    public PropagateModelToNewGenomeParams withExpressionCondition(java.lang.String expressionCondition) {
        this.expressionCondition = expressionCondition;
        return this;
    }

    @JsonProperty("translation_policy")
    public java.lang.String getTranslationPolicy() {
        return translationPolicy;
    }

    @JsonProperty("translation_policy")
    public void setTranslationPolicy(java.lang.String translationPolicy) {
        this.translationPolicy = translationPolicy;
    }

    public PropagateModelToNewGenomeParams withTranslationPolicy(java.lang.String translationPolicy) {
        this.translationPolicy = translationPolicy;
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

    public PropagateModelToNewGenomeParams withExpThresholdPercentile(Double expThresholdPercentile) {
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

    public PropagateModelToNewGenomeParams withExpThresholdMargin(Double expThresholdMargin) {
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

    public PropagateModelToNewGenomeParams withActivationCoefficient(Double activationCoefficient) {
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

    public PropagateModelToNewGenomeParams withOmega(Double omega) {
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

    public PropagateModelToNewGenomeParams withObjectiveFraction(Double objectiveFraction) {
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

    public PropagateModelToNewGenomeParams withMinimumTargetFlux(Double minimumTargetFlux) {
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

    public PropagateModelToNewGenomeParams withNumberOfSolutions(Long numberOfSolutions) {
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
        return ((((((((((((((((((((((((((((((((((((((((((((((((((((("PropagateModelToNewGenomeParams"+" [fbamodelId=")+ fbamodelId)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", proteincomparisonId=")+ proteincomparisonId)+", proteincomparisonWorkspace=")+ proteincomparisonWorkspace)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", keepNogeneRxn=")+ keepNogeneRxn)+", gapfillModel=")+ gapfillModel)+", mediaId=")+ mediaId)+", mediaWorkspace=")+ mediaWorkspace)+", thermodynamicConstraints=")+ thermodynamicConstraints)+", comprehensiveGapfill=")+ comprehensiveGapfill)+", customBoundList=")+ customBoundList)+", mediaSupplementList=")+ mediaSupplementList)+", expseriesId=")+ expseriesId)+", expseriesWorkspace=")+ expseriesWorkspace)+", expressionCondition=")+ expressionCondition)+", translationPolicy=")+ translationPolicy)+", expThresholdPercentile=")+ expThresholdPercentile)+", expThresholdMargin=")+ expThresholdMargin)+", activationCoefficient=")+ activationCoefficient)+", omega=")+ omega)+", objectiveFraction=")+ objectiveFraction)+", minimumTargetFlux=")+ minimumTargetFlux)+", numberOfSolutions=")+ numberOfSolutions)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
