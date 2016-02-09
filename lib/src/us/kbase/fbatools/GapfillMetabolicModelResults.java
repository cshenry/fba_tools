
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
 * <p>Original spec-file type: GapfillMetabolicModelResults</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "new_fbamodel_ref",
    "new_fba_ref",
    "number_gapfilled_reactions",
    "number_removed_biomass_compounds"
})
public class GapfillMetabolicModelResults {

    @JsonProperty("new_fbamodel_ref")
    private String newFbamodelRef;
    @JsonProperty("new_fba_ref")
    private String newFbaRef;
    @JsonProperty("number_gapfilled_reactions")
    private Long numberGapfilledReactions;
    @JsonProperty("number_removed_biomass_compounds")
    private Long numberRemovedBiomassCompounds;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("new_fbamodel_ref")
    public String getNewFbamodelRef() {
        return newFbamodelRef;
    }

    @JsonProperty("new_fbamodel_ref")
    public void setNewFbamodelRef(String newFbamodelRef) {
        this.newFbamodelRef = newFbamodelRef;
    }

    public GapfillMetabolicModelResults withNewFbamodelRef(String newFbamodelRef) {
        this.newFbamodelRef = newFbamodelRef;
        return this;
    }

    @JsonProperty("new_fba_ref")
    public String getNewFbaRef() {
        return newFbaRef;
    }

    @JsonProperty("new_fba_ref")
    public void setNewFbaRef(String newFbaRef) {
        this.newFbaRef = newFbaRef;
    }

    public GapfillMetabolicModelResults withNewFbaRef(String newFbaRef) {
        this.newFbaRef = newFbaRef;
        return this;
    }

    @JsonProperty("number_gapfilled_reactions")
    public Long getNumberGapfilledReactions() {
        return numberGapfilledReactions;
    }

    @JsonProperty("number_gapfilled_reactions")
    public void setNumberGapfilledReactions(Long numberGapfilledReactions) {
        this.numberGapfilledReactions = numberGapfilledReactions;
    }

    public GapfillMetabolicModelResults withNumberGapfilledReactions(Long numberGapfilledReactions) {
        this.numberGapfilledReactions = numberGapfilledReactions;
        return this;
    }

    @JsonProperty("number_removed_biomass_compounds")
    public Long getNumberRemovedBiomassCompounds() {
        return numberRemovedBiomassCompounds;
    }

    @JsonProperty("number_removed_biomass_compounds")
    public void setNumberRemovedBiomassCompounds(Long numberRemovedBiomassCompounds) {
        this.numberRemovedBiomassCompounds = numberRemovedBiomassCompounds;
    }

    public GapfillMetabolicModelResults withNumberRemovedBiomassCompounds(Long numberRemovedBiomassCompounds) {
        this.numberRemovedBiomassCompounds = numberRemovedBiomassCompounds;
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
        return ((((((((((("GapfillMetabolicModelResults"+" [newFbamodelRef=")+ newFbamodelRef)+", newFbaRef=")+ newFbaRef)+", numberGapfilledReactions=")+ numberGapfilledReactions)+", numberRemovedBiomassCompounds=")+ numberRemovedBiomassCompounds)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
