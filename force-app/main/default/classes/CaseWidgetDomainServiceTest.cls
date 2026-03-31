@IsTest
private class CaseWidgetDomainServiceTest {

    @TestSetup
    static void makeData() {
        CaseWidget_Domain__c domain = new CaseWidget_Domain__c(
            Name = 'Test Domain',
            Domain__c = 'testdomain.com',
            Active__c = true,
            Notes__c = 'Test notes'
        );
        insert domain;

        CaseWidget_Config__c config = new CaseWidget_Config__c(
            Domain__c = domain.Id,
            Recaptcha_Site_Key__c = 'test-site-key',
            Recaptcha_Secret_Key__c = 'test-secret-key',
            Modal_Title__c = 'Report an issue',
            Modal_Description__c = 'Please describe the issue',
            Success_Message__c = 'Thank you',
            Loading_Message__c = 'Sending...',
            Auto_Close_Seconds__c = 8,
            Recaptcha_Min_Score__c = 0.50,
            Msg_Email_Required__c = 'Email is required',
            Msg_Email_Invalid__c = 'Enter a valid email',
            Msg_Subject_Required__c = 'Subject is required',
            Msg_Description_Required__c = 'Description is required'
        );
        insert config;

        insert new List<CaseWidget_CaseType__c>{
            new CaseWidget_CaseType__c(
                Domain__c = domain.Id,
                Value__c = 'Bug',
                Label__c = 'Report a bug',
                Sort_Order__c = 0,
                Active__c = true
            ),
            new CaseWidget_CaseType__c(
                Domain__c = domain.Id,
                Value__c = 'Question',
                Label__c = 'I have a question',
                Sort_Order__c = 1,
                Active__c = true
            )
        };
    }

    @IsTest
    static void testGetDomains_returnsWrappers() {
        Test.startTest();
        List<Map<String, Object>> results = CaseWidgetDomainService.getDomains();
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return 1 domain');
        CaseWidget_Domain__c domain = (CaseWidget_Domain__c) results[0].get('domain');
        CaseWidget_Config__c config = (CaseWidget_Config__c) results[0].get('config');
        List<CaseWidget_CaseType__c> caseTypes = (List<CaseWidget_CaseType__c>) results[0].get('caseTypes');
        Assert.areEqual('testdomain.com', domain.Domain__c);
        Assert.isNotNull(config, 'Config should be present');
        Assert.isTrue((Boolean) results[0].get('hasSecretKey'), 'hasSecretKey should be true');
        Assert.areEqual(2, caseTypes.size(), 'Should have 2 case types');
    }

    @IsTest
    static void testGetDomains_noSecretKey_whenConfigEmpty() {
        insert new CaseWidget_Domain__c(
            Name = 'No Config Domain',
            Domain__c = 'noconfig.com',
            Active__c = true
        );

        Test.startTest();
        List<Map<String, Object>> results = CaseWidgetDomainService.getDomains();
        Test.stopTest();

        Map<String, Object> noConfigWrapper;
        for (Map<String, Object> wrapper : results) {
            CaseWidget_Domain__c domain = (CaseWidget_Domain__c) wrapper.get('domain');
            if (domain.Domain__c == 'noconfig.com') {
                noConfigWrapper = wrapper;
                break;
            }
        }
        Assert.isNotNull(noConfigWrapper);
        Assert.isFalse((Boolean) noConfigWrapper.get('hasSecretKey'));
        Assert.isNull(noConfigWrapper.get('config'));
    }

    @IsTest
    static void testGetCaseTypesForDomain() {
        CaseWidget_Domain__c domain = [SELECT Id FROM CaseWidget_Domain__c LIMIT 1];

        Test.startTest();
        List<CaseWidget_CaseType__c> types = CaseWidgetDomainService.getCaseTypesForDomain(domain.Id);
        Test.stopTest();

        Assert.areEqual(2, types.size());
        Assert.areEqual(0, (Integer) types[0].Sort_Order__c, 'First type should be order 0');
    }

    @IsTest
    static void testValidateDomainUniqueness_uniqueOnCreate() {
        Test.startTest();
        Boolean result = CaseWidgetDomainService.validateDomainUniqueness('newdomain.com', null);
        Test.stopTest();

        Assert.isTrue(result, 'New domain should be unique');
    }

    @IsTest
    static void testValidateDomainUniqueness_duplicateOnCreate() {
        Test.startTest();
        Boolean result = CaseWidgetDomainService.validateDomainUniqueness('testdomain.com', null);
        Test.stopTest();

        Assert.isFalse(result, 'Existing domain should not be unique');
    }

    @IsTest
    static void testValidateDomainUniqueness_selfExcludedOnEdit() {
        CaseWidget_Domain__c domain = [SELECT Id FROM CaseWidget_Domain__c LIMIT 1];

        Test.startTest();
        Boolean result = CaseWidgetDomainService.validateDomainUniqueness('testdomain.com', domain.Id);
        Test.stopTest();

        Assert.isTrue(result, 'Should be unique when the same domain excludes itself');
    }

    @IsTest
    static void testSaveDomain_create() {
        Map<String, Object> newDomain = new Map<String, Object>{
            'Name' => 'New Domain',
            'Domain__c' => 'newdomain.com',
            'Active__c' => true
        };
        Map<String, Object> newConfig = new Map<String, Object>{
            'Recaptcha_Site_Key__c' => 'site-key',
            'Recaptcha_Secret_Key__c' => 'secret-key',
            'Modal_Title__c' => 'Report',
            'Modal_Description__c' => 'Please describe',
            'Success_Message__c' => 'Thank you',
            'Loading_Message__c' => 'Sending...',
            'Auto_Close_Seconds__c' => 8,
            'Recaptcha_Min_Score__c' => 0.5,
            'Msg_Email_Required__c' => 'Email required',
            'Msg_Email_Invalid__c' => 'Invalid email',
            'Msg_Subject_Required__c' => 'Subject required',
            'Msg_Description_Required__c' => 'Description required'
        };
        List<Object> newTypes = new List<Object>{
            new Map<String, Object>{
                'Value__c' => 'Bug',
                'Label__c' => 'Report a bug',
                'Sort_Order__c' => 0,
                'Active__c' => true
            }
        };

        Test.startTest();
        Id domainId = CaseWidgetDomainService.saveDomain(
            JSON.serialize(newDomain),
            JSON.serialize(newConfig),
            JSON.serialize(newTypes)
        );
        Test.stopTest();

        Assert.isNotNull(domainId);
        CaseWidget_Domain__c saved = [SELECT Domain__c FROM CaseWidget_Domain__c WHERE Id = :domainId];
        Assert.areEqual('newdomain.com', saved.Domain__c);

        List<CaseWidget_Config__c> configs = [SELECT Id FROM CaseWidget_Config__c WHERE Domain__c = :domainId];
        Assert.areEqual(1, configs.size(), 'Config should be linked');

        List<CaseWidget_CaseType__c> types = [SELECT Id FROM CaseWidget_CaseType__c WHERE Domain__c = :domainId];
        Assert.areEqual(1, types.size(), 'Case type should be linked');
    }

    @IsTest
    static void testSaveDomain_edit_preservesSecretKey() {
        CaseWidget_Domain__c domain = [SELECT Id, Name, Domain__c, Active__c, Notes__c FROM CaseWidget_Domain__c LIMIT 1];
        CaseWidget_Config__c config = [
            SELECT Id, Recaptcha_Site_Key__c, Modal_Title__c, Modal_Description__c,
                   Success_Message__c, Loading_Message__c, Auto_Close_Seconds__c,
                   Recaptcha_Min_Score__c, Msg_Email_Required__c, Msg_Email_Invalid__c,
                   Msg_Subject_Required__c, Msg_Description_Required__c
            FROM CaseWidget_Config__c
            WHERE Domain__c = :domain.Id
            LIMIT 1
        ];
        List<CaseWidget_CaseType__c> existingTypes = [
            SELECT Id, Value__c, Label__c, Sort_Order__c, Active__c
            FROM CaseWidget_CaseType__c
            WHERE Domain__c = :domain.Id
            ORDER BY Sort_Order__c ASC
        ];

        Map<String, Object> domainData = new Map<String, Object>{
            'Id' => domain.Id,
            'Name' => domain.Name,
            'Domain__c' => domain.Domain__c,
            'Active__c' => domain.Active__c,
            'Notes__c' => domain.Notes__c
        };
        Map<String, Object> configData = new Map<String, Object>{
            'Id' => config.Id,
            'Recaptcha_Site_Key__c' => config.Recaptcha_Site_Key__c,
            'Recaptcha_Secret_Key__c' => '',
            'Modal_Title__c' => config.Modal_Title__c,
            'Modal_Description__c' => config.Modal_Description__c,
            'Success_Message__c' => config.Success_Message__c,
            'Loading_Message__c' => config.Loading_Message__c,
            'Auto_Close_Seconds__c' => config.Auto_Close_Seconds__c,
            'Recaptcha_Min_Score__c' => config.Recaptcha_Min_Score__c,
            'Msg_Email_Required__c' => config.Msg_Email_Required__c,
            'Msg_Email_Invalid__c' => config.Msg_Email_Invalid__c,
            'Msg_Subject_Required__c' => config.Msg_Subject_Required__c,
            'Msg_Description_Required__c' => config.Msg_Description_Required__c
        };

        Test.startTest();
        CaseWidgetDomainService.saveDomain(
            JSON.serialize(domainData),
            JSON.serialize(configData),
            JSON.serialize(existingTypes)
        );
        Test.stopTest();

        CaseWidget_Config__c updated = [SELECT Recaptcha_Secret_Key__c FROM CaseWidget_Config__c WHERE Id = :config.Id];
        Assert.isTrue(String.isNotBlank(updated.Recaptcha_Secret_Key__c), 'Secret key should be preserved');
    }

    @IsTest
    static void testToggleDomainActive_deactivate() {
        CaseWidget_Domain__c domain = [SELECT Id, Active__c FROM CaseWidget_Domain__c LIMIT 1];
        Assert.isTrue(domain.Active__c);

        Test.startTest();
        CaseWidgetDomainService.toggleDomainActive(domain.Id, false);
        Test.stopTest();

        CaseWidget_Domain__c updated = [SELECT Active__c FROM CaseWidget_Domain__c WHERE Id = :domain.Id];
        Assert.isFalse(updated.Active__c);
    }

    @IsTest
    static void testToggleDomainActive_activate() {
        CaseWidget_Domain__c domain = [SELECT Id FROM CaseWidget_Domain__c LIMIT 1];
        domain.Active__c = false;
        update domain;

        Test.startTest();
        CaseWidgetDomainService.toggleDomainActive(domain.Id, true);
        Test.stopTest();

        CaseWidget_Domain__c updated = [SELECT Active__c FROM CaseWidget_Domain__c WHERE Id = :domain.Id];
        Assert.isTrue(updated.Active__c);
    }

    @IsTest
    static void testDeleteDomain_success() {
        CaseWidget_Domain__c domain = [SELECT Id FROM CaseWidget_Domain__c LIMIT 1];

        Test.startTest();
        CaseWidgetDomainService.deleteDomain(domain.Id);
        Test.stopTest();

        List<CaseWidget_Domain__c> remaining = [SELECT Id FROM CaseWidget_Domain__c WHERE Id = :domain.Id];
        Assert.areEqual(0, remaining.size(), 'Domain should be deleted');

        List<CaseWidget_CaseType__c> types = [SELECT Id FROM CaseWidget_CaseType__c WHERE Domain__c = :domain.Id];
        Assert.areEqual(0, types.size(), 'Case types should be deleted');
    }

    @IsTest
    static void testDeleteDomain_blockedByRecentCases() {
        if (!Case.SObjectType.getDescribe().fields.getMap().containsKey('CaseWidget_Domain__c')) {
            return;
        }

        CaseWidget_Domain__c domain = [SELECT Id FROM CaseWidget_Domain__c LIMIT 1];
        Case recentCase = new Case(Subject = 'Test Case');
        recentCase.put('CaseWidget_Domain__c', domain.Id);
        insert recentCase;

        Test.startTest();
        try {
            CaseWidgetDomainService.deleteDomain(domain.Id);
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('recent activity'),
                'Exception message should mention recent activity'
            );
        }
        Test.stopTest();
    }
}
