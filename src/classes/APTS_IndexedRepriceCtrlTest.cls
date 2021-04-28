@isTest
private with sharing class APTS_IndexedRepriceCtrlTest
{
private static testMethod void test_logic1() {

 test.startTest();
  
              List<Apttus_Config2__PriceListItem__c> existingPli = new List<Apttus_Config2__PriceListItem__c>();
                          List<Apttus_Config2__PriceListItem__c> existingRentalPli=new List<Apttus_Config2__PriceListItem__c>();
                          List<Apttus_Config2__PriceMatrix__c> priceMatrixList=new List<Apttus_Config2__PriceMatrix__c>(); 
            List<Apttus_Config2__PriceMatrixEntry__c> pmeList = new List<Apttus_Config2__PriceMatrixEntry__c>();
            Set<Id> configId1 =new Set<Id>();


   Account acc = new Account();
        acc.name = 'Testreclog';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Valid').getRecordTypeId();
        acc.Phone = '+31123456789';
        acc.Account_Tier__c = 'Platinum';
        
    insert acc;
    // modified by Rajesh Patel
    System.assert(acc != Null);
    System.assertEquals(acc.name,'Testreclog');
    

    Contact con = new Contact();
        con.AccountId = acc.Id;
        con.MobilePhone = '+31123456789';
        con.LastName = acc.Name; 
        con.Email = 'test@qp1.org';
        insert con;
        // modified by Rajesh Patel
        System.assert(con != Null); 

            Product2 product1 = new Product2();
            product1.Name = 'Testlogic';
            product1.ProductCode = '12345';
            product1.family='SAP_05';
            insert product1;
            // modified by Rajesh Patel
            System.assert(product1 != Null); 
            
            Apttus_Config2__PriceList__c pricelist = new Apttus_Config2__PriceList__c();
            pricelist.APTS_SalesOrg__c='123456';
            pricelist.Name='JDEPL';
            insert pricelist;
            // modified by Rajesh Patel
            System.assert(pricelist != Null);
            
            Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
            pli.Apttus_Config2__PriceListId__c =pricelist.id;
            pli.APTS_Labour_Coverage__c = 10.5;
            pli.APTS_Call_Out_Coverage__c = 10.5;
            pli.APTS_Spare_Parts_Coverage__c = 10.5;
            pli.APTS_VAT_percentage__c=20;
            pli.APTS_VAT_indicator__c=3;
            pli.APTS_Tax_per_UOM__c=10;
            existingPli.add(pli);
            
            Apttus_Config2__PriceListItem__c pli1 = new Apttus_Config2__PriceListItem__c();
            pli1.Apttus_Config2__PriceListId__c =pricelist.id;
            pli1.Apttus_Config2__ListPrice__c=200;
            pli1.Apttus_Config2__ChargeType__c='Sales Price';
            pli1.APTS_Labour_Coverage__c = 10.5;
            pli1.APTS_Call_Out_Coverage__c = 10.5;
            pli1.APTS_Spare_Parts_Coverage__c = 10.5;
            pli1.APTS_VAT_percentage__c=20;
            pli1.APTS_VAT_indicator__c=3;
            pli1.APTS_Tax_per_UOM__c=10;
            existingPli.add(pli1);
            insert existingPli;
            
            Apttus_Config2__PriceListItem__c pliRep2=new Apttus_Config2__PriceListItem__c();
                pliRep2.Apttus_Config2__ChargeType__c='Rental Fee';
                pliRep2.Apttus_Config2__ListPrice__c=150;
                pliRep2.Apttus_Config2__PriceListId__c=priceList.Id;
                pliRep2.Apttus_Config2__ProductId__c=product1.Id;
                pliRep2.APTS_Product_Code__c=product1.ProductCode;
                pliRep2.APTS_Sales_Organization__c='0333';
                pliRep2.APTS_PriceListItemExtId__c='3000013YRF0';
                pliRep2.APTS_Lowest_Contract_Period__c='ZCONT1';
                pliRep2.APTS_TAX_all_countries_UOM__c=0;
                pliRep2.APTS_TAX_DK_specific_UOM__c=0;
                pliRep2.APTS_Tax_per_UOM__c=0;
                pliRep2.APTS_TXP_Cappuccino_Tax_Mixed__c=0;
                pliRep2.APTS_TXP_Chocolate_Tax__c=0;
                pliRep2.APTS_TXP_Coffee_Tax__c=0;
                pliRep2.APTS_TXP_Disposable_Tableware__c=0;
                pliRep2.APTS_TXP_Disposal_Fee__c=0;
                pliRep2.APTS_TXP_Instant_Coffee_Tax__c=0;
                pliRep2.APTS_TXP_Liquid_Coffee_Tax__c=0;
                pliRep2.APTS_TXP_Recycle_Con_Pack_Tax__c=0;
                pliRep2.APTS_TXP_Tea_Tax__c=0;
                pliRep2.APTS_VAT_indicator__c=1;
                existingRentalPli.add(pliRep2);
                insert existingRentalPli;
            
            Apttus_Config2__PriceDimension__c dimension = new Apttus_Config2__PriceDimension__c(Name='Selling Term', Apttus_Config2__BusinessObject__c='Apttus_Config2__LineItem__c',Apttus_Config2__ContextType__c='Line Item', Apttus_Config2__Type__c='Standard', Apttus_Config2__Datasource__c='Apttus_Config2__SellingTerm__c');
            Database.insert(dimension);
            
             Apttus_Config2__PriceMatrix__c priceMatrix = new Apttus_Config2__PriceMatrix__c();
                priceMatrix.APTS_PriceMatrixExtId__c ='70000|Matrix';
                priceMatrix.Apttus_Config2__Dimension1Id__c = dimension.Id;
                priceMatrix.Apttus_Config2__Dimension1ValueType__c = Label.APTS_Range;
                priceMatrix.Apttus_Config2__PriceListItemId__c = existingRentalPli[0].Id;
                priceMatrix.Apttus_Config2__Sequence__c = 1;
                priceMatrix.Apttus_Config2__StopProcessingMoreMatrices__c = false;
                priceMatrixList.add(priceMatrix);
             insert priceMatrixList;
             
              for(integer index=0; index < priceMatrixList.size(); index++){
                  for(integer matIndex=1; matIndex<=3; matIndex++){
                   Apttus_Config2__PriceMatrixEntry__c pme = new Apttus_Config2__PriceMatrixEntry__c();
                   pme.Apttus_Config2__AdjustmentAmount__c = 100;
                   pme.Apttus_Config2__AdjustmentType__c = 'List Price Override';
                   pme.APTS_PriceMatrixEntryExtId__c = '60000'+String.valueOf(index)+'ZCONT'+String.valueOf(matIndex);
                   pme.Apttus_Config2__Dimension1Value__c = 'Test';
                   pme.Apttus_Config2__Sequence__c =1;
                   pme.Apttus_Config2__PriceMatrixId__c = priceMatrixList[index].Id;
                   pmeList.add(pme);
                  }
             }
             insert pmeList;
            
            
            Apttus_Config2__ClassificationName__c cls = new Apttus_Config2__ClassificationName__c();
            cls.Name='Machine';
            //cls.Apttus_Config2__HierarchyLabel__c='Test';
            cls.Apttus_Config2__HierarchyLabel__c='Machine';
            insert cls;
            
            Apttus_Config2__ClassificationHierarchy__c instChildOG = new Apttus_Config2__ClassificationHierarchy__c();
            instChildOG.Apttus_Config2__HierarchyId__c = cls.id;
            instChildOG.Apttus_Config2__Label__c='Water System';
            instChildOG.Name='Machine';
            insert instChildOG;
            
            Apttus_Config2__ProductOptionGroup__c Prodoptiongroup = new Apttus_Config2__ProductOptionGroup__c();
            Prodoptiongroup.Apttus_Config2__OptionGroupId__c = instChildOG.id;
            Prodoptiongroup.Apttus_Config2__ParentOptionGroupId__c=instChildOG.id;
            Prodoptiongroup.Apttus_Config2__Sequence__c=5;
            insert Prodoptiongroup;
            
            Apttus_Config2__ProductOptionComponent__c optiongrpcomp = new Apttus_Config2__ProductOptionComponent__c();
            optiongrpcomp.Apttus_Config2__ProductOptionGroupId__c = Prodoptiongroup.id;
            optiongrpcomp.Apttus_Config2__Sequence__c=5;
            insert optiongrpcomp;
            String configId;
      
            Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c();
            aptContract.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
            aptContract.Name = 'Agreement';
            aptContract.Apttus__Account__c=acc.id;
            aptContract.Apttus__Primary_Contact__c=con.id;
            aptContract.Apttus_CMConfig__PriceListId__c=pricelist.id;
            aptContract.Apttus__Agreement_Category__c = 'Standard';
            insert aptContract;

            Apttus_Config2__ProductConfiguration__c  proconfig= new Apttus_Config2__ProductConfiguration__c();
        
            proconfig.Apttus_CMConfig__AgreementId__c=aptContract.id;
            insert proconfig;
            
            for(Apttus_Config2__ProductConfiguration__c pc:[select id from Apttus_Config2__ProductConfiguration__c where id =:proconfig.Id]){
            configId1.add(pc.id);
            }
            
            /*
            Apttus_Config2__LineItem__c li2 = new Apttus_Config2__LineItem__c();
            li2.Apttus_Config2__OptionId__c = product1.Id;
            li2.Apttus_Config2__ProductOptionId__c = optiongrpcomp.id;
            li2.Apttus_Config2__PriceListItemId__c = pli.id;
            //li2.Apttus_Config2__AttributeValueId__c=pav2.id;
            li2.Apttus_Config2__LineNumber__c = 5;
            li2.Apttus_Config2__ItemSequence__c = 5;
            li2.Apttus_Config2__ConfigurationId__c = proconfig.id;
            li2.CurrencyIsoCode = 'EUR'; 
            li2.Apttus_Config2__PriceUom__c='Piece';
            li2.Apttus_Config2__SellingUom__c='Box';
            li2.Apttus_Config2__IsPrimaryLine__c=true;
            li2.Apttus_Config2__LineType__c='Product/Service';
            li2.Apttus_Config2__Quantity__c=1234;
            li2.APTS_Net_Price_Inc_taxes__c=1111;
            li2.APTS_VAT__c=1111;
            li2.APTS_Tax__c=2000;
           li2.Apttus_Config2__PricingStatus__c='Pending';*/
            Apttus_Config2__LineItem__c li2 = APTS_TestDataFactory.createLineItem(proconfig,pli.id , NULL, product1.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, NULL,NULL, 'One Time', 'Per Unit', 'Each', 100, 2);
            li2.CurrencyIsoCode = 'EUR'; 
            li2.Apttus_Config2__PriceUom__c='SAP_PCE';
            li2.Apttus_Config2__SellingUom__c='SAP_BX';
            li2.Apttus_Config2__NetPrice__c=200;
            insert li2;

            //Inserting dummy option
            Apttus_Config2__LineItem__c li3 = APTS_TestDataFactory.createLineItem(proconfig,pli.id , NULL, product1.Id, product1.Id, NULL, 1, 1, 2, 'Product/Service', NULL, NULL,NULL, 'One Time', 'Per Unit', 'Each', 100, 2);
            li3.CurrencyIsoCode = 'EUR'; 
            li3.Apttus_Config2__PriceUom__c='SAP_PCE';
            li3.Apttus_Config2__SellingUom__c='SAP_BX';
            li3.Apttus_Config2__NetPrice__c=200;
            li3.Apttus_Config2__StartDate__c=system.today().addYears(-2);
            li3.Apttus_Config2__EndDate__c=system.today().addYears(4);
            li3.Apttus_Config2__SellingTerm__c=APTS_IndexedRepriceCtrl.calculateSellingTerm(system.today(),System.today().addYears(1));
            insert li3;
            ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(proconfig);
            ApexPages.Currentpage().getParameters().put('id',proconfig.id);
            APTS_IndexedRepriceCtrl ec = new APTS_IndexedRepriceCtrl(sc);
            //APTS_CalculateTaxesCtrl ec1 = new APTS_CalculateTaxesCtrl();
            ec.GoBacktoCart();          
            ec.IndexedReprice();
            ec.IndexedRepriceapi(configId1);
            ec.IndexedRepriceAction();         
   test.stopTest();
}

}