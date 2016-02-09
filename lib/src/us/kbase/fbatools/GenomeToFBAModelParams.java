
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
 * <p>Original spec-file type: GenomeToFBAModelParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "genome_id",
    "genome_workspace",
    "template_id",
    "template_workspace",
    "media_id",
    "media_workspace",
    "fbamodel_id",
    "workspace",
    "coremodel",
    "gapfill_model"
})
public class GenomeToFBAModelParams {

    @JsonProperty("genome_id")
    private String genomeId;
    @JsonProperty("genome_workspace")
    private String genomeWorkspace;
    @JsonProperty("template_id")
    private String templateId;
    @JsonProperty("template_workspace")
    private String templateWorkspace;
    @JsonProperty("media_id")
    private String mediaId;
    @JsonProperty("media_workspace")
    private String mediaWorkspace;
    @JsonProperty("fbamodel_id")
    private String fbamodelId;
    @JsonProperty("workspace")
    private String workspace;
    @JsonProperty("coremodel")
    private Long coremodel;
    @JsonProperty("gapfill_model")
    private Long gapfillModel;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("genome_id")
    public String getGenomeId() {
        return genomeId;
    }

    @JsonProperty("genome_id")
    public void setGenomeId(String genomeId) {
        this.genomeId = genomeId;
    }

    public GenomeToFBAModelParams withGenomeId(String genomeId) {
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

    public GenomeToFBAModelParams withGenomeWorkspace(String genomeWorkspace) {
        this.genomeWorkspace = genomeWorkspace;
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

    public GenomeToFBAModelParams withTemplateId(String templateId) {
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

    public GenomeToFBAModelParams withTemplateWorkspace(String templateWorkspace) {
        this.templateWorkspace = templateWorkspace;
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

    public GenomeToFBAModelParams withMediaId(String mediaId) {
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

    public GenomeToFBAModelParams withMediaWorkspace(String mediaWorkspace) {
        this.mediaWorkspace = mediaWorkspace;
        return this;
    }

    @JsonProperty("fbamodel_id")
    public String getFbamodelId() {
        return fbamodelId;
    }

    @JsonProperty("fbamodel_id")
    public void setFbamodelId(String fbamodelId) {
        this.fbamodelId = fbamodelId;
    }

    public GenomeToFBAModelParams withFbamodelId(String fbamodelId) {
        this.fbamodelId = fbamodelId;
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

    public GenomeToFBAModelParams withWorkspace(String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("coremodel")
    public Long getCoremodel() {
        return coremodel;
    }

    @JsonProperty("coremodel")
    public void setCoremodel(Long coremodel) {
        this.coremodel = coremodel;
    }

    public GenomeToFBAModelParams withCoremodel(Long coremodel) {
        this.coremodel = coremodel;
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

    public GenomeToFBAModelParams withGapfillModel(Long gapfillModel) {
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
        return ((((((((((((((((((((((("GenomeToFBAModelParams"+" [genomeId=")+ genomeId)+", genomeWorkspace=")+ genomeWorkspace)+", templateId=")+ templateId)+", templateWorkspace=")+ templateWorkspace)+", mediaId=")+ mediaId)+", mediaWorkspace=")+ mediaWorkspace)+", fbamodelId=")+ fbamodelId)+", workspace=")+ workspace)+", coremodel=")+ coremodel)+", gapfillModel=")+ gapfillModel)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
