
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
 * <p>Original spec-file type: BulkExportObjectsParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "refs",
    "all_models",
    "all_fba",
    "all_media",
    "all_phenotypes",
    "all_phenosims",
    "model_format",
    "fba_format",
    "media_format",
    "phenotype_format",
    "phenosim_format",
    "workspace",
    "report_workspace"
})
public class BulkExportObjectsParams {

    @JsonProperty("refs")
    private List<String> refs;
    @JsonProperty("all_models")
    private Long allModels;
    @JsonProperty("all_fba")
    private Long allFba;
    @JsonProperty("all_media")
    private Long allMedia;
    @JsonProperty("all_phenotypes")
    private Long allPhenotypes;
    @JsonProperty("all_phenosims")
    private Long allPhenosims;
    @JsonProperty("model_format")
    private java.lang.String modelFormat;
    @JsonProperty("fba_format")
    private java.lang.String fbaFormat;
    @JsonProperty("media_format")
    private java.lang.String mediaFormat;
    @JsonProperty("phenotype_format")
    private java.lang.String phenotypeFormat;
    @JsonProperty("phenosim_format")
    private java.lang.String phenosimFormat;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("report_workspace")
    private java.lang.String reportWorkspace;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("refs")
    public List<String> getRefs() {
        return refs;
    }

    @JsonProperty("refs")
    public void setRefs(List<String> refs) {
        this.refs = refs;
    }

    public BulkExportObjectsParams withRefs(List<String> refs) {
        this.refs = refs;
        return this;
    }

    @JsonProperty("all_models")
    public Long getAllModels() {
        return allModels;
    }

    @JsonProperty("all_models")
    public void setAllModels(Long allModels) {
        this.allModels = allModels;
    }

    public BulkExportObjectsParams withAllModels(Long allModels) {
        this.allModels = allModels;
        return this;
    }

    @JsonProperty("all_fba")
    public Long getAllFba() {
        return allFba;
    }

    @JsonProperty("all_fba")
    public void setAllFba(Long allFba) {
        this.allFba = allFba;
    }

    public BulkExportObjectsParams withAllFba(Long allFba) {
        this.allFba = allFba;
        return this;
    }

    @JsonProperty("all_media")
    public Long getAllMedia() {
        return allMedia;
    }

    @JsonProperty("all_media")
    public void setAllMedia(Long allMedia) {
        this.allMedia = allMedia;
    }

    public BulkExportObjectsParams withAllMedia(Long allMedia) {
        this.allMedia = allMedia;
        return this;
    }

    @JsonProperty("all_phenotypes")
    public Long getAllPhenotypes() {
        return allPhenotypes;
    }

    @JsonProperty("all_phenotypes")
    public void setAllPhenotypes(Long allPhenotypes) {
        this.allPhenotypes = allPhenotypes;
    }

    public BulkExportObjectsParams withAllPhenotypes(Long allPhenotypes) {
        this.allPhenotypes = allPhenotypes;
        return this;
    }

    @JsonProperty("all_phenosims")
    public Long getAllPhenosims() {
        return allPhenosims;
    }

    @JsonProperty("all_phenosims")
    public void setAllPhenosims(Long allPhenosims) {
        this.allPhenosims = allPhenosims;
    }

    public BulkExportObjectsParams withAllPhenosims(Long allPhenosims) {
        this.allPhenosims = allPhenosims;
        return this;
    }

    @JsonProperty("model_format")
    public java.lang.String getModelFormat() {
        return modelFormat;
    }

    @JsonProperty("model_format")
    public void setModelFormat(java.lang.String modelFormat) {
        this.modelFormat = modelFormat;
    }

    public BulkExportObjectsParams withModelFormat(java.lang.String modelFormat) {
        this.modelFormat = modelFormat;
        return this;
    }

    @JsonProperty("fba_format")
    public java.lang.String getFbaFormat() {
        return fbaFormat;
    }

    @JsonProperty("fba_format")
    public void setFbaFormat(java.lang.String fbaFormat) {
        this.fbaFormat = fbaFormat;
    }

    public BulkExportObjectsParams withFbaFormat(java.lang.String fbaFormat) {
        this.fbaFormat = fbaFormat;
        return this;
    }

    @JsonProperty("media_format")
    public java.lang.String getMediaFormat() {
        return mediaFormat;
    }

    @JsonProperty("media_format")
    public void setMediaFormat(java.lang.String mediaFormat) {
        this.mediaFormat = mediaFormat;
    }

    public BulkExportObjectsParams withMediaFormat(java.lang.String mediaFormat) {
        this.mediaFormat = mediaFormat;
        return this;
    }

    @JsonProperty("phenotype_format")
    public java.lang.String getPhenotypeFormat() {
        return phenotypeFormat;
    }

    @JsonProperty("phenotype_format")
    public void setPhenotypeFormat(java.lang.String phenotypeFormat) {
        this.phenotypeFormat = phenotypeFormat;
    }

    public BulkExportObjectsParams withPhenotypeFormat(java.lang.String phenotypeFormat) {
        this.phenotypeFormat = phenotypeFormat;
        return this;
    }

    @JsonProperty("phenosim_format")
    public java.lang.String getPhenosimFormat() {
        return phenosimFormat;
    }

    @JsonProperty("phenosim_format")
    public void setPhenosimFormat(java.lang.String phenosimFormat) {
        this.phenosimFormat = phenosimFormat;
    }

    public BulkExportObjectsParams withPhenosimFormat(java.lang.String phenosimFormat) {
        this.phenosimFormat = phenosimFormat;
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

    public BulkExportObjectsParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("report_workspace")
    public java.lang.String getReportWorkspace() {
        return reportWorkspace;
    }

    @JsonProperty("report_workspace")
    public void setReportWorkspace(java.lang.String reportWorkspace) {
        this.reportWorkspace = reportWorkspace;
    }

    public BulkExportObjectsParams withReportWorkspace(java.lang.String reportWorkspace) {
        this.reportWorkspace = reportWorkspace;
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
        return ((((((((((((((((((((((((((((("BulkExportObjectsParams"+" [refs=")+ refs)+", allModels=")+ allModels)+", allFba=")+ allFba)+", allMedia=")+ allMedia)+", allPhenotypes=")+ allPhenotypes)+", allPhenosims=")+ allPhenosims)+", modelFormat=")+ modelFormat)+", fbaFormat=")+ fbaFormat)+", mediaFormat=")+ mediaFormat)+", phenotypeFormat=")+ phenotypeFormat)+", phenosimFormat=")+ phenosimFormat)+", workspace=")+ workspace)+", reportWorkspace=")+ reportWorkspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
