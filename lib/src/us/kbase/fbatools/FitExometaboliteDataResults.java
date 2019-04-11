
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
 * <p>Original spec-file type: FitExometaboliteDataResults</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "new_fbamodel_ref",
    "new_fba_ref",
    "number_gapfilled_reactions"
})
public class FitExometaboliteDataResults {

    @JsonProperty("new_fbamodel_ref")
    private String newFbamodelRef;
    @JsonProperty("new_fba_ref")
    private String newFbaRef;
    @JsonProperty("number_gapfilled_reactions")
    private Long numberGapfilledReactions;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("new_fbamodel_ref")
    public String getNewFbamodelRef() {
        return newFbamodelRef;
    }

    @JsonProperty("new_fbamodel_ref")
    public void setNewFbamodelRef(String newFbamodelRef) {
        this.newFbamodelRef = newFbamodelRef;
    }

    public FitExometaboliteDataResults withNewFbamodelRef(String newFbamodelRef) {
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

    public FitExometaboliteDataResults withNewFbaRef(String newFbaRef) {
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

    public FitExometaboliteDataResults withNumberGapfilledReactions(Long numberGapfilledReactions) {
        this.numberGapfilledReactions = numberGapfilledReactions;
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
        return ((((((((("FitExometaboliteDataResults"+" [newFbamodelRef=")+ newFbamodelRef)+", newFbaRef=")+ newFbaRef)+", numberGapfilledReactions=")+ numberGapfilledReactions)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
