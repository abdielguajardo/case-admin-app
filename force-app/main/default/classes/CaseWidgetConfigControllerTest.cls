@IsTest
private class CaseWidgetConfigControllerTest {
  @TestSetup
  static void makeData() {
    CaseWidget_Domain__c allowedDomain = new CaseWidget_Domain__c(
      Name = 'Allowed Domain',
      Domain__c = 'example.com',
      Active__c = true
    );
    insert allowedDomain;

    insert new CaseWidget_Config__c(
      Domain__c = allowedDomain.Id,
      Recaptcha_Site_Key__c = 'site-key-123',
      Recaptcha_Secret_Key__c = 'secret-key-123',
      Modal_Title__c = 'Found a problem?',
      Modal_Description__c = 'Tell us what happened.',
      Success_Message__c = 'Thank you.',
      Loading_Message__c = 'Sending...',
      Auto_Close_Seconds__c = 8,
      Recaptcha_Min_Score__c = 0.50,
      Msg_Email_Required__c = 'Email is required',
      Msg_Email_Invalid__c = 'Please enter a valid email address',
      Msg_Subject_Required__c = 'Please provide a subject',
      Msg_Description_Required__c = 'Please describe the issue'
    );

    insert new List<CaseWidget_CaseType__c>{
      new CaseWidget_CaseType__c(
        Domain__c = allowedDomain.Id,
        Value__c = 'Bug',
        Label__c = 'Report a bug',
        Sort_Order__c = 1,
        Active__c = true
      ),
      new CaseWidget_CaseType__c(
        Domain__c = allowedDomain.Id,
        Value__c = 'Question',
        Label__c = 'I have a question',
        Sort_Order__c = 2,
        Active__c = true
      ),
      new CaseWidget_CaseType__c(
        Domain__c = allowedDomain.Id,
        Value__c = 'Inactive',
        Label__c = 'Should not render',
        Sort_Order__c = 3,
        Active__c = false
      )
    };

    insert new CaseWidget_Domain__c(
      Name = 'Inactive Domain',
      Domain__c = 'inactive.example.com',
      Active__c = false
    );

    insert new CaseWidget_Domain__c(
      Name = 'Missing Config Domain',
      Domain__c = 'missing-config.example.com',
      Active__c = true
    );
  }

  @IsTest
  static void testAllowedDomain() {
    Map<String, Object> payload = invokeGet('https://example.com');

    Assert.areEqual(true, payload.get('allowed'));
    Map<String, Object> recaptcha = (Map<String, Object>) payload.get(
      'recaptcha'
    );
    Assert.areEqual('site-key-123', recaptcha.get('siteKey'));
    Assert.areEqual(
      0.50,
      Decimal.valueOf(String.valueOf(recaptcha.get('minScore')))
    );

    Map<String, Object> modal = (Map<String, Object>) payload.get('modal');
    Assert.areEqual('Found a problem?', modal.get('title'));

    List<Object> caseTypes = (List<Object>) payload.get('caseTypes');
    Assert.areEqual(
      2,
      caseTypes.size(),
      'Only active case types should be returned'
    );
  }

  @IsTest
  static void testInactiveDomain() {
    Map<String, Object> payload = invokeGet('https://inactive.example.com');
    Assert.areEqual(false, payload.get('allowed'));
  }

  @IsTest
  static void testUnknownDomain() {
    Map<String, Object> payload = invokeGet('https://unknown.example.com');
    Assert.areEqual(false, payload.get('allowed'));
  }

  @IsTest
  static void testNullOriginHeader() {
    Map<String, Object> payload = invokeGet(null);
    Assert.areEqual(false, payload.get('allowed'));
  }

  @IsTest
  static void testEmptyOriginHeader() {
    Map<String, Object> payload = invokeGet('   ');
    Assert.areEqual(false, payload.get('allowed'));
  }

  @IsTest
  static void testMissingConfig() {
    Map<String, Object> payload = invokeGet(
      'https://missing-config.example.com'
    );
    Assert.areEqual(false, payload.get('allowed'));
  }

  @IsTest
  static void testNoCaseTypes() {
    CaseWidget_Domain__c domain = new CaseWidget_Domain__c(
      Name = 'No Type Domain',
      Domain__c = 'notypes.example.com',
      Active__c = true
    );
    insert domain;

    insert new CaseWidget_Config__c(
      Domain__c = domain.Id,
      Recaptcha_Site_Key__c = 'site-key-456',
      Recaptcha_Secret_Key__c = 'secret-key-456',
      Modal_Title__c = 'Need help?',
      Modal_Description__c = 'Describe the issue.',
      Success_Message__c = 'Thanks.',
      Loading_Message__c = 'Submitting...',
      Auto_Close_Seconds__c = 5,
      Recaptcha_Min_Score__c = 0.60,
      Msg_Email_Required__c = 'Email required',
      Msg_Email_Invalid__c = 'Invalid email',
      Msg_Subject_Required__c = 'Subject required',
      Msg_Description_Required__c = 'Description required'
    );

    Map<String, Object> payload = invokeGet('https://notypes.example.com');
    Assert.areEqual(true, payload.get('allowed'));
    Assert.areEqual(0, ((List<Object>) payload.get('caseTypes')).size());
  }

  @IsTest
  static void testDomainExtractionHttps() {
    Assert.areEqual(
      'example.com',
      CaseWidgetConfigController.extractDomain('https://example.com')
    );
  }

  @IsTest
  static void testDomainExtractionHttp() {
    Assert.areEqual(
      'localhost:3000',
      CaseWidgetConfigController.extractDomain('http://localhost:3000')
    );
  }

  @IsTest
  static void testDomainExtractionWithPath() {
    Assert.areEqual(
      'blog.example.com:8443',
      CaseWidgetConfigController.extractDomain(
        'https://Blog.Example.com:8443/some/path'
      )
    );
  }

  @IsTest
  static void testSecretKeyNotExposed() {
    String responseBody = invokeGetRaw('https://example.com');
    Assert.isFalse(
      responseBody.contains('secret-key-123'),
      'Secret key must not be present in the response body'
    );
    Assert.isFalse(
      responseBody.contains('Recaptcha_Secret_Key__c'),
      'Secret key field name must not be present in the response body'
    );
  }

  private static Map<String, Object> invokeGet(String origin) {
    return (Map<String, Object>) JSON.deserializeUntyped(invokeGetRaw(origin));
  }

  private static String invokeGetRaw(String origin) {
    RestRequest request = new RestRequest();
    request.httpMethod = 'GET';
    request.requestUri = '/services/apexrest/case-widget/config';
    if (origin != null) {
      request.addHeader('Origin', origin);
    }

    RestContext.request = request;
    RestContext.response = new RestResponse();

    Test.startTest();
    CaseWidgetConfigController.getConfig();
    Test.stopTest();

    return RestContext.response.responseBody.toString();
  }
}
