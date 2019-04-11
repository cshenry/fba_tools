
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
 * <p>Original spec-file type: FitExometaboliteDataParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fbamodel_id",
    "fbamodel_workspace",
    "source_fbamodel_id",
    "source_fbamodel_workspace",
    "media_id",
    "media_workspace",
    "metabolome_id",
    "metabolome_workspace",
    "metabolome_condition",
    "fbamodel_output_id",
    "workspace",
    "minimum_target_flux",
    "omnidirectional",
    "target_reaction",
    "feature_ko_list",
    "reaction_ko_list",
    "media_supplement_list"
})
public class FitExometaboliteDataParams {

    @JsonProperty("fbamodel_id")
    private java.lang.String fbamodelId;
    @JsonProperty("fbamodel_workspace")
    private java.lang.String fbamodelWorkspace;
    @JsonProperty("source_fbamodel_id")
    private java.lang.String sourceFbamodelId;
    @JsonProperty("source_fbamodel_workspace")
    private java.lang.String sourceFbamodelWorkspace;
    @JsonProperty("media_id")
    private java.lang.String mediaId;
    @JsonProperty("media_workspace")
    private java.lang.String mediaWorkspace;
    @JsonProperty("metabolome_id")
    private java.lang.String metabolomeId;
    @JsonProperty("metabolome_workspace")
    private java.lang.String metabolomeWorkspace;
    @JsonProperty("metabolome_condition")
    private java.lang.String metabolomeCondition;
    @JsonProperty("fbamodel_output_id")
    private java.lang.String fbamodelOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("minimum_target_flux")
    private Double minimumTargetFlux;
    @JsonProperty("omnidirectional")
    private Long omnidirectional;
    @JsonProperty("target_reaction")
    private java.lang.String targetReaction;
    @JsonProperty("feature_ko_list")
    private List<String> featureKoList;
    @JsonProperty("reaction_ko_list")
    private List<String> reactionKoList;
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

    public FitExometaboliteDataParams withFbamodelId(java.lang.String fbamodelId) {
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

    public FitExometaboliteDataParams withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
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

    public FitExometaboliteDataParams withSourceFbamodelId(java.lang.String sourceFbamodelId) {
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

    public FitExometaboliteDataParams withSourceFbamodelWorkspace(java.lang.String sourceFbamodelWorkspace) {
        this.sourceFbamodelWorkspace = sourceFbamodelWorkspace;
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

    public FitExometaboliteDataParams withMediaId(java.lang.String mediaId) {
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

    public FitExometaboliteDataParams withMediaWorkspace(java.lang.String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
        return this;
    }

    @JsonProperty("metabolome_id")
    public java.lang.String getMetabolomeId() {
        return metabolomeId;
    }

    @JsonProperty("metabolome_id")
    public void setMetabolomeId(java.lang.String metabolomeId) {
        this.metabolomeId = metabolomeId;
    }

    public FitExometaboliteDataParams withMetabolomeId(java.lang.String metabolomeId) {
        this.metabolomeId = metabolomeId;
        return this;
    }

    @JsonProperty("metabolome_workspace")
    public java.lang.String getMetabolomeWorkspace() {
        return metabolomeWorkspace;
    }

    @JsonProperty("metabolome_workspace")
    public void setMetabolomeWorkspace(java.lang.String metabolomeWorkspace) {
        this.metabolomeWorkspace = metabolomeWorkspace;
    }

    public FitExometaboliteDataParams withMetabolomeWorkspace(java.lang.String metabolomeWorkspace) {
        this.metabolomeWorkspace = metabolomeWorkspace;
        return this;
    }

    @JsonProperty("metabolome_condition")
    public java.lang.String getMetabolomeCondition() {
        return metabolomeCondition;
    }

    @JsonProperty("metabolome_condition")
    public void setMetabolomeCondition(java.lang.String metabolomeCondition) {
        this.metabolomeCondition = metabolomeCondition;
    }

    public FitExometaboliteDataParams withMetabolomeCondition(java.lang.String metabolomeCondition) {
        this.metabolomeCondition = metabolomeCondition;
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

    public FitExometaboliteDataParams withFbamodelOutputId(java.lang.String fbamodelOutputId) {
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

    public FitExometaboliteDataParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
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

    public FitExometaboliteDataParams withMinimumTargetFlux(Double minimumTargetFlux) {
        this.minimumTargetFlux = minimumTargetFlux;
        return this;
    }

    @JsonProperty("omnidirectional")
    public Long getOmnidirectional() {
        return omnidirectional;
    }

    @JsonProperty("omnidirectional")
    public void setOmnidirectional(Long omnidirectional) {
        this.omnidirectional = omnidirectional;
    }

    public FitExometaboliteDataParams withOmnidirectional(Long omnidirectional) {
        this.omnidirectional = omnidirectional;
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

    public FitExometaboliteDataParams withTargetReaction(java.lang.String targetReaction) {
        this.targetReaction = targetReaction;
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

    public FitExometaboliteDataParams withFeatureKoList(List<String> featureKoList) {
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

    public FitExometaboliteDataParams withReactionKoList(List<String> reactionKoList) {
        this.reactionKoList = reactionKoList;
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

    public FitExometaboliteDataParams withMediaSupplementList(List<String> mediaSupplementList) {
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
        return ((((((((((((((((((((((((((((((((((((("FitExometaboliteDataParams"+" [fbamodelId=")+ fbamodelId)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", sourceFbamodelId=")+ sourceFbamodelId)+", sourceFbamodelWorkspace=")+ sourceFbamodelWorkspace)+", mediaId=")+ mediaId)+", mediaWorkspace=")+ mediaWorkspace)+", metabolomeId=")+ metabolomeId)+", metabolomeWorkspace=")+ metabolomeWorkspace)+", metabolomeCondition=")+ metabolomeCondition)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", minimumTargetFlux=")+ minimumTargetFlux)+", omnidirectional=")+ omnidirectional)+", targetReaction=")+ targetReaction)+", featureKoList=")+ featureKoList)+", reactionKoList=")+ reactionKoList)+", mediaSupplementList=")+ mediaSupplementList)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
