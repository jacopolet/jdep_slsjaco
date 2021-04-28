/**
 * Class Name: SM_AgreementToAccountTest
 * @author: Alvin Lomod
 * Date: 23-Mar-2018
 * Requirement: KASM-1364; KASM-1724
 * @description: Test Class of SM_AgreementToAccount
 *
 */
 
 @isTest
private class SM_AgreementToAccountTest{
    
    private static testMethod void PromoteAndILogTest(){
        
        List<Account> accList = new List<Account>();
        for(Account acc : TestDataFactory.createAccounts(4,null)){
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
            acc.Sales_Office__c = null;
            acc.Creditworthiness_Flag__c = 'Green';
            acc.Main_Address_Validation_Pending__c = false;
            acc.SAP_Customer_ID__c = null;
            acc.Bill_Block_Reason__c = null;
                     
            accList.add(acc);
        }
        insert acclist;
        /*
        List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();
        for(Apttus_Config2__AccountLocation__c accLoc : TestDataFactory.createAccountLocation(1)){
            accLoc.Apttus_Config2__AccountId__c = accList[0].Id;
            accLoc.Shipping_Address_Validation_Code__c = 'testa1321';
            accLoc.Copy_of_Parent_Account__c = false;
            accLoc.RecordTypeId = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
            accLocList.add(accLoc);
        }
        */
        List<Apttus_Config2__AccountLocation__c> acctLocList = new List<Apttus_Config2__AccountLocation__c>();
        
        for(integer x = 0; x<=1; x++){
            Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
            acctLoc.Apttus_Config2__AccountId__c = accList[0].Id;
            acctLoc.Shipping_Address_Validation_Code__c = 'testa1321';
            acctLoc.Copy_of_Parent_Account__c = false;
            acctLoc.RecordTypeId = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
            acctLoc.Apttus_Config2__AccountId__c = accList[0].Id;
            acctLoc.Name = 'SAMP';
            acctLoc.Customer_calendar_key__c = 'SAP_32';
            acctLoc.Mini_Language__c = 'SAP_FR';
            acctLoc.Pallet_type__c = 'SAP_007';
            acctLoc.Saturday_Afternoon_From_Receiving__c = '14:30';
            acctLoc.Saturday_Afternoon_To_Receiving__c = '15:00';
            acctLoc.Saturday_Morning_From_Receiving__c = '02:45';
            acctLoc.Saturday_Morning_To_Receiving__c = '02:15';
            acctLoc.Sunday_Afternoon_From_Receiving__c = '15:15';
            acctLoc.Sunday_Afternoon_To_Receiving__c = '15:30';
            acctLoc.Sunday_Morning_From_Receiving__c = '03:30';
            acctLoc.Sunday_Morning_To_Receiving__c = '   01:00';
            acctLocList.add(acctLoc);
        }
        
        insert acctLocList;
        
        Apttus__APTS_Agreement__c agree = new Apttus__APTS_Agreement__c();
        agree.Apttus__Account__c = accList[0].Id;
        agree.APTS_Sold_To__c = accList[0].Id;
        agree.APTS_Bill_to_Party_Ingredients__c = accList[1].Id;
        agree.APTS_Bill_to_Party_MachServ__c = accList[2].Id;
        agree.APTS_Payer_Ingredients__c = accList[3].Id;
        agree.APTS_Payer_Machines_Services__c = accList[4].Id;
        agree.Apttus_CMConfig__LocationId__c = acctLocList[0].Id;
        agree.Name = 'Test Agreement';
        agree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        
        insert agree;
        
        List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
        agreeList.add(agree);
        
        Test.startTest();
        SM_AgreementToAccount smata = new SM_AgreementToAccount();
        smata.AgreementToAccountMethods(agreeList);
        
        Test.stopTest();
        
        List<Account> updatedAccountList = [SELECT RecordTypeId FROM Account WHERE RecordTypeId =: Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId()];
        system.assertEquals(acclist.size(), updatedAccountList.size());
        
        List<Apttus_Config2__AccountLocation__c> updatedAccLocList = [SELECT RecordTypeId FROM Apttus_Config2__AccountLocation__c WHERE RecordTypeId =: Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId()];
        system.assertEquals(acctLocList.size() - 1, updatedAccLocList.size());
        
        List<Integration_Log__c> createdIlogs = [SELECT Id, Object__c FROM Integration_Log__c WHERE Agreement__c =: agree.Id];
        Integer accIlogsCount = 0;
        Integer accLocIlogsCount = 0;
        Integer accHIlogsCount = 0;
        for(Integration_Log__c il : createdIlogs){
            if(il.Object__c == 'Account'){
                accIlogsCount++;
            }
            else if(il.Object__c == 'Account Location'){
                accLocIlogsCount++;
            }
            else if(il.Object__c == 'Account Hierarchy'){
                accHIlogsCount++;
            }
        }
        
        system.assertEquals(accIlogsCount, acclist.size()); //number of accounts linked
        system.assertEquals(accLocIlogsCount, acctLocList.size() -1); //number of account location linked
        system.assertEquals(accHIlogsCount, 0); //number of accounts linked

    }
    
    @testSetup
    static void testSetup(){
        //insert new Product_Categories__c(SetupOwnerId=UserInfo.getOrganizationId(), Coffee_Beans__c='Blend mainstream');
        Product_Categories__c Prod = Product_Categories__c.getOrgDefaults();
        Prod.Coffee_Beans__c = 'Blend mainstream';
        Prod.Machines_Liquid__c = 'Machine Yes';
        Prod.More_Sugar__c = 'Sugar Yes';
        Prod.More_Chocolate__c = 'Cacao Yes';
        Prod.More_Cups__c = 'Cups / Glasses & Porcelain Yes';
        Prod.More_Milk__c = 'Milk Yes';
        Prod.More_Tea_display__c = 'Tea display';
        Prod.Tea_Pickwick_Volume_Pack__c = 'Tea - Mainstream';
        upsert Prod Product_Categories__c.id;
        System.debug('Prod : ' +  Prod);
         
        List<Perfect_Experience_Score__c> pesList = new List<Perfect_Experience_Score__c>();
        
        Perfect_Experience_Score__c pes = new Perfect_Experience_Score__c();
        pes.Category_Score__c = 15;
        pes.Category__c = 'Blend mainstream';
        insert pes;
        pesList.add(pes);
        
        Perfect_Experience_Score__c pes1 = new Perfect_Experience_Score__c();
        pes1.Category_Score__c = 15;
        pes1.Category__c = 'Machine Yes';
        insert pes1;
        pesList.add(pes1);
        
        Perfect_Experience_Score__c pes2 = new Perfect_Experience_Score__c();
        pes2.Category_Score__c = 5;
        pes2.Category__c = 'Sugar Yes';
        insert pes2;
        pesList.add(pes2);
        
        Perfect_Experience_Score__c pes3 = new Perfect_Experience_Score__c();
        pes3.Category_Score__c = 5;
        pes3.Category__c = 'Milk Yes';
        insert pes3;
        pesList.add(pes3);
        
        Perfect_Experience_Score__c pes4 = new Perfect_Experience_Score__c();
        pes4.Category_Score__c = 5;
        pes4.Category__c = 'Cacao Yes';
        insert pes4;
        pesList.add(pes4);
        
        Perfect_Experience_Score__c pes5 = new Perfect_Experience_Score__c();
        pes5.Category_Score__c = 10;
        pes5.Category__c = 'Cups / Glasses & Porcelain Yes';
        insert pes5;
        pesList.add(pes5);
        
        Perfect_Experience_Score__c pes6 = new Perfect_Experience_Score__c();
        pes6.Category_Score__c = 5;
        pes6.Category__c = 'Tea display';
        insert pes6;
        pesList.add(pes6);
        
        Perfect_Experience_Score__c pes7 = new Perfect_Experience_Score__c();
        pes7.Category_Score__c = 6;
        pes7.Category__c = 'Tea - Mainstream';
        insert pes7;
        pesList.add(pes6);

        
        System.debug('pesList' + pesList);
        
    }
    
    private static testMethod void peSurveyAgreement() {
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Country= 'Netherlands');
        
        System.runAs(u){
            testSetup();
                
            Account acc = new Account();
            acc.Name = 'accName';
            acc.Second_Account_Name__c = 'sAccName';
            acc.Archiving_Flag__c = true;
            acc.BillingStreet = 'mainstreet';
            acc.Main_House_Number__c = '123';
            acc.Main_Street_Only__c = 'streetOnly';
            acc.BillingCity = 'mainCity';
            acc.BillingState = 'state';
            acc.BillingPostalCode = 'pCode';
            acc.BillingCountry = 'country';
            acc.Main_Country_ISO__c = 'countryISO';
            acc.Main_Postal_Box__c = 'pBox';
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
        
            acc.SAP_Customer_ID__c = '76509';
            acc.Phone = '+31302979111';   
            acc.Agreement_Based_Survey_Created__c = false;
            Test.startTest();
            insert acc;
            
            Apttus__APTS_Agreement__c agree = new Apttus__APTS_Agreement__c();
            agree.Apttus__Account__c = acc.Id;
            agree.APTS_Sold_To__c = acc.Id;
            agree.Apttus__Status_Category__c = 'In Effect';
            agree.Apttus__Status__c = 'Activated';
            agree.Apttus__Contract_End_Date__c = Date.today();
            // agree.APTS_Bill_to_Party_Ingredients__c = accList[1].Id;
            // agree.APTS_Bill_to_Party_MachServ__c = accList[2].Id;
            // agree.APTS_Payer_Ingredients__c = accList[3].Id;
            // agree.APTS_Payer_Machines_Services__c = accList[4].Id;
            // agree.Apttus_CMConfig__LocationId__c = acctLocList[0].Id;
            agree.Name = 'Test Agreement';
            agree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
            
            insert agree;
            
            //agreement line item for ingredient coffee
            Apttus__AgreementLineItem__c agreeLineItemIng = new Apttus__AgreementLineItem__c();
            agreeLineItemIng.Apttus_CMConfig__HasOptions__c = false;
            agreeLineItemIng.Apttus_CMConfig__LineType__c = 'Product/Service';
            agreeLineItemIng.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Beans | Beans | Douwe Egberts';
            agreeLineItemIng.Apttus__AgreementId__c = agree.Id;
            
            insert agreeLineItemIng;
            
            Apttus__AgreementLineItem__c agreeLineItemIngTea = new Apttus__AgreementLineItem__c();
            agreeLineItemIngTea.Apttus_CMConfig__HasOptions__c = false;
            agreeLineItemIngTea.Apttus_CMConfig__LineType__c = 'Product/Service';
            agreeLineItemIngTea.Apttus_CMConfig__ClassificationHierarchy__c = 'Tea | Pickwick Volume Pack';
            agreeLineItemIngTea.Apttus__AgreementId__c = agree.Id;
            
            insert agreeLineItemIngTea;
            
            Apttus__AgreementLineItem__c agreeLineItemMac = new Apttus__AgreementLineItem__c();
            agreeLineItemMac.Apttus_CMConfig__HasOptions__c = false;
            agreeLineItemMac.Apttus_CMConfig__LineType__c = 'Product/Service';
            agreeLineItemMac.Apttus_CMConfig__ClassificationHierarchy__c = 'Machines | Liquid | Liquid | Cafitesse';
            agreeLineItemMac.Apttus__AgreementId__c = agree.Id;
            
            insert agreeLineItemMac;
            
            Apttus__AgreementLineItem__c agreeLineItemMore = new Apttus__AgreementLineItem__c();
            agreeLineItemMore.Apttus_CMConfig__HasOptions__c = false;
            agreeLineItemMore.Apttus_CMConfig__LineType__c = 'Product/Service';
            agreeLineItemMore.Apttus_CMConfig__ClassificationHierarchy__c = '&More | Sugar | Sugar | Portion Packs';
            agreeLineItemMore.Apttus__AgreementId__c = agree.Id;
            
            insert agreeLineItemMore;
            
            Apttus__AgreementLineItem__c agreeLineItemMore1 = new Apttus__AgreementLineItem__c();
            agreeLineItemMore1.Apttus_CMConfig__HasOptions__c = false;
            agreeLineItemMore1.Apttus_CMConfig__LineType__c = 'Product/Service';
            agreeLineItemMore1.Apttus_CMConfig__ClassificationHierarchy__c = '&More | Milk | Milk | Portion Packs';
            agreeLineItemMore1.Apttus__AgreementId__c = agree.Id;
            
            insert agreeLineItemMore1;
            
            Apttus__AgreementLineItem__c agreeLineItemMore2 = new Apttus__AgreementLineItem__c();
            agreeLineItemMore2.Apttus_CMConfig__HasOptions__c = false;
            agreeLineItemMore2.Apttus_CMConfig__LineType__c = 'Product/Service';
            agreeLineItemMore2.Apttus_CMConfig__ClassificationHierarchy__c = '&More | Chocolate | Chocolate | Chocolate Powder';
            agreeLineItemMore2.Apttus__AgreementId__c = agree.Id;
            
            insert agreeLineItemMore2;
            
            Apttus__AgreementLineItem__c agreeLineItemMore3 = new Apttus__AgreementLineItem__c();
            agreeLineItemMore3.Apttus_CMConfig__HasOptions__c = false;
            agreeLineItemMore3.Apttus_CMConfig__LineType__c = 'Product/Service';
            agreeLineItemMore3.Apttus_CMConfig__ClassificationHierarchy__c = '&More | Cups | Cups | Portion Packs';
            agreeLineItemMore3.Apttus__AgreementId__c = agree.Id;
            
            insert agreeLineItemMore3;
            
            List<Apttus__AgreementLineItem__c> agreementLineItemList = new List<Apttus__AgreementLineItem__c>();
            agreementLineItemList = [Select Id, APTS_Machine_Bundle__c, APTS_Service_Product__c, APTS_Bundle_Option__c,
                                                 APTS_Ingredient_Standalone__c, APTS_Services_Standalone__c,
                                                 APTS_More_Standalone__c, Apttus__AgreementId__r.Id, Apttus__AgreementId__r.APTS_Sold_To__c,
                                                 Apttus_CMConfig__ClassificationHierarchy__c, APTS_Ingredient_Option_Product_Family__c
                                          FROM Apttus__AgreementLineItem__c
                                          WHERE Apttus__AgreementId__r.APTS_Sold_To__c = :acc.id];
                                          
            System.debug('agreementLineItemListTestclass: ' + agreementLineItemList);
            
            // Apttus__AgreementLineItem__c agreeLineItemMore4 = new Apttus__AgreementLineItem__c();
            // agreeLineItemMore4.Apttus_CMConfig__HasOptions__c = false;
            // agreeLineItemMore4.Apttus_CMConfig__LineType__c = 'Product/Service';
            // agreeLineItemMore4.Apttus_CMConfig__ClassificationHierarchy__c = '&More | Tea Display | Tea Display | Boxes';
            // agreeLineItemMore4.Apttus__AgreementId__c = agree.Id;
            
            // insert agreeLineItemMore4;
            
            
            // Apttus__AgreementLineItem__c agreeLineItemSer = new Apttus__AgreementLineItem__c();
            // agreeLineItemSer.Apttus_CMConfig__HasOptions__c = false;
            // agreeLineItemSer.Apttus_CMConfig__LineType__c = 'Product/Service';
            // agreeLineItemSer.Apttus_CMConfig__ClassificationHierarchy__c = 'Machines | Liquid | Liquid | Cafitesse';
            // agreeLineItemSer.Apttus__AgreementId__c = agree.Id;
            
            // insert agreeLineItemSer;
            
            List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
            agreeList.add(agree);
            
            SM_AgreementToAccount smata = new SM_AgreementToAccount();
            smata.AgreementToAccountMethods(agreeList);
      
            Test.stopTest();
                   

            Account acctRec = [Select Id, Agreement_Based_Survey_Created__c FROM Account WHERE Id = :agree.APTS_Sold_To__c];
            
            System.assert(acctRec.Agreement_Based_Survey_Created__c == true);

        }

        
    }
    
    
}