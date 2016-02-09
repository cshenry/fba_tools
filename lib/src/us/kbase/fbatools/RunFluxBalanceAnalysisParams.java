
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
 * <p>Original spec-file type: RunFluxBalanceAnalysisParams</p>
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
    "fba_output_id",
    "workspace",
    "thermodynamic_constraints",
    "fva",
    "minimize_flux",
    "simulate_ko",
    "find_min_media",
    "all_reversible",
    "feature_ko_list",
    "reaction_ko_list",
    "custom_bound_list",
    "media_supplement_list",
    "expseries_id",
    "expseries_workspace",
    "exp_condition",
    "exp_threshold_percentile",
    "exp_threshold_margin",
    "activation_coefficient",
    "omega",
    "objective_fraction",
    "max_c_uptake",
    "max_n_uptake",
    "max_p_uptake",
    "max_s_uptake",
    "max_o_uptake",
    "default_max_uptake",
    "notes",
    "massbalance"
})
public class RunFluxBalanceAnalysisParams {

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
    @JsonProperty("fba_output_id")
    private java.lang.String fbaOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("thermodynamic_constraints")
    private Long thermodynamicConstraints;
    @JsonProperty("fva")
    private Long fva;
    @JsonProperty("minimize_flux")
    private Long minimizeFlux;
    @JsonProperty("simulate_ko")
    private Long simulateKo;
    @JsonProperty("find_min_media")
    private Long findMinMedia;
    @JsonProperty("all_reversible")
    private Long allReversible;
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
    @JsonProperty("exp_condition")
    private java.lang.String expCondition;
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
    @JsonProperty("max_c_uptake")
    private Double maxCUptake;
    @JsonProperty("max_n_uptake")
    private Double maxNUptake;
    @JsonProperty("max_p_uptake")
    private Double maxPUptake;
    @JsonProperty("max_s_uptake")
    private Double maxSUptake;
    @JsonProperty("max_o_uptake")
    private Double maxOUptake;
    @JsonProperty("default_max_uptake")
    private Double defaultMaxUptake;
    @JsonProperty("notes")
    private java.lang.String notes;
    @JsonProperty("massbalance")
    private java.lang.String massbalance;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("fbamodel_id")
    public java.lang.String getFbamodelId() {
        return fbamodelId;
    }

    @JsonProperty("fbamodel_id")
    public void setFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
    }

    public RunFluxBalanceAnalysisParams withFbamodelId(java.lang.String fbamodelId) {
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

    public RunFluxBalanceAnalysisParams withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
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

    public RunFluxBalanceAnalysisParams withMediaId(java.lang.String mediaId) {
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

    public RunFluxBalanceAnalysisParams withMediaWorkspace(java.lang.String mediaWorkspace) {
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

    public RunFluxBalanceAnalysisParams withTargetReaction(java.lang.String targetReaction) {
        this.targetReaction = targetReaction;
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

    public RunFluxBalanceAnalysisParams withFbaOutputId(java.lang.String fbaOutputId) {
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

    public RunFluxBalanceAnalysisParams withWorkspace(java.lang.String workspace) {
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

    public RunFluxBalanceAnalysisParams withThermodynamicConstraints(Long thermodynamicConstraints) {
        this.thermodynamicConstraints = thermodynamicConstraints;
        return this;
    }

    @JsonProperty("fva")
    public Long getFva() {
        return fva;
    }

    @JsonProperty("fva")
    public void setFva(Long fva) {
        this.fva = fva;
    }

    public RunFluxBalanceAnalysisParams withFva(Long fva) {
        this.fva = fva;
        return this;
    }

    @JsonProperty("minimize_flux")
    public Long getMinimizeFlux() {
        return minimizeFlux;
    }

    @JsonProperty("minimize_flux")
    public void setMinimizeFlux(Long minimizeFlux) {
        this.minimizeFlux = minimizeFlux;
    }

    public RunFluxBalanceAnalysisParams withMinimizeFlux(Long minimizeFlux) {
        this.minimizeFlux = minimizeFlux;
        return this;
    }

    @JsonProperty("simulate_ko")
    public Long getSimulateKo() {
        return simulateKo;
    }

    @JsonProperty("simulate_ko")
    public void setSimulateKo(Long simulateKo) {
        this.simulateKo = simulateKo;
    }

    public RunFluxBalanceAnalysisParams withSimulateKo(Long simulateKo) {
        this.simulateKo = simulateKo;
        return this;
    }

    @JsonProperty("find_min_media")
    public Long getFindMinMedia() {
        return findMinMedia;
    }

    @JsonProperty("find_min_media")
    public void setFindMinMedia(Long findMinMedia) {
        this.findMinMedia = findMinMedia;
    }

    public RunFluxBalanceAnalysisParams withFindMinMedia(Long findMinMedia) {
        this.findMinMedia = findMinMedia;
        return this;
    }

    @JsonProperty("all_reversible")
    public Long getAllReversible() {
        return allReversible;
    }

    @JsonProperty("all_reversible")
    public void setAllReversible(Long allReversible) {
        this.allReversible = allReversible;
    }

    public RunFluxBalanceAnalysisParams withAllReversible(Long allReversible) {
        this.allReversible = allReversible;
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

    public RunFluxBalanceAnalysisParams withFeatureKoList(List<String> featureKoList) {
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

    public RunFluxBalanceAnalysisParams withReactionKoList(List<String> reactionKoList) {
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

    public RunFluxBalanceAnalysisParams withCustomBoundList(List<String> customBoundList) {
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

    public RunFluxBalanceAnalysisParams withMediaSupplementList(List<String> mediaSupplementList) {
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

    public RunFluxBalanceAnalysisParams withExpseriesId(java.lang.String expseriesId) {
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

    public RunFluxBalanceAnalysisParams withExpseriesWorkspace(java.lang.String expseriesWorkspace) {
        this.expseriesWorkspace = expseriesWorkspace;
        return this;
    }

    @JsonProperty("exp_condition")
    public java.lang.String getExpCondition() {
        return expCondition;
    }

    @JsonProperty("exp_condition")
    public void setExpCondition(java.lang.String expCondition) {
        this.expCondition = expCondition;
    }

    public RunFluxBalanceAnalysisParams withExpCondition(java.lang.String expCondition) {
        this.expCondition = expCondition;
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

    public RunFluxBalanceAnalysisParams withExpThresholdPercentile(Double expThresholdPercentile) {
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

    public RunFluxBalanceAnalysisParams withExpThresholdMargin(Double expThresholdMargin) {
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

    public RunFluxBalanceAnalysisParams withActivationCoefficient(Double activationCoefficient) {
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

    public RunFluxBalanceAnalysisParams withOmega(Double omega) {
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

    public RunFluxBalanceAnalysisParams withObjectiveFraction(Double objectiveFraction) {
        this.objectiveFraction = objectiveFraction;
        return this;
    }

    @JsonProperty("max_c_uptake")
    public Double getMaxCUptake() {
        return maxCUptake;
    }

    @JsonProperty("max_c_uptake")
    public void setMaxCUptake(Double maxCUptake) {
        this.maxCUptake = maxCUptake;
    }

    public RunFluxBalanceAnalysisParams withMaxCUptake(Double maxCUptake) {
        this.maxCUptake = maxCUptake;
        return this;
    }

    @JsonProperty("max_n_uptake")
    public Double getMaxNUptake() {
        return maxNUptake;
    }

    @JsonProperty("max_n_uptake")
    public void setMaxNUptake(Double maxNUptake) {
        this.maxNUptake = maxNUptake;
    }

    public RunFluxBalanceAnalysisParams withMaxNUptake(Double maxNUptake) {
        this.maxNUptake = maxNUptake;
        return this;
    }

    @JsonProperty("max_p_uptake")
    public Double getMaxPUptake() {
        return maxPUptake;
    }

    @JsonProperty("max_p_uptake")
    public void setMaxPUptake(Double maxPUptake) {
        this.maxPUptake = maxPUptake;
    }

    public RunFluxBalanceAnalysisParams withMaxPUptake(Double maxPUptake) {
        this.maxPUptake = maxPUptake;
        return this;
    }

    @JsonProperty("max_s_uptake")
    public Double getMaxSUptake() {
        return maxSUptake;
    }

    @JsonProperty("max_s_uptake")
    public void setMaxSUptake(Double maxSUptake) {
        this.maxSUptake = maxSUptake;
    }

    public RunFluxBalanceAnalysisParams withMaxSUptake(Double maxSUptake) {
        this.maxSUptake = maxSUptake;
        return this;
    }

    @JsonProperty("max_o_uptake")
    public Double getMaxOUptake() {
        return maxOUptake;
    }

    @JsonProperty("max_o_uptake")
    public void setMaxOUptake(Double maxOUptake) {
        this.maxOUptake = maxOUptake;
    }

    public RunFluxBalanceAnalysisParams withMaxOUptake(Double maxOUptake) {
        this.maxOUptake = maxOUptake;
        return this;
    }

    @JsonProperty("default_max_uptake")
    public Double getDefaultMaxUptake() {
        return defaultMaxUptake;
    }

    @JsonProperty("default_max_uptake")
    public void setDefaultMaxUptake(Double defaultMaxUptake) {
        this.defaultMaxUptake = defaultMaxUptake;
    }

    public RunFluxBalanceAnalysisParams withDefaultMaxUptake(Double defaultMaxUptake) {
        this.defaultMaxUptake = defaultMaxUptake;
        return this;
    }

    @JsonProperty("notes")
    public java.lang.String getNotes() {
        return notes;
    }

    @JsonProperty("notes")
    public void setNotes(java.lang.String notes) {
        this.notes = notes;
    }

    public RunFluxBalanceAnalysisParams withNotes(java.lang.String notes) {
        this.notes = notes;
        return this;
    }

    @JsonProperty("massbalance")
    public java.lang.String getMassbalance() {
        return massbalance;
    }

    @JsonProperty("massbalance")
    public void setMassbalance(java.lang.String massbalance) {
        this.massbalance = massbalance;
    }

    public RunFluxBalanceAnalysisParams withMassbalance(java.lang.String massbalance) {
        this.massbalance = massbalance;
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
        return ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((("RunFluxBalanceAnalysisParams"+" [fbamodelId=")+ fbamodelId)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", mediaId=")+ mediaId)+", mediaWorkspace=")+ mediaWorkspace)+", targetReaction=")+ targetReaction)+", fbaOutputId=")+ fbaOutputId)+", workspace=")+ workspace)+", thermodynamicConstraints=")+ thermodynamicConstraints)+", fva=")+ fva)+", minimizeFlux=")+ minimizeFlux)+", simulateKo=")+ simulateKo)+", findMinMedia=")+ findMinMedia)+", allReversible=")+ allReversible)+", featureKoList=")+ featureKoList)+", reactionKoList=")+ reactionKoList)+", customBoundList=")+ customBoundList)+", mediaSupplementList=")+ mediaSupplementList)+", expseriesId=")+ expseriesId)+", expseriesWorkspace=")+ expseriesWorkspace)+", expCondition=")+ expCondition)+", expThresholdPercentile=")+ expThresholdPercentile)+", expThresholdMargin=")+ expThresholdMargin)+", activationCoefficient=")+ activationCoefficient)+", omega=")+ omega)+", objectiveFraction=")+ objectiveFraction)+", maxCUptake=")+ maxCUptake)+", maxNUptake=")+ maxNUptake)+", maxPUptake=")+ maxPUptake)+", maxSUptake=")+ maxSUptake)+", maxOUptake=")+ maxOUptake)+", defaultMaxUptake=")+ defaultMaxUptake)+", notes=")+ notes)+", massbalance=")+ massbalance)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
