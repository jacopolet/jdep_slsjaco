/**
    * Class Name : APTS_PricingDistributionBatch_Test
    * Description :  Apex Class to test APTS_PricingDistributionBatchHandler class
    * Author : Nagavi Babu
    * Date Created : 04/13/2018
    **/
    @isTest(SeeAllData = false)
    private with sharing class APTS_PricingDistributionBatch_Test{
        
        @isTest
        static void testPricingBatch(){
            
            TriggerSettings__c settings = new TriggerSettings__c();
            settings.SalesOrgDataTrigger__c = true;
            Database.insert(settings, false);
            
            APTS_ProductPricingBatchSettings__c batchSetting = new APTS_ProductPricingBatchSettings__c(SetupOwnerId=UserInfo.getOrganizationId(),APTS_Pricing_Batch_Notification_Email_ID__c='test@test.com');
            Database.insert(batchSetting, false);
            
            Apttus_Config2__PriceDimension__c dimension = new Apttus_Config2__PriceDimension__c(Name='Selling Term', Apttus_Config2__BusinessObject__c='Apttus_Config2__LineItem__c',Apttus_Config2__ContextType__c='Line Item', Apttus_Config2__Type__c='Standard', Apttus_Config2__Datasource__c='Apttus_Config2__SellingTerm__c');
            Database.insert(dimension);
            
            APTS_ProductPricingBatchSettings__c settings2=new APTS_ProductPricingBatchSettings__c();
            settings2.APTS_Selling_Term_Price_Dimension_Rec_ID__c=dimension.Id;
            Database.insert(settings2, false);
            
            List<Product2> productList = TestDataFactory.createProduct(20);
            List<Apttus_Config2__PriceList__c> priceList = TestDataFactory.createPriceList(1);
            List<APTS_Sales_Org_Data__c > salesOrgList = new List<APTS_Sales_Org_Data__c>();
            List<APTS_Pricing_Staging__c> pricingStagingList = new List<APTS_Pricing_Staging__c>();
            List<Apttus_Config2__PriceListItem__c> existingPli = new List<Apttus_Config2__PriceListItem__c>();
            List<Apttus_Config2__PriceListItem__c> existingRentalPli=new List<Apttus_Config2__PriceListItem__c>();
            List<Apttus_Config2__PriceMatrix__c> priceMatrixList=new List<Apttus_Config2__PriceMatrix__c>(); 
            List<Apttus_Config2__PriceMatrixEntry__c> pmeList = new List<Apttus_Config2__PriceMatrixEntry__c>();
            List<Apttus_Config2__PriceListItem__c> tempPli=new List<Apttus_Config2__PriceListItem__c>();           
            
            for(integer index=0; index<productList.size(); index++){
                productList[index].ProductCode = '80000' + string.ValueOf(index);
                productList[index].APTS_Sales_Organization__c = '0333';
                productList[index].APTS_Option_Group_Indicator__c = '0107';
                
            }
            Database.insert(productList);
            System.assert(productList != Null);
            
            
            for(integer index=0; index<priceList.size(); index++){
                priceList[index].APTS_SalesOrg__c = '0333';
                priceList[index].APTS_PriceList_Type__c='Direct';
            }
            Database.insert(priceList);
            System.debug('Price List:==> ' + priceList);
            for(integer index=0; index<productList.size(); index++){
                APTS_Sales_Org_Data__c salesOrg = new APTS_Sales_Org_Data__c(
                    APTS_Sales_Org_Data_Ext_ID__c = productList[index].ProductCode+'|'+'0333',
                    APTS_Sales_Org_Data_Name__c = '0333',
                    APTS_Distribution_chain_specific_materia__c = 'SAP_01',
                    APTS_Product_Code__c ='8000018',
                    APTS_Cost_Price__c='1786',
                    APTS_Price_List__c=priceList[0].Id,APTS_VAT_Indicator__c='0'
                ); 
                salesOrgList.add(salesOrg);  
                 System.debug('salesOrg' + salesOrg);      
                 System.debug('priceList[0].Id' + priceList[0].Id);      
            }
            //salesOrgList[2].APTS_Distribution_chain_specific_materia__c='';
            Database.insert(salesOrgList);
                System.debug('salesOrgList' + salesOrgList);           
            
            APTS_Product_Replacement_Codes__c replacedProd=new APTS_Product_Replacement_Codes__c();
            replacedProd.APTS_Product_Code__c=productList[13].ProductCode;
            replacedProd.APTS_Product__c=productList[13].Id;
            replacedProd.APTS_Replacement_Product_Code__c='8000018';
            replacedProd.APTS_Sales_Org__c='0333';
            insert replacedProd;
            system.debug('replacedProd'+replacedProd);
            
            productList[13].APTS_Has_Replacement__c=True;
            productList[13].APTS_Replaced_by__c='8000018';
            update productList[13];  
            System.assert(productList != Null);       
            
            for(integer index=0; index<5; index++){
                Apttus_Config2__PriceListItem__c pli=new Apttus_Config2__PriceListItem__c();
                pli.Apttus_Config2__ChargeType__c='Sales Price';
                pli.Apttus_Config2__ListPrice__c=100;
                pli.Apttus_Config2__PriceListId__c=priceList[0].Id;
                pli.Apttus_Config2__ProductId__c=productList[18].Id;
                pli.APTS_Product_Code__c=productList[18].ProductCode;
                pli.APTS_Sales_Organization__c='0333';
                pli.APTS_PriceListItemExtId__c='30000'+String.valueOf(index)+'Z000';
                pli.Apttus_Config2__Active__c = true;
                pli.Apttus_Config2__ProductId__c = productList[18].Id;
                pli.APTS_TAX_all_countries_UOM__c=0;
                pli.APTS_TAX_DK_specific_UOM__c=0;
                pli.APTS_Tax_per_UOM__c=0;
                pli.APTS_TXP_Cappuccino_Tax_Mixed__c=0;
                pli.APTS_TXP_Chocolate_Tax__c=0;
                pli.APTS_TXP_Coffee_Tax__c=0;
                pli.APTS_TXP_Disposable_Tableware__c=0;
                pli.APTS_TXP_Disposal_Fee__c=0;
                pli.APTS_TXP_Instant_Coffee_Tax__c=0;
                pli.APTS_TXP_Liquid_Coffee_Tax__c=0;
                pli.APTS_TXP_Recycle_Con_Pack_Tax__c=0;
                pli.APTS_TXP_Tea_Tax__c=0;
                pli.APTS_VAT_indicator__c=1;
                existingPli.add(pli);
                tempPli.add(pli);
                
                Apttus_Config2__PriceListItem__c pli2=new Apttus_Config2__PriceListItem__c();
                pli2.Apttus_Config2__ChargeType__c='Rental Fee';
                pli2.Apttus_Config2__ListPrice__c=150;
                pli2.Apttus_Config2__PriceListId__c=priceList[0].Id;
                pli2.Apttus_Config2__ProductId__c=productList[index].Id;
                pli2.APTS_Product_Code__c=productList[index].ProductCode;
                pli2.APTS_Sales_Organization__c='0333';
                pli2.APTS_PriceListItemExtId__c='30000'+String.valueOf(index)+'YRF0';
                pli2.APTS_Lowest_Contract_Period__c='ZCONT1';
                pli2.APTS_TAX_all_countries_UOM__c=0;
                pli2.APTS_TAX_DK_specific_UOM__c=0;
                pli2.APTS_Tax_per_UOM__c=0;
                pli2.APTS_TXP_Cappuccino_Tax_Mixed__c=0;
                pli2.APTS_TXP_Chocolate_Tax__c=0;
                pli2.APTS_TXP_Coffee_Tax__c=0;
                pli2.APTS_TXP_Disposable_Tableware__c=0;
                pli2.APTS_TXP_Disposal_Fee__c=0;
                pli2.APTS_TXP_Instant_Coffee_Tax__c=0;
                pli2.APTS_TXP_Liquid_Coffee_Tax__c=0;
                pli2.APTS_TXP_Recycle_Con_Pack_Tax__c=0;
                pli2.APTS_TXP_Tea_Tax__c=0;
                pli2.APTS_VAT_indicator__c=1;
                existingRentalPli.add(pli2);
                                
                Apttus_Config2__PriceListItem__c pli3=new Apttus_Config2__PriceListItem__c();
                pli3.Apttus_Config2__ChargeType__c='Service Fee';
                pli3.Apttus_Config2__ListPrice__c=200;
                pli3.Apttus_Config2__PriceListId__c=priceList[0].Id;
                pli3.Apttus_Config2__ProductId__c=productList[index].Id;
                pli3.APTS_Product_Code__c=productList[index].ProductCode;
                pli3.APTS_Sales_Organization__c='0333';
                pli3.APTS_PriceListItemExtId__c='30000'+String.valueOf(index)+'YSF1';
                pli3.APTS_TAX_all_countries_UOM__c=0;
                pli3.APTS_TAX_DK_specific_UOM__c=0;
                pli3.APTS_Tax_per_UOM__c=0;
                pli3.APTS_TXP_Cappuccino_Tax_Mixed__c=0;
                pli3.APTS_TXP_Chocolate_Tax__c=0;
                pli3.APTS_TXP_Coffee_Tax__c=0;
                pli3.APTS_TXP_Disposable_Tableware__c=0;
                pli3.APTS_TXP_Disposal_Fee__c=0;
                pli3.APTS_TXP_Instant_Coffee_Tax__c=0;
                pli3.APTS_TXP_Liquid_Coffee_Tax__c=0;
                pli3.APTS_TXP_Recycle_Con_Pack_Tax__c=0;
                pli3.APTS_TXP_Tea_Tax__c=0;
                pli3.APTS_VAT_indicator__c=1;
                existingPli.add(pli3);
            }
            
                Apttus_Config2__PriceListItem__c pliRep=new Apttus_Config2__PriceListItem__c();
                pliRep.Apttus_Config2__ChargeType__c='Sales Price';
                pliRep.Apttus_Config2__ListPrice__c=100;
                pliRep.Apttus_Config2__PriceListId__c=priceList[0].Id;
                pliRep.Apttus_Config2__ProductId__c=productList[13].Id;
                pliRep.APTS_Product_Code__c=productList[13].ProductCode;
                pliRep.APTS_Sales_Organization__c='0333';
                pliRep.APTS_PriceListItemExtId__c='3000013Z000';
                pliRep.APTS_TAX_all_countries_UOM__c=0;
                pliRep.APTS_TAX_DK_specific_UOM__c=0;
                pliRep.APTS_Tax_per_UOM__c=0;
                pliRep.APTS_TXP_Cappuccino_Tax_Mixed__c=0;
                pliRep.APTS_TXP_Chocolate_Tax__c=0;
                pliRep.APTS_TXP_Coffee_Tax__c=0;
                pliRep.APTS_TXP_Disposable_Tableware__c=0;
                pliRep.APTS_TXP_Disposal_Fee__c=0;
                pliRep.APTS_TXP_Instant_Coffee_Tax__c=0;
                pliRep.APTS_TXP_Liquid_Coffee_Tax__c=0;
                pliRep.APTS_TXP_Recycle_Con_Pack_Tax__c=0;
                pliRep.APTS_TXP_Tea_Tax__c=0;
                pliRep.APTS_VAT_indicator__c=1;
                existingPli.add(pliRep);
                
                Apttus_Config2__PriceListItem__c pliRep2=new Apttus_Config2__PriceListItem__c();
                pliRep2.Apttus_Config2__ChargeType__c='Rental Fee';
                pliRep2.Apttus_Config2__ListPrice__c=150;
                pliRep2.Apttus_Config2__PriceListId__c=priceList[0].Id;
                pliRep2.Apttus_Config2__ProductId__c=productList[13].Id;
                pliRep2.APTS_Product_Code__c=productList[13].ProductCode;
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
                
                Apttus_Config2__PriceListItem__c pliRep3=new Apttus_Config2__PriceListItem__c();
                pliRep3.Apttus_Config2__ChargeType__c='Service Fee';
                pliRep3.Apttus_Config2__ListPrice__c=200;
                pliRep3.Apttus_Config2__PriceListId__c=priceList[0].Id;
                pliRep3.Apttus_Config2__ProductId__c=productList[13].Id;
                pliRep3.APTS_Product_Code__c=productList[13].ProductCode;
                pliRep3.APTS_Sales_Organization__c='0333';
                pliRep3.APTS_PriceListItemExtId__c='3000013YSF1';
                pliRep3.APTS_TAX_all_countries_UOM__c=0;
                pliRep3.APTS_TAX_DK_specific_UOM__c=0;
                pliRep3.APTS_Tax_per_UOM__c=0;
                pliRep3.APTS_TXP_Cappuccino_Tax_Mixed__c=0;
                pliRep3.APTS_TXP_Chocolate_Tax__c=0;
                pliRep3.APTS_TXP_Coffee_Tax__c=0;
                pliRep3.APTS_TXP_Disposable_Tableware__c=0;
                pliRep3.APTS_TXP_Disposal_Fee__c=0;
                pliRep3.APTS_TXP_Instant_Coffee_Tax__c=0;
                pliRep3.APTS_TXP_Liquid_Coffee_Tax__c=0;
                pliRep3.APTS_TXP_Recycle_Con_Pack_Tax__c=0;
                pliRep3.APTS_TXP_Tea_Tax__c=0;
                pliRep3.APTS_VAT_indicator__c=1;
                existingPli.add(pliRep3);           
            insert existingPli;
            insert existingRentalPli;
            
            for(integer index=0; index < existingRentalPli.size()-1; index++){
                Apttus_Config2__PriceMatrix__c priceMatrix = new Apttus_Config2__PriceMatrix__c();
                priceMatrix.APTS_PriceMatrixExtId__c ='60000'+String.valueOf(index)+'|Matrix';
                priceMatrix.Apttus_Config2__Dimension1Id__c = dimension.Id;
                priceMatrix.Apttus_Config2__Dimension1ValueType__c = Label.APTS_Range;
                priceMatrix.Apttus_Config2__PriceListItemId__c = existingRentalPli[index].Id;
                priceMatrix.Apttus_Config2__Sequence__c = 1;
                priceMatrix.Apttus_Config2__StopProcessingMoreMatrices__c = false;
                priceMatrixList.add(priceMatrix);
             } 
                Apttus_Config2__PriceMatrix__c priceMatrix = new Apttus_Config2__PriceMatrix__c();
                priceMatrix.APTS_PriceMatrixExtId__c ='70000|Matrix';
                priceMatrix.Apttus_Config2__Dimension1Id__c = dimension.Id;
                priceMatrix.Apttus_Config2__Dimension1ValueType__c = Label.APTS_Range;
                priceMatrix.Apttus_Config2__PriceListItemId__c = existingRentalPli[5].Id;
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

            APTS_Pricing_Staging__c staging1 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='Z000',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = '8000018',
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000250Z000ZCONT34324432432',
                    APTS_Contract_Period__c= 'ZCONT1',
                    APTS_Calculation_Type__c='M',
                    APTS_SAP_ListPriceUnits__c=2
                );
                pricingStagingList.add(staging1);
                System.assert(staging1 != Null);
                APTS_Pricing_Staging__c staging2 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='YRF0',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c ='8000018',
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000251YRF0ZCONT22439493894',
                    APTS_Contract_Period__c= 'ZCONT5',
                    APTS_Calculation_Type__c='N',
                    APTS_SAP_ListPriceUnits__c=2
                );
                pricingStagingList.add(staging2);
                
                APTS_Pricing_Staging__c staging3 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='YRF0',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = '8000018',
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000252YRF0',
                    APTS_Contract_Period__c= 'ZCONT2',
                    APTS_Calculation_Type__c='O',
                    APTS_SAP_ListPriceUnits__c=2
                );
                pricingStagingList.add(staging3);
            for(integer index=0; index<10; index++){
                APTS_Pricing_Staging__c staging4 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='Z000',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = productList[index].ProductCode,
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000'+String.valueOf(index)+'Z000',
                    APTS_Calculation_Type__c='P',
                    APTS_SAP_ListPriceUnits__c=2
                );
                pricingStagingList.add(staging4);
            }
            for(integer prodIndex=0; prodIndex<10; prodIndex++){
                for(integer index=1; index<3; index++){
                    APTS_Pricing_Staging__c staging5 = new APTS_Pricing_Staging__c(
                        APTS_Brands__c='BABYD',
                        APTS_Condition_Type__c='YRF0',
                        APTS_Configuration_Type__c='Standalone',
                        APTS_Cost_Price_Unit__c='2',
                        APTS_Description__c='Test Description',
                        APTS_Division__c='20',
                        APTS_Effective_Date__c=System.Today(),
                        APTS_Effective_Start_Date__c=System.Today(),
                        APTS_Expiration_Date__c=System.Today()+2,
                        APTS_IsActive__c=true,
                        APTS_List_Price__c=125,
                        APTS_Material_group__c='C01040499',
                        APTS_Material_pricing_group__c='35',
                        APTS_Price_Uom__c='APH',
                        APTS_Processed__c=false,
                        APTS_Product_Family__c='Machines',
                        APTS_Product_Family2__c='Cafitesse',
                        APTS_Sales_Organization__c='0333',
                        APTS_Sales_Unit__c='GPM',
                        APTS_Standard_price__c='123',
                        APTS_Product_Code__c = productList[index].ProductCode,
                        APTS_Process_Status__c='Unmatched',
                        APTS_PLI_Unique_Identifier__c = '80000'+String.valueOf(prodIndex)+'ZCONT'+String.valueOf(index),
                        APTS_Contract_Period__c= 'ZCONT'+String.valueOf(index),
                        APTS_Calculation_Type__c='M',
                    APTS_SAP_ListPriceUnits__c=2
                    );
                    pricingStagingList.add(staging5);
                }
            }
            for(integer index=0; index<10; index++){
                APTS_Pricing_Staging__c staging6 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='YSF1',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = productList[index].ProductCode,
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000'+String.valueOf(index)+'YSF1SERVICE',
                    APTS_Contract_Period__c= 'ZCONT1',
                    APTS_Calculation_Type__c='N',
                    APTS_SAP_ListPriceUnits__c=2
                );
                pricingStagingList.add(staging6);
            }
            for(integer index=0; index<10; index++){
                APTS_Pricing_Staging__c staging7 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='YSFL',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = productList[index].ProductCode,
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000'+String.valueOf(index)+'YSFLSERVICE',
                    APTS_Calculation_Type__c='O',
                    APTS_SAP_ListPriceUnits__c=2
                );
                pricingStagingList.add(staging7);
            }
            
            for(integer index=0; index<10; index++){
                APTS_Pricing_Staging__c staging8 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='YSFC',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = productList[index].ProductCode,
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000'+String.valueOf(index)+'YSFCSERVICE',
                    APTS_Calculation_Type__c='P',
                    APTS_SAP_ListPriceUnits__c=2
                );
                pricingStagingList.add(staging8);
            }
            
            for(integer index=0; index<12; index++){
                APTS_Pricing_Staging__c staging9 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='YSFS',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = productList[index].ProductCode,
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000'+String.valueOf(index)+'YSFSSERVICE',
                    APTS_Calculation_Type__c='M',
                    APTS_SAP_ListPriceUnits__c=2
                );
                pricingStagingList.add(staging9);
            }
            APTS_Pricing_Staging__c staging10 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='YD49',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = productList[0].ProductCode,
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000'+'S0'+'YSFSSERVICE',
                    APTS_Calculation_Type__c='M',
                    APTS_SAP_ListPriceUnits__c=2
            );
            pricingStagingList.add(staging10);
            APTS_Pricing_Staging__c staging11 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='YSF1',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = '8000018',
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000'+'S0'+'YSFSSERVICE1',
                    APTS_Calculation_Type__c='M',
                    APTS_SAP_ListPriceUnits__c=2
            );
            pricingStagingList.add(staging11);
            system.debug('pricingStagingList size'+pricingStagingList.size());
            Database.insert(pricingStagingList);
            Integer getSq = APTS_PricingDistributionBatchHandler.getSequence('YSF1');
            List<Apttus_Config2__PriceListItem__c> pLIUpdateList = APTS_PricingDistributionBatchHandler.deactivatePLIs(existingPli);
            Apttus_Config2__PriceMatrixEntry__c priceMatrixEntry = APTS_PricingDistributionBatchHandler.mapPMEFields(staging1, existingPli[0], pmeList[0], priceMatrix);
            
            test.startTest();
            //APTS_PricingDistributionBatchHandler.
            APTS_PricingDistributionBatch pricingBatch = new APTS_PricingDistributionBatch();
            DataBase.executeBatch(pricingBatch, 200);
            APTS_PricingDistributionBatchHandler.createPriceMatrix(existingRentalPli);
            APTS_PricingDistributionBatchHandler.processInactiveSalesOrg(salesOrgList);
            
            Set<string> statusList=new Set<String>();
            statusList.add('Completed');
            statusList.add('Aborted');
            AsyncApexJob job=[Select Id,JobType,ApexClassId, ApexClass.Name, Status,JobItemsProcessed,TotalJobItems,
            NumberOfErrors,CompletedDate,MethodName,ExtendedStatus,ParentJobId,LastProcessed,LastProcessedOffset 
            from AsyncApexJob where Status not in : statusList];
            APTS_PricingDistributionBatchHandler.sendEmail(job);
            test.stopTest();
        }
       
        @isTest
        static void testHandler(){
            APTS_Tax_Amendment_Settings__c taxSetting = new APTS_Tax_Amendment_Settings__c(Name='0080|0',APTS_SalesOrgClassificationCombination__c='0080|0',APTS_Percentage__c=0);
            Database.insert(taxSetting);
            
            Map<String, String> errorMap = new Map<String, String>();
            List<Integer> listOfContractPeriodNum = new List<Integer>{1};
            
            Map<String, Integer> taxSettingMap = APTS_PricingDistributionBatchHandler.getTaxAmendmentValues();
            Integer smallest = APTS_PricingDistributionBatchHandler.getLowestContractPeriodNumber(listOfContractPeriodNum);
            String priceType = APTS_PricingDistributionBatchHandler.getPriceType('YSFL','M');
            String chargeType = APTS_PricingDistributionBatchHandler.getChargeType('YSF1');
            String chargeType1 = APTS_PricingDistributionBatchHandler.getChargeType('YSF1','8000018');

            String freqM = APTS_PricingDistributionBatchHandler.getFrequency('M');
            String freqN = APTS_PricingDistributionBatchHandler.getFrequency('N');
            String freqO = APTS_PricingDistributionBatchHandler.getFrequency('O');
            String freqP = APTS_PricingDistributionBatchHandler.getFrequency('P');
            String freqC = APTS_PricingDistributionBatchHandler.getFrequency('C');

            List<Database.UpsertResult> pmUpsertResultList = new List<Database.UpsertResult>();
            List<Apttus_Config2__PriceMatrix__c> priceMatrixList = new List<Apttus_Config2__PriceMatrix__c>{new Apttus_Config2__PriceMatrix__c()};
            pmUpsertResultList = Database.Upsert(priceMatrixList, false);
            Map<string,String> pMErrorMap = APTS_PricingDistributionBatchHandler.processPMUpsertResult(pmUpsertResultList, errorMap, priceMatrixList);
            
            List<Database.UpsertResult> pmeUpsertResultList = new List<Database.UpsertResult>();
            List<Apttus_Config2__PriceMatrixEntry__c> priceMatrixEntryList = new List<Apttus_Config2__PriceMatrixEntry__c>{new Apttus_Config2__PriceMatrixEntry__c()};
            pmeUpsertResultList = Database.Upsert(priceMatrixEntryList, false);
            Map<string,String> pMEErrorMap = APTS_PricingDistributionBatchHandler.processPMEUpsertResult(pmeUpsertResultList, errorMap, priceMatrixEntryList);
        }

        @isTest
        static void testPricingBatch_AdditionalChanges(){
        
            test.startTest();
            //insert customSetting
            APTS_Tax_Pricing_Mapping__c taxMapping = new APTS_Tax_Pricing_Mapping__c();
            taxMapping.name = 'YD49';
            taxMapping.APTS_UOM_Supported__c = 'APH';
            taxMapping.APTS_Tax_field_on_price_list_item__c = 'APTS_TXP_Instant_coffee_tax__c';
            insert taxMapping;
            
           /* APTS_Tax_Pricing_Mapping__c taxMapping1 = new APTS_Tax_Pricing_Mapping__c();
            taxMapping1.name = 'Z000';
            taxMapping1.APTS_UOM_Supported__c = 'APH';
            taxMapping1.APTS_Tax_field_on_price_list_item__c = 'APTS_TXP_Instant_coffee_tax__c';
            insert taxMapping1;*/
            
            //Insert pricing staging
            APTS_Pricing_Staging__c staging1 = new APTS_Pricing_Staging__c(
                    APTS_Condition_Type__c='YD49',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c = '8000018',
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000250Z000ZCONT34324432432',
                    APTS_Calculation_Type__c='M'
            );
            insert staging1;

            APTS_Pricing_Staging__c staging2 = new APTS_Pricing_Staging__c(
                    APTS_Brands__c='BABYD',
                    APTS_Condition_Type__c='Z000',
                    APTS_Configuration_Type__c='Standalone',
                    APTS_Cost_Price_Unit__c='2',
                    APTS_Description__c='Test Description',
                    APTS_Division__c='20',
                    APTS_Effective_Date__c=System.Today(),
                    APTS_Effective_Start_Date__c=System.Today(),
                    APTS_Expiration_Date__c=System.Today()+2,
                    APTS_IsActive__c=true,
                    APTS_List_Price__c=125,
                    APTS_Material_group__c='C01040499',
                    APTS_Material_pricing_group__c='35',
                    APTS_Price_Uom__c='APH',
                    APTS_Processed__c=false,
                    APTS_Product_Family__c='Machines',
                    APTS_Product_Family2__c='Cafitesse',
                    APTS_Sales_Organization__c='0333',
                    APTS_Sales_Unit__c='GPM',
                    APTS_Standard_price__c='123',
                    APTS_Product_Code__c ='8000018',
                    APTS_Process_Status__c='Unmatched',
                    APTS_PLI_Unique_Identifier__c = '80000'+'123'+'Z000',
                    APTS_Contract_Period__c= 'ZCONT1',
                    APTS_Calculation_Type__c='P'
                );
            insert staging2;
            
            //Insert price list
            Apttus_Config2__PriceList__c priceList = APTS_TestDataFactory.createPriceList('EUR Price list');
            priceList.APTS_PriceList_Type__c='Direct';
            Database.Insert(priceList, false);
            
            //insert product
            Product2 prod = APTS_TestDataFactory.createProduct('TestCoffee', '8000018', 'Coffee', 'Standalone', true, false);
            Database.Insert(prod, false);
            
            //Insert price list item
            Apttus_Config2__PriceListItem__c pricelistItem = APTS_TestDataFactory.createPriceListItem(priceList.id,prod.id);
            pricelistItem.APTS_ConditionType__c='YRF0';
            pricelistItem.Apttus_Config2__ChargeType__c=Label.APTS_Rental_Price;
            pricelistItem.APTS_Sales_Organization__c='0333';
            pricelistItem.Apttus_Config2__Description__c='Karan tax test';
            pricelistItem.APTS_Product_Code__c='8000018';
            pricelistItem.APTS_TAX_all_countries_UOM__c=0;
            pricelistItem.APTS_TAX_DK_specific_UOM__c=0;
            pricelistItem.APTS_Tax_per_UOM__c=0;
            pricelistItem.APTS_TXP_Cappuccino_Tax_Mixed__c=0;
            pricelistItem.APTS_TXP_Chocolate_Tax__c=0;
            pricelistItem.APTS_TXP_Coffee_Tax__c=0;
            PricelistItem.APTS_TXP_Disposable_Tableware__c=0;
            PricelistItem.APTS_TXP_Disposal_Fee__c=0;
            PricelistItem.APTS_TXP_Instant_Coffee_Tax__c=0;
            PricelistItem.APTS_TXP_Liquid_Coffee_Tax__c=0;
            PricelistItem.APTS_TXP_Recycle_Con_Pack_Tax__c=0;
            PricelistItem.APTS_TXP_Tea_Tax__c=0;
            PricelistItem.APTS_VAT_indicator__c=1;
            PricelistItem.APTS_VAT_percentage__c=2;
            Database.Insert(pricelistItem, false);

                APTS_Sales_Org_Data__c salesOrg = new APTS_Sales_Org_Data__c(
                APTS_Sales_Org_Data_Ext_ID__c = prod.ProductCode+'|'+'0333',
                APTS_Sales_Org_Data_Name__c = '0333',
                APTS_Distribution_chain_specific_materia__c = 'SAP_01',
                APTS_Product_Code__c ='8000018',
                APTS_Price_List__c=priceList.Id
            ); 
            Database.Insert(salesOrg, false);

           

            APTS_PricingDistributionBatch pricingBatch = new APTS_PricingDistributionBatch();
            DataBase.executeBatch(pricingBatch, 200);

            test.stopTest();
        }
    }