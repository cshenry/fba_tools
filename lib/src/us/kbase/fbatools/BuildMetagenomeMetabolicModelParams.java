
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
 * <p>Original spec-file type: BuildMetagenomeMetabolicModelParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "input_ref",
    "input_workspace",
    "media_id",
    "media_workspace",
    "fbamodel_output_id",
    "workspace",
    "gapfill_model"
})
public class BuildMetagenomeMetabolicModelParams {

    @JsonProperty("input_ref")
    private String inputRef;
    @JsonProperty("input_workspace")
    private String inputWorkspace;
    @JsonProperty("media_id")
    private String mediaId;
    @JsonProperty("media_workspace")
    private String mediaWorkspace;
    @JsonProperty("fbamodel_output_id")
    private String fbamodelOutputId;
    @JsonProperty("workspace")
    private String workspace;
    @JsonProperty("gapfill_model")
    private Long gapfillModel;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("input_ref")
    public String getInputRef() {
        return inputRef;
    }

    @JsonProperty("input_ref")
    public void setInputRef(String inputRef) {
        this.inputRef = inputRef;
    }

    public BuildMetagenomeMetabolicModelParams withInputRef(String inputRef) {
        this.inputRef = inputRef;
        return this;
    }

    @JsonProperty("input_workspace")
    public String getInputWorkspace() {
        return inputWorkspace;
    }

    @JsonProperty("input_workspace")
    public void setInputWorkspace(String inputWorkspace) {
        this.inputWorkspace = inputWorkspace;
    }

    public BuildMetagenomeMetabolicModelParams withInputWorkspace(String inputWorkspace) {
        this.inputWorkspace = inputWorkspace;
        return this;
    }

    @JsonProperty("media_id")
    public String getMediaId() {
        return mediaId;
    }

    @JsonProperty("media_id")
    public void setMediaId(String mediaId) {
        this.mediaId = mediaId;
    }

    public BuildMetagenomeMetabolicModelParams withMediaId(String mediaId) {
        this.mediaId = mediaId;
        return this;
    }

    @JsonProperty("media_workspace")
    public String getMediaWorkspace() {
        return mediaWorkspace;
    }

    @JsonProperty("media_workspace")
    public void setMediaWorkspace(String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
    }

    public BuildMetagenomeMetabolicModelParams withMediaWorkspace(String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
        return this;
    }

    @JsonProperty("fbamodel_output_id")
    public String getFbamodelOutputId() {
        return fbamodelOutputId;
    }

    @JsonProperty("fbamodel_output_id")
    public void setFbamodelOutputId(String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
    }

    public BuildMetagenomeMetabolicModelParams withFbamodelOutputId(String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
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

    public BuildMetagenomeMetabolicModelParams withWorkspace(String workspace) {
        this.workspace = workspace;
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

    public BuildMetagenomeMetabolicModelParams withGapfillModel(Long gapfillModel) {
        this.gapfillModel = gapfillModel;
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
        return ((((((((((((((((("BuildMetagenomeMetabolicModelParams"+" [inputRef=")+ inputRef)+", inputWorkspace=")+ inputWorkspace)+", mediaId=")+ mediaId)+", mediaWorkspace=")+ mediaWorkspace)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", gapfillModel=")+ gapfillModel)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
