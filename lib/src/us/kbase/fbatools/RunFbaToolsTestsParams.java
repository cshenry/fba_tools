
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
 * <p>Original spec-file type: RunFbaToolsTestsParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "test_metagenomes",
    "workspace"
})
public class RunFbaToolsTestsParams {

    @JsonProperty("test_metagenomes")
    private Long testMetagenomes;
    @JsonProperty("workspace")
    private String workspace;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("test_metagenomes")
    public Long getTestMetagenomes() {
        return testMetagenomes;
    }

    @JsonProperty("test_metagenomes")
    public void setTestMetagenomes(Long testMetagenomes) {
        this.testMetagenomes = testMetagenomes;
    }

    public RunFbaToolsTestsParams withTestMetagenomes(Long testMetagenomes) {
        this.testMetagenomes = testMetagenomes;
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

    public RunFbaToolsTestsParams withWorkspace(String workspace) {
        this.workspace = workspace;
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
        return ((((((("RunFbaToolsTestsParams"+" [testMetagenomes=")+ testMetagenomes)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
