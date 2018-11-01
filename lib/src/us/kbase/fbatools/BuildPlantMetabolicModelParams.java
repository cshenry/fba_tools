
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
 * <p>Original spec-file type: BuildPlantMetabolicModelParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "genome_id",
    "genome_workspace",
    "fbamodel_output_id",
    "workspace",
    "template_id",
    "template_workspace"
})
public class BuildPlantMetabolicModelParams {

    @JsonProperty("genome_id")
    private String genomeId;
    @JsonProperty("genome_workspace")
    private String genomeWorkspace;
    @JsonProperty("fbamodel_output_id")
    private String fbamodelOutputId;
    @JsonProperty("workspace")
    private String workspace;
    @JsonProperty("template_id")
    private String templateId;
    @JsonProperty("template_workspace")
    private String templateWorkspace;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("genome_id")
    public String getGenomeId() {
        return genomeId;
    }

    @JsonProperty("genome_id")
    public void setGenomeId(String genomeId) {
        this.genomeId = genomeId;
    }

    public BuildPlantMetabolicModelParams withGenomeId(String genomeId) {
        this.genomeId = genomeId;
        return this;
    }

    @JsonProperty("genome_workspace")
    public String getGenomeWorkspace() {
        return genomeWorkspace;
    }

    @JsonProperty("genome_workspace")
    public void setGenomeWorkspace(String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
    }

    public BuildPlantMetabolicModelParams withGenomeWorkspace(String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
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

    public BuildPlantMetabolicModelParams withFbamodelOutputId(String fbamodelOutputId) {
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

    public BuildPlantMetabolicModelParams withWorkspace(String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("template_id")
    public String getTemplateId() {
        return templateId;
    }

    @JsonProperty("template_id")
    public void setTemplateId(String templateId) {
        this.templateId = templateId;
    }

    public BuildPlantMetabolicModelParams withTemplateId(String templateId) {
        this.templateId = templateId;
        return this;
    }

    @JsonProperty("template_workspace")
    public String getTemplateWorkspace() {
        return templateWorkspace;
    }

    @JsonProperty("template_workspace")
    public void setTemplateWorkspace(String templateWorkspace) {
        this.templateWorkspace = templateWorkspace;
    }

    public BuildPlantMetabolicModelParams withTemplateWorkspace(String templateWorkspace) {
        this.templateWorkspace = templateWorkspace;
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
        return ((((((((((((((("BuildPlantMetabolicModelParams"+" [genomeId=")+ genomeId)+", genomeWorkspace=")+ genomeWorkspace)+", fbamodelOutputId=")+ fbamodelOutputId)+", workspace=")+ workspace)+", templateId=")+ templateId)+", templateWorkspace=")+ templateWorkspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
