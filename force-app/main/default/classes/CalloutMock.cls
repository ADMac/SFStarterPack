@isTest
public class CalloutMock implements HttpCalloutMock {

    protected Integer code;
    protected String body;

    public CalloutMock(boolean successful) {
        code = successful ? 200 : 403;
    }

    public CalloutMock(boolean successful, String sampleResponse) {
        code = successful ? 200 : 403;
        body = sampleResponse;
    }
    
    public HTTPResponse Respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(code);
        return response;
    }
}