
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
 * <p>Original spec-file type: BuildMetabolicModelParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "genome_id",
    "genome_workspace",
    "media_id",
    "media_workspace",
    "fbamodel_output_id",
    "workspace",
    "template_id",
    "template_workspace",
    "coremodel",
    "gapfill_model",
    "thermodynamic_constraints",
    "comprehensive_gapfill",
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
public class BuildMetabolicModelParams {

    @JsonProperty("genome_id")
    private java.lang.String genomeId;
    @JsonProperty("genome_workspace")
    private java.lang.String genomeWorkspace;
    @JsonProperty("media_id")
    private java.lang.String mediaId;
    @JsonProperty("media_workspace")
    private java.lang.String mediaWorkspace;
    @JsonProperty("fbamodel_output_id")
    private java.lang.String fbamodelOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("template_id")
    private java.lang.String templateId;
    @JsonProperty("template_workspace")
    private java.lang.String templateWorkspace;
    @JsonProperty("coremodel")
    private Long coremodel;
    @JsonProperty("gapfill_model")
    private Long gapfillModel;
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

    @JsonProperty("genome_id")
    public java.lang.String getGenomeId() {
        return genomeId;
    }

    @JsonProperty("genome_id")
    public void setGenomeId(java.lang.String genomeId) {
        this.genomeId = genomeId;
    }

    public BuildMetabolicModelParams withGenomeId(java.lang.String genomeId) {
        this.genomeId = genomeId;
        return this;
    }

    @JsonProperty("genome_workspace")
    public java.lang.String getGenomeWorkspace() {
        return genomeWorkspace;
    }

    @JsonProperty("genome_workspace")
    public void setGenomeWorkspace(java.lang.String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
    }

    public BuildMetabolicModelParams withGenomeWorkspace(java.lang.String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
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

    public BuildMetabolicModelParams withMediaId(java.lang.String mediaId) {
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

    public BuildMetabolicModelParams withMediaWorkspace(java.lang.String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
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

    public BuildMetabolicModelParams withFbamodelOutputId(java.lang.String fbamodelOutputId) {
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

    public BuildMetabolicModelParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("template_id")
    public java.lang.String getTemplateId() {
        return templateId;
    }

    @JsonProperty("template_id")
    public void setTemplateId(java.lang.String templateId) {
        this.templateId = templateId;
    }

    public BuildMetabolicModelParams withTemplateId(java.lang.String templateId) {
        this.templateId = templateId;
        return this;
    }

    @JsonProperty("template_workspace")
    public java.lang.String getTemplateWorkspace() {
        return templateWorkspace;
    }

    @JsonProperty("template_workspace")
    public void setTemplateWorkspace(java.lang.String templateWorkspace) {
        this.templateWorkspace = templateWorkspace;
    }

    public BuildMetabolicModelParams withTemplateWorkspace(java.lang.String templateWorkspace) {
        this.templateWorkspace = templateWorkspace;
        return this;
    }

    @JsonProperty("coremodel")
    public Long getCoremodel() {
        return coremodel;
    }

    @JsonProperty("coremodel")
    public void setCoremodel(Long coremodel) {
        this.coremodel = coremodel;
    }

    public BuildMetabolicModelParams withCoremodel(Long coremodel) {
        this.coremodel = coremodel;
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

    public BuildMetabolicModelParams withGapfillModel(Long gapfillModel) {
        this.gapfillModel = gapfillModel;
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

    public BuildMetabolicModelParams withThermodynamicConstraints(Long thermodynamicConstraints) {
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

    public BuildMetabolicModelParams withComprehensiveGapfill(Long comprehensiveGapfill) {
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

    public BuildMetabolicModelParams withCustomBoundList(List<String> customBoundList) {
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

    public BuildMetabolicModelParams withMediaSupplementList(List<String> mediaSupplementList) {
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

    public BuildMetabolicModelParams withExpseriesId(java.lang.String expseriesId) {
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

    public BuildMetabolicModelParams withExpseriesWorkspace(java.lang.String expseriesWorkspace) {
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

    public BuildMetabolicModelParams withExpressionCondition(java.lang.String expressionCondition) {
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

    public BuildMetabolicModelParams withExpThresholdPercentile(Double expThresholdPercentile) {
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

    public BuildMetabolicModelParams withExpThresholdMargin(Double expThresholdMargin) {
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

    public BuildMetabolicModelParams withActivationCoefficient(Double activationCoefficient) {
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

    public BuildMetabolicModelParams withOmega(Double omega) {
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

    public BuildMetabolicModelParams withObjectiveFraction(Double objectiveFraction) {
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

    public BuildMetabolicModelParams withMinimumTargetFlux(Double minimumTargetFlux) {
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

    public BuildMetabolicModelParams withNumberOfSolutions(Long numberOfSolutions) {
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
        return ((((((((((((((((((((((((((((((((((((((((((((((((((("BuildMetabolicModelParams"+" [genomeId=")+ genomeId)+", genomeWorkspace=")+ genomeWorkspace)+", mediaId=")+ mediaId)+", mediaWorkspace=")+ mediaWorkspace)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", templateId=")+ templateId)+", templateWorkspace=")+ templateWorkspace)+", coremodel=")+ coremodel)+", gapfillModel=")+ gapfillModel)+", thermodynamicConstraints=")+ thermodynamicConstraints)+", comprehensiveGapfill=")+ comprehensiveGapfill)+", customBoundList=")+ customBoundList)+", mediaSupplementList=")+ mediaSupplementList)+", expseriesId=")+ expseriesId)+", expseriesWorkspace=")+ expseriesWorkspace)+", expressionCondition=")+ expressionCondition)+", expThresholdPercentile=")+ expThresholdPercentile)+", expThresholdMargin=")+ expThresholdMargin)+", activationCoefficient=")+ activationCoefficient)+", omega=")+ omega)+", objectiveFraction=")+ objectiveFraction)+", minimumTargetFlux=")+ minimumTargetFlux)+", numberOfSolutions=")+ numberOfSolutions)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
