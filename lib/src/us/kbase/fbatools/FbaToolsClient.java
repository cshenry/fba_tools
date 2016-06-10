package us.kbase.fbatools;

import com.fasterxml.jackson.core.type.TypeReference;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import us.kbase.auth.AuthToken;
import us.kbase.common.service.JsonClientCaller;
import us.kbase.common.service.JsonClientException;
import us.kbase.common.service.RpcContext;
import us.kbase.common.service.UnauthorizedException;

/**
 * <p>Original spec-file module name: fba_tools</p>
 * <pre>
 * A KBase module: fba_tools
 * This module contains the implementation for the primary methods in KBase for metabolic model reconstruction, gapfilling, and analysis
 * </pre>
 */
public class FbaToolsClient {
    private JsonClientCaller caller;


    /** Constructs a client with a custom URL and no user credentials.
     * @param url the URL of the service.
     */
    public FbaToolsClient(URL url) {
        caller = new JsonClientCaller(url);
    }
    /** Constructs a client with a custom URL.
     * @param url the URL of the service.
     * @param token the user's authorization token.
     * @throws UnauthorizedException if the token is not valid.
     * @throws IOException if an IOException occurs when checking the token's
     * validity.
     */
    public FbaToolsClient(URL url, AuthToken token) throws UnauthorizedException, IOException {
        caller = new JsonClientCaller(url, token);
    }

    /** Constructs a client with a custom URL.
     * @param url the URL of the service.
     * @param user the user name.
     * @param password the password for the user name.
     * @throws UnauthorizedException if the credentials are not valid.
     * @throws IOException if an IOException occurs when checking the user's
     * credentials.
     */
    public FbaToolsClient(URL url, String user, String password) throws UnauthorizedException, IOException {
        caller = new JsonClientCaller(url, user, password);
    }

    /** Get the token this client uses to communicate with the server.
     * @return the authorization token.
     */
    public AuthToken getToken() {
        return caller.getToken();
    }

    /** Get the URL of the service with which this client communicates.
     * @return the service URL.
     */
    public URL getURL() {
        return caller.getURL();
    }

    /** Set the timeout between establishing a connection to a server and
     * receiving a response. A value of zero or null implies no timeout.
     * @param milliseconds the milliseconds to wait before timing out when
     * attempting to read from a server.
     */
    public void setConnectionReadTimeOut(Integer milliseconds) {
        this.caller.setConnectionReadTimeOut(milliseconds);
    }

    /** Check if this client allows insecure http (vs https) connections.
     * @return true if insecure connections are allowed.
     */
    public boolean isInsecureHttpConnectionAllowed() {
        return caller.isInsecureHttpConnectionAllowed();
    }

    /** Deprecated. Use isInsecureHttpConnectionAllowed().
     * @deprecated
     */
    public boolean isAuthAllowedForHttp() {
        return caller.isAuthAllowedForHttp();
    }

    /** Set whether insecure http (vs https) connections should be allowed by
     * this client.
     * @param allowed true to allow insecure connections. Default false
     */
    public void setIsInsecureHttpConnectionAllowed(boolean allowed) {
        caller.setInsecureHttpConnectionAllowed(allowed);
    }

    /** Deprecated. Use setIsInsecureHttpConnectionAllowed().
     * @deprecated
     */
    public void setAuthAllowedForHttp(boolean isAuthAllowedForHttp) {
        caller.setAuthAllowedForHttp(isAuthAllowedForHttp);
    }

    /** Set whether all SSL certificates, including self-signed certificates,
     * should be trusted.
     * @param trustAll true to trust all certificates. Default false.
     */
    public void setAllSSLCertificatesTrusted(final boolean trustAll) {
        caller.setAllSSLCertificatesTrusted(trustAll);
    }
    
    /** Check if this client trusts all SSL certificates, including
     * self-signed certificates.
     * @return true if all certificates are trusted.
     */
    public boolean isAllSSLCertificatesTrusted() {
        return caller.isAllSSLCertificatesTrusted();
    }
    /** Sets streaming mode on. In this case, the data will be streamed to
     * the server in chunks as it is read from disk rather than buffered in
     * memory. Many servers are not compatible with this feature.
     * @param streamRequest true to set streaming mode on, false otherwise.
     */
    public void setStreamingModeOn(boolean streamRequest) {
        caller.setStreamingModeOn(streamRequest);
    }

    /** Returns true if streaming mode is on.
     * @return true if streaming mode is on.
     */
    public boolean isStreamingModeOn() {
        return caller.isStreamingModeOn();
    }

    public void _setFileForNextRpcResponse(File f) {
        caller.setFileForNextRpcResponse(f);
    }

    /**
     * <p>Original spec-file function name: build_metabolic_model</p>
     * <pre>
     * Build a genome-scale metabolic model based on annotations in an input genome typed object
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.BuildMetabolicModelParams BuildMetabolicModelParams}
     * @return   instance of type {@link us.kbase.fbatools.BuildMetabolicModelResults BuildMetabolicModelResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public BuildMetabolicModelResults buildMetabolicModel(BuildMetabolicModelParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<BuildMetabolicModelResults>> retType = new TypeReference<List<BuildMetabolicModelResults>>() {};
        List<BuildMetabolicModelResults> res = caller.jsonrpcCall("fba_tools.build_metabolic_model", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: gapfill_metabolic_model</p>
     * <pre>
     * Gapfills a metabolic model to induce flux in a specified reaction
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.GapfillMetabolicModelParams GapfillMetabolicModelParams}
     * @return   parameter "results" of type {@link us.kbase.fbatools.GapfillMetabolicModelResults GapfillMetabolicModelResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public GapfillMetabolicModelResults gapfillMetabolicModel(GapfillMetabolicModelParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<GapfillMetabolicModelResults>> retType = new TypeReference<List<GapfillMetabolicModelResults>>() {};
        List<GapfillMetabolicModelResults> res = caller.jsonrpcCall("fba_tools.gapfill_metabolic_model", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: run_flux_balance_analysis</p>
     * <pre>
     * Run flux balance analysis and return ID of FBA object with results
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.RunFluxBalanceAnalysisParams RunFluxBalanceAnalysisParams}
     * @return   parameter "results" of type {@link us.kbase.fbatools.RunFluxBalanceAnalysisResults RunFluxBalanceAnalysisResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public RunFluxBalanceAnalysisResults runFluxBalanceAnalysis(RunFluxBalanceAnalysisParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<RunFluxBalanceAnalysisResults>> retType = new TypeReference<List<RunFluxBalanceAnalysisResults>>() {};
        List<RunFluxBalanceAnalysisResults> res = caller.jsonrpcCall("fba_tools.run_flux_balance_analysis", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: compare_fba_solutions</p>
     * <pre>
     * Compares multiple FBA solutions and saves comparison as a new object in the workspace
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.CompareFBASolutionsParams CompareFBASolutionsParams}
     * @return   parameter "results" of type {@link us.kbase.fbatools.CompareFBASolutionsResults CompareFBASolutionsResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public CompareFBASolutionsResults compareFbaSolutions(CompareFBASolutionsParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<CompareFBASolutionsResults>> retType = new TypeReference<List<CompareFBASolutionsResults>>() {};
        List<CompareFBASolutionsResults> res = caller.jsonrpcCall("fba_tools.compare_fba_solutions", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: propagate_model_to_new_genome</p>
     * <pre>
     * Translate the metabolic model of one organism to another, using a mapping of similar proteins between their genomes
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.PropagateModelToNewGenomeParams PropagateModelToNewGenomeParams}
     * @return   parameter "results" of type {@link us.kbase.fbatools.PropagateModelToNewGenomeResults PropagateModelToNewGenomeResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public PropagateModelToNewGenomeResults propagateModelToNewGenome(PropagateModelToNewGenomeParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<PropagateModelToNewGenomeResults>> retType = new TypeReference<List<PropagateModelToNewGenomeResults>>() {};
        List<PropagateModelToNewGenomeResults> res = caller.jsonrpcCall("fba_tools.propagate_model_to_new_genome", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: simulate_growth_on_phenotype_data</p>
     * <pre>
     * Use Flux Balance Analysis (FBA) to simulate multiple growth phenotypes.
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.SimulateGrowthOnPhenotypeDataParams SimulateGrowthOnPhenotypeDataParams}
     * @return   parameter "results" of type {@link us.kbase.fbatools.SimulateGrowthOnPhenotypeDataResults SimulateGrowthOnPhenotypeDataResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public SimulateGrowthOnPhenotypeDataResults simulateGrowthOnPhenotypeData(SimulateGrowthOnPhenotypeDataParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<SimulateGrowthOnPhenotypeDataResults>> retType = new TypeReference<List<SimulateGrowthOnPhenotypeDataResults>>() {};
        List<SimulateGrowthOnPhenotypeDataResults> res = caller.jsonrpcCall("fba_tools.simulate_growth_on_phenotype_data", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: merge_metabolic_models_into_community_model</p>
     * <pre>
     * Merge two or more metabolic models into a compartmentalized community model
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.MergeMetabolicModelsIntoCommunityModelParams MergeMetabolicModelsIntoCommunityModelParams}
     * @return   parameter "results" of type {@link us.kbase.fbatools.MergeMetabolicModelsIntoCommunityModelResults MergeMetabolicModelsIntoCommunityModelResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public MergeMetabolicModelsIntoCommunityModelResults mergeMetabolicModelsIntoCommunityModel(MergeMetabolicModelsIntoCommunityModelParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<MergeMetabolicModelsIntoCommunityModelResults>> retType = new TypeReference<List<MergeMetabolicModelsIntoCommunityModelResults>>() {};
        List<MergeMetabolicModelsIntoCommunityModelResults> res = caller.jsonrpcCall("fba_tools.merge_metabolic_models_into_community_model", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: compare_flux_with_expression</p>
     * <pre>
     * Merge two or more metabolic models into a compartmentalized community model
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.CompareFluxWithExpressionParams CompareFluxWithExpressionParams}
     * @return   parameter "results" of type {@link us.kbase.fbatools.CompareFluxWithExpressionResults CompareFluxWithExpressionResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public CompareFluxWithExpressionResults compareFluxWithExpression(CompareFluxWithExpressionParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<CompareFluxWithExpressionResults>> retType = new TypeReference<List<CompareFluxWithExpressionResults>>() {};
        List<CompareFluxWithExpressionResults> res = caller.jsonrpcCall("fba_tools.compare_flux_with_expression", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: check_model_mass_balance</p>
     * <pre>
     * Identifies reactions in the model that are not mass balanced
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.CheckModelMassBalanceParams CheckModelMassBalanceParams}
     * @return   parameter "results" of type {@link us.kbase.fbatools.CheckModelMassBalanceResults CheckModelMassBalanceResults}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public CheckModelMassBalanceResults checkModelMassBalance(CheckModelMassBalanceParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<CheckModelMassBalanceResults>> retType = new TypeReference<List<CheckModelMassBalanceResults>>() {};
        List<CheckModelMassBalanceResults> res = caller.jsonrpcCall("fba_tools.check_model_mass_balance", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: compare_models</p>
     * <pre>
     * Compare models
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.ModelComparisonParams ModelComparisonParams}
     * @return   instance of type {@link us.kbase.fbatools.ModelComparisonResult ModelComparisonResult}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public ModelComparisonResult compareModels(ModelComparisonParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<ModelComparisonResult>> retType = new TypeReference<List<ModelComparisonResult>>() {};
        List<ModelComparisonResult> res = caller.jsonrpcCall("fba_tools.compare_models", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: edit_metabolic_model</p>
     * <pre>
     * Edit models
     * </pre>
     * @param   params   instance of type {@link us.kbase.fbatools.EditMetabolicModelParams EditMetabolicModelParams}
     * @return   instance of type {@link us.kbase.fbatools.EditMetabolicModelResult EditMetabolicModelResult}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public EditMetabolicModelResult editMetabolicModel(EditMetabolicModelParams params, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(params);
        TypeReference<List<EditMetabolicModelResult>> retType = new TypeReference<List<EditMetabolicModelResult>>() {};
        List<EditMetabolicModelResult> res = caller.jsonrpcCall("fba_tools.edit_metabolic_model", args, retType, true, true, jsonRpcContext);
        return res.get(0);
    }
}
