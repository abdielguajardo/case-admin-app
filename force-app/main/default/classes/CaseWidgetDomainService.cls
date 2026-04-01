public with sharing class CaseWidgetDomainService {
  private static final String CASE_DOMAIN_FIELD = 'CaseWidget_Domain__c';

  @AuraEnabled(cacheable=true)
  public static List<Map<String, Object>> getDomains() {
    try {
      List<CaseWidget_Domain__c> domains = [
        SELECT
          Id,
          Name,
          Domain__c,
          Active__c,
          Notes__c,
          CreatedDate,
          (
            SELECT
              Id,
              Domain__c,
              Recaptcha_Site_Key__c,
              Recaptcha_Secret_Key__c,
              Modal_Title__c,
              Modal_Description__c,
              Success_Message__c,
              Loading_Message__c,
              Auto_Close_Seconds__c,
              Recaptcha_Min_Score__c,
              Msg_Email_Required__c,
              Msg_Email_Invalid__c,
              Msg_Subject_Required__c,
              Msg_Description_Required__c
            FROM Configs__r
          ),
          (
            SELECT Id, Domain__c, Value__c, Label__c, Sort_Order__c, Active__c
            FROM CaseTypes__r
            ORDER BY Sort_Order__c ASC
          )
        FROM CaseWidget_Domain__c
        ORDER BY CreatedDate DESC
      ];

      Set<Id> domainIds = new Set<Id>();
      for (CaseWidget_Domain__c domain : domains) {
        domainIds.add(domain.Id);
      }
      Set<Id> recentActivityDomainIds = getRecentActivityDomainIds(domainIds);

      List<Map<String, Object>> wrappers = new List<Map<String, Object>>();
      for (CaseWidget_Domain__c domain : domains) {
        Map<String, Object> wrapper = new Map<String, Object>();
        wrapper.put('domain', domain);
        wrapper.put('caseTypes', domain.CaseTypes__r);

        if (domain.Configs__r != null && !domain.Configs__r.isEmpty()) {
          CaseWidget_Config__c config = domain.Configs__r[0];
          wrapper.put('config', config);
          wrapper.put(
            'hasSecretKey',
            String.isNotBlank(config.Recaptcha_Secret_Key__c)
          );
        } else {
          wrapper.put('config', null);
          wrapper.put('hasSecretKey', false);
        }

        wrapper.put(
          'hasRecentActivity',
          recentActivityDomainIds.contains(domain.Id)
        );
        wrappers.add(wrapper);
      }
      return wrappers;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error loading domains: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<CaseWidget_CaseType__c> getCaseTypesForDomain(
    Id domainId
  ) {
    try {
      return [
        SELECT Id, Domain__c, Value__c, Label__c, Sort_Order__c, Active__c
        FROM CaseWidget_CaseType__c
        WHERE Domain__c = :domainId AND Active__c = TRUE
        ORDER BY Sort_Order__c ASC
      ];
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error loading case types: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static Boolean validateDomainUniqueness(String domain, Id domainId) {
    try {
      String cleanDomain = CaseWidgetOriginUtil.normalizeOrigin(domain);
      Integer count;
      if (domainId == null) {
        count = [
          SELECT COUNT()
          FROM CaseWidget_Domain__c
          WHERE Domain__c = :cleanDomain
        ];
      } else {
        count = [
          SELECT COUNT()
          FROM CaseWidget_Domain__c
          WHERE Domain__c = :cleanDomain AND Id != :domainId
        ];
      }
      return count == 0;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error validating domain: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static Id saveDomain(
    String domainJson,
    String configJson,
    String caseTypesJson
  ) {
    try {
      Map<String, Object> domainData = (Map<String, Object>) JSON.deserializeUntyped(
        domainJson
      );
      Map<String, Object> configData = (Map<String, Object>) JSON.deserializeUntyped(
        configJson
      );
      List<Object> caseTypesData = (List<Object>) JSON.deserializeUntyped(
        caseTypesJson
      );

      if (domainData == null) {
        domainData = new Map<String, Object>();
      }
      if (configData == null) {
        configData = new Map<String, Object>();
      }
      if (caseTypesData == null) {
        caseTypesData = new List<Object>();
      }

      CaseWidget_Domain__c domainRecord = buildDomainRecord(domainData);
      upsert domainRecord;

      CaseWidget_Config__c configRecord = buildConfigRecord(
        configData,
        domainRecord.Id
      );
      if (configRecord.Id == null) {
        List<CaseWidget_Config__c> existingConfigs = [
          SELECT Id
          FROM CaseWidget_Config__c
          WHERE Domain__c = :domainRecord.Id
          LIMIT 1
        ];
        if (!existingConfigs.isEmpty()) {
          configRecord.Id = existingConfigs[0].Id;
        }
      }
      upsert configRecord;

      syncCaseTypes(domainRecord.Id, caseTypesData);
      return domainRecord.Id;
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException('Error saving domain: ' + e.getMessage());
    }
  }

  @AuraEnabled
  public static void toggleDomainActive(Id domainId, Boolean active) {
    try {
      update new CaseWidget_Domain__c(Id = domainId, Active__c = active);
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error updating domain status: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static void deleteDomain(Id domainId) {
    try {
      if (hasCaseDomainField()) {
        Integer recentCases = Database.countQuery(
          'SELECT COUNT() FROM Case' +
            ' WHERE ' +
            CASE_DOMAIN_FIELD +
            ' = :domainId' +
            ' AND CreatedDate = LAST_N_DAYS:30'
        );
        if (recentCases > 0) {
          throw new AuraHandledException(
            'This domain has recent activity and cannot be deleted.'
          );
        }
      }

      List<CaseWidget_CaseType__c> caseTypes = [
        SELECT Id
        FROM CaseWidget_CaseType__c
        WHERE Domain__c = :domainId
      ];
      if (!caseTypes.isEmpty()) {
        delete caseTypes;
      }

      delete new CaseWidget_Domain__c(Id = domainId);
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error deleting domain: ' + e.getMessage()
      );
    }
  }

  private static CaseWidget_Domain__c buildDomainRecord(
    Map<String, Object> domainData
  ) {
    CaseWidget_Domain__c domainRecord = new CaseWidget_Domain__c();
    if (domainData.containsKey('Id') && domainData.get('Id') != null) {
      domainRecord.Id = Id.valueOf(String.valueOf(domainData.get('Id')));
    }
    domainRecord.Name = (String) domainData.get('Name');
    String domainValue = (String) domainData.get('Domain__c');
    domainRecord.Domain__c = CaseWidgetOriginUtil.normalizeOrigin(domainValue);
    domainRecord.Active__c = (Boolean) domainData.get('Active__c');
    domainRecord.Notes__c = (String) domainData.get('Notes__c');
    return domainRecord;
  }

  private static CaseWidget_Config__c buildConfigRecord(
    Map<String, Object> configData,
    Id domainId
  ) {
    CaseWidget_Config__c configRecord = new CaseWidget_Config__c();
    if (configData.containsKey('Id') && configData.get('Id') != null) {
      configRecord.Id = Id.valueOf(String.valueOf(configData.get('Id')));
    }
    configRecord.Domain__c = domainId;
    configRecord.Recaptcha_Site_Key__c = (String) configData.get(
      'Recaptcha_Site_Key__c'
    );
    String secretKey = (String) configData.get('Recaptcha_Secret_Key__c');
    if (configRecord.Id == null || String.isNotBlank(secretKey)) {
      configRecord.Recaptcha_Secret_Key__c = secretKey;
    }
    configRecord.Modal_Title__c = (String) configData.get('Modal_Title__c');
    configRecord.Modal_Description__c = (String) configData.get(
      'Modal_Description__c'
    );
    configRecord.Success_Message__c = (String) configData.get(
      'Success_Message__c'
    );
    configRecord.Loading_Message__c = (String) configData.get(
      'Loading_Message__c'
    );
    configRecord.Auto_Close_Seconds__c = toDecimal(
      configData.get('Auto_Close_Seconds__c')
    );
    configRecord.Recaptcha_Min_Score__c = toDecimal(
      configData.get('Recaptcha_Min_Score__c')
    );
    configRecord.Msg_Email_Required__c = (String) configData.get(
      'Msg_Email_Required__c'
    );
    configRecord.Msg_Email_Invalid__c = (String) configData.get(
      'Msg_Email_Invalid__c'
    );
    configRecord.Msg_Subject_Required__c = (String) configData.get(
      'Msg_Subject_Required__c'
    );
    configRecord.Msg_Description_Required__c = (String) configData.get(
      'Msg_Description_Required__c'
    );
    return configRecord;
  }

  private static void syncCaseTypes(Id domainId, List<Object> caseTypesData) {
    Set<Id> incomingIds = new Set<Id>();
    for (Object item : caseTypesData) {
      Map<String, Object> caseTypeData = (Map<String, Object>) item;
      if (caseTypeData.containsKey('Id') && caseTypeData.get('Id') != null) {
        incomingIds.add(Id.valueOf(String.valueOf(caseTypeData.get('Id'))));
      }
    }

    List<CaseWidget_CaseType__c> toDelete;
    if (incomingIds.isEmpty()) {
      toDelete = [
        SELECT Id
        FROM CaseWidget_CaseType__c
        WHERE Domain__c = :domainId
      ];
    } else {
      toDelete = [
        SELECT Id
        FROM CaseWidget_CaseType__c
        WHERE Domain__c = :domainId AND Id NOT IN :incomingIds
      ];
    }
    if (!toDelete.isEmpty()) {
      delete toDelete;
    }

    List<CaseWidget_CaseType__c> upserts = new List<CaseWidget_CaseType__c>();
    Integer sortOrder = 0;
    for (Object item : caseTypesData) {
      Map<String, Object> caseTypeData = (Map<String, Object>) item;
      CaseWidget_CaseType__c caseType = new CaseWidget_CaseType__c();
      if (caseTypeData.containsKey('Id') && caseTypeData.get('Id') != null) {
        caseType.Id = Id.valueOf(String.valueOf(caseTypeData.get('Id')));
      }
      caseType.Domain__c = domainId;
      caseType.Value__c = (String) caseTypeData.get('Value__c');
      caseType.Label__c = (String) caseTypeData.get('Label__c');
      caseType.Sort_Order__c = sortOrder;
      caseType.Active__c = (Boolean) caseTypeData.get('Active__c');
      upserts.add(caseType);
      sortOrder++;
    }
    if (!upserts.isEmpty()) {
      upsert upserts;
    }
  }

  private static Decimal toDecimal(Object value) {
    if (value == null) {
      return null;
    }
    if (value instanceof Decimal) {
      return (Decimal) value;
    }
    if (value instanceof Integer) {
      return Decimal.valueOf(String.valueOf(value));
    }
    if (value instanceof Long) {
      return Decimal.valueOf(String.valueOf(value));
    }
    if (value instanceof Double) {
      return Decimal.valueOf(String.valueOf(value));
    }
    return Decimal.valueOf(String.valueOf(value));
  }

  private static Set<Id> getRecentActivityDomainIds(Set<Id> domainIds) {
    Set<Id> results = new Set<Id>();
    if (domainIds.isEmpty() || !hasCaseDomainField()) {
      return results;
    }

    for (
      SObject rowRecord : Database.query(
        'SELECT ' +
          CASE_DOMAIN_FIELD +
          ' domainId FROM Case' +
          ' WHERE ' +
          CASE_DOMAIN_FIELD +
          ' IN :domainIds' +
          ' AND CreatedDate = LAST_N_DAYS:30' +
          ' GROUP BY ' +
          CASE_DOMAIN_FIELD
      )
    ) {
      AggregateResult row = (AggregateResult) rowRecord;
      results.add((Id) row.get('domainId'));
    }
    return results;
  }

  private static Boolean hasCaseDomainField() {
    return Case.SObjectType.getDescribe()
      .fields.getMap()
      .containsKey(CASE_DOMAIN_FIELD);
  }
}
