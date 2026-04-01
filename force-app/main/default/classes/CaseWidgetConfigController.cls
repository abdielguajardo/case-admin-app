@RestResource(urlMapping='/case-widget/config')
global with sharing class CaseWidgetConfigController {
  private static final String CONTENT_TYPE = 'application/json';
  private static final String NOT_ALLOWED_BODY = '{"allowed":false}';

  @HttpGet
  global static void getConfig() {
    if (RestContext.response == null) {
      RestContext.response = new RestResponse();
    }
    RestResponse response = RestContext.response;
    response.addHeader('Content-Type', CONTENT_TYPE);

    try {
      String normalizedOrigin = extractDomain(
        RestContext.request.headers.get('Origin')
      );
      if (String.isBlank(normalizedOrigin)) {
        writeNotAllowed(response);
        return;
      }

      List<CaseWidget_Domain__c> domains = queryDomain(normalizedOrigin);
      if (domains.isEmpty()) {
        writeNotAllowed(response);
        return;
      }

      CaseWidget_Domain__c domain = domains[0];
      if (domain.Configs__r == null || domain.Configs__r.isEmpty()) {
        writeNotAllowed(response);
        return;
      }

      response.responseBody = Blob.valueOf(
        JSON.serialize(buildResponse(domain))
      );
    } catch (Exception e) {
      writeNotAllowed(response);
    }
  }

  @TestVisible
  private static String extractDomain(String origin) {
    return CaseWidgetOriginUtil.normalizeOrigin(origin);
  }

  @TestVisible
  private static List<CaseWidget_Domain__c> queryDomain(
    String normalizedOrigin
  ) {
    return [
      SELECT
        Id,
        Domain__c,
        Active__c,
        (
          SELECT
            Id,
            Recaptcha_Site_Key__c,
            Recaptcha_Min_Score__c,
            Modal_Title__c,
            Modal_Description__c,
            Loading_Message__c,
            Success_Message__c,
            Auto_Close_Seconds__c,
            Msg_Email_Required__c,
            Msg_Email_Invalid__c,
            Msg_Subject_Required__c,
            Msg_Description_Required__c
          FROM Configs__r
          LIMIT 1
        ),
        (
          SELECT Id, Value__c, Label__c, Sort_Order__c
          FROM CaseTypes__r
          WHERE Active__c = TRUE
          ORDER BY Sort_Order__c ASC
        )
      FROM CaseWidget_Domain__c
      WHERE Domain__c = :normalizedOrigin AND Active__c = TRUE
      LIMIT 1
    ];
  }

  @TestVisible
  private static Map<String, Object> buildResponse(
    CaseWidget_Domain__c domain
  ) {
    CaseWidget_Config__c config = domain.Configs__r[0];

    Map<String, Object> response = new Map<String, Object>{
      'allowed' => true,
      'recaptcha' => new Map<String, Object>{
        // SECURITY: secret key intentionally excluded
        'siteKey' => config.Recaptcha_Site_Key__c,
        'minScore' => config.Recaptcha_Min_Score__c
      },
      'modal' => new Map<String, Object>{
        'title' => config.Modal_Title__c,
        'description' => config.Modal_Description__c,
        'loadingMessage' => config.Loading_Message__c,
        'successMessage' => config.Success_Message__c,
        'autoCloseSeconds' => config.Auto_Close_Seconds__c
      },
      'validation' => new Map<String, Object>{
        'emailRequired' => config.Msg_Email_Required__c,
        'emailInvalid' => config.Msg_Email_Invalid__c,
        'subjectRequired' => config.Msg_Subject_Required__c,
        'descriptionRequired' => config.Msg_Description_Required__c
      }
    };

    List<Object> caseTypes = new List<Object>();
    if (domain.CaseTypes__r != null) {
      for (CaseWidget_CaseType__c caseType : domain.CaseTypes__r) {
        caseTypes.add(
          new Map<String, Object>{
            'value' => caseType.Value__c,
            'label' => caseType.Label__c,
            'order' => caseType.Sort_Order__c
          }
        );
      }
    }
    response.put('caseTypes', caseTypes);

    return response;
  }

  private static void writeNotAllowed(RestResponse response) {
    response.responseBody = Blob.valueOf(NOT_ALLOWED_BODY);
  }
}
