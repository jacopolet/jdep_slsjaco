@isTest
private with sharing class APTS_AdjustTSCoverageControllerTest
{
    private static testMethod void testAdjustCoverage(){
        test.startTest();
        PageReference pageRef = Page.APTS_AdjustTSCoverage;
        Product2 product1 = new Product2();
        product1.Name = 'ALL-IN COVERAGE';
        product1.ProductCode = '12345';
        insert product1;
        system.debug('Product ID from AdjustTSCoverage'+product1.id);
        Product2 product2 = new Product2();
        product2.Name = 'Basic Coverage';
        product2.ProductCode = '1234';
        insert product2;
        // modified by Rajesh Patel
        System.assert(product2 != Null);
        System.assertEquals(product1.Name,'ALL-IN COVERAGE');

        // APTS_AdjustTSCoverageController adjustTSCoverageController_var = new APTS_AdjustTSCoverageController(new ApexPages.StandardController(product1)); 
        //APTS_AdjustTSCoverageController.APTS_AdjustTSCoverageController();


        Apttus_Config2__PriceList__c pricelist = new Apttus_Config2__PriceList__c();
        pricelist.Name='JDEPL';
        pricelist.APTS_SalesOrg__c='Netherlands';
        insert pricelist;
        // modified by Rajesh Patel
        System.assert(pricelist != Null);

        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c =pricelist.id;
        pli.APTS_Labour_Coverage__c = 10.5;
        pli.APTS_Call_Out_Coverage__c = 10.5;
        pli.APTS_Spare_Parts_Coverage__c = 10.5;
        insert pli;
        // modified by Rajesh Patel
        System.assert(pli != Null);

        Apttus_Config2__ClassificationName__c cls = new Apttus_Config2__ClassificationName__c();
        //cls.Apttus_Config2__HierarchyLabel__c='Test';
        cls.Apttus_Config2__HierarchyLabel__c='Machine';
        insert cls;
        // modified by Rajesh Patel
        System.assert(cls != Null);

        Apttus_Config2__ClassificationHierarchy__c instChildOG = new Apttus_Config2__ClassificationHierarchy__c();
        instChildOG.Apttus_Config2__HierarchyId__c = cls.id;
        instChildOG.Apttus_Config2__Label__c='Payment Systems';
        instChildOG.Name='Payment Systems';
        insert instChildOG;
        // modified by Rajesh Patel
        System.assert(instChildOG != Null);

        Apttus_Config2__ClassificationHierarchy__c instOptionGroup = new Apttus_Config2__ClassificationHierarchy__c();
        instOptionGroup.Name = 'Machine';
        instOptionGroup.Apttus_Config2__HierarchyId__c = cls.id;
        instOptionGroup.Apttus_Config2__Label__c='Machine';
        insert instOptionGroup;

        Apttus_Config2__ProductOptionGroup__c Prodoptiongroup = new Apttus_Config2__ProductOptionGroup__c();
        Prodoptiongroup.Apttus_Config2__OptionGroupId__c = instChildOG.id;
        Prodoptiongroup.Apttus_Config2__ParentOptionGroupId__c=instOptionGroup.id;
        Prodoptiongroup.Apttus_Config2__Sequence__c=5;
        insert Prodoptiongroup;

        Apttus_Config2__ProductOptionComponent__c optiongrpcomp = new Apttus_Config2__ProductOptionComponent__c();
        optiongrpcomp.Apttus_Config2__ProductOptionGroupId__c = Prodoptiongroup.id;
        optiongrpcomp.Apttus_Config2__Sequence__c=5;
        insert optiongrpcomp;

        Apttus_Config2__ProductConfiguration__c  proconfig= new Apttus_Config2__ProductConfiguration__c();
        insert proconfig;        
        
    
        
        Apttus_Config2__LineItem__c li1 = new Apttus_Config2__LineItem__c();
        li1.Apttus_Config2__OptionId__c = product1.Id;
        li1.Apttus_Config2__ProductOptionId__c = optiongrpcomp.id;
        li1.Apttus_Config2__PriceListItemId__c = pli.id;       
        li1.Apttus_Config2__LineNumber__c = 5;
        li1.Apttus_Config2__ItemSequence__c = 5;
        li1.Apttus_Config2__ConfigurationId__c = proconfig.id;
        li1.CurrencyIsoCode = 'EUR'; 
        insert li1;
        
       Apttus_Config2__ProductAttributeValue__c pav1 = new Apttus_Config2__ProductAttributeValue__c();
       pav1.Apttus_Config2__LineItemId__c=li1.id;
        pav1.APTS_Spare_Parts_Coverage_Percent__c=70;
        pav1.APTS_Labour_Coverage_Percent__c=60;
        pav1.APTS_Call_Out_Coverage_Percent__c=80;
        insert pav1;
        
         li1.Apttus_Config2__AttributeValueId__c=pav1.id;
       // update li1;
        
        
        Apttus_Config2__LineItem__c li2 = new Apttus_Config2__LineItem__c();
        li2.Apttus_Config2__OptionId__c = product2.Id;
        li2.Apttus_Config2__ProductOptionId__c = optiongrpcomp.id;
        li2.Apttus_Config2__PriceListItemId__c = pli.id;      
        li2.Apttus_Config2__LineNumber__c = 5;
        li2.Apttus_Config2__ItemSequence__c = 5;
        li2.Apttus_Config2__ConfigurationId__c = proconfig.id;
        li2.CurrencyIsoCode = 'EUR'; 
        insert li2;
        
         Apttus_Config2__ProductAttributeValue__c pav2 = new Apttus_Config2__ProductAttributeValue__c();
        pav2.Apttus_Config2__LineItemId__c=li2.id;
        pav2.APTS_Spare_Parts_Coverage_Percent__c=70;
        pav2.APTS_Labour_Coverage_Percent__c=60;
        pav2.APTS_Call_Out_Coverage_Percent__c=80;
        insert pav2;
        
          li2.Apttus_Config2__AttributeValueId__c=pav2.id;
          //update li2;
        
       
        //Apttus_Config2__LineItemId__c=li.id;

        Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c();
        aptContract.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        aptContract.Name = 'Agreement';
        //aptContract.Apttus__Primary_Contact__c = conId;
        aptContract.Apttus__Agreement_Category__c = 'Standard';
        //aptContract.Apttus_CMConfig__PriceListId__c = priceListId;
        //aptContract.Apttus_CMConfig__PricingDate__c = System.Today();
        //aptContract.Apttus__Account__c = accountId;
        insert aptContract;

        // List<Apttus__AgreementLineItem__c> lstAgreementLineItem = new List<Apttus__AgreementLineItem__c>();
        //lstAgreementLineItem.
        //lstAgreementLineItem.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name
        
        Apttus__AgreementLineItem__c agreementLineItem1 = new Apttus__AgreementLineItem__c();
        agreementLineItem1.Apttus__ProductId__c = product1.Id;
        system.debug('Karthik'+agreementLineItem1.Apttus__ProductId__c);
        agreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        agreementLineItem1.Apttus_CMConfig__DerivedFromId__c = li1.Id;
        agreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        agreementLineItem1.Apttus__AgreementId__c = aptContract.Id;
       
        agreementLineItem1.CurrencyIsoCode = 'EUR';
        insert agreementLineItem1;

        Apttus__AgreementLineItem__c agreementLineItem2 = new Apttus__AgreementLineItem__c();
        agreementLineItem2.Apttus__ProductId__c = product2.Id;
        agreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        agreementLineItem2.Apttus_CMConfig__DerivedFromId__c = li2.Id;
        agreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        
        agreementLineItem2.Apttus__AgreementId__c=aptContract.Id;
        agreementLineItem2.CurrencyIsoCode = 'EUR';
        insert agreementLineItem2;    

        Apttus_CMConfig__AgreementProductAttributeValue__c oAGAttributeValue = new Apttus_CMConfig__AgreementProductAttributeValue__c(Apttus_CMConfig__LineItemId__c=agreementLineItem1.Id);
        //oAGAttributeValue.Apttus_CMConfig__BillingOffsetDays__c = 1;
        insert oAGAttributeValue; 
        
        Apttus_CMConfig__AgreementProductAttributeValue__c oAGAttributeValue1 = new Apttus_CMConfig__AgreementProductAttributeValue__c(Apttus_CMConfig__LineItemId__c=agreementLineItem2.Id);
        //oAGAttributeValue1.Apttus_CMConfig__BillingOffsetDays__c = 1;
        insert oAGAttributeValue1;
        
        agreementLineItem1.Apttus_CMConfig__AttributeValueId__c = oAGAttributeValue.Id;
        agreementLineItem2.Apttus_CMConfig__AttributeValueId__c = oAGAttributeValue1.Id;
        update agreementLineItem1;
        update agreementLineItem2;
        //Apttus_Config2__ProductAttributeValue__c listPAVA = new Apttus_Config2__ProductAttributeValue__c();
        /*Apttus_Config2__ProductAttributeValue__c pav1 = new Apttus_Config2__ProductAttributeValue__c();


        //Apttus_Config2__OptionId__c
        pav1.APTS_Spare_Parts_Coverage_Percent__c=70;
        pav1.APTS_Labour_Coverage_Percent__c=60;
        pav1.APTS_Call_Out_Coverage_Percent__c=80;

        insert pav1;

        Apttus_Config2__ProductAttributeValue__c pav2 = new Apttus_Config2__ProductAttributeValue__c();


        //Apttus_Config2__OptionId__c
        pav2.APTS_Spare_Parts_Coverage_Percent__c=70;
        pav2.APTS_Labour_Coverage_Percent__c=60;
        pav2.APTS_Call_Out_Coverage_Percent__c=80;

        insert pav2;
        */  



        // product.Family = productFamily;
        // product.IsActive = true;
        // product.Apttus_Config2__ConfigurationType__c = 'Standalone';

        //Test.setCurrentPage(pageRef);
        //pageRef.getParameters().put('id',agreementLineItem1.id);        
        
        ApexPages.Currentpage().getParameters().put('id',aptContract.id);
        //apexPages.Currentpage().getParameters().put('Id',agreementLineItem2.id);
        // ApexPages.StandardController sc = new ApexPages.standardController();
        System.debug('Agreement Li 1: ==' + agreementLineItem1);
        APTS_AdjustTSCoverageController  controller = new APTS_AdjustTSCoverageController();
        controller.save();
        test.stopTest();
    }
}