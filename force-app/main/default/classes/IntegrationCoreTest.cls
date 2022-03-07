@isTest
private class IntegrationCoreTest {

    @isTest static void testSettingAutogenerationViaParameter() {
        IntegrationCallouts__c ic  = IntegrationCallouts__c.getInstance('Default');
        system.assertEquals(null, ic, 'Integration Callouts setting should be absent');

        ic = IntegrationCore.Callouts;
        system.assertNotEquals(null, ic, 'Integration Callouts setting should be present');
        system.assertEquals('Default', ic.Name, 'Default setting name incorrectly set');
        system.assertEquals(0, ic.CalloutsToday__c, 'Initial callout counter not set to zero');
    }

    @isTest static void testSettingAutogeneration() {
        IntegrationCallouts__c ic  = IntegrationCallouts__c.getInstance('Default');
        system.assertEquals(null, ic, 'Integration Callouts setting should be absent');

        ic = IntegrationCore.getCallout();
        system.assertNotEquals(null, ic, 'Integration Callouts setting should be present');
        system.assertEquals('Default', ic.Name, 'Default setting name incorrectly set');
        system.assertEquals(0, ic.CalloutsToday__c, 'Initial callout counter not set to zero');
    }

    @isTest static void testDefaultDelayedCommits() {
        IntegrationCore.DelayedDML delay = IntegrationCore.DelayedCommits;
        system.assertNotEquals(null, delay, 'DelayedDML object not instantiated');
        system.assert(!delay.DmlLogs, 'DML Logs parameter incorrectly set');
        system.assert(!delay.DmlCallouts, 'DML Callouts parameter incorrectly set');
    }

    @isTest static void testDefaultCommitDelayed() {
        // Verify property instantiation
        system.assert(!IntegrationCore.isCommitDelayed, 'Property default not properly set');

        // Verify processing
        IntegrationCore.Log('description', 'errorMessage');
        list<IntegrationLog__c> logs = IntegrationCore.LogEntries;

        system.assertEquals(1, logs.size(), 'Log entry not queued for commit');
        IntegrationCore.CommitDelayed();
        system.assert(logs.isEmpty(), 'Log queue not cleared upon commit');
    }

    @isTest static void testDMLOptions() {
        database.DMLOptions options = IntegrationCore.getDMLOpt();
        system.assertNotEquals(null, options, 'DML options not instantiated');
        system.assert(options.allowFieldTruncation, 'Field trunction incorrectly set');
        system.assert(options.optAllOrNone, 'All or None incorrectly set');
    }

    @isTest static void testLogging() {
        list<IntegrationLog__c> logs = IntegrationCore.LogEntries;
        system.assertNotEquals(null, logs, 'Log list not instantiated');
        system.assert(logs.isEmpty(), 'New log list should be empty');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('endpoint');

        IntegrationCore.Log('description', 'resource', 'method', req, null, 200, 'errorMessage');
        system.assertEquals(1, logs.size(), 'New log entry not added correctly to log list');

        IntegrationLog__c entry = logs[0];
        system.assertEquals('description', entry.Description__c, 'Description not correctly logged');
        system.assertEquals('resource', entry.Resource__c, 'Resource not correctly logged');
        system.assertEquals('method', entry.Method__c, 'Method not correctly logged');
        system.assertEquals('endpoint', entry.Endpoint__c, 'Request not correctly logged');
        system.assertEquals('errorMessage', entry.Response__c, 'Response not correctly logged');
        system.assertEquals('200', entry.ResponseCode__c, 'Code not correctly logged');
        system.assert(!entry.IsError__c, 'Error flag not correctly logged');
    }
}