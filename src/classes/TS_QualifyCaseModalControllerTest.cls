/**
* @author        Rey Austral
* @date          10.2.2017           
* @description   Test Class for TS_QualifyCaseModalController
* @revision(s)
*/
@isTest
private class TS_QualifyCaseModalControllerTest {
    
    @isTest static void test_getDependentValue() {
        Test.startTest();
        Map<String,TS_PicklistEntryWrapper> picMap = TS_QualifyCaseModalController.getDependentValue('Case','Type','SubType__c');
        Test.stopTest();
        System.assertNotEquals(0,picMap.size());
    }
    
    @isTest static void test_InvalidObject() {
        Test.startTest();
        Map<String,TS_PicklistEntryWrapper> picMap = TS_QualifyCaseModalController.getDependentValue('Case__c','Type','SubType__c');
        Test.stopTest();
        System.assertEquals(null, picMap);
    }

    @isTest static void test_InvalidField() {
        Test.startTest();
        Map<String,TS_PicklistEntryWrapper> picMap = TS_QualifyCaseModalController.getDependentValue('Case','Type','SubType1__c');
        Test.stopTest();
        System.assertEquals(0, picMap.size());
    }
    
    /**
    * @author        Ritesh Kuamr
    * @date          15.08.2018           
    * @description   Test Class for TS_QualifyCaseModalController
    * @revision(s)
    */
    @isTest static void test_getPLvalueOption2(){
        Test.startTest();
        Map<String,List<String>> plValues = TS_QualifyCaseModalController.getPLvalueOption2('Case','Type','SubType__c');
        Test.stopTest();
        System.assertNotEquals(0,plValues.size());
    }
    
    @isTest static void test_getPLvalueOption3(){
        Test.startTest();
        Map<String,TS_PicklistEntryWrapper> plValues = TS_QualifyCaseModalController.getPLvalueOption3('Case','Type','SubType__c');
        Test.stopTest();
        System.assertNotEquals(0,plValues.size());
    }
    
    @isTest static void test_insertCase(){
       Case caseTest = new Case();
       caseTest.Subject = 'Test class';
       caseTest.Status = Label.TS_Status_New;
       Test.startTest();
       String status = TS_QualifyCaseModalController.insertCase(caseTest);
       Test.stopTest();
       System.assertEquals('SUCCESS', status);
    }
    
    @isTest static void test_insertCaseDebug(){
       Case caseTest = TS_TestDataFactory.createCase('Test Case');
       Test.startTest();
       String status = TS_QualifyCaseModalController.insertCaseDebug(caseTest);
       Test.stopTest();
    }
    
    @isTest static void test_qualifyCase(){
        List<Account> accountList = TS_TestDataFactory.createAccounts(1);
        accountList.get(0).Name = 'SendToClick_Test Name';
        insert accountList;
        
        Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        Apttus_Config2__AccountLocation__c alocation = TS_TestDataFactory.createAccountLocation( accountList.get(0).Id );
        alocation.Apttus_Config2__PostalCode__c   = '123';
        alocation.Shipping_Country_ISO__c = 'NL';
        alocation.Shipping_Street_Only__c = '1';
        alocation.Apttus_Config2__City__c = 'city';
        insert alocation;
        
        PhysicalAsset__c testAsset = new PhysicalAsset__c();
        testAsset.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        testAsset.Name = 'Test Asset';
        testAsset.UniqueNumber__c = '12345';
        testAsset.AccountLocation__c = alocation.Id;
        insert testAsset;
        
        PhysicalAsset__c testAssetOptions = new PhysicalAsset__c();
        testAssetOptions.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Option');
        testAssetOptions.Name = 'Test AssetOption';
        testAssetOptions.UniqueNumber__c = '67890';
        testAssetOptions.AccountLocation__c = alocation.Id;
        testAssetOptions.ParentPhysicalAsset__c = testAsset.Id;
        insert testAssetOptions;
        
        Case cseData = TS_TestDataFactory.createFieldServiceCase();
        cseData.AccountId = accountList[0].Id;
        cseData.ContactId = con.Id;       
        cseData.SalesOrganization__c = 'SAP_0333';
        cseData.Subject = 'Bas';
        cseData.Type ='Complaint';
        cseData.Description = 'Bas';
        cseData.Priority = 'Medium';
        cseData.PhysicalAsset__c = testAsset.Id;
        cseData.SLADate__c = System.now() + 7;
        insert cseData;
        
        Case cseData2 = TS_TestDataFactory.createFieldServiceCase();
        cseData2.AccountId = accountList[0].Id;
        cseData2.ContactId = con.Id;       
        cseData2.SalesOrganization__c = 'SAP_0333';
        cseData2.Subject = 'Bas';
        cseData2.Type ='Field Service';
        cseData2.Description = 'Bas';
        cseData2.Priority = 'Medium';
        cseData2.PhysicalAsset__c = testAsset.Id;
        cseData2.SLADate__c = System.now() + 7;
        cseData2.RequiresCostEstimate__c = true;
        cseData2.CostIndicationAsDiscussed__c = 200;
        cseData2.Customer_Case_ID__c = 'ccase';
        cseData2.CoffeeIsRunning__c = true;
        cseData2.ScheduleManually__c = true;        
        insert cseData2;
                        
        Test.startTest();
        TS_QualifyCaseModalController.qualifyCase(cseData.Id, con.ID, testAsset.ID, alocation.ID, cseData.Type, cseData.SubType__c, true, cseData.Subject, cseData.Description,'Appearance','Appearance, Other','',
                                                  null,null,null,null,null,null,null,null,null,null,null,null,null,null,false);
        
        TS_QualifyCaseModalController.qualifyCase(cseData2.Id, con.ID, testAsset.ID, alocation.ID, cseData2.Type, cseData2.SubType__c, true, cseData2.Subject, cseData2.Description,'Appearance','Appearance, Other','',
                                                  null,null,cseData2.Customer_Case_ID__c,null,null,null,null,null,null,cseData2.RequiresCostEstimate__c,cseData2.CoffeeIsRunning__c,cseData2.ScheduleManually__c,cseData2.CostIndicationAsDiscussed__c,cseData2.SLADate__c, false);
        Test.stopTest();
    }
    
    @isTest static void test_getRecordTypeCR(){
        Test.startTest();
        String status = TS_QualifyCaseModalController.getRecordTypeCR();
        Test.stopTest();
        System.assertNotEquals('', status);
    }
    
    @isTest static void test_getPLvalueOptionBulk(){
        TS_QualifyCaseModalController.dependentPicklistWrapper dpWrap = new TS_QualifyCaseModalController.dependentPicklistWrapper();
        dpWrap.controllingField = 'SubType__c';
        dpWrap.dependentField = 'ReasonLevel1__c';
        dpWrap.objectName = 'Case';
        List<TS_QualifyCaseModalController.dependentPicklistWrapper> newList = new List<TS_QualifyCaseModalController.dependentPicklistWrapper>();
        newList.add(dpWrap);

        Test.startTest();
        String serialized = JSON.serialize(newList);
        String retVal = TS_QualifyCaseModalController.getPLvalueOptionBulk(serialized);
        Test.stopTest(); 
        System.assertNotEquals('', retVal);
    }
    
    @isTest static void test_isServiceConsole(){
        Boolean isService;
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        Test.startTest();
        System.runAs(u){
            AppDefinition appDefinition = [SELECT Id, DurableId, Label FROM AppDefinition LIMIT 1];
            UserAppInfo app =new UserAppInfo();
            app.AppDefinitionId = appDefinition.DurableId;
            app.UserId = u.Id;
            app.FormFactor = 'Large';
            upsert app;            
            isService = TS_QualifyCaseModalController.isServiceConsole();
        }
        Test.stopTest();
        //System.assertEquals(isService,false);
    }
    
    @isTest static void test_isFeatureFlagEnabled(){
        Boolean isFeatureFlagEnabled;
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        Test.startTest();
        System.runAs(u){
            String apiName = 'DOO_4700_Custom_Lookup_Case_Registration';
            isFeatureFlagEnabled = TS_QualifyCaseModalController.isFeatureFlagEnabled(apiName);        
        }
        Test.stopTest();
    }
}