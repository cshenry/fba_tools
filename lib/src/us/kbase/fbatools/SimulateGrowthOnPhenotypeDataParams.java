
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
 * <p>Original spec-file type: SimulateGrowthOnPhenotypeDataParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fbamodel_id",
    "fbamodel_workspace",
    "phenotypeset_id",
    "phenotypeset_workspace",
    "phenotypesim_output_id",
    "workspace",
    "all_reversible",
    "feature_ko_list",
    "reaction_ko_list",
    "custom_bound_list",
    "media_supplement_list"
})
public class SimulateGrowthOnPhenotypeDataParams {

    @JsonProperty("fbamodel_id")
    private java.lang.String fbamodelId;
    @JsonProperty("fbamodel_workspace")
    private java.lang.String fbamodelWorkspace;
    @JsonProperty("phenotypeset_id")
    private java.lang.String phenotypesetId;
    @JsonProperty("phenotypeset_workspace")
    private java.lang.String phenotypesetWorkspace;
    @JsonProperty("phenotypesim_output_id")
    private java.lang.String phenotypesimOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
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
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("fbamodel_id")
    public java.lang.String getFbamodelId() {
        return fbamodelId;
    }

    @JsonProperty("fbamodel_id")
    public void setFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
    }

    public SimulateGrowthOnPhenotypeDataParams withFbamodelId(java.lang.String fbamodelId) {
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

    public SimulateGrowthOnPhenotypeDataParams withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
        return this;
    }

    @JsonProperty("phenotypeset_id")
    public java.lang.String getPhenotypesetId() {
        return phenotypesetId;
    }

    @JsonProperty("phenotypeset_id")
    public void setPhenotypesetId(java.lang.String phenotypesetId) {
        this.phenotypesetId = phenotypesetId;
    }

    public SimulateGrowthOnPhenotypeDataParams withPhenotypesetId(java.lang.String phenotypesetId) {
        this.phenotypesetId = phenotypesetId;
        return this;
    }

    @JsonProperty("phenotypeset_workspace")
    public java.lang.String getPhenotypesetWorkspace() {
        return phenotypesetWorkspace;
    }

    @JsonProperty("phenotypeset_workspace")
    public void setPhenotypesetWorkspace(java.lang.String phenotypesetWorkspace) {
        this.phenotypesetWorkspace = phenotypesetWorkspace;
    }

    public SimulateGrowthOnPhenotypeDataParams withPhenotypesetWorkspace(java.lang.String phenotypesetWorkspace) {
        this.phenotypesetWorkspace = phenotypesetWorkspace;
        return this;
    }

    @JsonProperty("phenotypesim_output_id")
    public java.lang.String getPhenotypesimOutputId() {
        return phenotypesimOutputId;
    }

    @JsonProperty("phenotypesim_output_id")
    public void setPhenotypesimOutputId(java.lang.String phenotypesimOutputId) {
        this.phenotypesimOutputId = phenotypesimOutputId;
    }

    public SimulateGrowthOnPhenotypeDataParams withPhenotypesimOutputId(java.lang.String phenotypesimOutputId) {
        this.phenotypesimOutputId = phenotypesimOutputId;
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

    public SimulateGrowthOnPhenotypeDataParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
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

    public SimulateGrowthOnPhenotypeDataParams withAllReversible(Long allReversible) {
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

    public SimulateGrowthOnPhenotypeDataParams withFeatureKoList(List<String> featureKoList) {
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

    public SimulateGrowthOnPhenotypeDataParams withReactionKoList(List<String> reactionKoList) {
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

    public SimulateGrowthOnPhenotypeDataParams withCustomBoundList(List<String> customBoundList) {
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

    public SimulateGrowthOnPhenotypeDataParams withMediaSupplementList(List<String> mediaSupplementList) {
        this.mediaSupplementList = mediaSupplementList;
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
        return ((((((((((((((((((((((((("SimulateGrowthOnPhenotypeDataParams"+" [fbamodelId=")+ fbamodelId)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", phenotypesetId=")+ phenotypesetId)+", phenotypesetWorkspace=")+ phenotypesetWorkspace)+", phenotypesimOutputId=")+ phenotypesimOutputId)+", workspace=")+ workspace)+", allReversible=")+ allReversible)+", featureKoList=")+ featureKoList)+", reactionKoList=")+ reactionKoList)+", customBoundList=")+ customBoundList)+", mediaSupplementList=")+ mediaSupplementList)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
