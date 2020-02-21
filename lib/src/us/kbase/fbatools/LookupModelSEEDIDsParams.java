
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
 * <p>Original spec-file type: LookupModelSEEDIDsParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace",
    "chemical_abundance_matrix_id",
    "chemical_abundance_matrix_out_id"
})
public class LookupModelSEEDIDsParams {

    @JsonProperty("workspace")
    private String workspace;
    @JsonProperty("chemical_abundance_matrix_id")
    private String chemicalAbundanceMatrixId;
    @JsonProperty("chemical_abundance_matrix_out_id")
    private String chemicalAbundanceMatrixOutId;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("workspace")
    public String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(String workspace) {
        this.workspace = workspace;
    }

    public LookupModelSEEDIDsParams withWorkspace(String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("chemical_abundance_matrix_id")
    public String getChemicalAbundanceMatrixId() {
        return chemicalAbundanceMatrixId;
    }

    @JsonProperty("chemical_abundance_matrix_id")
    public void setChemicalAbundanceMatrixId(String chemicalAbundanceMatrixId) {
        this.chemicalAbundanceMatrixId = chemicalAbundanceMatrixId;
    }

    public LookupModelSEEDIDsParams withChemicalAbundanceMatrixId(String chemicalAbundanceMatrixId) {
        this.chemicalAbundanceMatrixId = chemicalAbundanceMatrixId;
        return this;
    }

    @JsonProperty("chemical_abundance_matrix_out_id")
    public String getChemicalAbundanceMatrixOutId() {
        return chemicalAbundanceMatrixOutId;
    }

    @JsonProperty("chemical_abundance_matrix_out_id")
    public void setChemicalAbundanceMatrixOutId(String chemicalAbundanceMatrixOutId) {
        this.chemicalAbundanceMatrixOutId = chemicalAbundanceMatrixOutId;
    }

    public LookupModelSEEDIDsParams withChemicalAbundanceMatrixOutId(String chemicalAbundanceMatrixOutId) {
        this.chemicalAbundanceMatrixOutId = chemicalAbundanceMatrixOutId;
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
        return ((((((((("LookupModelSEEDIDsParams"+" [workspace=")+ workspace)+", chemicalAbundanceMatrixId=")+ chemicalAbundanceMatrixId)+", chemicalAbundanceMatrixOutId=")+ chemicalAbundanceMatrixOutId)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
