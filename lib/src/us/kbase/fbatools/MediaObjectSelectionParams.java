
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
 * <p>Original spec-file type: MediaObjectSelectionParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace_name",
    "media_name",
    "save_to_shock"
})
public class MediaObjectSelectionParams {

    @JsonProperty("workspace_name")
    private String workspaceName;
    @JsonProperty("media_name")
    private String mediaName;
    @JsonProperty("save_to_shock")
    private Long saveToShock;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("workspace_name")
    public String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public MediaObjectSelectionParams withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
        return this;
    }

    @JsonProperty("media_name")
    public String getMediaName() {
        return mediaName;
    }

    @JsonProperty("media_name")
    public void setMediaName(String mediaName) {
        this.mediaName = mediaName;
    }

    public MediaObjectSelectionParams withMediaName(String mediaName) {
        this.mediaName = mediaName;
        return this;
    }

    @JsonProperty("save_to_shock")
    public Long getSaveToShock() {
        return saveToShock;
    }

    @JsonProperty("save_to_shock")
    public void setSaveToShock(Long saveToShock) {
        this.saveToShock = saveToShock;
    }

    public MediaObjectSelectionParams withSaveToShock(Long saveToShock) {
        this.saveToShock = saveToShock;
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
        return ((((((((("MediaObjectSelectionParams"+" [workspaceName=")+ workspaceName)+", mediaName=")+ mediaName)+", saveToShock=")+ saveToShock)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
