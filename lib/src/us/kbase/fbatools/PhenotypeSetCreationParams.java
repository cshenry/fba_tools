
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
 * <p>Original spec-file type: PhenotypeSetCreationParams</p>
 * <pre>
 * ****** Phenotype Data Converters *******
 * </pre>
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "phenotype_set_file",
    "phenotype_set_name",
    "workspace_name",
    "genome"
})
public class PhenotypeSetCreationParams {

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("phenotype_set_file")
    private File phenotypeSetFile;
    @JsonProperty("phenotype_set_name")
    private String phenotypeSetName;
    @JsonProperty("workspace_name")
    private String workspaceName;
    @JsonProperty("genome")
    private String genome;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("phenotype_set_file")
    public File getPhenotypeSetFile() {
        return phenotypeSetFile;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("phenotype_set_file")
    public void setPhenotypeSetFile(File phenotypeSetFile) {
        this.phenotypeSetFile = phenotypeSetFile;
    }

    public PhenotypeSetCreationParams withPhenotypeSetFile(File phenotypeSetFile) {
        this.phenotypeSetFile = phenotypeSetFile;
        return this;
    }

    @JsonProperty("phenotype_set_name")
    public String getPhenotypeSetName() {
        return phenotypeSetName;
    }

    @JsonProperty("phenotype_set_name")
    public void setPhenotypeSetName(String phenotypeSetName) {
        this.phenotypeSetName = phenotypeSetName;
    }

    public PhenotypeSetCreationParams withPhenotypeSetName(String phenotypeSetName) {
        this.phenotypeSetName = phenotypeSetName;
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

    public PhenotypeSetCreationParams withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
        return this;
    }

    @JsonProperty("genome")
    public String getGenome() {
        return genome;
    }

    @JsonProperty("genome")
    public void setGenome(String genome) {
        this.genome = genome;
    }

    public PhenotypeSetCreationParams withGenome(String genome) {
        this.genome = genome;
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
        return ((((((((((("PhenotypeSetCreationParams"+" [phenotypeSetFile=")+ phenotypeSetFile)+", phenotypeSetName=")+ phenotypeSetName)+", workspaceName=")+ workspaceName)+", genome=")+ genome)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
