
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
 * <p>Original spec-file type: MergeMetabolicModelsIntoCommunityModelParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "fbamodel_id_list",
    "fbamodel_workspace",
    "fbamodel_output_id",
    "workspace",
    "mixed_bag_model"
})
public class MergeMetabolicModelsIntoCommunityModelParams {

    @JsonProperty("fbamodel_id_list")
    private List<String> fbamodelIdList;
    @JsonProperty("fbamodel_workspace")
    private java.lang.String fbamodelWorkspace;
    @JsonProperty("fbamodel_output_id")
    private java.lang.String fbamodelOutputId;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("mixed_bag_model")
    private Long mixedBagModel;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("fbamodel_id_list")
    public List<String> getFbamodelIdList() {
        return fbamodelIdList;
    }

    @JsonProperty("fbamodel_id_list")
    public void setFbamodelIdList(List<String> fbamodelIdList) {
        this.fbamodelIdList = fbamodelIdList;
    }

    public MergeMetabolicModelsIntoCommunityModelParams withFbamodelIdList(List<String> fbamodelIdList) {
        this.fbamodelIdList = fbamodelIdList;
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

    public MergeMetabolicModelsIntoCommunityModelParams withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
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

    public MergeMetabolicModelsIntoCommunityModelParams withFbamodelOutputId(java.lang.String fbamodelOutputId) {
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

    public MergeMetabolicModelsIntoCommunityModelParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("mixed_bag_model")
    public Long getMixedBagModel() {
        return mixedBagModel;
    }

    @JsonProperty("mixed_bag_model")
    public void setMixedBagModel(Long mixedBagModel) {
        this.mixedBagModel = mixedBagModel;
    }

    public MergeMetabolicModelsIntoCommunityModelParams withMixedBagModel(Long mixedBagModel) {
        this.mixedBagModel = mixedBagModel;
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
        return ((((((((((((("MergeMetabolicModelsIntoCommunityModelParams"+" [fbamodelIdList=")+ fbamodelIdList)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", mixedBagModel=")+ mixedBagModel)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
