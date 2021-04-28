/**************************************************************
 * @Author: Ankit Joshi
 * @Description: Test class for APTS_AgreementLIOnCounterReading
 * @Created Date: June 18, 2018
 * @Revisions:
 * 
 *************************************************************/
@isTest
public with sharing class APTS_AgreementLIOnCounterReadingTest {
   
    static testmethod void logic1(){
        TriggerSettings__c ts=APTS_TestDataFactory.CreateTriggerSettings(false,false);
        insert ts;
        
        Product2 product1 = APTS_TestDataFactory.createProduct('All-in Coverage-Draft', '12345', 'MA', 'Bundle', FALSE, FALSE);
        product1.APTS_Material_Type__c='ZCMA';
        product1.APTS_Option_Group_Indicator__c= '00';
        insert product1;
        
        Product2 planogramProduct = APTS_TestDataFactory.createProduct('Planogram Product', '12346', 'MA', 'Bundle', FALSE, FALSE);
        planogramProduct.APTS_Material_Type__c = 'ZCMA';
        planogramProduct.APTS_Option_Group_Indicator__c = '04';
        insert planogramProduct;  
        
        Product2 L3Product = APTS_TestDataFactory.createProduct('Coffee', '12347', 'MA', 'Bundle', FALSE, FALSE);
        L3Product.APTS_Material_Type__c = 'ZCBB';
        insert L3Product; 
        
        // Hot water 
        Product2 L3Product1 = APTS_TestDataFactory.createProduct('Hot water', string.valueOf(datetime.now()), 'MA', 'Bundle', FALSE, FALSE);
        L3Product1.APTS_Material_Type__c = 'ZCBB';
        insert L3Product1;
        
        Apttus_Config2__PriceList__c pricelist=APTS_TestDataFactory.createPriceList('JDEPL');
        insert pricelist;
        
        Apttus_Config2__PriceListItem__c pli = APTS_TestDataFactory.CreatePriceListIemWithOnlyPriceList(pricelist.Id,10.5,10.5,10.5);
        insert pli;
            
        Apttus_Config2__ClassificationName__c cls = APTS_TestDataFactory.createCategory();
        cls.Name='Machine';
        cls.Apttus_Config2__HierarchyLabel__c='Test';
        cls.Apttus_Config2__HierarchyLabel__c='Machine';
        insert cls;
 
         Apttus_Config2__ClassificationHierarchy__c instChildOG = APTS_TestDataFactory.createCategoryHierarchy(cls.id,'Machine');
        instChildOG.Apttus_Config2__Label__c='Menu';
        insert instChildOG;

        Apttus_Config2__ClassificationHierarchy__c instChildOG1 = APTS_TestDataFactory.createCategoryHierarchy(cls.id,'Machine');
        instChildOG1.Apttus_Config2__Label__c='Water System';
        insert instChildOG1;

        Apttus_Config2__ProductOptionGroup__c Prodoptiongroup =APTS_TestDataFactory.createProductOptionGroup(instChildOG.id, instChildOG.id);
        Prodoptiongroup.Apttus_Config2__Sequence__c=5;
        insert Prodoptiongroup;

        Apttus_Config2__ProductOptionGroup__c Prodoptiongroup1 = APTS_TestDataFactory.createProductOptionGroup(instChildOG1.id, instChildOG1.id);
        Prodoptiongroup1.Apttus_Config2__Sequence__c=5;
        insert Prodoptiongroup1;
        
        

        Apttus_Config2__ProductOptionComponent__c optiongrpcomp = APTS_TestDataFactory.createProductOptionComponent(Prodoptiongroup.id);
        optiongrpcomp.Apttus_Config2__ProductOptionGroupId__c = Prodoptiongroup.id;
        optiongrpcomp.Apttus_Config2__Sequence__c=5;
        insert optiongrpcomp;

        Apttus_Config2__ProductOptionComponent__c optiongrpcomp1 = APTS_TestDataFactory.createProductOptionComponent(Prodoptiongroup1.id);
        optiongrpcomp1.Apttus_Config2__ProductOptionGroupId__c = Prodoptiongroup1.id;
        optiongrpcomp1.Apttus_Config2__Sequence__c=5;
        insert optiongrpcomp1;
            
        Apttus_Config2__ProductConfiguration__c  proconfig= new Apttus_Config2__ProductConfiguration__c();
        insert proconfig;
       
            
        Apttus_Config2__LineItem__c li2 = APTS_TestDataFactory.createLineItem(proconfig, 
                                                                              pli.id,
                                                                              null,
                                                                              product1.Id, planogramProduct.Id, null, 
                                                                              5, 5, 5, 'Product/Service', null, 'Monthly'
                                                                              , 'Bill In Advance', null, null, null, null, null);
        
        
        li2.Apttus_Config2__ProductOptionId__c = optiongrpcomp.id;
        li2.CurrencyIsoCode = 'EUR'; 
        li2.Apttus_Config2__IsPrimaryLine__c=true;
        insert li2;
       
        
        
        Apttus_Config2__LineItem__c cofeeLineItem = APTS_TestDataFactory.createLineItem(proconfig, 
                                                                              pli.id,
                                                                              null,
                                                                              product1.Id, L3Product.Id, null, 
                                                                              6, 6, 6, 'Product/Service', null, 'Monthly'
                                                                              , 'Bill In Advance', null, null, null, null, null);

       
        Apttus_Config2__LineItem__c hotwaterLineItem = APTS_TestDataFactory.createLineItem(proconfig, 
                                                                              pli.id,
                                                                              null,
                                                                              product1.Id, L3Product1.Id, null, 
                                                                              6, 6, 6, 'Product/Service', null, 'Monthly'
                                                                              , 'Bill In Advance', null, null, null, null, null);
      
        List<APTS_CounterReadingData__c> counterDatalist = new List<APTS_CounterReadingData__c>();
        APTS_CounterReadingData__c counterData =APTS_TestDataFactory.createCounterREadingData(li2.id) ;
        counterData.APTS_LineItem__c = li2.Id;
        counterDatalist.add(counterData);

        APTS_CounterReadingData__c counterDatahw =APTS_TestDataFactory.createCounterREadingData(hotwaterLineItem.id) ;
        counterData.APTS_LineItem__c = hotwaterLineItem.Id;
        counterDatalist.add(counterDatahw);
        insert counterDatalist;
        
         Apttus__APTS_Agreement__c aptContract = APTS_TestDataFactory.createAgreement(null, pricelist.id, null,'Standard Deal') ;
         aptContract.Name = 'Agreement';
         aptContract.Apttus__Agreement_Category__c = 'Standard';
         insert aptContract;

        Apttus__AgreementLineItem__c agreementLineItem1 = APTS_TestDataFactory.createAgreementLineItem(product1.id, aptContract.id, null, pli.id);
        agreementLineItem1.Apttus_CMConfig__OptionId__c = planogramProduct.Id;
        agreementLineItem1.Apttus_CMConfig__ClassificationId__c=instChildOG.Id;
        agreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        agreementLineItem1.Apttus_CMConfig__DerivedFromId__c = li2.Id;
        agreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        agreementLineItem1.Apttus__AgreementId__c=aptContract.Id;
        agreementLineItem1.CurrencyIsoCode='EUR';
        agreementLineItem1.APTS_Option_Group_Text__c='Menu';
        agreementLineItem1.Apttus_CMConfig__PrimaryLineNumber__c=2;
        agreementLineItem1.Apttus_CMConfig__ParentBundleNumber__c = 2;
        insert agreementLineItem1;

        Apttus__AgreementLineItem__c coffeeALI = APTS_TestDataFactory.createAgreementLineItem(product1.id, aptContract.id, null,  pli.id);
        coffeeALI.Apttus_CMConfig__OptionId__c = L3Product.Id;
        coffeeALI.Apttus__Description__c = 'Coffee';
        coffeeALI.Apttus_CMConfig__DerivedFromId__c = cofeeLineItem.Id;
        coffeeALI.Apttus_CMConfig__ParentBundleNumber__c = 2;
        coffeeALI.Apttus__AgreementId__c=aptContract.Id;
        coffeeALI.APTS_Option_Group_Text__c = 'Consumption Categories';
        coffeeALI.Apttus_CMConfig__PrimaryLineNumber__c=3;
        insert coffeeALI;
        
        Apttus__AgreementLineItem__c hotwtALI = APTS_TestDataFactory.createAgreementLineItem(product1.id, aptContract.id, null,  pli.id);
        hotwtALI.Apttus_CMConfig__OptionId__c = L3Product1.Id;
        hotwtALI.Apttus__Description__c = 'Hot water';
        hotwtALI.Apttus_CMConfig__DerivedFromId__c = hotwaterLineItem.Id;
        hotwtALI.Apttus_CMConfig__ParentBundleNumber__c = 2;
        hotwtALI.Apttus__AgreementId__c=aptContract.Id;
        hotwtALI.APTS_Option_Group_Text__c = 'Consumption Categories';
        hotwtALI.Apttus_CMConfig__PrimaryLineNumber__c=3;
        insert hotwtALI;

        //Insert Agreement Product Attribute Value
        Apttus_CMConfig__AgreementProductAttributeValue__c pav =APTS_TestDataFactory.createAgreementProductAttributeValue(coffeeALI.Id);
        insert pav;
        
        Apttus_CMConfig__AgreementProductAttributeValue__c pavhw =APTS_TestDataFactory.createAgreementProductAttributeValue(hotwtALI.Id);
        insert pavhw;
        //Update ALI's product attribute value
        coffeeALI.Apttus_CMConfig__AttributeValueId__c = pav.Id;
        update coffeeALI;
        
        coffeeALI.Apttus_CMConfig__AttributeValueId__c = pavhw.Id;
        update hotwtALI;
        
        List<Apttus_CMConfig__AgreementUsagePriceTier__c> agrTierlist = new List<Apttus_CMConfig__AgreementUsagePriceTier__c>();
        //Insert Usage Tier 1
        Apttus_CMConfig__AgreementUsagePriceTier__c ut1 = APTS_TestDataFactory.createAgreementUsagePriceTier(coffeeALI.id,'Free Vend',1);
        ut1.Apttus_CMConfig__LineItemId__c=coffeeALI.id;
        agrTierlist.add(ut1);

        //Insert Usage Tier 2
        Apttus_CMConfig__AgreementUsagePriceTier__c ut2 = APTS_TestDataFactory.createAgreementUsagePriceTier(coffeeALI.id,'Paid',2);
        ut2.Apttus_CMConfig__LineItemId__c=coffeeALI.id;
        agrTierlist.add(ut2);
        insert agrTierlist;

        //insert Consumption Group Detail
        APTS_Consumption_Group_Detail__c cgd = APTS_TestDataFactory.createConsumptionGroupDetail();
        insert cgd;
        
        //insert Consumption Group Detail
        APTS_Consumption_Group_Detail__c cgdhw = APTS_TestDataFactory.createConsumptionGroupDetail();
        insert cgdhw;
        //Insert Consumption Group master
        APTS_Consumption_Group_Master__c cgm = APTS_TestDataFactory.createConsumptionGroupMaster(L3Product.Id,cgd.Id,product1.Id,planogramProduct.Id);
        insert cgm;
        
        //Insert Consumption Group master
        APTS_Consumption_Group_Master__c cgmhw1 = APTS_TestDataFactory.createConsumptionGroupMaster(L3Product1.Id,cgdhw.Id,product1.Id,planogramProduct.Id);
        insert cgmhw1;
        //Insert Consumption Group master
        APTS_Consumption_Group_Master__c cgmhw2= APTS_TestDataFactory.createConsumptionGroupMaster(L3Product1.Id,cgdhw.Id,product1.Id,planogramProduct.Id);
        insert cgmhw2;
        //Insert Consumption Group master
        APTS_Consumption_Group_Master__c cgmhw3= APTS_TestDataFactory.createConsumptionGroupMaster(L3Product1.Id,cgdhw.Id,product1.Id,planogramProduct.Id);
        insert cgmhw3;

        //Insert Recipe Master
        APTS_Recipe_Master__c rm = APTS_TestDataFactory.createRecipeMaster(product1.Id,planogramProduct.Id);
        insert rm;

        //Insert Recipe Detail
        APTS_Recipe_Details__c rd = APTS_TestDataFactory.createRecipeDetails(rm.id,cgd.Id);
        insert rd;
        
        
        //Insert Recipe Detail
        APTS_Recipe_Details__c rdh1 = APTS_TestDataFactory.createRecipeDetails(rm.id,cgdhw.Id);
        insert rdh1;
        
        //Insert Recipe Detail
        APTS_Recipe_Details__c rdh2 = APTS_TestDataFactory.createRecipeDetails(rm.id,cgdhw.Id);
        insert rdh2;
        
        //Insert Recipe Detail
        APTS_Recipe_Details__c rdh3 = APTS_TestDataFactory.createRecipeDetails(rm.id,cgdhw.Id);
        insert rdh3;
         
        map<id,Apttus__AgreementLineItem__c> mapAgreementLineItem=new map<id,Apttus__AgreementLineItem__c>();
        mapAgreementLineItem.put(agreementLineItem1.Id, agreementLineItem1);
        mapAgreementLineItem.put(coffeeALI.Id, coffeeALI);
        mapAgreementLineItem.put(hotwtALI.Id,hotwtALI);

        Test.startTest();

        //APTS_AgreementLIOnCounterReading.updateAgreementLIOnCounterReading(mapAgreementLineItem);
        Integer before = Limits.getQueueableJobs();
        APTS_AgreementLIOnCounterReading astCntReading =  new APTS_AgreementLIOnCounterReading(mapAgreementLineItem);
        ID jobId = System.enqueueJob(astCntReading); 
        Integer after = Limits.getQueueableJobs();
        

        Test.stopTest();
       //System.assertEquals(before,after-1); 
       List<Apttus_CMConfig__AgreementUsagePriceTier__c> ut = new List<Apttus_CMConfig__AgreementUsagePriceTier__c>([Select Id,Apttus_CMConfig__AdjustmentType__c from Apttus_CMConfig__AgreementUsagePriceTier__c]);
       System.assertEquals('Tier Price',ut[0].Apttus_CMConfig__AdjustmentType__c);
    }
}