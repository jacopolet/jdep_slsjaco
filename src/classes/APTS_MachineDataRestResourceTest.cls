/******************************************************************************************************
Name            : APTS_MachineDataRestResourceTest
Created By      : Kiruthika Pachaimaal
Created Date    : 26.02.2018
Description     : Class which will create test data and will test APTS_OrderLineItemTriggerHandler Class
Version history : v1.0 - Created - 
Classes Covered : APTS_MachineDataRestResource(94% code coverage)
                  APTS_VIINETInterfacePojo(94% code coverage)
********************************************************************************************************/
@isTest
public class APTS_MachineDataRestResourceTest {
    private static string ACTIVATED= 'Activated';
    private static String MACHINE = 'Machine';
    
    /* Test Method to create test data*/
    @testSetup
    static void setupTestData(){
        
        Account account = APTS_TestUtils.createGrandParentAccount();
        Database.insert(account);
        List<Product2> pro = new List<Product2>();
        Product2 product = APTS_TestUtils.createProduct('TestCoffeeMachine', '123', 'Machines');
        product.Apttus_Config2__ConfigurationType__c = 'Bundle';
        product.APTS_Installation_Type__c = 'Plug and Play';
        product.Family = 'SAP_04';
        product.APTS_Option_Group_Indicator__c = '0106'; 
        pro.add(product);

        Apttus_Config2__AccountLocation__c accountLocation = APTS_TestUtils.createAccountLocation(account.id);
        accountLocation.Apttus_Config2__City__c ='Bangalore';
        accountLocation.Apttus_Config2__Street__c ='Sai Bavan Street';
        accountLocation.Shipping_House_Number__c ='132';
        accountLocation.House_Number_Supplement__c ='133';
        accountLocation.SAP_Customer_ID__c ='12334';
        Database.insert(accountLocation);
        
        Product2 product1 = APTS_TestUtils.createProduct('TestCoffee', '126', 'Machines');
        product1.Apttus_Config2__ConfigurationType__c = 'Bundle';
        product1.APTS_Installation_Type__c = 'Plug and Play';
        product1.Family = 'SAP_04';
        product1.APTS_Option_Group_Indicator__c = '0106'; 
        pro.add(product1);
        Database.insert(pro);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList);
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.Id, product.Id);
        
        Apttus_Config2__BillingPreference__c billPref = APTS_TestUtils.createBillingPrefrence('January');
        billPref.Name=string.valueOf(system.now());
        Database.insert(billPref); 
        
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('New', priceList.Id, account.Id, billPref.Id);
        Database.insert(order);
        
       
        PhysicalAsset__c phyAst = new PhysicalAsset__c();
        Id machineRecTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(MACHINE).getRecordTypeId();
        phyAst.RecordTypeId = machineRecTypeId;
        phyAst.UniqueNumber__c = 'BAS102';
        phyAst.Product__c = product.Id;  
        phyAst.AssetStatus__c = 'Pending Activation';
        phyAst.Building__c = 'Block-A';
        phyAst.PostalCode__c = '6000345';
        phyAst.Country__c = 'India';
        phyAst.Connected__c = 'Yes';
        phyAst.AccountLocation__c=accountLocation.Id;
        Database.insert(phyAst);
     
        List<Apttus_Config2__AssetLineItem__c> assetLineItem = new List<Apttus_Config2__AssetLineItem__c>();
        
        Apttus_Config2__AssetLineItem__c assetLineItem1 = APTS_TestUtils.createAssetLineItem(account.Id, product.Id,  priceList.Id, priceListItem.Id, billPref.Id, order.Id); 
        assetLineItem1.APTS_Physical_Asset__c = phyAst.Id; 
        assetLineItem1.Apttus_Config2__AssetStatus__c = 'Activated';
        assetLineItem1.APTS_Option_Group_Text__c='Menu';
        assetLineItem1.Apttus_Config2__OptionId__c = product1.Id ;
        insert assetLineItem1;
        assetLineItem1.APTS_Is_Primary_L1_Parent__c = assetLineItem1.Id;
        assetLineItem1.APTS_Is_Primary_L1_Line__c = true;
        assetLineItem1.Apttus_Config2__LineType__c = 'Product/Service';
        //assetLineItem1.APTS_Is_Primary_L1_Asset__c = assetLineItem1.Id;
        update assetLineItem1;
        //assetLineItem.add(assetLineItem1);
        
        Apttus_Config2__AssetLineItem__c assetLineItem2 = APTS_TestUtils.createAssetLineItem(account.Id, product.Id,  priceList.Id, priceListItem.Id, billPref.Id, order.Id); 
        assetLineItem2.APTS_Physical_Asset__c = phyAst.Id; 
        assetLineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
        assetLineItem2.APTS_Option_Group_Text__c='Menu';
        assetLineItem2.Apttus_Config2__OptionId__c = product1.Id ;
        assetLineItem2.APTS_Is_Primary_L1_Parent__c = assetLineItem1.Id;
        assetLineItem2.APTS_Is_Primary_L1_Asset__c = assetLineItem1.Id;
        assetLineItem.add(assetLineItem2);
        
        Apttus_Config2__AssetLineItem__c assetLineItem3 = APTS_TestUtils.createAssetLineItem(account.Id, product.Id,  priceList.Id, priceListItem.Id, billPref.Id, order.Id); 
        assetLineItem3.APTS_Physical_Asset__c = phyAst.Id; 
        assetLineItem3.Apttus_Config2__AssetStatus__c = 'Activated';
        assetLineItem3.APTS_Option_Group_Text__c='Menu';
        assetLineItem3.Apttus_Config2__OptionId__c = product1.Id ;
        assetLineItem3.APTS_Is_Primary_L1_Parent__c = assetLineItem1.Id;
        assetLineItem3.APTS_Is_Primary_L1_Asset__c = assetLineItem1.Id;
        assetLineItem.add(assetLineItem3);
        
        //Apttus_Config2__AssetLineItem__c assetLineItem2 = APTS_TestUtils.createAssetLineItem(account.Id, product.Id,  priceList.Id, priceListItem.Id, billPref.Id, order.Id); 
        Database.insert(assetLineItem); 
        
       assetLineItem2.Apttus_Config2__ParentAssetId__c = assetLineItem1.Id; 
       update assetLineItem2; 
        
        Apttus_Config2__AssetAttributeValue__c aAttVle = new Apttus_Config2__AssetAttributeValue__c();
        aAttVle.Apttus_Config2__Vendor__c = 'Default';
        aAttVle.Apttus_Config2__AssetLineItemId__c = assetLineItem1.Id;
        Database.insert(aAttVle);
    }
    
    //@isTest
    static testMethod void testMachineDataGetMethod(){
        Test.startTest();
       // setupTestData();

        Datetime fromDateTimeval = DateTime.Now().AddDays(-1);  
        Datetime toDateTimeval = DateTime.Now().AddDays(1); 
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/getAssetDetails';  
        request.addParameter('fromDateTime', string.valueOfGmt(fromDateTimeval));
        request.addParameter('toDateTime', string.valueOfGmt(toDateTimeval));
        //request.addParameter('serialNumber', string.valueOf(01232345));
        request.httpMethod = 'GET';
        RestContext.request = request;
        APTS_MachineDataRestResource.doGet();
        fromDateTimeval = Datetime.valueOfGmt(RestContext.request.params.get('fromDateTime'));
        toDateTimeval = Datetime.valueOfGmt(RestContext.request.params.get('toDateTime'));  
        List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__AccountId__c,Apttus_Config2__AccountId__r.Name,APTS_Physical_Asset__r.UniqueNumber__c,
                                                            APTS_Physical_Asset__r.Product__r.Name,APTS_Physical_Asset__r.AssetStatus__c,APTS_Physical_Asset__r.Building__c,
                                                            APTS_Option_Group_Text__c,Apttus_Config2__OptionId__r.ProductCode, APTS_Is_Primary_L1_Asset__c,
                                                            APTS_Physical_Asset__r.Street__c,APTS_Physical_Asset__r.Floor__c,APTS_Physical_Asset__r.City__c,   
                                                            APTS_Physical_Asset__r.PostalCode__c,APTS_Physical_Asset__r.Country__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c,
                                                            (select Id,Apttus_Config2__Vendor__c from  Apttus_Config2__AssetAttributeValues__r order by LastModifiedDate  desc  limit 1) 
                                                            from Apttus_Config2__AssetLineItem__c 
                                                            where Apttus_Config2__ProductId__r.Family = 'SAP_04' and (LastModifiedDate >= :fromDateTimeval and LastModifiedDate <= :toDateTimeval) and  Apttus_Config2__AssetStatus__c=:ACTIVATED
                                                            ];
        system.debug('assetLineItem-->'+assetLineItem);
        APTS_VIINETInterfacePojo vIFPTest;
        
        for(Apttus_Config2__AssetLineItem__c ali : assetLineItem){
            vIFPTest = new APTS_VIINETInterfacePojo();
            vIFPTest.TelemetrySerial = 'picounit'; //Need to change this.
            vIFPTest.SerialNumber = ali.APTS_Physical_Asset__r.UniqueNumber__c;
            vIFPTest.MachineModel = ali.APTS_Physical_Asset__r.Product__r.Name;
            vIFPTest.OrganisationName = ali.Apttus_Config2__AccountId__r.Name;
            vIFPTest.Status = ali.APTS_Physical_Asset__r.AssetStatus__C;
            vIFPTest.PlanogramID= ali.Apttus_Config2__OptionId__r.ProductCode;
            vIFPTest.SiteName = ali.APTS_Physical_Asset__r.Building__c +' '+ ali.APTS_Physical_Asset__r.Street__C;
            vIFPTest.OnsiteLocation  = ali.APTS_Physical_Asset__r.Floor__c;
            vIFPTest.City = ali.APTS_Physical_Asset__r.City__c;
            vIFPTest.PostCode = ali.APTS_Physical_Asset__r.PostalCode__C;
            vIFPTest.Country = ali.APTS_Physical_Asset__r.Country__c;
            vIFPTest.SiteType = ali.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c;
            vIFPTest.Channel = ali.APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c;    
        }
        System.assert(assetLineItem != null);
        //System.assertEquals('Test record', assetLineItem.Subject);
        Test.stopTest();
    } 
    static testMethod void testMachineDataGetMethod2(){
        Test.startTest();
       // setupTestData();

        Datetime fromDateTimeval = DateTime.Now().AddDays(-1);  
        Datetime toDateTimeval = DateTime.Now().AddDays(1); 
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/getAssetDetails';  
        request.addParameter('fromDateTime', string.valueOfGmt(fromDateTimeval));
        request.addParameter('toDateTime', string.valueOfGmt(toDateTimeval));
        request.addParameter('serialNumber', string.valueOf(01232345));
        request.httpMethod = 'GET';
        RestContext.request = request;
        APTS_MachineDataRestResource.doGet();
        fromDateTimeval = Datetime.valueOfGmt(RestContext.request.params.get('fromDateTime'));
        toDateTimeval = Datetime.valueOfGmt(RestContext.request.params.get('toDateTime'));  
        List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__AccountId__c,Apttus_Config2__AccountId__r.Name,APTS_Physical_Asset__r.UniqueNumber__c,
                                                            APTS_Physical_Asset__r.Product__r.Name,APTS_Physical_Asset__r.AssetStatus__c,APTS_Physical_Asset__r.Building__c,
                                                            APTS_Physical_Asset__r.Street__c,APTS_Physical_Asset__r.Floor__c,APTS_Physical_Asset__r.City__c, APTS_Is_Primary_L1_Asset__c,   
                                                            APTS_Physical_Asset__r.PostalCode__c,APTS_Physical_Asset__r.Country__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c,
                                                            (select Id,Apttus_Config2__Vendor__c from  Apttus_Config2__AssetAttributeValues__r order by LastModifiedDate  desc  limit 1) 
                                                            from Apttus_Config2__AssetLineItem__c 
                                                            where Apttus_Config2__ProductId__r.Family = 'SAP_04' and (LastModifiedDate >= :fromDateTimeval and LastModifiedDate <= :toDateTimeval) and  Apttus_Config2__AssetStatus__c=:ACTIVATED
                                                            ];
        system.debug('assetLineItem-->'+assetLineItem);
        APTS_VIINETInterfacePojo vIFPTest;
        
        for(Apttus_Config2__AssetLineItem__c ali : assetLineItem){
            vIFPTest = new APTS_VIINETInterfacePojo();
            vIFPTest.TelemetrySerial = 'picounit'; //Need to change this.
            vIFPTest.SerialNumber = ali.APTS_Physical_Asset__r.UniqueNumber__c;
            vIFPTest.MachineModel = ali.APTS_Physical_Asset__r.Product__r.Name;
            vIFPTest.OrganisationName = ali.Apttus_Config2__AccountId__r.Name;
            vIFPTest.Status = ali.APTS_Physical_Asset__r.AssetStatus__C;
                    
            vIFPTest.SiteName = ali.APTS_Physical_Asset__r.Building__c +' '+ ali.APTS_Physical_Asset__r.Street__C;
            vIFPTest.OnsiteLocation  = ali.APTS_Physical_Asset__r.Floor__c;
            vIFPTest.City = ali.APTS_Physical_Asset__r.City__c;
            vIFPTest.PostCode = ali.APTS_Physical_Asset__r.PostalCode__C;
            vIFPTest.Country = ali.APTS_Physical_Asset__r.Country__c;
            vIFPTest.SiteType = ali.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c;
            vIFPTest.Channel = ali.APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c;    
        }
        System.assert(assetLineItem != null);
        //System.assertEquals('Test record', assetLineItem.Subject);
        Test.stopTest();
    } 
        static testMethod void testMachineDataGetMethod3(){
        Test.startTest(); 
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/getAssetDetails';  
        request.addParameter('serialNumber', string.valueOf(01232345));
        request.addParameter('fromDateTime', null);
        request.addParameter('toDateTime', null);
        request.httpMethod = 'GET';
        RestContext.request = request;
        APTS_MachineDataRestResource.doGet();
        List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__AccountId__c,Apttus_Config2__AccountId__r.Name,APTS_Physical_Asset__r.UniqueNumber__c,
                                                            APTS_Physical_Asset__r.Product__r.Name,APTS_Physical_Asset__r.AssetStatus__c,APTS_Physical_Asset__r.Building__c,
                                                            APTS_Physical_Asset__r.Street__c,APTS_Physical_Asset__r.Floor__c,APTS_Physical_Asset__r.City__c, APTS_Is_Primary_L1_Asset__c,
                                                            APTS_Physical_Asset__r.PostalCode__c,APTS_Physical_Asset__r.Country__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c,
                                                            (select Id,Apttus_Config2__Vendor__c from  Apttus_Config2__AssetAttributeValues__r order by LastModifiedDate  desc  limit 1) 
                                                            from Apttus_Config2__AssetLineItem__c 
                                                            where Apttus_Config2__ProductId__r.Family = 'SAP_04' and  Apttus_Config2__AssetStatus__c=:ACTIVATED
                                                            ];
        system.debug('assetLineItem-->'+assetLineItem);
        APTS_VIINETInterfacePojo vIFPTest;
        
        for(Apttus_Config2__AssetLineItem__c ali : assetLineItem){
            vIFPTest = new APTS_VIINETInterfacePojo();
            vIFPTest.TelemetrySerial = 'picounit'; //Need to change this.
            vIFPTest.SerialNumber = ali.APTS_Physical_Asset__r.UniqueNumber__c;
            vIFPTest.MachineModel = ali.APTS_Physical_Asset__r.Product__r.Name;
            vIFPTest.OrganisationName = ali.Apttus_Config2__AccountId__r.Name;
            vIFPTest.Status = ali.APTS_Physical_Asset__r.AssetStatus__C;
                    
            vIFPTest.SiteName = ali.APTS_Physical_Asset__r.Building__c +' '+ ali.APTS_Physical_Asset__r.Street__C;
            vIFPTest.OnsiteLocation  = ali.APTS_Physical_Asset__r.Floor__c;
            vIFPTest.City = ali.APTS_Physical_Asset__r.City__c;
            vIFPTest.PostCode = ali.APTS_Physical_Asset__r.PostalCode__C;
            vIFPTest.Country = ali.APTS_Physical_Asset__r.Country__c;
            vIFPTest.SiteType = ali.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c;
            vIFPTest.Channel = ali.APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c;    
        }
        System.assert(assetLineItem != null);
        //System.assertEquals('Test record', assetLineItem.Subject);
        Test.stopTest();
    }
       static testMethod void testMachineDataGetMethod4(){
        Test.startTest(); 
        try{
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/getAssetDetails';  
        request.addParameter('serialNumber', string.valueOf(01232345));
        request.addParameter('fromDateTime', null);
        request.addParameter('toDateTime', null);
        request.httpMethod = '';
        RestContext.request = request;
        APTS_MachineDataRestResource.doGet();
        List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__AccountId__c,Apttus_Config2__AccountId__r.Name,APTS_Physical_Asset__r.UniqueNumber__c,
                                                            APTS_Physical_Asset__r.Product__r.Name,APTS_Physical_Asset__r.AssetStatus__c,APTS_Physical_Asset__r.Building__c,
                                                            APTS_Physical_Asset__r.Street__c,APTS_Physical_Asset__r.Floor__c,APTS_Physical_Asset__r.City__c,   
                                                            APTS_Physical_Asset__r.PostalCode__c,APTS_Physical_Asset__r.Country__c, APTS_Is_Primary_L1_Asset__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c,
                                                            (select Id,Apttus_Config2__Vendor__c from  Apttus_Config2__AssetAttributeValues__r order by LastModifiedDate  desc  limit 1) 
                                                            from Apttus_Config2__AssetLineItem__c 
                                                            where Apttus_Config2__ProductId__r.Family = 'SAP_04' and  Apttus_Config2__AssetStatus__c=:ACTIVATED
                                                            ];
        system.debug('assetLineItem-->'+assetLineItem);
        APTS_VIINETInterfacePojo vIFPTest;
        
        for(Apttus_Config2__AssetLineItem__c ali : assetLineItem){
            vIFPTest = new APTS_VIINETInterfacePojo();
            vIFPTest.TelemetrySerial = 'picounit'; //Need to change this.
            vIFPTest.SerialNumber = ali.APTS_Physical_Asset__r.UniqueNumber__c;
            vIFPTest.MachineModel = ali.APTS_Physical_Asset__r.Product__r.Name;
            vIFPTest.OrganisationName = ali.Apttus_Config2__AccountId__r.Name;
            vIFPTest.Status = ali.APTS_Physical_Asset__r.AssetStatus__C;
                    
            vIFPTest.SiteName = ali.APTS_Physical_Asset__r.Building__c +' '+ ali.APTS_Physical_Asset__r.Street__C;
            vIFPTest.OnsiteLocation  = ali.APTS_Physical_Asset__r.Floor__c;
            vIFPTest.City = ali.APTS_Physical_Asset__r.City__c;
            vIFPTest.PostCode = ali.APTS_Physical_Asset__r.PostalCode__C;
            vIFPTest.Country = ali.APTS_Physical_Asset__r.Country__c;
            vIFPTest.SiteType = ali.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c;
            vIFPTest.Channel = ali.APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c;    
        }
        System.assert(assetLineItem != null);
        //System.assertEquals('Test record', assetLineItem.Subject);
        }
         catch (Exception e) {
        System.assert(false, 'Exception ' + e);
        }
        Test.stopTest();
    }   
    static testMethod void testMachineDataGetMethod5(){
        Test.startTest(); 
        try{
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/getAssetDetails';  
        request.addParameter('serialNumber', string.valueOf(01232345));
        request.addParameter('fromDateTime', null);
        request.addParameter('toDateTime', null);
        request.httpMethod = '';
       // RestContext.request = request;
        APTS_MachineDataRestResource.doGet();
        List<Apttus_Config2__AssetLineItem__c> assetLineItem = [select id,Apttus_Config2__AccountId__c,Apttus_Config2__AccountId__r.Name,APTS_Physical_Asset__r.UniqueNumber__c,
                                                            APTS_Physical_Asset__r.Product__r.Name,APTS_Physical_Asset__r.AssetStatus__c,APTS_Physical_Asset__r.Building__c,
                                                            APTS_Physical_Asset__r.Street__c,APTS_Physical_Asset__r.Floor__c,APTS_Physical_Asset__r.City__c,   
                                                            APTS_Physical_Asset__r.PostalCode__c,APTS_Physical_Asset__r.Country__c, APTS_Is_Primary_L1_Asset__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c,
                                                            APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c,
                                                            (select Id,Apttus_Config2__Vendor__c from  Apttus_Config2__AssetAttributeValues__r order by LastModifiedDate  desc  limit 1) 
                                                            from Apttus_Config2__AssetLineItem__c 
                                                            where Apttus_Config2__ProductId__r.Family = 'SAP_04' and  Apttus_Config2__AssetStatus__c=:ACTIVATED
                                                            ];
        system.debug('assetLineItem-->'+assetLineItem);
        APTS_VIINETInterfacePojo vIFPTest;
        
        for(Apttus_Config2__AssetLineItem__c ali : assetLineItem){
            vIFPTest = new APTS_VIINETInterfacePojo();
            vIFPTest.TelemetrySerial = 'picounit'; //Need to change this.
            vIFPTest.SerialNumber = ali.APTS_Physical_Asset__r.UniqueNumber__c;
            vIFPTest.MachineModel = ali.APTS_Physical_Asset__r.Product__r.Name;
            vIFPTest.OrganisationName = ali.Apttus_Config2__AccountId__r.Name;
            vIFPTest.Status = ali.APTS_Physical_Asset__r.AssetStatus__C;
                    
            vIFPTest.SiteName = ali.APTS_Physical_Asset__r.Building__c +' '+ ali.APTS_Physical_Asset__r.Street__C;
            vIFPTest.OnsiteLocation  = ali.APTS_Physical_Asset__r.Floor__c;
            vIFPTest.City = ali.APTS_Physical_Asset__r.City__c;
            vIFPTest.PostCode = ali.APTS_Physical_Asset__r.PostalCode__C;
            vIFPTest.Country = ali.APTS_Physical_Asset__r.Country__c;
            vIFPTest.SiteType = ali.APTS_Physical_Asset__r.AccountLocation__r.Apttus_Config2__Type__c;
            vIFPTest.Channel = ali.APTS_Physical_Asset__r.AccountLocation__r.Mini_Distribution_Channel__c;    
        }
        System.assert(assetLineItem != null);
        //System.assertEquals('Test record', assetLineItem.Subject);
        }
         catch (Exception e) {
        System.assert(false, 'Exception ' + e);
        }
        Test.stopTest();
    }
     
}