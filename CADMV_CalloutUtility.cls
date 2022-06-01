public with sharing class CADMV_CalloutUtility {

    /**

* @description: This method does the callout based on the https request parameters provided

* @author Sukrut Nagarkar | 02-01-2022

* @param namedCredentialName 

* @param requestBody 

* @param method 

* @param headers 

* @return HttpResponse 

**/    

    public static HttpResponse sendRequest( String namedCredentialName, 

                                           String requestBody, 

                                           String method,

                                           List<CADMV_RequestHeaderWrapper> headers,

                                           Integer timeout, 

                                           String className, 

                                           String methodName

                                          )

    {

        

        

        HttpRequest request = new HttpRequest();

        request.setEndpoint(namedCredentialName);

        request.setMethod(method);

        if(headers != null){

            for(CADMV_RequestHeaderWrapper header : headers){

                request.setHeader(header.key, header.value);

            }

        }

        

        if(requestBody != null){

            request.setBody(requestBody);

        }

        

        

        if(timeout != null){

            request.setTimeout(timeout);

        }

        else{

            request.setTimeout(120000);

        }

        

        Http http = new Http();

        HttpResponse response = http.send(request);

        return response;

    }

    /**

* Method Name  : getAccessToken

* Description  : This method is used to get the access token for the api calls

*/

    public static String getAccessToken(String interfaceName) {

        String accessToken = null;

        

        

        try{

            List<Organization> orgInfo= [

                SELECT Id,InstanceName 

                FROM Organization 

                WITH SECURITY_ENFORCED

                LIMIT 1

            ];

            String orgInstanceName = orgInfo != null && orgInfo.size()>0 && orgInfo[0].InstanceName != null ? orgInfo[0].InstanceName : null;

            if(orgInstanceName != null && interfaceName != null){

                List<CADMV_IntegrationEndpointDetail__mdt> headerAndEndpointDetails = [

                    SELECT Id,MasterLabel,CADMV_ClientId__c,CADMV_ClientSecret__c,

                        CADMV_EndPoint__c,CADMV_TimeOut__c,CADMV_GrantType__c,CADMV_OrgInstanceName__c,

                        CADMV_Scope__c,CADMV_TokenURL__c,CADMV_ClientName__c,CADMV_UIPath__c,CADMV_APIKey__c 

                    FROM CADMV_IntegrationEndpointDetail__mdt

                    WHERE CADMV_OrgInstanceName__c =: orgInstanceName 

                        AND MasterLabel =:interfaceName 

                    WITH SECURITY_ENFORCED

                    LIMIT 1

                ];

                if(headerAndEndpointDetails != null && headerAndEndpointDetails.size()>0){

                    List<CADMV_RequestHeaderWrapper> lstHeaders = new List<CADMV_RequestHeaderWrapper>();

                    CADMV_RequestHeaderWrapper header = new CADMV_RequestHeaderWrapper();

                    header.key = CADMV_AppConstants.HEADER_KEY_ACCEPT;

                    header.value = CADMV_AppConstants.HEADER_VALUE_APP_JSON;

                    lstHeaders.add(header);

                    header = new CADMV_RequestHeaderWrapper();

                    header.key = CADMV_AppConstants.HEADER_KEY_CONTENT_TYPE;

                    if(headerAndEndpointDetails[0].MasterLabel == CADMV_AppConstants.RPACALLOUT)

                    {

                        header.value =CADMV_AppConstants.HEADER_VALUE_URL_ENCODED;

                    }

                    else{

                        header.value =CADMV_AppConstants.HEADER_VALUE_APP_JSON;

                    }

                    lstHeaders.add(header);

                    if(headerAndEndpointDetails[0].MasterLabel == CADMV_AppConstants.RPACALLOUT)

                    {

                        String grantType =headerAndEndpointDetails[0].CADMV_GrantType__c;

                        String clientId = headerAndEndpointDetails[0].CADMV_ClientId__c;

                        String clientSecret = headerAndEndpointDetails[0].CADMV_ClientSecret__c;

                        String scope = headerAndEndpointDetails[0].CADMV_Scope__c;

                        String reqbody = 'grant_type='+grantType+'&client_id='+clientId+'&client_secret='+clientSecret+'&scope='+scope;

                    	HttpResponse responseToken = CADMV_CalloutUtility.sendRequest(headerAndEndpointDetails[0].CADMV_TokenURL__c,reqbody,CADMV_AppConstants.REQUEST_METHOD_GET,lstHeaders,NULL,CADMV_AppConstants.CADMV_RPAAPICALLOUTS_CLASS,CADMV_AppConstants.GET_ACCESS_TOKEN);

                        if(responseToken.getStatusCode() == 200) 

                        {

                            Map<String, Object> authMap = (Map<String, Object>) JSON.deserializeUntyped(responseToken.getBody());

                           	accessToken = (String)authMap.get('access_token');

                        }

                    }

                }

                

            }

            return accessToken;

        }catch(Exception ex){

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

        return accessToken;

    }

    /**

    * Method Name  : getEndpointAndHeaderDetails

    * Description  :  Method to get endpoint URL and Header list 

    */

    public static HeaderAndEndpointWrapper getEndpointAndHeaderDetails(String interfaceName){

        HeaderAndEndpointWrapper headerAndEndpoints = new HeaderAndEndpointWrapper();

        try{

            /* In the below query we have not used With SECURITY_Enforced and Schema.IsAccessible because customer portal users do not have access to Organization Object.

            * https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_organization.htm

            * Organization related details are only used for backend processing and data will not be shared with portal users.

            */

            List<Organization> orgInfo= [

                SELECT Id, InstanceName 

                FROM Organization 

                WITH SECURITY_ENFORCED

                LIMIT 1

            ];

            String orgInstanceName = orgInfo != null && orgInfo.size()>0 && orgInfo[0].InstanceName != null ? orgInfo[0].InstanceName : null;

            if(orgInstanceName != null && interfaceName != null){

                List<CADMV_IntegrationEndpointDetail__mdt> headerAndEndpointDetails = [

                    SELECT Id,MasterLabel,CADMV_ClientId__c,CADMV_ClientSecret__c,CADMV_AuthorizationToken__c,

                        CADMV_EndPoint__c,CADMV_TimeOut__c,CADMV_GrantType__c,CADMV_OrgInstanceName__c,

                        CADMV_Scope__c,CADMV_TokenURL__c,CADMV_ClientName__c,CADMV_UIPath__c,CADMV_APIKey__c 

                    FROM CADMV_IntegrationEndpointDetail__mdt

                    WHERE CADMV_OrgInstanceName__c =: orgInstanceName 

                        AND MasterLabel =:interfaceName 

                    WITH SECURITY_ENFORCED

                    LIMIT 1

                ];

                if(headerAndEndpointDetails != null && headerAndEndpointDetails.size()>0){

                    List<CADMV_RequestHeaderWrapper> lstHeaders = new List<CADMV_RequestHeaderWrapper>();

                    CADMV_RequestHeaderWrapper header = new CADMV_RequestHeaderWrapper();

                    header.key = CADMV_AppConstants.HEADER_KEY_ACCEPT;

                    header.value = CADMV_AppConstants.HEADER_VALUE_APP_JSON;

                    lstHeaders.add(header);

                    header = new CADMV_RequestHeaderWrapper();

                    header.key = CADMV_AppConstants.HEADER_KEY_CONTENT_TYPE;

                    header.value =CADMV_AppConstants.HEADER_VALUE_APP_JSON;

                    lstHeaders.add(header);

                    

                    if(headerAndEndpointDetails[0].CADMV_ClientId__c != null && headerAndEndpointDetails[0].CADMV_ClientSecret__c != null){

                        header = new CADMV_RequestHeaderWrapper();

                        header.key = CADMV_AppConstants.HEADER_KEY_CLIENT_ID;

                        header.value = headerAndEndpointDetails[0].CADMV_ClientId__c ;

                        lstHeaders.add(header);

                        header = new CADMV_RequestHeaderWrapper();

                        header.key = CADMV_AppConstants.HEADER_KEY_CLIENT_SECRET;

                        header.value = headerAndEndpointDetails[0].CADMV_ClientSecret__c;

                        lstHeaders.add(header);

                    }

                    if(headerAndEndpointDetails[0].CADMV_UIPath__c != null && headerAndEndpointDetails[0].CADMV_APIKey__c != null){

                        header = new CADMV_RequestHeaderWrapper();

                        header.key = CADMV_AppConstants.HEADER_UI_PATH;

                        header.value = headerAndEndpointDetails[0].CADMV_UIPath__c;

                        lstHeaders.add(header);

                        header = new CADMV_RequestHeaderWrapper();

                        header.key = CADMV_AppConstants.HEADER_API_KEY;

                        header.value = headerAndEndpointDetails[0].CADMV_APIKey__c;

                        lstHeaders.add(header);

                    }

                    

                    headerAndEndpoints.listofheaders= lstHeaders;

                    headerAndEndpoints.endpointURL = headerAndEndpointDetails[0].CADMV_EndPoint__c;

                    headerAndEndpoints.tokenURL = headerAndEndpointDetails[0].CADMV_TokenURL__c;

                    headerAndEndpoints.clientName = headerAndEndpointDetails[0].CADMV_ClientName__c;

                    headerAndEndpoints.grantType = headerAndEndpointDetails[0].CADMV_GrantType__c;

                    headerAndEndpoints.timeOut = headerAndEndpointDetails[0].CADMV_TimeOut__c != null ? headerAndEndpointDetails[0].CADMV_TimeOut__c.intValue() : null;

                }

                

            }

        }catch(Exception ex) {

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

        return headerAndEndpoints;

    }

    /**

* Method Name  : logCalloutStatus

* Description  : This method is used to log callout status in the Integration Callout Status object.

*/

    public static void logCalloutStatus(String className,String methodName, String interfaceName, String requestBody,HttpResponse response)

    {

        try{

            CADMV_IntegrationCalloutStatus__c newCall = new CADMV_IntegrationCalloutStatus__c();

            newCall.CADMV_ClassName__c = className;

            newCall.CADMV_MethodName__c = methodName;

            newCall.CADMV_InterfaceName__c = interfaceName;        

            newCall.CADMV_Payload__c = requestBody.length() > 131072? requestBody.substring(1, 131072):requestBody;

            newCall.CADMV_Response__c = response.toString();

            if(response.getStatusCode() == 201 || response.getStatusCode() == 200 )

            {        

                newCall.CADMV_Status__c = CADMV_AppConstants.CALLOUT_SUCCESS;

            }

            else

            {

                newCall.CADMV_Status__c = CADMV_AppConstants.CALLOUT_FAIL;           

            }        

           

            insert Security.stripInaccessible(AccessType.CREATABLE, new List<CADMV_IntegrationCalloutStatus__c> { newCall }).getRecords(); //SAST

        }catch(Exception ex) {

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

        

    }

	        /**

* Method Name  : sendRequestWithQueryParams

* Description  : This method is used to create endpointUrl with query parameters (to be used in GET methods).

*/

    

    public static HttpResponse sendRequestWithQueryParams(string endpointURL,

                                                    Map<String,String> queryParams,

                                                    String requestBody, 

                                           			String method,

                                           			List<CADMV_RequestHeaderWrapper> headers,

                                           			Integer timeout, 

                                           			String className, 

                                           			String methodName){

        try{

            String endUrlWithQueryParams; 

            if(endpointURL!=null || endpointURL!='' ){

                endUrlWithQueryParams = endpointURL;

                if(!queryParams.isEmpty()){

                    endUrlWithQueryParams += '?';

                    integer count = 0;

                    for(String key: queryParams.keySet()){

                        if(count>0){

                            endUrlWithQueryParams += '&';

                        }

                        endUrlWithQueryParams += key;

                        endUrlWithQueryParams += '=' + queryParams.get(key);

                        count++;

                    }

                }

            }

            System.debug('Final URL ::'+endUrlWithQueryParams);

            return sendRequest(endUrlWithQueryParams, requestBody, method, headers, timeout, className, methodName);

        }catch(Exception ex) {

            CADMV_CreateErrorLogException.logApplicationError(ex);

            return null;

        }

    }

    

    public class HeaderAndEndpointWrapper {

        public CADMV_RequestHeaderWrapper[] listofheaders { get;set; }

        public string endpointURL { get;set; }

        public string tokenURL { get;set; }

        public string clientId { get;set; }

        public string clientSecret { get;set; }

        public string clientName { get;set; }

        public string scope { get;set; }

        public string grantType { get;set; }

        public Integer timeOut { get;set; }

    }

    

}