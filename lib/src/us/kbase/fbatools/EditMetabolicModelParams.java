
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
 * <p>Original spec-file type: EditMetabolicModelParams</p>
 * <pre>
 * EditMetabolicModelParams object: arguments for the edit model function
 * </pre>
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace",
    "fbamodel_workspace",
    "fbamodel_id",
    "fbamodel_output_id",
    "compounds_to_add",
    "compounds_to_change",
    "biomasses_to_add",
    "biomass_compounds_to_change",
    "reactions_to_remove",
    "reactions_to_change",
    "reactions_to_add",
    "edit_compound_stoichiometry"
})
public class EditMetabolicModelParams {

    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("fbamodel_workspace")
    private java.lang.String fbamodelWorkspace;
    @JsonProperty("fbamodel_id")
    private java.lang.String fbamodelId;
    @JsonProperty("fbamodel_output_id")
    private java.lang.String fbamodelOutputId;
    @JsonProperty("compounds_to_add")
    private List<Map<String, String>> compoundsToAdd;
    @JsonProperty("compounds_to_change")
    private List<Map<String, String>> compoundsToChange;
    @JsonProperty("biomasses_to_add")
    private List<Map<String, String>> biomassesToAdd;
    @JsonProperty("biomass_compounds_to_change")
    private List<Map<String, String>> biomassCompoundsToChange;
    @JsonProperty("reactions_to_remove")
    private List<Map<String, String>> reactionsToRemove;
    @JsonProperty("reactions_to_change")
    private List<Map<String, String>> reactionsToChange;
    @JsonProperty("reactions_to_add")
    private List<Map<String, String>> reactionsToAdd;
    @JsonProperty("edit_compound_stoichiometry")
    private List<Map<String, String>> editCompoundStoichiometry;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("workspace")
    public java.lang.String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
    }

    public EditMetabolicModelParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("fbamodel_workspace")
    public java.lang.String getFbamodelWorkspace() {
        return fbamodelWorkspace;
    }

    @JsonProperty("fbamodel_workspace")
    public void setFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
    }

    public EditMetabolicModelParams withFbamodelWorkspace(java.lang.String fbamodelWorkspace) {
        this.fbamodelWorkspace = fbamodelWorkspace;
        return this;
    }

    @JsonProperty("fbamodel_id")
    public java.lang.String getFbamodelId() {
        return fbamodelId;
    }

    @JsonProperty("fbamodel_id")
    public void setFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
    }

    public EditMetabolicModelParams withFbamodelId(java.lang.String fbamodelId) {
        this.fbamodelId = fbamodelId;
        return this;
    }

    @JsonProperty("fbamodel_output_id")
    public java.lang.String getFbamodelOutputId() {
        return fbamodelOutputId;
    }

    @JsonProperty("fbamodel_output_id")
    public void setFbamodelOutputId(java.lang.String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
    }

    public EditMetabolicModelParams withFbamodelOutputId(java.lang.String fbamodelOutputId) {
        this.fbamodelOutputId = fbamodelOutputId;
        return this;
    }

    @JsonProperty("compounds_to_add")
    public List<Map<String, String>> getCompoundsToAdd() {
        return compoundsToAdd;
    }

    @JsonProperty("compounds_to_add")
    public void setCompoundsToAdd(List<Map<String, String>> compoundsToAdd) {
        this.compoundsToAdd = compoundsToAdd;
    }

    public EditMetabolicModelParams withCompoundsToAdd(List<Map<String, String>> compoundsToAdd) {
        this.compoundsToAdd = compoundsToAdd;
        return this;
    }

    @JsonProperty("compounds_to_change")
    public List<Map<String, String>> getCompoundsToChange() {
        return compoundsToChange;
    }

    @JsonProperty("compounds_to_change")
    public void setCompoundsToChange(List<Map<String, String>> compoundsToChange) {
        this.compoundsToChange = compoundsToChange;
    }

    public EditMetabolicModelParams withCompoundsToChange(List<Map<String, String>> compoundsToChange) {
        this.compoundsToChange = compoundsToChange;
        return this;
    }

    @JsonProperty("biomasses_to_add")
    public List<Map<String, String>> getBiomassesToAdd() {
        return biomassesToAdd;
    }

    @JsonProperty("biomasses_to_add")
    public void setBiomassesToAdd(List<Map<String, String>> biomassesToAdd) {
        this.biomassesToAdd = biomassesToAdd;
    }

    public EditMetabolicModelParams withBiomassesToAdd(List<Map<String, String>> biomassesToAdd) {
        this.biomassesToAdd = biomassesToAdd;
        return this;
    }

    @JsonProperty("biomass_compounds_to_change")
    public List<Map<String, String>> getBiomassCompoundsToChange() {
        return biomassCompoundsToChange;
    }

    @JsonProperty("biomass_compounds_to_change")
    public void setBiomassCompoundsToChange(List<Map<String, String>> biomassCompoundsToChange) {
        this.biomassCompoundsToChange = biomassCompoundsToChange;
    }

    public EditMetabolicModelParams withBiomassCompoundsToChange(List<Map<String, String>> biomassCompoundsToChange) {
        this.biomassCompoundsToChange = biomassCompoundsToChange;
        return this;
    }

    @JsonProperty("reactions_to_remove")
    public List<Map<String, String>> getReactionsToRemove() {
        return reactionsToRemove;
    }

    @JsonProperty("reactions_to_remove")
    public void setReactionsToRemove(List<Map<String, String>> reactionsToRemove) {
        this.reactionsToRemove = reactionsToRemove;
    }

    public EditMetabolicModelParams withReactionsToRemove(List<Map<String, String>> reactionsToRemove) {
        this.reactionsToRemove = reactionsToRemove;
        return this;
    }

    @JsonProperty("reactions_to_change")
    public List<Map<String, String>> getReactionsToChange() {
        return reactionsToChange;
    }

    @JsonProperty("reactions_to_change")
    public void setReactionsToChange(List<Map<String, String>> reactionsToChange) {
        this.reactionsToChange = reactionsToChange;
    }

    public EditMetabolicModelParams withReactionsToChange(List<Map<String, String>> reactionsToChange) {
        this.reactionsToChange = reactionsToChange;
        return this;
    }

    @JsonProperty("reactions_to_add")
    public List<Map<String, String>> getReactionsToAdd() {
        return reactionsToAdd;
    }

    @JsonProperty("reactions_to_add")
    public void setReactionsToAdd(List<Map<String, String>> reactionsToAdd) {
        this.reactionsToAdd = reactionsToAdd;
    }

    public EditMetabolicModelParams withReactionsToAdd(List<Map<String, String>> reactionsToAdd) {
        this.reactionsToAdd = reactionsToAdd;
        return this;
    }

    @JsonProperty("edit_compound_stoichiometry")
    public List<Map<String, String>> getEditCompoundStoichiometry() {
        return editCompoundStoichiometry;
    }

    @JsonProperty("edit_compound_stoichiometry")
    public void setEditCompoundStoichiometry(List<Map<String, String>> editCompoundStoichiometry) {
        this.editCompoundStoichiometry = editCompoundStoichiometry;
    }

    public EditMetabolicModelParams withEditCompoundStoichiometry(List<Map<String, String>> editCompoundStoichiometry) {
        this.editCompoundStoichiometry = editCompoundStoichiometry;
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
        return ((((((((((((((((((((((((((("EditMetabolicModelParams"+" [workspace=")+ workspace)+", fbamodelWorkspace=")+ fbamodelWorkspace)+", fbamodelId=")+ fbamodelId)+", fbamodelOutputId=")+ fbamodelOutputId)+", compoundsToAdd=")+ compoundsToAdd)+", compoundsToChange=")+ compoundsToChange)+", biomassesToAdd=")+ biomassesToAdd)+", biomassCompoundsToChange=")+ biomassCompoundsToChange)+", reactionsToRemove=")+ reactionsToRemove)+", reactionsToChange=")+ reactionsToChange)+", reactionsToAdd=")+ reactionsToAdd)+", editCompoundStoichiometry=")+ editCompoundStoichiometry)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
