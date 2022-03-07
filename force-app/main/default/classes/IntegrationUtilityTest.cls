@isTest
private class IntegrationUtilityTest {
    static IntegrationCallouts__c integrationSettings;

    static {
        integrationSettings = createIntegrationSettings(0);
    }
    
    // This usually lives in a TestDataFactory class
    public static IntegrationCallouts__c createIntegrationSettings(integer callouts) {
        IntegrationCallouts__c ic = new IntegrationCallouts__c(
            Name                    = 'Default',
            CalloutsToday__c        = callouts,
            MaximumDailyCallouts__c = 1000,
            Today__c                = System.today()
        );

        insert ic;
        return ic;
    }

    @isTest static void testResponseClass() {
        IntegrationUtility.Response response;

        // Successful response from GET
        response = new IntegrationUtility.Response(200, 'Response GET Body');
        system.assertEquals(200, response.code, 'Incorrect response code value');
        system.assertEquals('Response GET Body', response.body, 'Incorrect body content');
        system.assert(response.success, 'Successful response not recognized');

        // Successful response from POST
        response = new IntegrationUtility.Response(201, 'Response POST Body');
        system.assertEquals(201, response.code, 'Incorrect response code value');
        system.assert(response.success, 'Successful response not recognized');

        // Failure response
        response = new IntegrationUtility.Response(500, 'Failed response Body');
        system.assert(!response.success, 'Failed response incorrectly treated as successful');
    }

    @isTest static void testErrorClass() {
        IntegrationUtility.Error error = new IntegrationUtility.Error('Oops', 'Somthing went wrong');
        system.assertEquals('Oops', error.error, 'Error type ');
        system.assertEquals('Somthing went wrong', error.error_description, 'Error type ');
    }


    @isTest static void testCalloutNoUrl() {
        // IntegrationUtility.Response response;
        // IntegrationUtility googleMaps = new IntegrationUtility(null);
				//
        // Test.startTest();
        // Test.setMock(HttpCalloutMock.class, new NIPRAPICalloutMock(true));
        // response = googleMaps.Callout('', 'GET');
        // Test.stopTest();
				//
        // system.assert(!response.success, 'No URL provided yet callout returned success');
    }

    @isTest static void testCalloutUrlEndsWithNoSlash() {
        // IntegrationUtility.Response response;
        // IntegrationUtility google = new IntegrationUtility('google.com');
				//
        // Test.startTest();
        // Test.setMock(HttpCalloutMock.class, new NIPRAPICalloutMock(true));
        // response = google.Callout('key?=', 'GET');
        // Test.stopTest();
				//
        // system.assert(response.success);
    }

    @isTest static void testLogCalloutException() {
        IntegrationUtility callout = new IntegrationUtility('https://www.somewhere.com/');
        string message = callout.LogCalloutException('Oops: Read timed out', 'test', 'GET', null, null);

        system.assert(string.IsNotBlank(message), 'Exception message not created');
        system.assert(message.contains('Please try again'), 'Exception message is incomplete');
        system.assert(message.contains('Message'), 'Exception message does not containg Message portion');
        system.assert(message.contains('Oops: Read timed out'), 'Exception message does not contain actual error');
    }
}