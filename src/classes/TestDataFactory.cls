@isTest
public class TestDataFactory {

    public static List<Account> createAccounts(Integer i, String randSapID) {
        List<Account> accList = new List<Account>();
        
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'testDataFactory';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'factory123';
        insert paymentTerm;
        
        for(integer x = 0; x<=i; x++){
            Account acc = new Account();
            acc.Name = 'accName' + i;
            acc.Second_Account_Name__c = 'sAccName' + i;
            acc.Archiving_Flag__c = false;
            acc.BillingStreet = 'mainstreet' + i;
            acc.Main_House_Number__c = '123' + i;
            acc.Main_Street_Only__c = 'streetOnly' + i;
            acc.BillingCity = 'mainCity' + i;
            acc.BillingState = 'state' + i;
            acc.BillingPostalCode = 'pCode' + i;
            acc.BillingCountry = 'country' + i;
            acc.Main_Country_ISO__c = 'countryISO' + i;
            acc.Language__c = 'SAP_SR';
            acc.Bill_Block_Reason__c = 'SAP_00';
            acc.Transactional_Block_Reason__c = 'SAP_00';
            acc.Delivery_Block_Reason__c = 'SAP_D3';
            acc.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
             
            acc.SAP_Customer_ID__c = randSapID + x;
            acc.Phone = '+31302979111';
            accList.add(acc);
        }
        
        return accList;
    }
    
    public static List<Operational_Tasks__c> createOT(Integer i) {
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0333';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'System Administrator']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser19801.com', Sales_Organization__c = 'SAP_0333', Country= 'Netherlands',
        Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        insert u;
        
        Task taskRec = new Task();
        taskRec.WhatId = acc.Id;
        taskRec.OwnerId = u.Id;
        insert taskRec;
        
        List<Operational_Tasks__c> otList = new List<Operational_Tasks__c>();
        
        for(integer x = 0; x<=i; x++){
            Operational_Tasks__c otRec = new Operational_Tasks__c();
            otRec.Task_ID__c = taskRec.Id;
            otList.add(otRec);
        }
        
        return otList;
    }
    
    public static List<Account_Value_Estimation_Size_Price__c> createAVESize(Integer i) {
        List<Account_Value_Estimation_Size_Price__c> aveList = new List<Account_Value_Estimation_Size_Price__c>();
        
        for(integer x = 0; x<i; x++){
            Account_Value_Estimation_Size_Price__c ave = new Account_Value_Estimation_Size_Price__c();
            ave.Segment__c= 'SAP_A';
            ave.Company_Code__c = 'SAP_0202';
            ave.Size_Type_Input__c = '# of FTE';
            ave.Number_of_Drinks_per_Size_Type__c = 4;
            ave.RecordTypeId = Schema.SObjectType.Account_Value_Estimation_Size_Price__c.getRecordTypeInfosByName().get('Account Value Estimation Size Q').getRecordTypeId();            
            aveList.add(ave);
        }
        
        return aveList;
    }
    
    public static List<Account_Value_Estimation_Size_Price__c> createAVEPrice(Integer i) {
        List<Account_Value_Estimation_Size_Price__c> aveList = new List<Account_Value_Estimation_Size_Price__c>();
        
        for(integer x = 0; x<i; x++){
            Account_Value_Estimation_Size_Price__c ave = new Account_Value_Estimation_Size_Price__c();
            ave.Segment__c= 'SAP_A';
            ave.Company_Code__c = 'SAP_0202';
            ave.Avg_Price_per_Drink__c = 123;
            ave.RecordTypeId = Schema.SObjectType.Account_Value_Estimation_Size_Price__c.getRecordTypeInfosByName().get('Account Value Estimation Price P').getRecordTypeId();
            
            aveList.add(ave);
        }
        
        return aveList;
    }

    public static List<Bank_Details__c> createBankDetail (Integer i){
        List<Bank_Details__c> bDetailList = new List<Bank_Details__c>();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+3493849340';
        insert acc;
        
        for(integer x = 0; x<=i; x++){
            Bank_Details__c bDetail = new Bank_Details__c();
            bDetail.Bank_account__c = 'Bank Account ' + i;
            bDetail.Collection_authorization__c = false;
            bDetail.Control_key__c = '1';
            bDetail.IBAN__c = 'IBAN ' + i;
            bDetail.Account__c = acc.Id;
            bDetail.Updated_Request_Validation__c = SM_Constants.NoUpdateRequest;
            bDetailList.add(bDetail);
        }
        
        return bDetailList;
    }
     
    public static List<Account_Tax__c> createAccountTax (Integer i){
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+09238409384';
        insert acc;
        
        List<Account_Tax__c> acctTaxList = new List<Account_Tax__c>();
        
        for(integer x = 0; x<=i; x++){
            Account_Tax__c acctTax = new Account_Tax__c();
            acctTax.Mini_Tax_Classification__c = 'SAP_3';
            acctTax.Mini_Tax_Category__c = 'SAP_MWST';
            acctTax.Mini_Tax_Country__c = 'SAP_FR';
            acctTax.Mini_Account__c = acc.Id;
            acctTaxList.add(acctTax);
        }
        
        return acctTaxList;
    }
    
    public static List<Apttus_Config2__AccountLocation__c> createAccountLocation (Integer i){
        Id alRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        List<Apttus_Config2__AccountLocation__c> acctLocList = new List<Apttus_Config2__AccountLocation__c>();
        
        for(integer x = 0; x<=i; x++){
            Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
            acctLoc.RecordTypeId = alRO;
            acctLoc.Copy_of_Parent_Account__c = true;
            acctLoc.Apttus_Config2__AccountId__c = acc.Id;
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
        
        return acctLocList;
    }
    
    public static List<Task> createTask (Integer i){
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        List<Task> taskList = new List<Task>();
        
        for(integer x = 0; x <= 1; x++) {
            Task taskRec = new Task();
            taskRec.WhatId = acc.Id;
            taskList.add(taskRec);
        }
        
        return taskList;
    }
    
    public static List<Product2> createProduct(Integer i){
                
        List<Product2> productList = new List<Product2>();
        
        for(integer x = 0; x <= i; x++) {
            Product2 prd= new Product2();
            prd.Name= 'Test Prod NB'+x;
            prd.APTS_Product_Enabled_for_web_shop_s__c='NL';
            prd.APTS_Cross_plant_material_status__c='PR';
            prd.IsActive=true;
            prd.ProductCode='34500'+string.ValueOf(x);
            productList.add(prd);
        }
        
        return productList;
    }
    
   /* public static List<APTS_Replacement_Product__c> insertReplacement(integer i,List<Product2> prodList){
        List<APTS_Replacement_Product__c> prodReplacementList = new List<APTS_Replacement_Product__c>();
        for(integer x = 0; x <= i; x++) {
            APTS_Replacement_Product__c rep= new APTS_Replacement_Product__c();
            rep.APTS_Product__c= prodList[x].Id;
            rep.APTS_Start_Date__c=System.Now();
            rep.APTS_End_Date__c=System.Now()+1;
            rep.APTS_Description__c='TestReplacement'+x;
            
            prodReplacementList.add(rep);
        }
        return prodReplacementList;
    }*/
   
    
    public static List<Apttus_Config2__PriceList__c> createPriceList(Integer i){
                
        List<Apttus_Config2__PriceList__c> priceList = new List<Apttus_Config2__PriceList__c>();
        
        for(integer x = 0; x < i; x++) {
            Apttus_Config2__PriceList__c pl= new Apttus_Config2__PriceList__c();
            if(i>1){
                pl.Name= 'Test PriceList'+x;
            }
            else{
                pl.Name= 'Digital NL';
            }
            pl.Apttus_Config2__Active__c=true;
            pl.CurrencyIsoCode='EUR';
            pl.APTS_Region__c='SAP_0975';
            pl.APTS_SalesOrg__c = 'Denmark';
            pl.APTS_PriceList_Type__c = 'Direct';
            priceList.add(pl);
        }
        
        return priceList;
    }
    
    public static List<Apttus_Config2__PriceListItem__c> createPriceListItem(Integer i,List<Product2> prodList,List<Apttus_Config2__PriceList__c> priceList){
                
        List<Apttus_Config2__PriceListItem__c> pLItemList = new List<Apttus_Config2__PriceListItem__c>();
        
        for(integer x = 0; x <= i; x++) {
            Apttus_Config2__PriceListItem__c pli= new Apttus_Config2__PriceListItem__c();
            if(priceList.size()>1){
                pli.Apttus_Config2__PriceListId__c= priceList[x].Id;
            }
            else{
                pli.Apttus_Config2__PriceListId__c= priceList[0].Id;
            }
            pli.Apttus_Config2__Active__c=true;
            pli.Apttus_Config2__ProductId__c=prodList[x].Id;
            pli.APTS_Product_Code__c = prodList[x].ProductCode;
            pli.APTS_Sales_Organization__c = prodList[x].APTS_Sales_Organization__c;
            pli.Apttus_Config2__ChargeType__c='Rental Price';            
            pLItemList.add(pli);
        }
        
        return pLItemList;
    }

    public static List<Apttus_Config2__ProductOptionComponent__c> createProdOptionComp(Integer i,List<Product2> prodList){
                
        List<Apttus_Config2__ProductOptionComponent__c> pLItemList = new List<Apttus_Config2__ProductOptionComponent__c>();
        
        for(integer x = 0; x <= i; x++) {
            Apttus_Config2__ProductOptionComponent__c pli= new Apttus_Config2__ProductOptionComponent__c();
            if(prodList.size()>1){
                pli.Apttus_Config2__ComponentProductId__c= prodList[x].Id;
            }
            else{
                pli.Apttus_Config2__ComponentProductId__c= prodList[0].Id;
            }
           
            
               pli.Apttus_Config2__ParentProductId__c=prodList[x].Id;
               pli.Apttus_Config2__Sequence__c=120.00;
               pli.Apttus_Config2__Modifiable__c=True;
               pli.CurrencyIsoCode='EUR';
          
            
            
            pLItemList.add(pli);
        }
        
        return pLItemList;
    }
    
        public static List<Apttus_Config2__ClassificationName__c> createCategory(Integer i){
                
        List<Apttus_Config2__ClassificationName__c> category = new List<Apttus_Config2__ClassificationName__c>();
        
        for(integer x = 0; x < i; x++) {
            Apttus_Config2__ClassificationName__c pl= new Apttus_Config2__ClassificationName__c();
            if(i>1){
                pl.Name= 'Test cateList'+x;
                
            }
            else{
                pl.Name= 'Digital NL';
                
            }
             pl.Apttus_Config2__HierarchyLabel__c='Test';
            pl.CurrencyIsoCode='EUR';
            pl.Apttus_Config2__Active__c=True;
            category.add(pl);
        }
        
        return category;
    }
    
    
    
    
     public static List<Apttus_Config2__ClassificationHierarchy__c> createHierarchy(Integer i,List<Apttus_Config2__ClassificationName__c> category){
                
        List<Apttus_Config2__ClassificationHierarchy__c> cateList = new List<Apttus_Config2__ClassificationHierarchy__c>();
        
        for(integer x = 0; x < i; x++) {
            Apttus_Config2__ClassificationHierarchy__c pl= new Apttus_Config2__ClassificationHierarchy__c();
            if(i>1){
                 
                pl.Name= 'Test cateList'+x;
                
            }
            else{
                pl.Name= 'Digital NL';
                
            }
           pl.Apttus_Config2__HierarchyId__c=category[x].Id;
            pl.CurrencyIsoCode='EUR';
            pl.Apttus_Config2__Label__c='Test';
            cateList.add(pl);
        }
        
        return cateList;
    }
    
     public static List<Apttus_Config2__ProductClassification__c> createClassification(Integer i,List<Product2> prodList,List<Apttus_Config2__ClassificationName__c> category,List<Apttus_Config2__ClassificationHierarchy__c> cateList){
                
        List<Apttus_Config2__ProductClassification__c> cateHierList = new List<Apttus_Config2__ProductClassification__c>();
        
        for(integer x = 0; x <= i; x++) {
            Apttus_Config2__ProductClassification__c pli= new Apttus_Config2__ProductClassification__c();
            if(cateList.size()>1){
                pli.Apttus_Config2__ClassificationId__c= cateList[1].Id;
            }
            else{
                pli.Apttus_Config2__ClassificationId__c= cateList[0].Id;
            }
            
            pli.Apttus_Config2__ProductId__c=prodList[x].Id;
             pli.CurrencyIsoCode='EUR';
            cateHierList.add(pli);
        }
        
        return cateHierList;
    }
    
    public static APTS_Sales_Org_Data__c createSalesOrgData(Id testProductId){
        APTS_Sales_Org_Data__c salesOrgData = new APTS_Sales_Org_Data__c();
        //salesOrgData.Name = 'Test Sales Org Data';
        salesOrgData.APTS_Product__c = testProductId;
        return salesOrgData;
    }
    
    /*public static List<Product2> testUpdate_Error(Integer i)
        {
        List<Product2> productList = new List<Product2>();
        for(integer x = 0; x <= i; x++) {
            Product2 prd= new Product2();
            prd.Name= 'test';
            prd.APTS_Product_Enabled_for_web_shop_s__c='';
            prd.IsActive=false;
            
            productList.add(prd);
        }
       return productList;
   }*/
    
    public static Apttus_Config2__ProductOptionGroup__c createProdOptnGrp(Integer sequence,Id prodId, Id optnGrpId, Id pOptnGrpId, Id rOptnGrpId ){
        Apttus_Config2__ProductOptionGroup__c prodOptnGrp = new Apttus_Config2__ProductOptionGroup__c();
        prodOptnGrp.Apttus_Config2__Sequence__c = sequence; 
        prodOptnGrp.Apttus_Config2__ProductId__c = prodId;
        prodOptnGrp.Apttus_Config2__OptionGroupId__c = optnGrpId; 
        prodOptnGrp.Apttus_Config2__ParentOptionGroupId__c = pOptnGrpId; 
        prodOptnGrp.Apttus_Config2__RootOptionGroupId__c = rOptnGrpId;
        return prodOptnGrp;       
    }
    
    public static APTS_ProdDistributionGroupSettings__c createProdDistbGrpStgs(String Name, String extnId){
        APTS_ProdDistributionGroupSettings__c prodDisbtnGrpStng = new APTS_ProdDistributionGroupSettings__c();
        prodDisbtnGrpStng.Name = Name; 
        prodDisbtnGrpStng.APTS_External_ID__c = extnId;
        return prodDisbtnGrpStng; 
    }
    
    public static APTS_Sales_Org_Data__c createSlsOrgData(String Name, String sOrgDtNm, Id prodId, String disbnChnSpcMatr){
        APTS_Sales_Org_Data__c slsOrgData = new APTS_Sales_Org_Data__c();
        //slsOrgData.Name = Name;
        slsOrgData.APTS_Sales_Org_Data_Name__c = sOrgDtNm; 
        slsOrgData.APTS_Product__c = prodId; 
        slsOrgData.APTS_Distribution_chain_specific_materia__c = disbnChnSpcMatr; 
        return slsOrgData;
    }
    
    public static Apttus_Config2__ProductGroup__c createprodGrp(String Name, String prodGrpExId){
        Apttus_Config2__ProductGroup__c prodGrp = new Apttus_Config2__ProductGroup__c();
        prodGrp.Name = Name;
        prodGrp.APTS_ProductGroupExtId__c = prodGrpExId;
        return prodGrp;
    }
    public static String createCloneTask (Integer i){
        Id taskAutomated = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Archiving_Flag__c = true;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.BillingCountry = 'country';
        acc.Main_Country_ISO__c = 'countryISO' ;
        acc.Main_Postal_Box__c = 'pBox';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
         
        acc.SAP_Customer_ID__c = '1234567890';
        acc.Phone = '+31302979111';
        insert acc;
        
        List<Task> taskList = new List<Task>();
        String IdTask;
        Task taskRec = new Task();
        for(integer x = 0; x <= 1; x++) {
            taskRec.WhatId = acc.Id;
            taskRec.Subject = 'asdfggg';
            taskRec.RecordTypeId = taskAutomated;
            taskRec.ActivityDate = System.today();
            taskRec.Priority = 'High Priority';
            taskRec.Type = 'Call';
            taskRec.Task_Source__c = 'EPI';
            taskRec.Status = 'Open';
            taskRec.Reason__c = null;
            taskRec.Sales_Organization__c = 'SAP_0111'; 
            taskRec.Role_Id__c = null;
            taskRec.WhoType__c = null;
            taskRec.WhatType__c = null;
            taskRec.Campaign__c = null;
            taskRec.Contact__c = null;
            taskRec.Date_Time_Closed__c = null;
            taskRec.WhoId = null;
            taskRec.Description = 'asdfasdfasdfsadfsadf';
            taskRec.Start_DateCS__c = null;
            taskRec.Suggested_Completion_Date__c = null; 
            taskRec.Contract_Asset_Expiration_Date__c = null; 
            taskRec.Task_Expiration_Date__c = null;
            taskRec.Contract_Asset_Lifetime__c = null;
            taskRec.Touchpoint_Type__c = 'INBOUND CALL';
            taskRec.Guidance__c = null;
            taskRec.Account_Segment_HANA__c = null;
            taskRec.Account_Lifecycle_HANA__c = null;
            taskRec.Oldest_Contract_End_Date_Expiration_F__c = null;
            taskRec.Oldest_Contract_End_Date_Relationship__c = null;
            taskRec.Oldest_Machine_Installation_Date_Expira__c = null;
            taskRec.Oldest_Machine_Installation_Date_Relati__c = null;
            taskRec.Newest_Contract_End_Date_Expiration_F__c = null;
            taskRec.Newest_Contract_End_Date_Relationship__c = null;
            taskRec.Newest_Machine_Installation_Date_Expira__c = null;
            taskRec.Newest_Machine_Installation_Date_Relati__c = null;
            taskRec.Cloned__c = false;
            taskList.add(taskRec);
            IdTask = taskRec.Id;
        }
        
        return IdTask;
    }
}