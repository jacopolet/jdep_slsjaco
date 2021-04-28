/**********************
  Purpose: 
  Revision History:
  #No     Name          Purpose
  1.0     Lavanya       TestClass for APTS_FreqConversionRateTriggerHandler
  ************************/
@IsTest
public class APTS_FreqConversionRateHandlerTest {

	public static testmethod void Positive()
	{
		Product2 instprod = new Product2(Name = 'SaltNSugar', ProductCode = '4055052');
		insert instprod;

		 	
		List<Apttus_Config2__FrequencyConversionRate__c> lstfreq = new List<Apttus_Config2__FrequencyConversionRate__c> ();
		Map<Id, Apttus_Config2__FrequencyConversionRate__c> mapfreq = new Map<Id, Apttus_Config2__FrequencyConversionRate__c> ();
		Map<Id, Apttus_Config2__FrequencyConversionRate__c> mapfreqUpdate = new Map<Id, Apttus_Config2__FrequencyConversionRate__c> ();
		for (integer i = 0; i< 300; i++)
		{
			Apttus_Config2__FrequencyConversionRate__c instfr = new Apttus_Config2__FrequencyConversionRate__c(APTS_ProductCode__c = '4055052', Apttus_Config2__ToUom__c = 'SAP_BX',
			                                                                                                   Apttus_Config2__FromUom__c = 'SAP_PCE', APTS_Numerator__c = 2, APTS_Denominator__c = 1, Apttus_Config2__FromFrequency__c = 'Yearly', Apttus_Config2__ToFrequency__c = 'Monthly');
			instfr.Apttus_Config2__ConversionFactor__c = (instfr.APTS_Numerator__c / instfr.APTS_Denominator__c);
			lstfreq.add(instfr);
			mapfreq.put(instfr.id, instfr);

			Apttus_Config2__FrequencyConversionRate__c instfrUpdate = new Apttus_Config2__FrequencyConversionRate__c(APTS_ProductCode__c = '4055052', APTS_Numerator__c = 3, Apttus_Config2__ToUom__c = 'SAP_BX', Apttus_Config2__FromUom__c = 'SAP_PCE' , APTS_Denominator__c = 1, Apttus_Config2__FromFrequency__c = 'Yearly', Apttus_Config2__ToFrequency__c = 'Monthly');
			instfr.Apttus_Config2__ConversionFactor__c = (instfr.APTS_Numerator__c / instfr.APTS_Denominator__c);
			lstfreq.add(instfrUpdate);
			mapfreqUpdate.put(instfr.id, instfrUpdate);



		}
		insert lstfreq;

		APTS_FreqConversionRateTriggerHandler instfreq = new APTS_FreqConversionRateTriggerHandler();
		instfreq.beforeInsert(lstfreq);
		instfreq.beforeUpdate(lstfreq, mapfreq, lstfreq, mapfreq);
		instfreq.afterUpdate(lstfreq, mapfreq, lstfreq, mapfreqUpdate);
		instfreq.afterInsert(lstfreq, mapfreq);
		instfreq.beforeUpdate(lstfreq, mapfreq, lstfreq, mapfreq);
		instfreq.beforeDelete(lstfreq, mapfreq);
		instfreq.afterDelete(lstfreq, mapfreq);
		instfreq.afterUndelete(lstfreq, mapfreq);
	}
	public static testmethod void NPE()
	{
		insert new TriggerSettings__c(FreqConversionRate__c = true);
		// Creation of test accounts
		User testUser = APTS_TestUtils.createUser();
		testUser.LocaleSidKey = 'nl_NL';
		System.runAs(testUser) {
			Account acc1 = new Account(Name = 'NC Account1', Phone = '+3209999999');
			acc1.Sales_Organization__c='SAP_0111';
			acc1.SAP_Customer_ID__c='1496369';
			insert acc1;

			Account ncAccount1 = new Account(Name = 'NC Account2', Phone = '+3209999999');
			ncAccount1.Sales_Organization__c='SAP_0111';
			ncAccount1.parentId=acc1.id;
			ncAccount1.SAP_Customer_ID__c='1496368';
			insert ncAccount1;

			Account ncAccount2 = new Account(Name = 'NC Account3', Phone = '+3209999999');
			ncAccount2.Sales_Organization__c='SAP_0111';
			ncAccount2.SAP_Customer_ID__c='1496367';
			ncAccount2.parentId=ncAccount1.id;
			insert ncAccount2;

			Account ncAccount3 = new Account(Name = 'NC Account4', Phone = '+3209999999');
			ncAccount3.Sales_Organization__c='SAP_0111';
			ncAccount3.SAP_Customer_ID__c='1496366';
			ncAccount3.parentId=ncAccount2.id;
			insert ncAccount3;

			Account acc = new Account(Name = 'NC Account5', Phone = '+3209999999');
			acc.Sales_Organization__c='SAP_0111';
			acc.parentId=ncAccount3.id;
			acc.SAP_Customer_ID__c='1496365';
			insert acc;

			Contact con=APTS_TestDataFactory.createContact(acc,'1234556');
			insert con;
			
			Product2 prod1 = APTS_TestDataFactory.createProduct('TestProduct','test1000','Coffee', 'Option', FALSE, TRUE);
			prod1.APTS_Associated_Sales_Org__c= 'SAP_0975';
			prod1.APTS_Cross_plant_material_status__c= 'PR';
			prod1.APTS_Sales_Catalog__c = '1234';
			prod1.Apttus_Config2__ConfigurationType__c='Option';
			insert prod1;

			System.debug('prod1=======>'+prod1);
			
			Apttus_Config2__PriceList__c  priceList = APTS_TestDataFactory.createPriceList('testpricelist');
			priceList.APTS_Region__c='SAP_0975';
			priceList.APTS_PriceList_Type__c= 'CSP';
			insert priceList;
			
			APTS_Sales_Org_Data__c sales = new APTS_Sales_Org_Data__c();
			sales.APTS_Distribution_channel__c='SAP_10';
			insert sales;

			Apttus_Config2__PriceListItem__c priceListItem = APTS_TestDataFactory.createPriceListItem(PriceList.id,prod1.id);
			priceListItem.Apttus_Config2__PriceUom__c=' SAP_PCE';
			priceListItem.APTS_TAX_DK_specific_UOM__c=10;
			priceListItem.APTS_Related_sales_org_data__c=sales.id;
			insert priceListItem;
			
			Apttus__APTS_Agreement__c agree=APTS_TestDataFactory.createAgreement(con.id,priceList.id,acc.id,'Standard Deal');
			agree.APTS_Region__c='SAP_0975';
			agree.Apttus__Status_Category__c='In Effect';
			agree.Apttus__Status__c='Activated';
			agree.APTS_Distribution_Channel__c = 'National (SAP_10)';
			agree.Apttus__Contract_End_Date__c= Date.Today() ;
			insert agree;
			System.debug('agree=======>'+agree);
			
			List <Apttus__AgreementLineItem__c> agreementLineList = new List <Apttus__AgreementLineItem__c>();
			Apttus__AgreementLineItem__c agreementLine = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem.id);
			agreementLine.Apttus_CMConfig__OptionId__c = prod1.id;
			agreementLine.Apttus_CMConfig__LineType__c ='Option'; 
			agreementLine.Apttus__Quantity__c=5;
			//agreementLine.Apttus_CMConfig__HasOptions__c =false;
			agreementLine.Apttus_CMConfig__PriceListId__c = PriceList.id;
			agreementLine.Apttus__AgreementId__c= agree.id;
			agreementLine.Apttus__NetPrice__c=1500;
			agreementLine.Apttus__ExtendedPrice__c=1500;
			agreementLine.Apttus_CMConfig__SellingUom__c='SAP_BX';
			agreementLineList.add(agreementLine);

			insert agreementLineList;

			System.debug('agreementLineList=======>'+agreementLineList);

			Apttus_Config2__FrequencyConversionRate__c frequencyRate = APTS_TestDataFactory.createConversionRate('SAP_PCE','SAP_BX');
			frequencyRate.Apttus_Config2__ProductId__c=prod1.id;
			frequencyRate.Apttus_Config2__ConversionFactor__c=1;
			insert frequencyRate;

			frequencyRate.Apttus_Config2__ToUom__c='SAP_KGM';
			update frequencyRate;
		}	
	}
	public static testmethod void NPE_Negetive()
	{
		insert new TriggerSettings__c(FreqConversionRate__c = true);
		// Creation of test accounts
		User testUser = APTS_TestUtils.createUser();
		testUser.LocaleSidKey = 'nl_NL';
		System.runAs(testUser) {
			Account acc1 = new Account(Name = 'NC Account1', Phone = '+3209999999');
			acc1.Sales_Organization__c='SAP_0111';
			acc1.SAP_Customer_ID__c='1496370';
			insert acc1;

			Account ncAccount1 = new Account(Name = 'NC Account2', Phone = '+3209999999');
			ncAccount1.Sales_Organization__c='SAP_0111';
			ncAccount1.parentId=acc1.id;
			ncAccount1.SAP_Customer_ID__c='1496368';
			insert ncAccount1;

			Account ncAccount2 = new Account(Name = 'NC Account3', Phone = '+3209999999');
			ncAccount2.Sales_Organization__c='SAP_0111';
			ncAccount2.SAP_Customer_ID__c='1496367';
			ncAccount2.parentId=ncAccount1.id;
			insert ncAccount2;

			Account ncAccount3 = new Account(Name = 'NC Account4', Phone = '+3209999999');
			ncAccount3.Sales_Organization__c='SAP_0111';
			ncAccount3.SAP_Customer_ID__c='1496366';
			ncAccount3.parentId=ncAccount2.id;
			insert ncAccount3;

			Account acc = new Account(Name = 'NC Account5', Phone = '+3209999999');
			acc.Sales_Organization__c='SAP_0111';
			acc.parentId=ncAccount3.id;
			acc.SAP_Customer_ID__c='1496365';
			insert acc;

			Contact con=APTS_TestDataFactory.createContact(acc,'1234556');
			insert con;
			
			Product2 prod1 = APTS_TestDataFactory.createProduct('TestProduct','test1000','Coffee', 'Option', FALSE, TRUE);
			prod1.APTS_Associated_Sales_Org__c= 'SAP_0975';
			prod1.APTS_Cross_plant_material_status__c= 'PR';
			prod1.APTS_Sales_Catalog__c = '1234';
			prod1.Apttus_Config2__ConfigurationType__c='Option';
			insert prod1;

			System.debug('prod1=======>'+prod1);
			
			Apttus_Config2__PriceList__c  priceList = APTS_TestDataFactory.createPriceList('testpricelist');
			priceList.APTS_Region__c='SAP_0975';
			priceList.APTS_PriceList_Type__c= 'CSP';
			insert priceList;
			
			APTS_Sales_Org_Data__c sales = new APTS_Sales_Org_Data__c();
			sales.APTS_Distribution_channel__c='SAP_10';
			insert sales;

			Apttus_Config2__PriceListItem__c priceListItem = APTS_TestDataFactory.createPriceListItem(PriceList.id,prod1.id);
			priceListItem.Apttus_Config2__PriceUom__c=' SAP_PCE';
			priceListItem.APTS_TAX_DK_specific_UOM__c=10;
			priceListItem.APTS_Related_sales_org_data__c=sales.id;
			insert priceListItem;
			
			Apttus__APTS_Agreement__c agree=APTS_TestDataFactory.createAgreement(con.id,priceList.id,acc.id,'Standard Deal');
			agree.APTS_Region__c='SAP_0975';
			agree.Apttus__Status_Category__c='In Effect';
			agree.Apttus__Status__c='Activated';
			agree.APTS_Distribution_Channel__c = 'National (SAP_10)';
			agree.Apttus__Contract_End_Date__c= Date.Today() ;
			insert agree;
			System.debug('agree=======>'+agree);
			
			List <Apttus__AgreementLineItem__c> agreementLineList = new List <Apttus__AgreementLineItem__c>();
			Apttus__AgreementLineItem__c agreementLine = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem.id);
			agreementLine.Apttus_CMConfig__OptionId__c = prod1.id;
			agreementLine.Apttus_CMConfig__LineType__c ='Option'; 
			agreementLine.Apttus__Quantity__c=5;
			//agreementLine.Apttus_CMConfig__HasOptions__c =false;
			agreementLine.Apttus_CMConfig__PriceListId__c = PriceList.id;
			agreementLine.Apttus__AgreementId__c= agree.id;
			agreementLine.Apttus__NetPrice__c=1500;
			agreementLine.Apttus__ExtendedPrice__c=1500;
			agreementLine.Apttus_CMConfig__SellingUom__c='SAP_BX';
			agreementLineList.add(agreementLine);

			insert agreementLineList;

			System.debug('agreementLineList=======>'+agreementLineList);

			Apttus_Config2__FrequencyConversionRate__c frequencyRate = APTS_TestDataFactory.createConversionRate('SAP_PCE','SAP_BX');
			frequencyRate.Apttus_Config2__ProductId__c=prod1.id;
			frequencyRate.Apttus_Config2__ConversionFactor__c=1;
			insert frequencyRate;

			frequencyRate.Apttus_Config2__ToUom__c='SAP_KGM';
			update frequencyRate;
		}	
	}
}