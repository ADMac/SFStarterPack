public with sharing class IntegrationCore {
    // Access to callout custom setting
    public static IntegrationCallouts__c Callouts { get { if (Callouts == null) Callouts = getCallout(); return Callouts; } set; }
    // Access to delayed commit tracking
    public static DelayedDML DelayedCommits { get { if (DelayedCommits == null) DelayedCommits = new DelayedDML(); return DelayedCommits; } private set; }
    // Flag controlling whether dml should not be done until the end of the transaction
    public static boolean isCommitDelayed { get { if (isCommitDelayed == null) isCommitDelayed = false; return isCommitDelayed; } set; }

    // Obtain custom setting record to store details about the integration callouts
    public static IntegrationCallouts__c getCallout() {
        // TODO: Check if user has CRUD/FLS access

        // Attempt to obtain existing record
        IntegrationCallouts__c ic  = IntegrationCallouts__c.getInstance('Default');

        // Create a new record when an existing record is not found
        if (ic == null) {
            ic = new IntegrationCallouts__c (
                Name = 'Default',
                Today__c =system.now().addHours(-7).dateGMT(),
                CalloutsToday__c = 0
            );

            // Store the new record
            insert ic;
        }

        // Return custom setting record
        return ic;
    }

    // Commit anything delayed
    public static void CommitDelayed() {
        try {
            if (DelayedCommits.DmlLogs || !LogEntries.isEmpty())
                CommitLog();

            if (DelayedCommits.DmlCallouts)
                update Callouts;
        } catch (exception e) {
            system.debug('An exception was encountered while trying to perform delayed commits:  ' + DelayedCommits + '\r\n' + e.getMessage() + '\r\n' + e.getStackTraceString());
        }
    }

    // Allow truncating to prevent DML errors (if text received > permitted field length)
    private static database.DMLOptions DMLOpt;
    public static database.DMLOptions getDMLOpt() {
        if (DMLOpt == null) {
            DMLOpt = new database.DMLOptions();
            DMLOpt.allowFieldTruncation = true;
            DMLOpt.optAllOrNone = true;
        }
        return DMLOpt;
    }

    ////////////////////////////////////
    //  Logging
    ////////////////////////////////////

    // Property to hold log entries
    @TestVisible
    private static list<IntegrationLog__c> LogEntries { get { if (LogEntries == null) LogEntries = new list<IntegrationLog__c>(); return LogEntries; } set; }

    private static void CommitLog() {
        // TODO: Check if user has CRUD/FLS access

        // Insert the pending logs
        if (!LogEntries.isEmpty()) {
            try {
                database.insert(LogEntries, getDMLOpt());
            } catch (exception e) {
                system.debug('Log Creation Error:  \r\n\r\n' + e.getStackTraceString());
            }

            // Reset the variable in case the caller reuses the class.
            LogEntries.clear();
        }
    }

    public static void Log(string description, string errorMessage) { 
        Log(description, null, null, null, null, null, errorMessage); 
    }
    public static void Log(string description, string resource, string method, HttpRequest request, HttpResponse response, integer responseCode, string errorMessage) {
        // TODO: Check if user has CRUD/FLS access

        // Set log timestamp
        IntegrationLog__c logEntry = new IntegrationLog__c(Datetime__c = system.now());

        // Set log resource, if available
        if (resource != null)
            logEntry.Resource__c = resource;

        // Set log method, if available
        if (method != null)
            logEntry.Method__c = method;

        // Set request made, if available
        if (request != null) {
            logEntry.Endpoint__c = request.getEndpoint();
            logEntry.RequestBody__c = request.getBody();
        }

        // Set response received / error message
        if (response != null && string.isNotBlank(response.getBody()))
            logEntry.Response__c = response.getBody();
        else
            logEntry.Response__c = errorMessage;

        // Identify whether or not this is an error log
        string code = string.valueof(responseCode);
        logEntry.ResponseCode__c = code;
        logEntry.IsError__c = !(code == '201' || code =='200');
        logEntry.Description__c = description;

        // Add to the list of log entries (to be committed together later)
        LogEntries.add(logEntry);
    }

    // Delete the specified set of integration logs
    public static Id PurgeLogs(set<Id> logs) {
        PurgeData purge = new PurgeData('IntegrationLog__c', logs);
        return database.executeBatch(purge);
    }

    // Delete all of integration logs
    public static Id PurgeAllLogs() {
        return PurgeLogs(new map<Id, IntegrationLog__c>([SELECT Id FROM IntegrationLog__c LIMIT 50000]).KeySet());
    }


    ////////////////////////////////////
    //  Support Classes
    ////////////////////////////////////

    // Class to help with delayed commits
    public class DelayedDML {
        public boolean DmlLogs { get; set; }
        public boolean DmlCallouts { get; set; }
        public DelayedDML() {
            DmlLogs = false;
            DmlCallouts = false;
        }
    }
}