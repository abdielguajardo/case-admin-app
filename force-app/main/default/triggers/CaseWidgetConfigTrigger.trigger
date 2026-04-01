trigger CaseWidgetConfigTrigger on CaseWidget_Config__c(
  before insert,
  before update
) {
  CaseWidgetConfigTriggerHandler.validateSingleConfigPerDomain(
    Trigger.new,
    Trigger.oldMap
  );
}
