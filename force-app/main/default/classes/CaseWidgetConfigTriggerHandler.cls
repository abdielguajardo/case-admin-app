public class CaseWidgetConfigTriggerHandler {
  public static void validateSingleConfigPerDomain(
    List<CaseWidget_Config__c> newRecords,
    Map<Id, CaseWidget_Config__c> oldMap
  ) {
    Set<Id> domainIds = new Set<Id>();
    Map<Id, Integer> incomingCountsByDomain = new Map<Id, Integer>();

    for (CaseWidget_Config__c record : newRecords) {
      if (record.Domain__c == null) {
        continue;
      }

      domainIds.add(record.Domain__c);
      Integer currentCount = incomingCountsByDomain.containsKey(
          record.Domain__c
        )
        ? incomingCountsByDomain.get(record.Domain__c)
        : 0;
      incomingCountsByDomain.put(record.Domain__c, currentCount + 1);
    }

    for (CaseWidget_Config__c record : newRecords) {
      if (
        record.Domain__c != null &&
        incomingCountsByDomain.get(record.Domain__c) > 1
      ) {
        record.Domain__c.addError(
          'Only one config record is allowed per domain.'
        );
      }
    }

    if (domainIds.isEmpty()) {
      return;
    }

    Set<Id> currentRecordIds = new Set<Id>();
    for (CaseWidget_Config__c record : newRecords) {
      if (record.Id != null) {
        currentRecordIds.add(record.Id);
      }
    }

    Map<Id, Id> existingConfigIdsByDomain = new Map<Id, Id>();
    for (CaseWidget_Config__c existing : [
      SELECT Id, Domain__c
      FROM CaseWidget_Config__c
      WHERE Domain__c IN :domainIds
    ]) {
      if (!currentRecordIds.contains(existing.Id)) {
        existingConfigIdsByDomain.put(existing.Domain__c, existing.Id);
      }
    }

    for (CaseWidget_Config__c record : newRecords) {
      if (
        record.Domain__c != null &&
        existingConfigIdsByDomain.containsKey(record.Domain__c)
      ) {
        record.Domain__c.addError(
          'Only one config record is allowed per domain.'
        );
      }
    }
  }
}
