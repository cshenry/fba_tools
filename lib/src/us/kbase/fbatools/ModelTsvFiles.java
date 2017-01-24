
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
 * <p>Original spec-file type: ModelTsvFiles</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "compounds_file",
    "reactions_file"
})
public class ModelTsvFiles {

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("compounds_file")
    private File compoundsFile;
    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("reactions_file")
    private File reactionsFile;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("compounds_file")
    public File getCompoundsFile() {
        return compoundsFile;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("compounds_file")
    public void setCompoundsFile(File compoundsFile) {
        this.compoundsFile = compoundsFile;
    }

    public ModelTsvFiles withCompoundsFile(File compoundsFile) {
        this.compoundsFile = compoundsFile;
        return this;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("reactions_file")
    public File getReactionsFile() {
        return reactionsFile;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("reactions_file")
    public void setReactionsFile(File reactionsFile) {
        this.reactionsFile = reactionsFile;
    }

    public ModelTsvFiles withReactionsFile(File reactionsFile) {
        this.reactionsFile = reactionsFile;
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
        return ((((((("ModelTsvFiles"+" [compoundsFile=")+ compoundsFile)+", reactionsFile=")+ reactionsFile)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
