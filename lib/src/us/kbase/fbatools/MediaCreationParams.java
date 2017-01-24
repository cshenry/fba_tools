
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
 * <p>Original spec-file type: MediaCreationParams</p>
 * <pre>
 * ****** Media Converters *********
 * </pre>
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "media_file",
    "media_name",
    "workspace_name"
})
public class MediaCreationParams {

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("media_file")
    private File mediaFile;
    @JsonProperty("media_name")
    private String mediaName;
    @JsonProperty("workspace_name")
    private String workspaceName;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("media_file")
    public File getMediaFile() {
        return mediaFile;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("media_file")
    public void setMediaFile(File mediaFile) {
        this.mediaFile = mediaFile;
    }

    public MediaCreationParams withMediaFile(File mediaFile) {
        this.mediaFile = mediaFile;
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

    public MediaCreationParams withMediaName(String mediaName) {
        this.mediaName = mediaName;
        return this;
    }

    @JsonProperty("workspace_name")
    public String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public MediaCreationParams withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
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
        return ((((((((("MediaCreationParams"+" [mediaFile=")+ mediaFile)+", mediaName=")+ mediaName)+", workspaceName=")+ workspaceName)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
