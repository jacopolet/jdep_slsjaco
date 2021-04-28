@isTest
private class APTS_ListPriceExtractionCtrlTest{
    @isTest
    static void priceListBased(){

        test.startTest();
        //Account creation
        Account acc = APTS_TestUtils.createaccount();
        insert Acc;
        System.assert(acc != Null);
        System.assertEquals(acc.name,'Test account');
        
        Opportunity opp = APTS_TestUtils.createOpportunity(Acc.id);
        insert opp;
        System.assert(opp != Null);
        Contact con= APTS_TestUtils.createContact();
        insert con;
        System.assert(con != Null);
      
        
        //Price list creation
        Apttus_Config2__PriceList__c pricelist = new Apttus_Config2__PriceList__c();
        pricelist.APTS_SalesOrg__c='123456';
        pricelist.Name='JDEPL';
        pricelist.Apttus_Config2__Active__c = true;
        insert pricelist;
       /*********************PLI 1 Data******************************/
        //create product
        Product2 testProduct = APTS_TestDataFactory.createProduct('Test Product','123','SAP_04','Standalone',false,false);
        testProduct.APTS_Sales_Catalog__c='040202';
        testProduct.IsActive = true;
        insert testProduct;
        System.assertEquals(testProduct.APTS_Sales_Catalog__c,'040202');
        System.assertEquals(testProduct.Family,'SAP_04');

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct.id);
        testPLI.Apttus_Config2__Active__c = true;
        insert testPLI;

        //create category
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        category.name = 'Machines';
        insert category;

        //create category hierarchy 
        Apttus_Config2__ClassificationHierarchy__c subCategory = APTS_TestDataFactory.createCategoryHierarchy(category.id,'sub category | sub sub category');
        subCategory.APTS_CategoryHierarchyOfferingExtId__c ='040202';
        subCategory.name='Machines Pads|Gevalia';
        insert subCategory;

        /*********************PLI 2 Data******************************/
       //create product
        Product2 testProduct1 = APTS_TestDataFactory.createProduct('Test Product 1','123','SAP_04','Standalone',false,false);
        testProduct1.APTS_Sales_Catalog__c='040303';
        testProduct1.IsActive = true;
        insert testProduct1;

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI2 = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct1.id);
        testPLI2.Apttus_Config2__ChargeType__c = 'Rental Price';
        testPLI2.Apttus_Config2__Active__c = true;
        insert testPLI2;
        /*
        //create category
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        insert category;

        //create category hierarchy 
        Apttus_Config2__ClassificationHierarchy__c subCategory = APTS_TestDataFactory.createCategoryHierarchy(category.id,'sub category | sub sub category');
        subCategory.APTS_CategoryHierarchyOfferingExtId__c ='020202';
        insert subCategory;
        */

        /*********************PLI 3 Data******************************/
        //create product
        Product2 testProduct2 = APTS_TestDataFactory.createProduct('Test Product 2','123','SAP_04','Standalone',false,false);
        testProduct2.APTS_Sales_Catalog__c='040202';
        testProduct2.IsActive = true;
        insert testProduct2;

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI3 = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct2.id);
        testPLI3.Apttus_Config2__Active__c = true;
        insert testPLI3;
        
        Apttus_Proposal__Proposal__c quote = APTS_TestUtils.getQuoteProposal(Acc.id,opp.Id,'Proposal','Test',priceList.id);
        insert quote;
            
        Apttus_Config2__ProductConfiguration__c config = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=quote.id,Apttus_Config2__PriceListId__c=priceList.id);
        insert config;
        
        Apttus_Config2__LineItem__c lineItem = APTS_TestUtils.getConfigLineItem(config.id, null, 1, true, 2, '', testProduct2.id, false, null,testProduct2.id, null, '', 2.3, false, '', 1, priceList.id, testPLI3.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
        insert lineItem;
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(con.Id,quote.Id, priceList.Id, Acc.Id);
        insert agreement;
        
        List<Apttus__AgreementLineItem__c> agreementLineItems = APTS_TestUtils.createAgreementLineItem(testProduct2.Id, agreement.Id, Acc.Id, lineItem, testPLI3.Id,subCategory.Id);
        insert agreementLineItems;
        
        Apttus_Config2__AdjustmentLineItem__c adjline = APTS_TestUtils.createadjustmentlineitems(lineItem.id);
        insert adjline;
        
        Apttus_CMConfig__AgreementAdjustmentLineItem__c  agradjline= APTS_TestUtils.createagrementadjustmentlineitem(agreementLineItems[0].id);
        insert agradjline;
        
        APTS_Contract_Entitlement_Repository__c cerrec = APTS_TestUtils.createCerrecords(agradjline.id,agreementLineItems[0].id,testProduct2.id); 
        insert cerrec;      
        
         APTS_Contract_Entitlement_Repository__c cer1 = new APTS_Contract_Entitlement_Repository__c(APTS_Product__c=testProduct1.id,APTS_Agreement_Line_Item__c=agreementLineItems[0].id,APTS_Agreement_Type__c='Standard Deal',APTS_Sold_to_Party__c=acc.id);
         cer1.APTS_Type__c ='PPR';
         cer1.APTS_Is_Pending__c=false;
         insert cer1;  
        
        //Call class logic
        ApexPages.Currentpage().getParameters().put('pliid',pricelist.id);
        ApexPages.Currentpage().getParameters().put('selectedCatgsXLS','Machines');

        APTS_ListPriceExtractionCtrl listPriceExtObj = new APTS_ListPriceExtractionCtrl();
        listPriceExtObj.GroupByCategory =true;
        listPriceExtObj.selectedCatgs = 'Machines';
       // listPriceExtObj.selectedCatgs = 'ABC';
        List<string> stringList = new List<string>{'ABC'};
        //listPriceExtObj.catselected = stringList;
        //listPriceExtObj.priceListDetails = pricelist;
        listPriceExtObj.IncludeVat =true;
        listPriceExtObj.IncludeTax = true;
        listPriceExtObj.loadProductsList();
        //listPriceExtObj.getcategories();
        APTS_ListPriceExtractionCtrl.getAllPicklistValues();
        listPriceExtObj.getcerforplis(new Set<Id>{pricelist.id});
        PageReference pg = listPriceExtObj.viewListOfPriceListItems();
        PageReference pg1 = listPriceExtObj.previousActionPage();
        listPriceExtObj.previous();
        listPriceExtObj.next();
        listPriceExtObj.first();
        listPriceExtObj.last();
        Boolean hasNext = listPriceExtObj.hasNext;
        Boolean hasPrevious = listPriceExtObj.hasPrevious;
        Integer pageNo = listPriceExtObj.pageNumber;
        Integer totalPages = listPriceExtObj.totalPages;
        List<SelectOption> optionList = listPriceExtObj.getuomValues();
        //PageReference pg2 = listPriceExtObj.previousPage();
        //listPriceExtObj.downloadAsPDF();
        //listPriceExtObj.exportAsExcel();
        //listPriceExtObj.exportAsCSV();
        PageReference pg4 = listPriceExtObj.CancelPage();
        Apttus_Config2__PriceListItem__c pli =[SELECT Id 
                                                FROM Apttus_Config2__PriceListItem__c 
                                                WHERE Id =: testPLI.Id  AND 
                                                Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true AND  
                                                Apttus_Config2__Active__c = true AND 
                                                Apttus_Config2__ProductId__r.Family =:'SAP_04' AND                                                 
                                                Apttus_Config2__ProductId__r.IsActive = true];
        system.assertEquals(pli.Id, testPLI.Id);
        //APTS_ListPriceExtractionPDF pdfClass = new APTS_ListPriceExtractionPDF();
        //pdfClass.loadProductsList();
        APTS_ListPriceExtractionCtrl.ListPriceExtractionWrapper pt = new APTS_ListPriceExtractionCtrl.ListPriceExtractionWrapper('mycatr',testPLI,'testuom',10.0,'Monthly','SAP_BX',100,'100','productname','100','optiongroupname', 'productName');
        test.stopTest();
    }
    
    @isTest
    static void accountBased(){

        test.startTest();
        //Account creation
        Account acc = APTS_TestUtils.createaccount();
        insert Acc;
        System.assert(acc != Null);
        System.assertEquals(acc.name,'Test account');
        
        Opportunity opp = APTS_TestUtils.createOpportunity(Acc.id);
        insert opp;
        System.assert(opp != Null);
        Contact con= APTS_TestUtils.createContact();
        insert con;
        System.assert(con != Null);
      
        
        //Price list creation
        Apttus_Config2__PriceList__c pricelist = new Apttus_Config2__PriceList__c();
        pricelist.APTS_SalesOrg__c='123456';
        pricelist.Name='JDEPL';
        priceList.APTS_Region__c='SAP_0111';
        insert pricelist;
       /*********************PLI 1 Data******************************/
        //create product
        Product2 testProduct = APTS_TestDataFactory.createProduct('Test Product','123','SAP_04','Standalone',false,false);
        testProduct.APTS_Sales_Catalog__c='040202';
        insert testProduct;
        System.assertEquals(testProduct.APTS_Sales_Catalog__c,'040202');

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct.id);
        insert testPLI;

        //create category
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        category.name = 'Machines';
        insert category;

        //create category hierarchy 
        Apttus_Config2__ClassificationHierarchy__c subCategory = APTS_TestDataFactory.createCategoryHierarchy(category.id,'sub category | sub sub category');
        subCategory.APTS_CategoryHierarchyOfferingExtId__c ='040202';
        subCategory.name='Machines Pads|Gevalia';
        insert subCategory;

        /*********************PLI 2 Data******************************/
        //create product
        Product2 testProduct1 = APTS_TestDataFactory.createProduct('Test Product 1','123','SAP_03','Standalone',false,false);
        testProduct1.APTS_Sales_Catalog__c='030303';
        insert testProduct1;

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI2 = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct1.id);
        insert testPLI2;
        /*
        //create category
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        insert category;

        //create category hierarchy 
        Apttus_Config2__ClassificationHierarchy__c subCategory = APTS_TestDataFactory.createCategoryHierarchy(category.id,'sub category | sub sub category');
        subCategory.APTS_CategoryHierarchyOfferingExtId__c ='020202';
        insert subCategory;
        */

        /*********************PLI 3 Data******************************/
        //create product
        List<Product2> productList = new List<Product2>(); 
        for(Integer i=0;i<Integer.valueof(System.label.APTS_List_Price_Extraction_Page_Size);i++){
            Product2 testProduct2 = APTS_TestDataFactory.createProduct('Test Product'+i,'123'+i,'SAP_04','Standalone',false,false);
            testProduct2.APTS_Sales_Catalog__c='040202';
            productList.add(testProduct2);
        }
        insert productList;

        //Create Price list Item
        List<Apttus_Config2__PriceListItem__c> plitList = new List<Apttus_Config2__PriceListItem__c>(); 
        for(Integer i=0;i<Integer.valueof(System.label.APTS_List_Price_Extraction_Page_Size);i++){
            Apttus_Config2__PriceListItem__c testPLI3 = APTS_TestDataFactory.createPriceListItem(pricelist.id,productList[i].id);
            testPLI3.Apttus_Config2__PriceUom__c='SAP_PCE';
            testPLI3.APTS_Default_Selling_Uom__c='SAP_BX';
            plitList.add(testPLI3);
        }
        insert plitList;
        
        Apttus_Proposal__Proposal__c quote = APTS_TestUtils.getQuoteProposal(Acc.id,opp.Id,'Proposal','Test',priceList.id);
        insert quote;
            
        Apttus_Config2__ProductConfiguration__c config = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=quote.id,Apttus_Config2__PriceListId__c=priceList.id);
        insert config;
        
        Apttus_Config2__LineItem__c lineItem = APTS_TestUtils.getConfigLineItem(config.id, null, 1, true, 2, '', productList[0].id, false, null,productList[0].id, null, '', 2.3, false, '', 1, priceList.id, plitList[0].Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
        insert lineItem;
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(con.Id,quote.Id, priceList.Id, Acc.Id);
        insert agreement;
        
        List<Apttus__AgreementLineItem__c> agreementLineItems = APTS_TestUtils.createAgreementLineItem(productList[0].Id, agreement.Id, Acc.Id, lineItem, plitList[0].Id,subCategory.Id);
        insert agreementLineItems;
        
        Apttus_Config2__AdjustmentLineItem__c adjline = APTS_TestUtils.createadjustmentlineitems(lineItem.id);
        insert adjline;
        
        Apttus_CMConfig__AgreementAdjustmentLineItem__c  agradjline= APTS_TestUtils.createagrementadjustmentlineitem(agreementLineItems[0].id);
        insert agradjline;
        
        APTS_Contract_Entitlement_Repository__c cerrec = APTS_TestUtils.createCerrecords(agradjline.id,agreementLineItems[0].id,productList[0].id); 
        insert cerrec;      
        
        APTS_Contract_Entitlement_Repository__c cer1 = new APTS_Contract_Entitlement_Repository__c(APTS_Product__c=testProduct1.id,APTS_Agreement_Line_Item__c=agreementLineItems[0].id,APTS_Agreement_Type__c='Standard Deal',APTS_Sold_to_Party__c=acc.id);
        cer1.APTS_Type__c ='PPR';
        cer1.APTS_Is_Pending__c=false;
        insert cer1;  


        Apttus_Config2__FrequencyConversionRate__c fre = new Apttus_Config2__FrequencyConversionRate__c();
        fre.Apttus_Config2__FromUom__c ='SAP_PCE';
        fre.Apttus_Config2__ToUom__c  ='SAP_BX';
        fre.Apttus_Config2__ProductId__c = productList[0].Id;
        fre.APTS_ProductCode__c='1230';
        fre.Apttus_Config2__ConversionFactor__c=1000;
        insert fre;
        
        //
        ApexPages.Currentpage().getParameters().put('pliid',pricelist.id);
        ApexPages.Currentpage().getParameters().put('id',acc.id);
        ApexPages.Currentpage().getParameters().put('selectedCatgsXLS','Machines');
        APTS_ListPriceExtractionCtrl listPriceExtObj1 = new APTS_ListPriceExtractionCtrl();
        listPriceExtObj1.GroupByCategory =true;
        listPriceExtObj1.IncludeVat =true;
        listPriceExtObj1.IncludeTax = true;
        listPriceExtObj1.selectedCatgs = 'Machines';
        //listPriceExtObj1.includeVatPdf = 'true';
        //listPriceExtObj1.includeTaxPdf = 'true';
        //listPriceExtObj1.isExportAsXls = 'true';
        //listPriceExtObj1.isExportAsXls = 'true';
        listPriceExtObj1.userDefinedUOM = 'SAP_BX';
        //listPriceExtObj1.priceListDetails = pricelist;
        //listPriceExtObj1.groupByCategoryPdf = 'true';
        listPriceExtObj1.loadProductsList();
        //listPriceExtObj1.getcategories();
        APTS_ListPriceExtractionCtrl.getAllPicklistValues();
        listPriceExtObj1.getcerforplis(new Set<Id>{pricelist.id});
        APTS_ListPriceExtractionCtrl.ListPriceExtractionWrapper wrap;
        PageReference pag = listPriceExtObj1.viewListOfPriceListItems();
        PageReference pag1 = listPriceExtObj1.previousActionPage();
        //PageReference pag2 = listPriceExtObj.previousPage();
        listPriceExtObj1.downloadAsPDF();
        PageReference pag4 = listPriceExtObj1.cancelPage();
        listPriceExtObj1.exportAsExcel();
        listPriceExtObj1.exportAsCSV();

        APTS_ListPriceExtractionCtrl.compareListPriceExtractionWrapper pt1 = new APTS_ListPriceExtractionCtrl.compareListPriceExtractionWrapper('mycatr',testPLI,'testuom',10.0,10.0,'SAP_BX',100,'100','productname','100','optiongroupname', 'productName');
        listPriceExtObj1.previous();
        listPriceExtObj1.next();
        listPriceExtObj1.first();
        listPriceExtObj1.last();
        Boolean hasNext = listPriceExtObj1.hasNext;
        Boolean hasPrevious = listPriceExtObj1.hasPrevious;
        Integer pageNo = listPriceExtObj1.pageNumber;
        Integer totalPages = listPriceExtObj1.totalPages;
        List<SelectOption> optionList = listPriceExtObj1.getuomValues();

        APTS_ListPriceExtractionPDF pdfClass = new APTS_ListPriceExtractionPDF();
        pdfClass.GroupByCategory =true;
        pdfClass.IncludeVat =true;
        pdfClass.IncludeTax = true;
        //pdfClass.selectedCatgs = 'Machines';
        pdfClass.includeVatPdf = 'true';
        pdfClass.includeTaxPdf = 'true';
        pdfClass.isExportAsXls = 'true';
        pdfClass.isExportAsXls = 'true';
        pdfClass.userDefinedUOM = 'SAP_BX';
        pdfClass.priceListDetails = pricelist;
        pdfClass.groupByCategoryPdf = 'true';
        pdfClass.loadProductsList();

        
        test.stopTest();
    }

    @isTest
    static void priceListBasedOptionGroup(){

        test.startTest();
        //Account creation
        Account acc = APTS_TestUtils.createaccount();
        insert Acc;
        System.assert(acc != Null);
        System.assertEquals(acc.name,'Test account');
        
        Opportunity opp = APTS_TestUtils.createOpportunity(Acc.id);
        insert opp;
        System.assert(opp != Null);
        Contact con= APTS_TestUtils.createContact();
        insert con;
        System.assert(con != Null);
      
        
        //Price list creation
        Apttus_Config2__PriceList__c pricelist = new Apttus_Config2__PriceList__c();
        pricelist.APTS_SalesOrg__c='123456';
        pricelist.Name='JDEPL';
        priceList.Apttus_Config2__Active__c = true;

        insert pricelist;
       /*********************PLI 1 Data******************************/
        //create product
        Product2 testProduct = APTS_TestDataFactory.createProduct('Test Product','123','SAP_04','Standalone',false,false);
        testProduct.APTS_Sales_Catalog__c='040202';
        testProduct.IsActive = true;
        insert testProduct;
        System.assertEquals(testProduct.APTS_Sales_Catalog__c,'040202');

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct.id);
        insert testPLI;

        //create category
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        category.name = 'Machines';
        insert category;

        //create category hierarchy 
        Apttus_Config2__ClassificationHierarchy__c subCategory = APTS_TestDataFactory.createCategoryHierarchy(category.id,'sub category | sub sub category');
        subCategory.APTS_CategoryHierarchyOfferingExtId__c ='040202';
        subCategory.name='Machines Pads|Gevalia';
        insert subCategory;

        /*********************PLI 2 Data******************************/
        //create product
        Product2 testProduct1 = APTS_TestDataFactory.createProduct('Test Product 1','123','SAP_04','Standalone',false,false);
        testProduct1.APTS_Sales_Catalog__c='040303';
        testProduct1.IsActive = true;
        insert testProduct1;

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI2 = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct1.id);
        testPLI2.Apttus_Config2__ChargeType__c = 'Rental Price';
        insert testPLI2;
        /*
        //create category
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        insert category;

        //create category hierarchy 
        Apttus_Config2__ClassificationHierarchy__c subCategory = APTS_TestDataFactory.createCategoryHierarchy(category.id,'sub category | sub sub category');
        subCategory.APTS_CategoryHierarchyOfferingExtId__c ='020202';
        insert subCategory;
        */

        /*********************PLI 3 Data******************************/
        //create product
        Product2 testProduct2 = APTS_TestDataFactory.createProduct('Test Product 2','123','SAP_04','Standalone',false,false);
        testProduct2.APTS_Sales_Catalog__c='040202';
        testProduct2.IsActive = true;
        insert testProduct2;

        Product2 testProduct3 = APTS_TestDataFactory.createProduct('Test Product 2','123','SAP_04','Standalone',false,false);
        testProduct3.APTS_Sales_Catalog__c='';
        testProduct3.APTS_Material_Type__c ='ZOPT';
        testProduct3.APTS_Option_Group_Indicator__c = '0201';
        testProduct3.APTS_Option_Family__c = 'Machines';
        testProduct3.IsActive = true;
        insert testProduct3;

        Apttus_Config2__ProductOptionComponent__c poc = new Apttus_Config2__ProductOptionComponent__c();
        poc.Apttus_Config2__ParentProductId__c = testProduct2.Id;
        poc.Apttus_Config2__ComponentProductId__c = testProduct3.Id;
        poc.Apttus_Config2__Sequence__c = 1;
        insert poc;

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI3 = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct3.id);
        insert testPLI3;
        
        Apttus_Proposal__Proposal__c quote = APTS_TestUtils.getQuoteProposal(Acc.id,opp.Id,'Proposal','Test',priceList.id);
        insert quote;
            
        Apttus_Config2__ProductConfiguration__c config = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=quote.id,Apttus_Config2__PriceListId__c=priceList.id);
        insert config;
        
        Apttus_Config2__LineItem__c lineItem = APTS_TestUtils.getConfigLineItem(config.id, null, 1, true, 2, '', testProduct2.id, false, null,testProduct2.id, null, '', 2.3, false, '', 1, priceList.id, testPLI3.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
        insert lineItem;
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(con.Id,quote.Id, priceList.Id, Acc.Id);
        insert agreement;
        
        List<Apttus__AgreementLineItem__c> agreementLineItems = APTS_TestUtils.createAgreementLineItem(testProduct2.Id, agreement.Id, Acc.Id, lineItem, testPLI3.Id,subCategory.Id);
        insert agreementLineItems;
        
        Apttus_Config2__AdjustmentLineItem__c adjline = APTS_TestUtils.createadjustmentlineitems(lineItem.id);
        insert adjline;
        
        Apttus_CMConfig__AgreementAdjustmentLineItem__c  agradjline= APTS_TestUtils.createagrementadjustmentlineitem(agreementLineItems[0].id);
        insert agradjline;
        
        APTS_Contract_Entitlement_Repository__c cerrec = APTS_TestUtils.createCerrecords(agradjline.id,agreementLineItems[0].id,testProduct2.id); 
        insert cerrec;      
        
         APTS_Contract_Entitlement_Repository__c cer1 = new APTS_Contract_Entitlement_Repository__c(APTS_Product__c=testProduct1.id,APTS_Agreement_Line_Item__c=agreementLineItems[0].id,APTS_Agreement_Type__c='Standard Deal',APTS_Sold_to_Party__c=acc.id);
         cer1.APTS_Type__c ='PPR';
         cer1.APTS_Is_Pending__c=false;
         insert cer1;  

        //Call class logic
        ApexPages.Currentpage().getParameters().put('pliid',pricelist.id);
        ApexPages.Currentpage().getParameters().put('selectedCatgsXLS','Machines');
        APTS_ListPriceExtractionCtrl listPriceExtObj = new APTS_ListPriceExtractionCtrl();
        listPriceExtObj.GroupByCategory =true;
        listPriceExtObj.selectedCatgs = 'Machines';
        List<string> stringList = new List<string>{'ABC'};
        //listPriceExtObj.catselected = stringList;
        //listPriceExtObj.priceListDetails = pricelist;
        listPriceExtObj.IncludeVat =true;
        listPriceExtObj.IncludeTax = true;
        listPriceExtObj.loadProductsList();
        //listPriceExtObj.getcategories();
        APTS_ListPriceExtractionCtrl.getAllPicklistValues();
        listPriceExtObj.getcerforplis(new Set<Id>{pricelist.id});
        PageReference pg = listPriceExtObj.viewListOfPriceListItems();
        PageReference pg1 = listPriceExtObj.previousActionPage();
        listPriceExtObj.previous();
        listPriceExtObj.next();
        listPriceExtObj.first();
        listPriceExtObj.last();
        Boolean hasNext = listPriceExtObj.hasNext;
        Boolean hasPrevious = listPriceExtObj.hasPrevious;
        Integer pageNo = listPriceExtObj.pageNumber;
        Integer totalPages = listPriceExtObj.totalPages;
        List<SelectOption> optionList = listPriceExtObj.getuomValues();
        //PageReference pg2 = listPriceExtObj.previousPage();
        listPriceExtObj.downloadAsPDF();
        listPriceExtObj.exportAsExcel();
        listPriceExtObj.exportAsCSV();
        List<Id> priceListItemIds = new List<Id>();
        priceListItemIds.add(testPLI2.id);
        priceListItemIds.add(testPLI3.id);
        priceListItemIds.add(testPLI.id);
        APTS_ListPriceExtractionCSV.insertCSVFile(priceListItemIds, 'Machines', '', '', 'testuom', '', true, pricelist.Id, '', 'Set1');
        PageReference pg4 = listPriceExtObj.CancelPage();
        
        //
        APTS_ListPriceExtractionPDF pdfClass = new APTS_ListPriceExtractionPDF();
        pdfClass.loadProductsList();
        APTS_ListPriceExtractionCtrl.ListPriceExtractionWrapper pt = new APTS_ListPriceExtractionCtrl.ListPriceExtractionWrapper('mycatr',testPLI,'testuom',10.0,'Monthly','SAP_BX',100,'100','productname','100','optiongroupname', 'productName');
        test.stopTest();
    }

    @isTest
    static void accountBasedOptionGroup(){

        test.startTest();
        //Account creation
        Account acc = APTS_TestUtils.createaccount();
        insert Acc;
        System.assert(acc != Null);
        System.assertEquals(acc.name,'Test account');
        
        Opportunity opp = APTS_TestUtils.createOpportunity(Acc.id);
        insert opp;
        System.assert(opp != Null);
        Contact con= APTS_TestUtils.createContact();
        insert con;
        System.assert(con != Null);
      
        
        //Price list creation
        Apttus_Config2__PriceList__c pricelist = new Apttus_Config2__PriceList__c();
        pricelist.APTS_SalesOrg__c='123456';
        pricelist.Name='JDEPL';
        priceList.APTS_Region__c='SAP_0111';
        priceList.Apttus_Config2__Active__c = true;
        insert pricelist;
       /*********************PLI 1 Data******************************/
        //create product
        Product2 testProduct = APTS_TestDataFactory.createProduct('Test Product','123','SAP_04','Standalone',false,false);
        testProduct.APTS_Sales_Catalog__c='040202';
        testProduct.isActive = true;
        insert testProduct;
        System.assertEquals(testProduct.APTS_Sales_Catalog__c,'040202');

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct.id);
        insert testPLI;

        //create category
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        category.name = 'Machines';
        insert category;

        //create category hierarchy 
        Apttus_Config2__ClassificationHierarchy__c subCategory = APTS_TestDataFactory.createCategoryHierarchy(category.id,'sub category | sub sub category');
        subCategory.APTS_CategoryHierarchyOfferingExtId__c ='040202';
        subCategory.name='Machines Pads|Gevalia';
        insert subCategory;

        /*********************PLI 2 Data******************************/
        //create product
        Product2 testProduct1 = APTS_TestDataFactory.createProduct('Test Product 1','123','SAP_04','Standalone',false,false);
        testProduct1.APTS_Sales_Catalog__c='040303';
        insert testProduct1;

        //Create Price list Item
        Apttus_Config2__PriceListItem__c testPLI2 = APTS_TestDataFactory.createPriceListItem(pricelist.id,testProduct1.id);
        insert testPLI2;
        /*
        //create category
        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        insert category;

        //create category hierarchy 
        Apttus_Config2__ClassificationHierarchy__c subCategory = APTS_TestDataFactory.createCategoryHierarchy(category.id,'sub category | sub sub category');
        subCategory.APTS_CategoryHierarchyOfferingExtId__c ='020202';
        insert subCategory;
        */

        /*********************PLI 3 Data******************************/
        //create product
        List<Product2> productList = new List<Product2>(); 
        for(Integer i=0;i<Integer.valueof(System.label.APTS_List_Price_Extraction_Page_Size);i++){
            Product2 testProduct2 = APTS_TestDataFactory.createProduct('Test Product'+i,'123'+i,'SAP_04','Standalone',false,false);
            testProduct2.APTS_Sales_Catalog__c='040202';
            testProduct2.isActive = true;
            productList.add(testProduct2);
        }
        insert productList;

        //Create Price list Item
        List<Apttus_Config2__PriceListItem__c> plitList = new List<Apttus_Config2__PriceListItem__c>(); 
        for(Integer i=0;i<Integer.valueof(System.label.APTS_List_Price_Extraction_Page_Size);i++){
            Apttus_Config2__PriceListItem__c testPLI3 = APTS_TestDataFactory.createPriceListItem(pricelist.id,productList[i].id);
            testPLI3.Apttus_Config2__PriceUom__c='SAP_PCE';
            testPLI3.APTS_Default_Selling_Uom__c='SAP_BX';
            testPLI3.Apttus_Config2__ChargeType__c = 'Rental Price';
            testPLI3.Apttus_Config2__Active__c = true;
            plitList.add(testPLI3);
        }
        insert plitList;

        List<Product2> productList2 = new List<Product2>(); 
        for(Integer i=0;i<Integer.valueof(System.label.APTS_List_Price_Extraction_Page_Size);i++){
            Product2 testProduct3 = APTS_TestDataFactory.createProduct('Test Product'+i,'123'+i,'SAP_04','Standalone',false,false);
            testProduct3.APTS_Sales_Catalog__c='';
            testProduct3.APTS_Material_Type__c ='ZOPT';
            testProduct3.APTS_Option_Group_Indicator__c = '0201';
            testProduct3.APTS_Option_Family__c = 'Machines';
            testProduct3.IsActive = true;
            productList2.add(testProduct3);
        }
        insert productList2;

        
        List<Apttus_Config2__PriceListItem__c> plitList33 = new List<Apttus_Config2__PriceListItem__c>(); 
        for(Integer i=0;i<Integer.valueof(System.label.APTS_List_Price_Extraction_Page_Size);i++){
            Apttus_Config2__PriceListItem__c testPLI33 = APTS_TestDataFactory.createPriceListItem(pricelist.id,productList2[i].id);
            testPLI33.Apttus_Config2__PriceUom__c='SAP_PCE';
            testPLI33.APTS_Default_Selling_Uom__c='SAP_BX';
            testPLI33.Apttus_Config2__ChargeType__c = 'Rental Price';
            testPLI33.Apttus_Config2__Active__c = true;
            plitList33.add(testPLI33);
        }
        insert plitList33;

        List<Apttus_Config2__ProductOptionComponent__c> poclist = new List<Apttus_Config2__ProductOptionComponent__c>(); 
        for(Integer i=0;i<Integer.valueof(System.label.APTS_List_Price_Extraction_Page_Size);i++){
            Apttus_Config2__ProductOptionComponent__c poc = new Apttus_Config2__ProductOptionComponent__c();
            poc.Apttus_Config2__ParentProductId__c = productList[i].Id;
            poc.Apttus_Config2__ComponentProductId__c = productList2[i].Id;
            poc.Apttus_Config2__Sequence__c = i;
            poclist.add(poc);
        }
        insert poclist;
        
        
        Apttus_Proposal__Proposal__c quote = APTS_TestUtils.getQuoteProposal(Acc.id,opp.Id,'Proposal','Test',priceList.id);
        insert quote;
            
        Apttus_Config2__ProductConfiguration__c config = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=quote.id,Apttus_Config2__PriceListId__c=priceList.id);
        insert config;
        
        Apttus_Config2__LineItem__c lineItem = APTS_TestUtils.getConfigLineItem(config.id, null, 1, true, 2, '', productList[0].id, false, null,productList[0].id, null, '', 2.3, false, '', 1, priceList.id, plitList[0].Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
        insert lineItem;
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(con.Id,quote.Id, priceList.Id, Acc.Id);
        insert agreement;
        
        List<Apttus__AgreementLineItem__c> agreementLineItems = APTS_TestUtils.createAgreementLineItem(productList[0].Id, agreement.Id, Acc.Id, lineItem, plitList[0].Id,subCategory.Id);
        insert agreementLineItems;
        
        Apttus_Config2__AdjustmentLineItem__c adjline = APTS_TestUtils.createadjustmentlineitems(lineItem.id);
        insert adjline;
        
        Apttus_CMConfig__AgreementAdjustmentLineItem__c  agradjline= APTS_TestUtils.createagrementadjustmentlineitem(agreementLineItems[0].id);
        insert agradjline;
        
        APTS_Contract_Entitlement_Repository__c cerrec = APTS_TestUtils.createCerrecords(agradjline.id,agreementLineItems[0].id,productList[0].id); 
        insert cerrec;      
        
        APTS_Contract_Entitlement_Repository__c cer1 = new APTS_Contract_Entitlement_Repository__c(APTS_Product__c=testProduct1.id,APTS_Agreement_Line_Item__c=agreementLineItems[0].id,APTS_Agreement_Type__c='Standard Deal',APTS_Sold_to_Party__c=acc.id);
        cer1.APTS_Type__c ='PPR';
        cer1.APTS_Is_Pending__c=false;
        insert cer1;  


        Apttus_Config2__FrequencyConversionRate__c fre = new Apttus_Config2__FrequencyConversionRate__c();
        fre.Apttus_Config2__FromUom__c ='SAP_PCE';
        fre.Apttus_Config2__ToUom__c  ='SAP_BX';
        fre.Apttus_Config2__ProductId__c = productList[0].Id;
        fre.APTS_ProductCode__c='1230';
        fre.Apttus_Config2__ConversionFactor__c=1000;
        insert fre;
        
        //
        ApexPages.Currentpage().getParameters().put('pliid',pricelist.id);
        ApexPages.Currentpage().getParameters().put('id',acc.id);
        ApexPages.Currentpage().getParameters().put('selectedCatgsXLS','Machines');
        APTS_ListPriceExtractionCtrl listPriceExtObj1 = new APTS_ListPriceExtractionCtrl();
        listPriceExtObj1.GroupByCategory =true;
        listPriceExtObj1.IncludeVat =true;
        listPriceExtObj1.IncludeTax = true;
        listPriceExtObj1.selectedCatgs = 'Machines';
        //listPriceExtObj1.includeVatPdf = 'true';
        //listPriceExtObj1.includeTaxPdf = 'true';
        //listPriceExtObj1.isExportAsXls = 'true';
        //listPriceExtObj1.isExportAsXls = 'true';
        listPriceExtObj1.userDefinedUOM = 'SAP_BX';
        //listPriceExtObj1.priceListDetails = pricelist;
        //listPriceExtObj1.groupByCategoryPdf = 'true';
        listPriceExtObj1.loadProductsList();
        //listPriceExtObj1.getcategories();
        APTS_ListPriceExtractionCtrl.getAllPicklistValues();
        listPriceExtObj1.getcerforplis(new Set<Id>{pricelist.id});
        APTS_ListPriceExtractionCtrl.ListPriceExtractionWrapper wrap;
        PageReference pag = listPriceExtObj1.viewListOfPriceListItems();
        PageReference pag1 = listPriceExtObj1.previousActionPage();
        //PageReference pag2 = listPriceExtObj.previousPage();
        listPriceExtObj1.downloadAsPDF();
        PageReference pag4 = listPriceExtObj1.cancelPage();
        listPriceExtObj1.exportAsExcel();
        listPriceExtObj1.exportAsCSV();

        List<Id> priceListItemIds = new List<Id>();
        for(Apttus_Config2__PriceListItem__c pp :plitList){
            priceListItemIds.add(pp.Id);
        }
        for(Apttus_Config2__PriceListItem__c pp :plitList33){
            priceListItemIds.add(pp.Id);
        }
        APTS_ListPriceExtractionCSV.insertCSVFile(priceListItemIds, 'Machines', '', '', 'testuom', '', true, pricelist.Id, '', 'Set1');
       
       
        APTS_ListPriceExtractionCtrl.compareListPriceExtractionWrapper pt1 = new APTS_ListPriceExtractionCtrl.compareListPriceExtractionWrapper('mycatr',testPLI,'testuom',10.0,10.0,'SAP_BX',100,'100','productname','100','optiongroupname', 'productName');
        listPriceExtObj1.previous();
        listPriceExtObj1.next();
        listPriceExtObj1.first();
        listPriceExtObj1.last();
        Boolean hasNext = listPriceExtObj1.hasNext;
        Boolean hasPrevious = listPriceExtObj1.hasPrevious;
        Integer pageNo = listPriceExtObj1.pageNumber;
        Integer totalPages = listPriceExtObj1.totalPages;
        List<SelectOption> optionList = listPriceExtObj1.getuomValues();

        APTS_ListPriceExtractionPDF pdfClass = new APTS_ListPriceExtractionPDF();
        pdfClass.GroupByCategory =true;
        pdfClass.IncludeVat =true;
        pdfClass.IncludeTax = true;
        //pdfClass.selectedCatgs = 'Machines';
        pdfClass.includeVatPdf = 'true';
        pdfClass.includeTaxPdf = 'true';
        pdfClass.isExportAsXls = 'true';
        pdfClass.isExportAsXls = 'true';
        pdfClass.userDefinedUOM = 'SAP_BX';
        pdfClass.priceListDetails = pricelist;
        pdfClass.groupByCategoryPdf = 'true';
        pdfClass.loadProductsList();

        
        test.stopTest();
    }

   
}