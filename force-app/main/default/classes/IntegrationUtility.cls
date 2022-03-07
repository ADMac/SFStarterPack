//Manages generic integration via REST
global with sharing class IntegrationUtility {
    // Property to flag that DML operations should not be done until the end of the transaction
    public boolean DelayedCommit { get { if (DelayedCommit == null) DelayedCommit = false; return DelayedCommit; } set; }
    // Base url being accessed for REST requests
    @TestVisible
    private string RequestUrl;
    // Identify if success messages are to be logged
    public boolean DetailLoggingEnabled { get { if (DetailLoggingEnabled == null) DetailLoggingEnabled = false; return DetailLoggingEnabled; } set; }

    public IntegrationUtility(string url) {
        DetailLoggingEnabled = false;

        if (string.isNotBlank(url)) {
            RequestUrl = url.trim();

            if (!RequestUrl.endsWith('/'))
                RequestUrl += '/';
        }
    }

    public IntegrationUtility(string url, boolean detailedLogging) {
        DetailLoggingEnabled = detailedLogging;

        if (string.isNotBlank(url)) {
            RequestUrl = url.trim();

            if (!RequestUrl.endsWith('/'))
                RequestUrl += '/';
        }
    }

    // generic Method that is called by other classes to to execute an api call, and handles logging
    public Response Callout(string resource, string method) { return Callout(resource, method, null, null, null, null); }
    public Response Callout(string resource, string method, map<string,string> headers) { 
        return Callout(resource, method, null, null, headers, null); 
    }
    public Response Callout(string resource, string method, DOM.Document bodyDocument, map<string,string> headers) {
        return Callout(resource, method, null, bodyDocument, headers, null);
    }
    public Response Callout(string resource, string method, string body, DOM.Document bodyDocument, map<string,string> headers, string query) {
        if (!DelayedCommit)
            DelayedCommit = true;

        if (IntegrationCore.Callouts.Today__c != system.now().addHours(-8).dateGMT()) {
            IntegrationCore.Callouts.Today__c = system.now().addHours(-8).dateGMT();
            IntegrationCore.Callouts.CalloutsToday__c = 0;
        } else
            IntegrationCore.Callouts.CalloutsToday__c += 1;

        //  Flag for delayed commit
        IntegrationCore.DelayedCommits.DmlCallouts = true;

        Response calloutResponse;

        if (IntegrationCore.Callouts.CalloutsToday__c <= IntegrationCore.Callouts.MaximumDailyCallouts__c) {
            // Check callout limits and log if necessarylog a Limit Exception
            if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
                IntegrationCore.Log('Limit Exception', resource, method, null, null, 55, 'Maximum daily callout limit hit. Limit is reset at 12 AM PST.');
                calloutResponse = new Response(55, 'Limit Exception');
            } else if (string.IsBlank(RequestUrl)) {
                calloutResponse = new Response(0, 'Callout could not be perfomed -- No API Base URL specified');
            } else {
                // Under limits and the utility instance is prepped, so make the callout
                HttpRequest req = new HttpRequest();
                HttpResponse res = new HttpResponse();
                Http h = new Http();

                // Prepare the endpoint for the request
                string endpoint = RequestUrl + resource;
                // Include query parameters when present
                if (string.isNotBlank(query))
                    endpoint += '?' + query;

                req.setEndpoint(endpoint);
                req.setMethod(method);
                req.setTimeout(120000);

                // Prepare the header
                req.setHeader('Accept', '*/*');

                if (headers != null) {
                    for (string header : headers.keySet())
                        req.setHeader(header, headers.get(header));
                }

                // Set the request body when present
                if (body != null)
                    req.setBody(body);
                if (bodyDocument != null) 
                    req.setBodyDocument(bodyDocument);
                // Send the request, and evaluate the response
                try {
                    // make the callout
                    res = h.send(req);

                    // evaluate if transactuion was successful
                    if (res.getStatusCode() == 200) {
                        calloutResponse = new Response(res);

                        if (DetailLoggingEnabled)
                            IntegrationCore.Log('Successful Transaction', resource, method, req, res, calloutResponse.code, calloutResponse.body);
                    } else {
                        // error occured - deserialize response
                        Error err = (Error)JSON.deserialize(res.getBody(), Error.class);
                        calloutResponse = new Response(res.getStatusCode(), err.error + ': ' + err.error_description);
                        IntegrationCore.Log(err.error, resource, method, req, res, res.getStatusCode(), err.error_description);
                    }
                } catch (exception e) {
                    // exception occured
                    string msg = LogCalloutException(e.getMessage(), resource, method, req, res);
                    calloutResponse = new Response(0, msg);
                }
            }
        } else
            calloutResponse = new Response(0, 'Callout could not be perfomed -- exceeded daily callout limit');

        return calloutResponse;
    }

    @TestVisible
    private string LogCalloutException(string error, string resource, string method, HttpRequest request, HttpResponse response) {
        string dsc = 'Callout Exception';
        string msg = 'Callout Exception:  ';

        //  Add user friendly messages
        if (error.contains('Read timed out')) {
            dsc += ' - API Timeout';
            msg += 'The API failed to respond within the timeframe allowed by Salesforce.  Please try again.';
        }

        //  Add details
        msg += '\r\n\r\n';
        msg += 'Message:  ' + error + '\r\n\r\n';

        IntegrationCore.Log(dsc, resource, method, request, response, 0, msg);

        return msg;
    }


    ////////////////////////////////////
    //  Support Classes
    ////////////////////////////////////

    // property to hold response for caller
    global class Response {
        public integer code { get; set; }
        public string body { get; set; }
        public boolean success { get; set; }
        public map<string, string> header { get { if (header == null) header = new map<string, string>(); return header; } private set; }
        public DOM.Document bodyDocument { get; set; }

        public Response(integer code, string body) {
            this.code = code;
            this.body = body;
            this.success = (code == 200 || code == 201);
        }

        public Response(HttpResponse res) {
            this(res.getStatusCode(), res.getBody());

            for (string key : res.getHeaderKeys()) {
                if (key != null)
                    header.put(key, res.getHeader(key));
            }
            this.bodyDocument = res.getBodyDocument();
        }
    }

    // property to hold errors for caller
    public class Error {
        public string error { get; set; }
        public string error_description { get; set; }

        public Error(string error, string description) {
            this.error = error;
            this.error_description = description;
        }
    }
}