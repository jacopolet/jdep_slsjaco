@isTest
private class APTS_DefaultAgreementDatesTest {
    @testSetup
    static void testSetup(){
        TriggerSettings__c tstSetting = new TriggerSettings__c();
        tstSetting.Agreement__c = true;
        insert tstSetting;
        
        APTS_Payment_Method__c pm = APTS_TestUtils.paymentMethod();
        insert pm;  
        
        Account account = APTS_TestUtils.createaccount();
        account.APTS_Payment_Method__c = pm.id; 
        insert account;
        
        
        Contact contact= APTS_TestUtils.createContact();
        contact.Main_Commercial_Person__c=true;
        insert contact;
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList ;
        
        APTS_DaysByCalendarMonthAVG__c days = new APTS_DaysByCalendarMonthAVG__c();
        days.Name = 'Decimal2';
        insert days;
        // List<Opportunity> opportunitylist = APTS_TestUtils.createOppQueList(account);
        //insert opportunitylist; 
    }
    
    private static testMethod void datelocationaccount(){
        
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        
        Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
        //agreement.recordtypeId = rtId;
        agreement.Apttus_CMConfig__LocationId__c = loc.Id;
        Database.insert(agreement);
        Apttus__APTS_Agreement__c agreement1 =  APTS_TestUtils.createAgreement(con.Id, null, prl.Id, acc.Id);
        Database.insert(agreement1);
        Apttus_Config2__PriceList__c prlu = new Apttus_Config2__PriceList__c();
        prlu.Name = 'Netherland General PriceList';
        prlu.APTS_SalesOrg__c= 'SAP_0011';
        insert prlu;
        agreement1.Apttus_CMConfig__PriceListId__c = prlu.id;
        Database.update(agreement1);
        // Copy from other test class
        
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Apttus_Config2__PriceList__c> plList = [SELECT ID FROM Apttus_Config2__PriceList__c];
        
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
            delete plList;
            
            List<Account> accList = [SELECT Id, Partner__c FROM Account];
            ////Set Account Sales Org to Netherlands
            for (Account instacc : accList) {
                instacc.Sales_Organization__c = 'SAP_0111';
            }
            update accList;
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            for (Opportunity instopp : [SELECT Id, Account.Id, Account.Name FROM Opportunity]) {
                Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
                agg.Name = instopp.Account.Name + ' Agreement';
                agg.Apttus__Account__c = instopp.Account.Id;
                agg.RecordTypeId = standardDealRT;
                agg.Apttus__Related_Opportunity__c = instopp.id;
                agreementList.add(agg);
            }
            test.startTest();
            database.insert(agreementList);
            test.stopTest();
            
            List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null];
            system.assertEquals(3, checkAgreementList.size());
        }
        Delete agreement1;
    } 
    
    private static testMethod void datelocationaccount1(){
        
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        
        Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
        //agreement.recordtypeId = rtId;
        agreement.Apttus_CMConfig__LocationId__c = loc.Id;
        Database.insert(agreement);
        Apttus__APTS_Agreement__c agreement1 =  APTS_TestUtils.createAgreement(con.Id, null, prl.Id, acc.Id);
        Database.insert(agreement1);
        Apttus_Config2__PriceList__c prlu = new Apttus_Config2__PriceList__c();
        prlu.Name = 'Netherland General PriceList';
        prlu.APTS_SalesOrg__c= 'SAP_0011';
        insert prlu;
        agreement1.Apttus_CMConfig__PriceListId__c = prlu.id;
        Database.update(agreement1);
        // Copy from other test class
        
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Apttus_Config2__PriceList__c> plList = [SELECT ID FROM Apttus_Config2__PriceList__c];
        
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
            delete plList;
            
            List<Account> accList = [SELECT Id, Partner__c FROM Account];
            ////Set Account Sales Org to Netherlands
            for (Account instacc : accList) {
                instacc.Sales_Organization__c = 'SAP_0111';
            }
            update accList;
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            List<Opportunity> oppty=[SELECT Id, Account.Id, Account.Name FROM Opportunity where id  in:opplist];
            for (Opportunity instopp : oppty) {
                Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
                agg.Name = instopp.Account.Name + ' Agreement';
                agg.Apttus__Account__c = instopp.Accountid;
                agg.RecordTypeId = standardDealRT;
                //agg.Apttus__Related_Opportunity__c = instopp.id;
                agreementList.add(agg);
            }
            test.startTest();
            database.insert(agreementList);
            test.stopTest();
            
            List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null];
            system.assertEquals(2, checkAgreementList.size());
        }
        Delete agreement1;
    } 
    
    private static testMethod void datelocationaccountFixedEndDate(){
    

        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Initial_Agreement__c=true;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           insert agreement;

            agreement.Apttus__Status__c = 'Internal Review';
            agreement.Apttus__Status_Category__c = 'In Authoring';
            update agreement;

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
    } 
    private static testMethod void defaultdatesOnStatusChange(){
    
    Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
    Account acc = [Select Id,name from Account where Name =: 'Test account'];
    List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
    Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
    Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
    loc.Apttus_Config2__IsDefault__c=true;
    Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
    Insert Opp;
    insert loc;
       
    Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                              Name = 'Agreement',
                                                                              Apttus__Primary_Contact__c = con.Id,
                                                                              Apttus__Agreement_Category__c = 'Standard',
                                                                              Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                              Apttus_CMConfig__PricingDate__c = System.Today());
        
   // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
        agreement.Apttus_CMConfig__LocationId__c = loc.Id;
        agreement.Apttus__Auto_Renewal__c = false;
        agreement.APTS_Migration_Date__c = null;
        system.debug('SOFI Migration Date:'+agreement.APTS_Migration_Date__c);
        Date dt = date.today();
        agreement.Apttus__Contract_Start_Date__c = dt;
        system.debug('SOFI Contract start Date:'+agreement.Apttus__Contract_Start_Date__c);
        agreement.Apttus__Contract_End_Date__c = dt.addDays(398);
        system.debug('SOFI Contract end Date:'+agreement.Apttus__Contract_End_Date__c);
        agreement.Apttus__Status__c = 'Internal Review';
        Database.insert(agreement);
        system.debug('SOFI Migration Date@@:'+agreement.APTS_Migration_Date__c);
        Apttus_Config2__PriceList__c prlu = new Apttus_Config2__PriceList__c();
        prlu.Name = 'Netherland General PriceList';
        prlu.APTS_SalesOrg__c= 'SAP_0011';
        insert prlu;
        agreement.Apttus_CMConfig__PriceListId__c = prlu.id;
        agreement.Apttus__Subtype__c = 'Fixed End Date';
        agreement.Apttus__Status_Category__c = 'In Signatures';
        agreement.Apttus__Status__c = 'Request';
        Database.update(agreement);
        // Copy from other test class
        List<Apttus__APTS_Agreement__c> checkAgreementList = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agr : [SELECT ID, Apttus__Auto_Renewal__c, Apttus__Subtype__c FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null]){
            agr.Apttus__Subtype__c = 'Fixed End Date';
            agr.Apttus__Auto_Renewal__c = false;
            checkAgreementList.add(agr);
        }
        update checkAgreementList;
        /* List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null];
        system.assertEquals(1, checkAgreementList.size()); */
        
        Delete agreement;
    } 
    private static testMethod void defaultdatesOnStatusChange1(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            
            agreement.Apttus__Status__c = 'Request';
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           
            insert agreement;
            system.debug('Approval Status SOFI:'+agreement.Apttus__Status__c);
            agreement.Apttus__Status__c = 'Internal Review';
            update agreement;
            system.debug('Status SOFIaf up:'+agreement.Apttus__Status__c);
            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
         
            /* List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null];
            system.assertEquals(1, checkAgreementList.size()); */
            
            //Delete agreement;
    }

     private static testMethod void defaultdatesOnStatusChange2(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           
            insert agreement;
            system.debug('SYNC CALL METHOD');
            system.debug('Approval Status SOFI:'+agreement.Apttus__Status__c);
            agreement.Apttus__Status__c = 'Activated';
            agreement.Apttus__Status_Category__c = 'In Effect';
            update agreement;
            system.debug('Status SOFIaf up:'+agreement.Apttus__Status__c);

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
            /* List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null];
            system.assertEquals(1, checkAgreementList.size()); */
            
            //Delete agreement;
    }
     private static testMethod void defaultdatesOnStatusChange3(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Initial_Agreement__c=true;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           
            insert agreement;
            agreement.Apttus__Status__c = 'Internal Signatures';
            agreement.Apttus__Status_Category__c = 'In Signatures';
            update agreement;

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
            /* List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null];
            system.assertEquals(1, checkAgreementList.size()); */
            
            //Delete agreement;
    }
    private static testMethod void defaultdatesOnStatusChange4(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            //agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Initial_Agreement__c=true;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           insert agreement;

            agreement.Apttus__Status__c = 'Initial Agreement';
            agreement.Apttus__Status_Category__c = 'In Effect';
            update agreement;

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
            /* List<Apttus__APTS_Agreement__c> checkAgreementList = [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Apttus_CMConfig__PriceListId__c = null];
            system.assertEquals(1, checkAgreementList.size()); */
            
            //Delete agreement;
    }
    private static testMethod void defaultdatesOnStatusChange5(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Initial_Agreement__c=true;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           insert agreement;

            agreement.Apttus__Status__c = 'Initial Agreement';
            agreement.Apttus__Status_Category__c = 'Request';
            update agreement;

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
    }
     private static testMethod void defaultdatesOnStatusChange6(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Initial_Agreement__c=true;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           insert agreement;

            agreement.Apttus__Status__c = 'Submitted Request';
            agreement.Apttus__Status_Category__c = 'Request';
            update agreement;

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
    }
    private static testMethod void defaultdatesOnStatusChange7(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Initial_Agreement__c=true;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           insert agreement;

            agreement.Apttus__Status__c = 'Terminated';
            agreement.Apttus__Status_Category__c = 'Request';
            update agreement;

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
    }
    private static testMethod void defaultdatesOnStatusChange8(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Initial_Agreement__c=true;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
           test.startTest();
           insert agreement;

            agreement.Apttus__Status__c = 'In Amendment';
            agreement.Apttus__Status_Category__c = 'Request';
            update agreement;

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
    }
     private static testMethod void defaultdatesOnStatusChange9(){
    
        Contact con = [Select Id,name from Contact where FirstName =: 'Test'];
        Account acc = [Select Id,name from Account where Name =: 'Test account'];
        List<Opportunity> opplist= [select id,Accountid,Account.Sales_Organization__c,Account.billingcountry,Account.Language__c,Account.Bill_To_Payer_Account__c,Account.Related_Bill_to_Machines_Services__c,Account.Related_Caterer__c,Account.Related_Payer_Account__c,Account.Related_Payer_Machines_Services__c from Opportunity where AccountId =:acc.id LIMIT 1];
        Apttus_Config2__PriceList__c prl = [Select Id,name from Apttus_Config2__PriceList__c where Name = 'JDE Price List'];
        Apttus_Config2__AccountLocation__c loc = APTS_TestUtils.createAccountLocationagreement(acc.id);
        loc.Apttus_Config2__IsDefault__c=true;
        Opportunity Opp= APTS_TestUtils.createOpportunity(acc.id);
        Insert Opp;
        insert loc;
        APTS_CheckRecursive.processedSet.clear();
        user testUser = [SELECT Id FROM USER LIMIT 1];
        system.runAs(testUser) {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                                                                                  Name = 'Agreement',
                                                                                  Apttus__Primary_Contact__c = con.Id,
                                                                                  Apttus__Agreement_Category__c = 'Standard',
                                                                                  Apttus_CMConfig__PriceListId__c = prl.Id,
                                                                                  Apttus_CMConfig__PricingDate__c = System.Today());
            
       // Apttus__APTS_Agreement__c agreement =  APTS_TestUtils.createconsumptionAgreement(con.Id, null, prl.Id, acc.Id);                         
            agreement.Apttus_CMConfig__LocationId__c = loc.Id;
            agreement.Apttus__Related_Opportunity__c=Opp.id;
            agreement.Apttus__Status__c = 'Request';
            agreement.Apttus__Status_Category__c = 'Request';
            agreement.Apttus__Version_Number__c=0;
            agreement.APTS_Initial_Agreement__c=true;
            agreement.APTS_Primary__c=true;             
            //agreement.Apttus_Approval__Approval_Status__c = 'Submitted';
           
            test.startTest();
            insert agreement;

            //Number of drinks logic
            APTS_AgreementTotalVolumeObligation__c totalVolumeObligation1 = new APTS_AgreementTotalVolumeObligation__c (
                                                                                    APTS_Agreement__c = agreement.Id,
                                                                                    APTS_CategoryName__c = 'categoryHierarchy',
                                                                                    APTS_Categoryvalue__c = null  ,
                                                                                    APTS_Malus_per_Unit__c = 10,
                                                                                    APTS_Name__c = 'v1' ,
                                                                                    APTS_Product_Name__c = 'test',
                                                                                    APTS_SubCategoryName__c = 'subCategoryHierarchy',
                                                                                    APTS_SubCategoryValue__c = null,
                                                                                    APTS_Type__c = 'SubCategory' ,
                                                                                    APTS_Unit_of_Measure__c = 'SAP_KGM',
                                                                                    APTS_Value__c = null,
                                                                                    APTS_Value_Name__c = 'subCategoryHierarchy'
                                                                                    );
                                                                          
            INSERT totalVolumeObligation1;

            agreement.Apttus_CMConfig__ConfigurationFinalizedDate__c=System.today();
            update agreement;

            test.stopTest();
            
            system.debug('SOFI after update:'+agreement);
        } 
    }
}