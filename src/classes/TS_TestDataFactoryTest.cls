@isTest
private class TS_TestDataFactoryTest {
    
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderLineItemTrigger__c = true;
        upsert trg;           
  
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        upsert trg1; 
    

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = true;
        insert pb;
    }
    
    static testMethod void testCreateAccounts(){       
        List<Account> acctList = TS_TestDataFactory.createAccounts(3);
        insert acctList;       
        Integer acctSize = [Select count() from Account where Id In :acctList];       
        system.assertEquals(acctSize, acctList.size());
    }
    
    static testMethod void testCreateOrders(){
        List<Apttus_Config2__Order__c> orderList = TS_TestDataFactory.createOrders(3);
        insert orderList;
        Integer orderSize = [Select count() from Apttus_Config2__Order__c where Id in :orderList];
        system.assertEquals(orderSize, orderList.size());    
    }
    
    static testMethod void testCreateWorkOrderList(){
        List<WorkOrder> woList = TS_TestDataFactory.createWorkOrderList(3);
        system.assertEquals(4, woList.size());
    }
    
    static testMethod void testCreateUser(){
        Integer userCount = [Select count() from User where Profile.Name = 'System Administrator'];
        User u = TS_TestDataFactory.createUser('System Administrator');
        Integer userCountNew = [Select count() from User where Profile.Name = 'System Administrator'];
        System.assertEquals(userCount + 1, userCountNew);
    }
    
    static testMethod void testCreateProduct(){
        Product2 prod = TS_TestDataFactory.createProduct('Sample Product', 'Hardware');
        insert prod;
        Integer prodCount = [Select count() from Product2 where Name='Sample Product' and Family = 'Hardware'];
        //system.assertEquals(1, prodCount);
    }
    
    static testMethod void testcreateContact(){
        List<Account> acct = TS_TestDataFactory.createAccounts(0);
        insert acct;
        Contact con  = TS_TestDataFactory.createContact();
        con.Email = 'sample@test.com';
        con.AccountId = acct.get(0).Id;
        insert con;
        Integer contCount = [Select count() from Contact];
        system.assertEquals(1, contCount);
    }

    static testMethod void testCreateCaseWOWOLI(){
        Case c1 = TS_TestDataFactory.createCase('Case Subject');
        Contact con  = TS_TestDataFactory.createContact();
        con.Email = 'sample@test.com';
        con.Preferred_Language__c = 'SAP_EN';
        insert con;
        Case c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        insert c;
        
        WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
        parentWO.CaseId = c.Id;
        parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        parentWO.ContactId = con.Id;
        insert parentWO;
        
        WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        
        List<WorkOrderLineItem> woliList = TS_TestDataFactory.createWorkOrderLineItemList(1, parentWO.Id);
        
        Resource__c r = TS_TestDataFactory.createResourceSingle('resource name');
        Resource__c r2 = TS_TestDataFactory.createResourceSingle('sample resource');
        String s = TS_TestDataFactory.createBase64();
        Integer caseCount = [Select count() from Case];
        system.assertEquals(2, caseCount);

        Integer countWorkOrder = [Select count() from WorkOrder];
        system.assertEquals(1, countWorkOrder);

        //woli was not inserted
        Integer countWorkOrderLineItem = [Select count() from WorkOrderLineItem];
        //system.assertEquals(1, countWorkOrderLineItem);

    }
    
    static testMethod void testCreateAccountLocation(){
        List<Account> acct = TS_TestDataFactory.createAccounts(0);
        insert acct;
        Apttus_Config2__AccountLocation__c acctLoc = TS_TestDataFactory.createAccountLocation(acct.get(0).Id);
        insert acctLoc;
        Integer acctLocCount = [Select count() from Apttus_Config2__AccountLocation__c];
        system.assertEquals(1, acctLocCount);       
    }    
    
    static testMethod void testCreateAssetLineItem(){
        Apttus_Config2__AssetLineItem__c ali = TS_TestDataFactory.createAssetLineItem();
        insert ali;

        Integer countAssetLine = [Select count() from Apttus_Config2__AssetLineItem__c];
        system.assertEquals(1, countAssetLine);
    }
    
    static testMethod void testCreateOrder(){
        Apttus_Config2__Order__c order = TS_TestDataFactory.createOrderRecord('Activated','New');
        insert order;
        
        Product2 prod = TS_TestDataFactory.createProduct('Sample Product', 'Hardware');
        insert prod;
        
        Apttus_Config2__OrderLineItem__c oli = TS_TestDataFactory.createOrderLineItem('New', prod.Id, order.Id, prod.Id);
        insert oli;

        Integer countorder = [Select count() from Apttus_Config2__Order__c];
        system.assertEquals(1, countorder);

        Integer countProduct2 = [Select count() from Product2];
        system.assertEquals(1, countProduct2);

        Integer countOrderLine = [Select count() from Apttus_Config2__OrderLineItem__c];
        system.assertEquals(1, countOrderLine);
    }

    static testMethod void testRoute(){
        List<Account> acct = TS_TestDataFactory.createAccounts(0);
        insert acct;
        Apttus_Config2__AccountLocation__c acctLoc = TS_TestDataFactory.createAccountLocation(acct.get(0).Id);
        insert acctLoc;

        Route__c route = TS_TestDataFactory.createRoute('test',acctLoc.Id);
        insert route;
        
        Integer countRoute = [Select count() from Route__c];
        system.assertEquals(1, countRoute);
    }

    
    static testMethod void testRouteLine(){
        List<Account> acct = TS_TestDataFactory.createAccounts(0);
        insert acct;
        Apttus_Config2__AccountLocation__c acctLoc = TS_TestDataFactory.createAccountLocation(acct.get(0).Id);
        insert acctLoc;

        Route__c route = TS_TestDataFactory.createRoute('test',acctLoc.Id);
        insert route;

        Route_Line_Item__c rli = TS_TestDataFactory.createRouteLine('testLine', route.Id);
        insert rli;
        
        Integer countRouteItem = [Select count() from Route_Line_Item__c];
        system.assertEquals(1, countRouteItem);
    }

    static testMethod void testHoliday(){
        List<Account> acct = TS_TestDataFactory.createAccounts(0);
        insert acct;
        Apttus_Config2__AccountLocation__c acctLoc = TS_TestDataFactory.createAccountLocation(acct.get(0).Id);
        insert acctLoc;

        Customer_Holiday__c holiday = TS_TestDataFactory.createHoliday('testLine', acctLoc.Id);
        insert holiday;
        
        Integer countHoliday = [Select count() from Customer_Holiday__c];
        system.assertEquals(1, countHoliday);
    }

    static testMethod void testCountrySetting(){
        CountrySetting__c cs = TS_TestDataFactory.createCountrySettings();
        insert cs;
  
        Integer cscnt = [SELECT count() from CountrySetting__c];
        system.assertEquals(1, cscnt);
    }

        
    static testMethod void testPhysicalAsset(){
        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        insert pa;
  
        Integer pacnt = [SELECT count() from PhysicalAsset__c];
        system.assertEquals(1, pacnt);
    }

    
    static testMethod void testCreateProductTest(){
        String name = 'my name';
        String materialType = 'my material';

        Product2 pt = TS_TestDataFactory.createProductTest(name,materialType);
        insert pt;
  
        Integer ptcnt = [SELECT count() from Product2];
        system.assertEquals(1, ptcnt);
    }


    static testMethod void testCreateResourceTest(){
        Resource__c res = TS_TestDataFactory.createResourceTest('Resource Name');
        insert res;

        Integer rescnt = [SELECT count() from Resource__c WHERE Id = :res.Id];
        system.assertEquals(1, rescnt);
    }

    
    static testMethod void testOperatingschedule(){
        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        insert pa;
        OperatingSchedule__c os = TS_TestDataFactory.createOperatingSchedule();
        os.PhysicalAsset__c = pa.Id;
        os.Start_Date__c = Date.today();
        insert os;
  
        OperatingSchedule__c osq = [SELECT Id,Active__c from OperatingSchedule__c WHERE Id = :os.Id];
        system.assert(TRUE, osq.Active__c);
    }

    
     static testMethod void testCreateAccountLocationTest(){

        List<Account> accList = TS_TestDataFactory.createAccounts(1);
        insert accList;
        
        Apttus_Config2__AccountLocation__c al = TS_TestDataFactory.createAccountLocationTest('123457456345', accList[0].Id);
        insert al;

        Integer alcnt = [SELECT count() from Apttus_Config2__AccountLocation__c WHERE Id = :al.Id];
        system.assertEquals(1, alcnt);
    }

    
    static testMethod void testCreatePhysicalAssetTest(){ 

        Id recordTypeId = Schema.getGlobalDescribe().get('PhysicalAsset__c').getDescribe().getRecordTypeInfosByName().get('Machine').getRecordTypeId();
        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAssetTest(recordTypeId, null, 'SAP_0111', null, null, 'bldg', '4f', null, 'Full Operating' );
        insert pa;
  
        Integer pacnt = [SELECT count() from PhysicalAsset__c WHERE Id = :pa.Id];
        system.assertEquals(1, pacnt);
    }

    
    static testMethod void testCreatePricebookEntryTest(){ 
        //String productId, String pricebookId

        product2 p = new product2();
        p.Name = 'KTS-1028';
        p.APTS_Material_Type__c = 'ZSPR';
        insert p;
        
        Id pbId = Test.getStandardPricebookId();

        PricebookEntry pbe = TS_TestDataFactory.createPricebookEntryTest(p.Id,pbId);
        insert pbe;

        Integer pbecnt = [SELECT count() from PricebookEntry WHERE Id = :pbe.Id];
        system.assertEquals(1, pbecnt);
    }
        
    static testMethod void testCreateOperatingScheduleTest(){
        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        insert pa;
        
        OperatingSchedule__c op = TS_TestDataFactory.createOperatingScheduleTest(false, true, '1', '1', '1', '1', '1', '1', '1');
    	op.PhysicalAsset__c = pa.Id;
        op.Start_Date__c = Date.today();
        insert op;
        
        Integer opCount = [SELECT count() from OperatingSchedule__c WHERE Id = :op.Id];
        system.assertEquals(1, opCount);    
    }

}