@IsTest
public class APTS_PenaltyCalculationCtrlTest{
    
    Public Static TestMethod Void allTests()
    {

        test.startTest();
        Account acct= APTS_TestUtils.createOrganisationproduct();
        insert acct;
        Product2 prod = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
        insert prod;
        Product2 prod1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
        insert prod1;
        
        Apttus_Config2__AssetLineItem__c  alineItem = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem.Apttus_Config2__Frequency__c='Monthly';
        alineItem.Apttus_Config2__PriceType__c='Recurring';
        alineItem.APTS_Type_Of_Contract__c = 'Rent';
        alineItem.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem.Apttus_Config2__AccountId__c = acct.id;
        alineItem.APTS_Is_Primary_L1_Line__c = true;
        insert alineItem;
        
        Apttus_Config2__AssetLineItem__c  alineItem2 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem2.Apttus_Config2__Frequency__c='Monthly';
        alineItem2.Apttus_Config2__PriceType__c='Recurring';
        alineItem2.APTS_Type_Of_Contract__c = 'Rent';
        alineItem2.Apttus_Config2__AssetStatus__c ='Renewed';
        alineItem2.Apttus_Config2__AccountId__c = acct.id;
        alineItem2.APTS_Is_Primary_L1_Line__c = true;
        insert alineItem2;
        
        Apttus_Config2__AssetLineItem__c  alineItem1 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem1.Apttus_Config2__Frequency__c='Monthly';
        alineItem1.Apttus_Config2__PriceType__c='Renewed';
        alineItem1.APTS_Type_Of_Contract__c = 'Rent';
        alineItem1.Apttus_Config2__OptionId__c = prod1.id;
        alineItem1.Apttus_Config2__ParentAssetId__c = alineItem.id;
        alineItem1.Apttus_Config2__BundleAssetId__c = alineItem.id;
        alineItem1.Apttus_Config2__AssetStatus__c=APTS_CPQConstants.LABEL_ACTIVATED;
        alineItem1.APTS_Is_Primary_L1_Line__c = true;
        insert alineItem1;
        
        Apttus_Config2__AssetLineItem__c  alineItem4 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem4.Apttus_Config2__Frequency__c='Monthly';
        alineItem4.Apttus_Config2__PriceType__c='Renewed';
        alineItem4.APTS_Type_Of_Contract__c = 'Rent';
        alineItem4.Apttus_Config2__OptionId__c = prod1.id;
        alineItem4.Apttus_Config2__ParentAssetId__c = alineItem.id;
        alineItem4.Apttus_Config2__BundleAssetId__c = alineItem.id;
        alineItem4.Apttus_Config2__AssetStatus__c=APTS_CPQConstants.LABEL_ACTIVATED;
        alineItem4.APTS_Is_Primary_L1_Line__c = true;
        insert alineItem4;
        
        
        Apttus__APTS_Agreement__c agr = APTS_TestUtils.createAgreement(null, null, null, acct.id);
        insert agr;
        List<Apttus__AgreementLineItem__c> aglilist = APTS_TestUtils.createAgreementLineItem(prod.id, agr.id, acct.id,new Apttus_Config2__LineItem__c (), null,null);
        insert aglilist;
        System.assert(aglilist != Null);
        
        Apttus_Config2__Order__c ord4 = APTS_TestUtils.createOrder('New',null,acct.Id,null);
        ord4.Apttus_CMConfig__AgreementId__c = agr.id;
        ord4.APTS_Requested_Installation_Date__c = Date.newInstance(2019, 01, 14);
        insert ord4;
        
        Apttus_Config2__ProductConfiguration__c prodConfig = new Apttus_Config2__ProductConfiguration__c(Name = 'Sample', Apttus_Config2__OrderId__c = ord4.id, Apttus_Config2__PriceListId__c = null,Apttus_Config2__AccountId__c=acct.id);
        insert prodConfig;
        System.assert(prodConfig != Null);
        Apttus_Billing__BillingSchedule__c bs1 = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__AssetLineItemId__c=alineItem.id,Apttus_Billing__Status__c='Invoiced',Apttus_Billing__PeriodStartDate__c=Date.Today(),Apttus_Billing__PeriodEndDate__c=Date.today().addDays(5),Apttus_Billing__FeeAmount__c=100);
        insert bs1;
        Apttus_Billing__BillingSchedule__c bs2 = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__AssetLineItemId__c=alineItem2.id,Apttus_Billing__Status__c='Pending Billing',Apttus_Billing__PeriodStartDate__c=Date.Today(),Apttus_Billing__PeriodEndDate__c=Date.today().addDays(5),Apttus_Billing__FeeAmount__c=100);
        insert bs2;
        Apttus_Billing__BillingSchedule__c bs3 = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__AssetLineItemId__c=alineItem1.id,Apttus_Billing__Status__c='Pending Billing',Apttus_Billing__PeriodStartDate__c=Date.Today(),Apttus_Billing__PeriodEndDate__c=Date.today().addDays(5),Apttus_Billing__FeeAmount__c=100);
        
        //insert bs2;
        insert bs3;
        
        Apttus_Billing__BillingSchedule__c bs4 = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__AssetLineItemId__c=alineItem4.id,Apttus_Billing__Status__c='Pending Billing',Apttus_Billing__PeriodStartDate__c=Date.Today(),Apttus_Billing__PeriodEndDate__c=Date.today().addDays(5),Apttus_Billing__FeeAmount__c=100);
        
        //insert bs2;
        insert bs4;
        
        //Set<Id> prodt = new Set<Id>();
        //prodt.add(prod);
        //prodt.add(prod1);
        Apttus_Config2__ClassificationName__c cls = new Apttus_Config2__ClassificationName__c();
        //cls.Apttus_Config2__HierarchyLabel__c='Test';
        cls.Apttus_Config2__HierarchyLabel__c='Machine';
        insert cls;
        
        Apttus_Config2__ClassificationHierarchy__c instChildOG = new Apttus_Config2__ClassificationHierarchy__c();
        instChildOG.Apttus_Config2__HierarchyId__c = cls.id;
        instChildOG.Apttus_Config2__Label__c='Payment Systems';
        instChildOG.Name='Payment Systems';
        insert instChildOG;
        Apttus_Config2__ClassificationHierarchy__c instOptionGroup = new Apttus_Config2__ClassificationHierarchy__c();
        instOptionGroup.Name = 'Machine';
        instOptionGroup.Apttus_Config2__HierarchyId__c = cls.id;
        instOptionGroup.Apttus_Config2__Label__c='Machine';
        insert instOptionGroup;
        Apttus_Config2__ProductOptionGroup__c prodgp = new Apttus_Config2__ProductOptionGroup__c();
        prodgp.Apttus_Config2__ProductId__c=prod.id;
        
        prodgp.Apttus_Config2__OptionGroupId__c = instChildOG.id;
        prodgp.Apttus_Config2__ParentOptionGroupId__c=instOptionGroup.id;
        prodgp.Apttus_Config2__Sequence__c=5;
        
        insert prodgp;
        
        Apttus_Config2__ProductOptionComponent__c opt = APTS_TestDataFactory.createProductOptionComponent(prodgp.id);
        opt.Apttus_Config2__ComponentProductId__c =prod.id;
        opt.Apttus_Config2__ParentProductId__c = null;
        opt.Apttus_Config2__ComponentProductId__c =null;
        opt.Apttus_Config2__RelationshipType__c = 'Option';
        opt.Apttus_Config2__ProductOptionGroupId__c =prodgp.id;
        insert opt; 
        
        PageReference myVfPage = Page.APTS_CustomTerminate;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('prodConfig',prodConfig.Id);
        ApexPages.currentPage().getParameters().put('ids',String.valueOf(alineItem.Id)+','+String.valueOf(alineItem.id));
        ApexPages.StandardController sc = new ApexPages.StandardController(alineItem);
        APTS_PenaltyCalculationCtrl standardPenaltyCtrl = new APTS_PenaltyCalculationCtrl(sc);
        APTS_PenaltyCalculationCtrl penaltyctrl = new APTS_PenaltyCalculationCtrl();
        penaltyctrl.calculate();
        penaltyctrl.confirm();
        penaltyctrl.cancel();
        penaltyctrl.goToCart();
        
        /*PageReference myVfPage1 = Page.APTS_AssetInstalledProducts;
        Test.setCurrentPage(myVfPage1);*/
        
        // Put Id into the current page Parameters
        //ApexPages.currentPage().getParameters().put('id',prodConfig.Id);
        /*APTS_AssetInstalledProductsController ac = new APTS_AssetInstalledProductsController();
        ac.next();
        ac.previous();
        ac.proceed();
        ac.gotocart();*/
        test.stopTest();
    }
}