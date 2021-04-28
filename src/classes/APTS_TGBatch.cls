/*******************************************************************************************
Name            : APTS_TGBatch
Created By      : Ariel Quesada
Created Date    : 06/19/2018
Description     : This class is the batch to manage the Transgourmet batch
Version history : 
Test Class      : APTS_TGBatchTest
*********************************************************************************************/
global class APTS_TGBatch implements Database.Batchable<sObject> 
{
	// SECTION 0: MEMBER AND ATTRIBUTES
	// Subclass to support the output of TG Batch
	global class TGRecord
	{
		String AccountNumber; 
		Decimal netPrice;	
		String currencyOfAgreement; 
		Decimal Quantity; 
		String Uom; 
		Date priceStartDate; 
		Date priceEndDate; 
		Date transferDate; 
		String ProductNumber; 
		String Comment; 
		String Status; 
	}

	// Static global variable to control account management
	global static Integer nTGAccounts = 0;

	// SECTION 1: STANDARD METHODS OF THE BATCH
	// Method 0: Constructor of the class
	global APTS_TGBatch() {
		
	}
	
	// Method 1: Standard method of the batch to start tasks
	global Database.QueryLocator start(Database.BatchableContext BC) {
		
		// The scope is the review of every Account
		String query = 'SELECT Id,Name,SAP_Customer_ID__c,APTS_Partner_Pricing_Portal_Applicable__c, APTS_Partner_Pricing_Portal_Looped_in__c,ParentId FROM Account WHERE APTS_Partner_Pricing_Portal_applicable__c=true'; 
		return Database.getQueryLocator(query);
	}


	// Method 2: Actual execution of the batch
   	global void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
   		System.debug('TGBatch: Start of the execution batch');
   		// Before generating the file, the results will be stored in a list
   		List<TGRecord> completeResults = new List<TGRecord>();

		List<Account> accounts = scope;
		completeResults = processTG(accounts);
		System.debug(loggingLevel.error, 'TGBatch: Complete Results: ' + completeResults);
		String strFile = APTS_TGBatch.generateTGFile(completeResults);
		System.debug(loggingLevel.error, 'TGBatch: StrFile: ' + strFile);
		Boolean bResult = APTS_TGBatch.sendFile(strFile);
		System.debug(loggingLevel.error, 'TGBatch: Notification of file sent: ' + bResult);
	}

	// Method 3: Finish method of the batch
	global void finish(Database.BatchableContext BC) {
		
	}	

	// SECTION 2: METHODS THAT VERIFY INFO IN THE ACCOUNT. THOSE METHODS ARE STATIC BECAUSE THEY DO NOT 
	// REQUIRE THE EXISTENCE OF THE BATCH
	// Method 4: Boolean method that defines if an Account is TG Applicable
	global static boolean isTGApplicable(Account a)
	{
		if (a != null)
		{
			return a.APTS_Partner_Pricing_Portal_Applicable__c;
		}
		else
		{
			return false;
		}
	}

	// Method 5a: Boolean method that defines if an Account is TG Looped In
	global static boolean isTGLoopedIn(Account a)
	{
		if (a != null)
		{
			return a.APTS_Partner_Pricing_Portal_Looped_in__c;
		}
		else
		{
			return false;
		}
	}

	// Method 5b: Void method that updates the TG Looped In of the account
	global static void setTGLoopedIn(Account a, Boolean value)
	{
		a.APTS_Partner_Pricing_Portal_Looped_in__c = value;
		update a;
	}


	// SECTION 5: FILE GENERATION AND MANAGEMENT
	// Method 13: Method that generates the CSV File to be managed in the batch.
	global static String generateTGFile(List<TGRecord> tgRecords)
	{
		string strHeader = 'KGpA, Rechnungspreis, PreisEinh, Pro, ME, PreisGueltigAb, PreisGueltigBis,  Uebermittelt, PhgNr, Kommentar, Status' + '\n';
		string strFinal = strHeader;
		for (TGRecord rcd : tgRecords)
		{
			String AccountNumber; 
			Decimal netPrice;	
			String currencyOfAgreement; 
			Decimal Quantity; 
			String Uom; 
			Date priceStartDate; 
			Date priceEndDate; 
			Date transferDate; 
			String ProductNumber; 
			String Comment; 
			Boolean Status; 
			string strRecord = rcd.AccountNumber + ',' + rcd.netPrice + ',' + rcd.currencyofAgreement + ',' + rcd.Quantity + ',' +
								rcd.Uom + ',' + rcd.priceStartDate + ',' + rcd.priceEndDate + ',' + rcd.transferDate + ',' + 
								rcd.productNumber + ',' + rcd.Comment + ',' + rcd.Status + '\n';
			strFinal = strFinal + strRecord;
		}
		return strFinal;
	}

	// Method 14: Method that send the file to the recipients set in the configuration
	global static Boolean sendFile(String strFile)
	{
		Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
		blob csvBlob = Blob.valueOf(strFile);
		string csvname= 'Account.csv';
		csvAttc.setFileName(csvname);
		csvAttc.setBody(csvBlob);
		Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
		String[] toAddresses = new list<string> {'raulorozco@commercecx.com','Jan.Hoffmann@JDEcoffee.com','cedric.bogaert@accenture.com'};
		//String[] toAddresses = new list<string> {'arielquesada@commercecx.com'};
		String subject ='Account CSV';
		email.setSubject(subject);
		email.setToAddresses( toAddresses );
		email.setPlainTextBody('Account CSV ');
		email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
		Messaging.SendEmailResult [] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

		if (results[0].success) {
    		System.debug('TGBatch: The email was sent successfully to: ' + toAddresses);
		} else {
    		System.debug('TGBatch: The email failed to send: ' + results[0].errors[0].message);
		}
		return true;
	}

	// SECTION 6: Utilitary methods that support the rest of the logic
	// Method 15: Method that calculates the union of two lists of products
	global static List<Product2> intersectionOfListProducts(List<Product2> list1, List<Product2> list2)
	{
		Set<Product2> set1 = (list1 != null) ? new Set<Product2>(list1) : new Set<Product2>();
		Set<Product2> set2 = (list2 != null) ? new Set<Product2>(list2) : new Set<Product2>();
		Set<Product2> intersectSet = new Set<Product2>();
		Set<Product2> unionSet = new Set<Product2>();
		unionSet.addAll(set1);
		unionSet.addAll(set2);
		
		for (Product2 prd : unionSet)
		{
			if (set1.contains(prd) && set2.contains(prd))
			{
				intersectSet.add(prd);
			}
		}

		List<Product2> intersectList = new List<Product2>(intersectSet);
		return intersectList;
	}

	// Method 16: Method that calculates the intersection of two lists of products
	global static List<Product2> unionOfListProducts(List<Product2> list1, List<Product2> list2)
	{
		Set<Product2> set1 = (list1 != null) ? new Set<Product2>(list1) : new Set<Product2>();
		Set<Product2> set2 = (list2 != null) ? new Set<Product2>(list2) : new Set<Product2>();
		Set<Product2> unionSet = new Set<Product2>();
		unionSet.addAll(set1);
		unionSet.addAll(set2);

		List<Product2> unionList = new List<Product2>(unionSet);
		return unionList;
	}

	// Bulkified version of Transgourmet
	// Method (1) that generates the list 'Agr_list_all': list which 
	// contains the product codes of all products present in its agreement (and the agreement of its parent/grandparent).
	// Those methods are static because they do not require the existence of the Batch.
	// Parameter: List of accounts
	// result: map of account/list of products
	global static Map<Id, List<Product2>> getAgreementListAll(List<Account> accounts)
	{
		if (accounts != null)
		{
			if (accounts.size() == 0)
			{
				return null;
			}
			else
			{
				Map<Id, List<Product2>> accountProductsMap = new Map<Id, List<Product2>>();				
				List<Id> accountsIds = new List<Id>();
				List<Id> productsIds = new List<Id>();

				for (Account account: accounts)
				{
					if (account != null)
					{
						accountsIds.add(account.Id);
					}
				}

				/*List<APTS_Contract_Entitlement_Repository__c> cers = 
					[SELECT Id,APTS_Product__c,APTS_Sold_to_Party__c
					 FROM APTS_Contract_Entitlement_Repository__c 
					 WHERE APTS_Sold_to_Party__c IN: accountsIds];*/

				/******
					Defect #22323
					Date: 11/12/2018
					Author: Raul Orozco
				*******/
				List<APTS_Contract_Entitlement_Repository__c> cers = 
				[
					SELECT Id,APTS_Product__c,APTS_Sold_to_Party__c
					FROM APTS_Contract_Entitlement_Repository__c 
					WHERE APTS_Sold_to_Party__c IN: accountsIds
					AND (NOT(APTS_Product__r.APTS_Sales_Catalog__c LIKE '04%' OR APTS_Product__r.APTS_Sales_Catalog__c LIKE '0701%'))
				];
				
				if (cers.size() > 0 )
				{
					Map<Id, List<Id>> accountProductsIdMap = new Map<Id, List<Id>>();

			        for (APTS_Contract_Entitlement_Repository__c cer: cers)
			        {			        	
			        	if (accountProductsIdMap.get(cer.APTS_Sold_to_Party__c) == null)
			        	{
			        		List<Id> prdIds = new List<Id>();
			        		prdIds.add(cer.APTS_Product__c);
			        		accountProductsIdMap.put(cer.APTS_Sold_to_Party__c, prdIds);
			        	}
			        	else
			        	{
			        		List<Id> prdIds = (List<Id>) accountProductsIdMap.get(cer.APTS_Sold_to_Party__c);
			        		prdIds.add(cer.APTS_Product__c);
			        		accountProductsIdMap.put(cer.APTS_Sold_to_Party__c, prdIds);
			        	}
			        	productsIds.add(cer.APTS_Product__c);
			        }
			        Map<Id, Product2> productsMap = new Map<Id,Product2>([SELECT Id,Name,ProductCode FROM Product2 WHERE Id  IN :productsIds]);
			        for (Id accountId : accountProductsIdMap.keySet())
			        {
			        	List<Id> prdIds = (List<Id>)accountProductsIdMap.get(accountId);
			        	List<Product2> products = new List<Product2>();
			        	for (Id prdId: prdIds)
			     		{
			     			Product2 prd = (Product2) productsMap.get(prdId);
			     			products.add(prd);
			     		}			     				
			     		accountProductsMap.put(accountId, products);	     	
			        }
			        return accountProductsMap;
			    }
			    else
			    {
			    	return null;
			    }
			}
		}
		else
		{
			return null;
		}
	}

	global static Map<Id, Map<Id,Apttus__AgreementLineItem__c>> getAgreementListAllALI(List<Account> accounts)
	{
		Map<Id, Map<Id,Apttus__AgreementLineItem__c>> fullMapAccountALIs = new Map<Id, Map<Id,Apttus__AgreementLineItem__c>>();
		Map<Id, Map<Id,Id>> fullMapAccountALIIds = new Map<Id, Map<Id,Id>>();
		if (accounts != null)
		{
			if (accounts.size() == 0)
			{
				return null;
			}
			else
			{
				List<Id> accountsIds = new List<Id>();
				for (Account account: accounts)
				{
					if (account != null)
					{
						accountsIds.add(account.Id);
					}
				}

				/*List<APTS_Contract_Entitlement_Repository__c> cers = 
					[SELECT Id,APTS_Product__c,APTS_Sold_to_Party__c,APTS_Agreement_Line_Item__c
					 FROM APTS_Contract_Entitlement_Repository__c 
					 WHERE APTS_Sold_to_Party__c IN: accountsIds]; */  
				
				/******
					Defect #22323
					Date: 11/12/2018
					Author: Raul Orozco
				*******/
				List<APTS_Contract_Entitlement_Repository__c> cers = 
				[
					SELECT Id,APTS_Product__c,APTS_Sold_to_Party__c,APTS_Agreement_Line_Item__c
					FROM APTS_Contract_Entitlement_Repository__c 
					WHERE APTS_Sold_to_Party__c IN: accountsIds
					AND (NOT(APTS_Product__r.APTS_Sales_Catalog__c LIKE '04%' OR APTS_Product__r.APTS_Sales_Catalog__c LIKE '0701%'))	
				];   
				
				if (cers.size() > 0 )
				{
					List<Id> ALIsIds = new List<Id>();
			        for (APTS_Contract_Entitlement_Repository__c cer: cers)
			        {
						if (fullMapAccountALIIds.get(cer.APTS_Sold_to_Party__c) == null)
						{
							Map<Id,Id> prdALIId = new Map<Id,Id>();
							prdALIId.put(cer.APTS_Product__c,cer.APTS_Agreement_Line_Item__c);
							fullMapAccountALIIds.put(cer.APTS_Sold_to_Party__c, prdALIId);
							ALIsIds.add(cer.APTS_Agreement_Line_Item__c);
						}
			        }
					// At this moment the Map of Ids is complete. The next step is to fill the object with the ALIs records
					/*Map<Id, Apttus__AgreementLineItem__c> ALIsMap = new Map<Id,Apttus__AgreementLineItem__c>
						([SELECT Id,Apttus__NetPrice__c,Apttus__Quantity__c FROM Apttus__AgreementLineItem__c WHERE Id  IN :ALIsIds]);*/
					
					/******
						Defect #22323
						Date: 11/12/2018
						Author: Raul Orozco
					*******/
					Map<Id, Apttus__AgreementLineItem__c> ALIsMap = new Map<Id,Apttus__AgreementLineItem__c>
						([
							SELECT Id,Apttus__NetPrice__c,Apttus__Quantity__c 
							FROM Apttus__AgreementLineItem__c 
							WHERE Id IN :ALIsIds
							AND Apttus_CMConfig__LineType__c != 'Option'
						]);
						
					for (Id accountId: fullMapAccountALIIds.KeySet() )
					{
						Map<Id,Id> prdALIId = fullMapAccountALIIds.get(accountId);
						for (Id prd: prdALIId.KeySet())
						{
							Id ALIId = prdALIid.get(prd);
							Apttus__AgreementLineItem__c ALI = ALIsMap.get(ALIId);
							ALIsMap.put(prd,ALI);
						}
						fullMapAccountALIs.put(accountId, ALIsMap);
					}
			        return fullMapAccountALIs;
			    }
			    else
			    {
			    	return null;
			    }
			}
		}
		else
		{
			return null;
		}
	}

	global static Map<Id, Apttus__APTS_Agreement__c> getAgreementListAllAgreement(List<Account> accounts)
	{
		System.debug(loggingLevel.error, 'Accounts: ' + accounts);
		Map<Id, Apttus__APTS_Agreement__c> fullMapAccountAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
		Map<Id, Id> fullMapAccountAgreementId = new Map<Id, Id>();
		if (accounts != null)
		{
			if (accounts.size() == 0)
			{
				return null;
			}
			else
			{
				List<Id> accountsIds = new List<Id>();
				for (Account account: accounts)
				{
					if (account != null)
					{
						accountsIds.add(account.Id);
					}
				}
				System.debug(loggingLevel.error, 'AccountIds: ' + accountsIds);
				/*List<APTS_Contract_Entitlement_Repository__c> cers = 
					[SELECT Id,APTS_Product__c,APTS_Sold_to_Party__c,APTS_Contributing_Agreement__c
					 FROM APTS_Contract_Entitlement_Repository__c 
					 WHERE APTS_Sold_to_Party__c IN: accountsIds];*/

				List<APTS_Contract_Entitlement_Repository__c> cers = 
				[
					SELECT Id,APTS_Product__c,APTS_Sold_to_Party__c,APTS_Contributing_Agreement__c
					FROM APTS_Contract_Entitlement_Repository__c 
					WHERE APTS_Sold_to_Party__c IN: accountsIds
					AND (NOT(APTS_Product__r.APTS_Sales_Catalog__c LIKE '04%' OR APTS_Product__r.APTS_Sales_Catalog__c LIKE '0701%'))
				];   
				
				System.debug(loggingLevel.error, 'Cers: ' + cers);
				if (cers.size() > 0 )
				{
					List<Id> agreementsIds = new List<Id>();
			        for (APTS_Contract_Entitlement_Repository__c cer: cers)
			        {
						fullMapAccountAgreementId.put(cer.APTS_Sold_to_Party__c,cer.APTS_Contributing_Agreement__c);
						agreementsIds.add(cer.APTS_Contributing_Agreement__c);
			        }
					System.debug(loggingLevel.error, 'AgreementIds: ' + agreementsIds);
					Map<Id, Apttus__APTS_Agreement__c> agreementsMap = new Map<Id,Apttus__APTS_Agreement__c>
						 ([SELECT Id,CurrencyIsoCode FROM Apttus__APTS_Agreement__c WHERE Id IN: agreementsIds]);
					System.debug(loggingLevel.error, 'agreementsMap: ' + agreementsMap);
					for (Id accountId: fullMapAccountAgreementId.KeySet() )
					{
						Id agreementId = fullMapAccountAgreementId.get(accountId);
						Apttus__APTS_Agreement__c agreement = agreementsMap.get(agreementId);
						fullMapAccountAgreement.put(accountId, agreement);
					}
					System.debug(loggingLevel.error, 'fullMapAccountAgreement: ' + fullMapAccountAgreement);
			        return fullMapAccountAgreement;
			    }
			    else
			    {
			    	return null;
			    }
			}
		}
		else
		{
			return null;
		}
	}

	// Method (2) that generates the list 'Agr_list_delta': list which 
	// contains the product codes of all products whose agreed-upon conditions changed in the past day 
	// (in its agreement / parent’s agreement / GP’s agreement)
	// Parameter: List of accounts
	// result: map of account/list of products
	global static Map<Id, List<Product2>> getAgreementListDelta(List<Account> accounts)
	{
		if (accounts != null)
		{
			if (accounts.size() == 0)
			{
				return null;
			}
			else
			{
				Map<Id, List<Product2>> accountProductsMap = new Map<Id, List<Product2>>();				
				List<Id> accountsIds = new List<Id>();
				List<Id> productsIds = new List<Id>();

				for (Account account: accounts)
				{
					if (account != null)
					{
						accountsIds.add(account.Id);
					}
				}

				/*List<APTS_Contract_Entitlement_Repository__c> cers = 
					[SELECT Id,APTS_Product__c,APTS_Sold_to_Party__c FROM APTS_Contract_Entitlement_Repository__c WHERE APTS_Sold_to_Party__c IN: accountsIds
					AND SystemModStamp >= LAST_N_DAYS:1];  */    

				/******
					Defect #22323
					Date: 11/12/2018
					Author: Raul Orozco
				*******/
				List<APTS_Contract_Entitlement_Repository__c> cers = 
				[
					SELECT Id,APTS_Product__c,APTS_Sold_to_Party__c 
					FROM APTS_Contract_Entitlement_Repository__c 
					WHERE APTS_Sold_to_Party__c IN: accountsIds
					AND SystemModStamp >= LAST_N_DAYS:1
					AND (NOT(APTS_Product__r.APTS_Sales_Catalog__c LIKE '04%' OR APTS_Product__r.APTS_Sales_Catalog__c LIKE '0701%'))
				];      
				
				if (cers.size() > 0 )
				{
					Map<Id, List<Id>> accountProductsIdMap = new Map<Id, List<Id>>();

			        for (APTS_Contract_Entitlement_Repository__c cer: cers)
			        {
			        	if (accountProductsIdMap.get(cer.APTS_Sold_to_Party__c) == null)
			        	{
			        		List<Id> prdIds = new List<Id>();
			        		prdIds.add(cer.APTS_Product__c);
			        		accountProductsIdMap.put(cer.APTS_Sold_to_Party__c, prdIds);
			        	}
			        	else
			        	{
			        		List<Id> prdIds = (List<Id>) accountProductsIdMap.get(cer.APTS_Sold_to_Party__c);
			        		prdIds.add(cer.APTS_Product__c);
			        		accountProductsIdMap.put(cer.APTS_Sold_to_Party__c, prdIds);
			        	}
			        	productsIds.add(cer.APTS_Product__c);
			        }

			        Map<Id, Product2> productsMap = new Map<Id,Product2>([SELECT Id,Name,ProductCode FROM Product2 WHERE Id  IN :productsIds]);
			        for (Id accountId : accountProductsIdMap.keySet())
			        {
			        	List<Id> prdIds = (List<Id>)accountProductsIdMap.get(accountId);
			        	List<Product2> products = new List<Product2>();
			        	for (Id prdId: prdIds)
			     		{
			     			Product2 prd = (Product2) productsMap.get(prdId);
			     			products.add(prd);
			     		}			     				
			     		accountProductsMap.put(accountId, products);	     	
			        }
			        return accountProductsMap;
			    }
			    else
			    {
			    	return null;
			    }
			}
		}
		else
		{
			return null;
		}
	}

	// Method (3) that generates the list 'PLI_list_delta': list which contains the product codes of all products whose PLI 
	// changed in the past day.
	// Parameter: List of PriceLists
	// Result: List of Products whose PLI changes in the past day
	global static List<Product2> getPLIListDelta(List<Apttus_Config2__PriceList__c> priceLists)
	{
		// The first step is to obtain the Ids of the pricelists
		List<Id> priceListsIds = new List<Id>();
		for (Apttus_Config2__PriceList__c priceList : priceLists)
		{
			priceListsIds.add(priceList.Id);
		}

      	// Actual Price List Items restricted to the last day
      	/*List<Apttus_Config2__PriceListItem__c> priceListItems = 
      		[SELECT Id,Apttus_Config2__ProductId__c 
      		FROM Apttus_Config2__PriceListItem__c 
      		WHERE Apttus_Config2__PriceListId__c IN : priceListsIds
      		AND SystemModStamp >= LAST_N_DAYS:1];*/
      	
		/******
			Defect #22323
			Date: 11/12/2018
			Author: Raul Orozco
		*******/
		List<Apttus_Config2__PriceListItem__c> priceListItems = 
		[
			SELECT Id,Apttus_Config2__ProductId__c 
			FROM Apttus_Config2__PriceListItem__c 
			WHERE Apttus_Config2__PriceListId__c IN : priceListsIds
			AND SystemModStamp >= LAST_N_DAYS:1
			AND (NOT(Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c LIKE '04%' OR Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c LIKE '0701%'))
		];

      	List<Id> ProductIds = new List<Id>();
      	for (Apttus_Config2__PriceListItem__c pli : pricelistItems)
      	{
      		productIds.add(pli.Apttus_Config2__ProductId__c);
      	}
        List<Product2> products = [SELECT Id,Name,ProductCode FROM Product2 WHERE Id  IN :productIds];
        return products;	
	}

	// Method (4) that generates the list 'PLI_list_full': list which contains the product codes of all products 
	// Parameter: List of PriceLists
	// Result: List of Products whose PLI changes in the past day
	global static List<Product2> getPLIListFull(List<Apttus_Config2__PriceList__c> priceLists)
	{
		// The first step is to obtain the Ids of the pricelists
		List<Id> priceListsIds = new List<Id>();
		for (Apttus_Config2__PriceList__c priceList : priceLists)
		{
			priceListsIds.add(priceList.Id);
		}

      	// Actual Price List Items restricted to the last day
      	/*List<Apttus_Config2__PriceListItem__c> priceListItems = 
      		[SELECT Id,Apttus_Config2__ProductId__c 
      		FROM Apttus_Config2__PriceListItem__c 
      		WHERE Apttus_Config2__PriceListId__c IN : priceListsIds];*/
		
		/******
			Defect #22323
			Date: 11/12/2018
			Author: Raul Orozco
		*******/
		List<Apttus_Config2__PriceListItem__c> priceListItems = 
		[
			SELECT Id,Apttus_Config2__ProductId__c 
			FROM Apttus_Config2__PriceListItem__c 
			WHERE Apttus_Config2__PriceListId__c IN : priceListsIds
			AND (NOT(Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c LIKE '04%' OR Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c LIKE '0701%'))
		];

      	List<Id> ProductIds = new List<Id>();
      	for (Apttus_Config2__PriceListItem__c pli : pricelistItems)
      	{
      		productIds.add(pli.Apttus_Config2__ProductId__c);
      	}
        List<Product2> products = [SELECT Id,Name,ProductCode FROM Product2 WHERE Id  IN :productIds];
        return products;	
	}

	// Method (5) that generates the list 'getCategoryListAll': categ_list_full: list of all products that are present in the categories selected in the picklist.
	// Parameter: No Parameter
	// Result: List of Products whose categories are present in custom setting "APTS_Categories_to_Send_over"
	global static List<Product2> getCategoryListAll()
	{
		APTS_TG_Batch_Settings__c objSettings = APTS_TG_Batch_Settings__c.getValues('Transgourmet');

		if (objSettings != null){			    
			
			System.debug(LoggingLevel.ERROR,'Categories>>>> ' + objSettings.Categories_to_send_over__c);
		
			List<String> categoriesList = objSettings.Categories_to_send_over__c.split(';');
		
			List<Product2> products = [SELECT Id,Name,ProductCode FROM Product2 WHERE toLabel(Family) IN :categoriesList];    
			
			system.debug('Product List >>>>>> ' + products);
		 	
			 return products;
		}

		return null;
	}

	global static Map<Id,boolean> canOrderNonContractedProducts(List<Account> accounts)
	{
		Map<Id, boolean> results = new Map<Id, boolean>();

		for (Account a: accounts)
		{
			if (a != null)
			{
				results.put(a.Id, false);
			}
		}
		
		List<Apttus__APTS_Agreement__c> agreements = [SELECT Id, Apttus__Account__c, APTS_Order_Non_Contracted_Products__c 
														FROM Apttus__APTS_Agreement__c														
														WHERE Apttus__Status__c = 'Activated'
														AND Apttus__Account__c IN: results.KeySet()];

		for (Apttus__APTS_Agreement__c agreement: agreements)
		{
			results.put(agreement.Apttus__Account__c, agreement.APTS_Order_Non_Contracted_Products__c);
		}
		return results;
	}

	// Method: Method that generates the output for the account specified in the parameter
	global List<TGRecord> processTG(List<Account> accounts)
	{
		System.debug(logginglevel.Error, 'ProcessTG: Start of processTG: Accounts: ' + accounts);
		Map<Account,List<Product2>> fullMapAccountProducts = new Map<Account, List<Product2>>();
		//List to store errors in batch execution
		List<APTS_Error_Object__c> lstErrorLogs = new List<APTS_Error_Object__c>();
		
		// Obtain general Information from Accounts
		List<Id> accountIds = new List<Id>();
		for (Account a: accounts)
		{
			if (a != null)
			{
				accountIds.add(a.Id);
			}
		}
		// Queries to obtain every info

		// Query# 1: Account Info
		Map<Id,Account> accountInfoMap = new Map<Id, Account>([SELECT Id,SAP_Customer_ID__c, Name 
																FROM Account 
																WHERE Id IN: accountIds]);
		// List #1: Agreement List All
		Map<Id,List<Product2>> productsAgreementListAllMap = APTS_TGBatch.getAgreementListAll(accounts);
		// List #2: Agreement List delta
		Map<Id,List<Product2>> productsAgreementListDeltaMap = APTS_TGBatch.getAgreementListDelta(accounts);
		System.debug(loggingLevel.error, 'productsAgreementListDeltaMap:' + productsAgreementListDeltaMap);
		// List #3: PLI List Delta
		List<Apttus_Config2__PriceList__c> priceLists = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Name = 'Germany General Pricelist - EUR'];
		List<Id> priceListsIds = new List<Id>();
		for (Apttus_Config2__PriceList__c priceList: priceLists)
		{
			priceListsIds.add(priceList.Id);
		}
		List<Product2> productsPLIListDelta = APTS_TGBatch.getPLIListDelta(priceLists);
		// List #4: Category List Full
		List<Product2> productCategoryFull = APTS_TGBatch.getCategoryListAll();
		// List #5: Full Price List
		List<Product2> productsPLIListFull = APTS_TGBatch.getPLIListFull(priceLists);
		// Obtain Order Non Contracted products information
		Map<Id, Boolean> canOrderNonContractedProductsMap = canOrderNonContractedProducts(accounts);
		// List of products that contain the whole list of products 
		List<Product2> fullProductList = new List<Product2>();

		for (Account account: accounts)
		{
			String strAccount = (account!=null)?account.Name:'Null Account';
			System.debug(logginglevel.Error, 'ProcessTG: Analysis TG for Account: ' + strAccount);
			// First, verify info for the account
			boolean isTGApplicable = isTGApplicable(account);
			System.debug(logginglevel.Error, 'ProcessTG: TGApplicable: ' + isTGApplicable);
			boolean isTGLoopedIn = isTGLoopedIn(account);
			System.debug(logginglevel.Error, 'ProcessTG: TGLoopedIn: ' + isTGLoopedIn);
			boolean canOrderNonContractedProducts = (account==null) ? false : canOrderNonContractedProductsMap.get(account.Id);
			System.debug(logginglevel.Error, 'ProcessTG: canOrderNonContractedProducts: ' + canOrderNonContractedProducts);
			If (!isTGApplicable)
			{
				// Scenario #1: If the account is not TGApplicable, there will not be results generated
				System.debug(logginglevel.Error, 'ProcessTG: Scenario #1: If the account is not TGApplicable, there will not be results generated');
				fullMapAccountProducts.put(account, new List<Product2>());
			}
			else 
			{				
				List<Product2> productsResult = new List<Product2>();
				if (isTGApplicable && !isTGLoopedIn && !canOrderNonContractedProducts)
				{
					System.debug(logginglevel.Error, 'ProcessTG: Scenario #2: If the account is TG Applicable, Non TG Looped In, and cannot order non contracted products ' +
								 'Results = "Agreement list all" Intersect "Category list full"');
					// Scenario #2: If the account is TG Applicable, Non TG Looped In, and cannot order non contracted products
					// 1) Results = "Agreement list all" Intersect "Category list full"
					List<Product2> agreementListAllProducts = (productsAgreementListAllMap!=null)?(List<Product2>) productsAgreementListAllMap.get(account.Id):null;
					System.debug('AgreementListAllProducts: ' + agreementListAllProducts);
					List<Product2> productCategoryFullProducts = (productCategoryFull!=null)?(List<Product2>) productCategoryFull:null;		
					System.debug( 'productCategoryFullProducts: ' + productCategoryFullProducts);
					productsResult = agreementListAllProducts;
					if (productCategoryFull != null)
					{
						productsResult = APTS_TGBatch.intersectionOfListProducts(productCategoryFullProducts,productsResult);
					}
					// 2) Set TG Looped-in to true
					setTGLoopedIn(account, true);
					System.debug(logginglevel.Error, 'ProcessTG: Products Result for Scenario #2: ' + productsResult);
				}
				else if (isTGApplicable && isTGLoopedIn && !canOrderNonContractedProducts)
				{
					System.debug(logginglevel.Error, 'ProcessTG: Scenario #3: If the account is TGApplicable and TG Loopedin, and cannot order non contracted products ' +
								'Results = "Agreement list delta" Union ("PLI List delta" Intersect "Agreement List all") Intersect "Category List full"');
					// Scenario #3: If the account is TGApplicable and TG Loopedin, and cannot order non contracted products
					// 1) Results = "Agreement list delta" Union ("PLI List delta" Intersect "Agreement List all") Intersect "Category List full"
					List<Product2> productsPLIListDeltaProducts = (productsPLIListDelta!=null)?productsPLIListDelta:null;
					List<Product2> agreementListAllProducts = (productsAgreementListAllMap!=null)?(List<Product2>) productsAgreementListAllMap.get(account.Id):null;
					List<Product2> agreementListDeltaProducts = (productsAgreementListDeltaMap!=null)?(List<Product2>) productsAgreementListDeltaMap.get(account.Id):null;
					List<Product2> productCategoryFullProducts = (productCategoryFull!=null)?(List<Product2>) productCategoryFull:null;					
					// Set operation
					productsResult = APTS_TGBatch.intersectionOfListProducts(productsPLIListDeltaProducts,agreementListAllProducts);
					productsResult = APTS_TGBatch.unionOfListProducts(agreementListDeltaProducts, productsResult);
					if (productCategoryFull != null)
					{
						productsResult = APTS_TGBatch.intersectionOfListProducts(productsResult,productCategoryFullProducts);
					}

					System.debug(logginglevel.Error, 'ProcessTG: Products Result for Scenario #3: ' + productsResult);
				}
				else if (isTGApplicable && !isTGLoopedIn && canOrderNonContractedProducts)
				{
					System.debug(logginglevel.Error, 'ProcessTG: Scenario #4: If the account is TGApplicable and TG LoopedIn and can order non contracted products ' +
						'Result = "Full price list" intersect "Category List full"');					
					// Scenario #4: If the account is TGApplication and TG LoopedIn and can order non contracted products
					// 1) Result = "Full price list" intersect "Category List full"
					List<Product2> productCategoryFullProducts = (productCategoryFull!=null)?(List<Product2>) productCategoryFull:null;					
					List<Product2> productsPLIListFullProducts = (productsPLIListFull!=null)?(List<Product2>) productsPLIListFull:null;
 					productsResult = productsPLIListFullProducts;
					if (productCategoryFull != null)
					{
						productsResult = APTS_TGBatch.intersectionOfListProducts(productsResult,productCategoryFullProducts);
					}
					// 2) Set TG Looped-in to true
					setTGLoopedIn(account, true);
					System.debug(logginglevel.Error, 'ProcessTG: Products Result for Scenario #4: ' + productsResult);
				}
				
				else if (isTGApplicable && isTGLoopedIn && canOrderNonContractedProducts)
				{
					System.debug(logginglevel.Error, 'ProcessTG: Scenario #5: If the account is TGApplicable and TGLoopedIn and can order non contracted products ' +
							'Result = ("Agreement list delta" Union "PLI List Delta" ) Intersect "Category List full"');
					// Scenario #5: If the account is TGApplicable and TGLoopedIn and can order non contracted products
					// 1) Result = ("Agreement list delta" Union "PLI List Delta" ) Intersect "Category List full"
					List<Product2> productsPLIListDeltaProducts = productsPLIListDelta;
					List<Product2> agreementListDeltaProducts = (productsAgreementListDeltaMap!=null)?(List<Product2>) productsAgreementListDeltaMap.get(account.Id):null;
					List<Product2> productCategoryFullProducts = (List<Product2>) productCategoryFull;					

					productsResult = APTS_TGBatch.unionOfListProducts(agreementListDeltaProducts,productsPLIListDeltaProducts);
					if (productCategoryFull != null)
					{
						productsResult = APTS_TGBatch.intersectionOfListProducts(productsResult,productCategoryFullProducts);	
					}
					System.debug(logginglevel.Error, 'ProcessTG: Products Result for Scenario #5: ' + productsResult);
				}
				// The account information and product result is stored in the map
				if (productsResult != null)
                {
					fullMapAccountProducts.put(account, productsResult);
					fullProductList.addAll(productsResult);
                }
			}
		}

		// The next step is to build the map of Agreement Line Items (info to be utilized in the construction of TG Records)		
		RecordType standardDeal = [SELECT Id, SobjectType, Name FROM RecordType WHERE SObjectType = 'Apttus__APTS_Agreement__c' AND Name = 'Standard Deal' LIMIT 1];
		// Map with Account Id and info from the Agreement
		Map<Id,  Apttus__APTS_Agreement__c> fullMapAccountAgreement = getAgreementListAllAgreement(accounts);

		System.debug(loggingLevel.error, 'FullMapAccountAgreement: ' + fullMapAccountAgreement);
		// Map with Account Id as Key, and Map of Product Id and ALI as value
		Map<Id, Map<Id,Apttus__AgreementLineItem__c>> fullMapAccountALIs = getAgreementListAllALI(accounts);
		
		// The next step is to build the map <Id of the product, Apttus_Config2__PriceListItem__c> to access PLI Information}
		List<Id> fullProductListIds = new List<Id>();
		for (Product2 prd: fullProductList)
		{
			fullProductListIds.add(prd.Id);
		}
		Map<Id,Apttus_Config2__PriceListItem__c> fullMapProductPLI = new Map<Id,Apttus_Config2__PriceListItem__c>();
		/*List<Apttus_Config2__PriceListItem__c> PLIs = [SELECT Id,Apttus_Config2__ProductId__c,APTS_Status__c,
														Apttus_Config2__PriceUom__c,Apttus_Config2__ListPrice__c
														FROM Apttus_Config2__PriceListItem__c
														WHERE Apttus_Config2__ProductId__c IN: fullProductListIds
														AND Apttus_Config2__PriceListId__c IN: priceListsIds
														AND Apttus_Config2__ProductId__r.Name != 'Category Product'];*/

		/******
			Defect #22323
			Date: 11/12/2018
			Author: Raul Orozco
		*******/
		List<Apttus_Config2__PriceListItem__c> PLIs = 
		[
			SELECT Id,Apttus_Config2__ProductId__c,APTS_Status__c,
			Apttus_Config2__PriceUom__c,Apttus_Config2__ListPrice__c
			FROM Apttus_Config2__PriceListItem__c
			WHERE Apttus_Config2__ProductId__c IN: fullProductListIds
			AND Apttus_Config2__PriceListId__c IN: priceListsIds
			AND Apttus_Config2__ProductId__r.Name != 'Category Product'
			AND (NOT(Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c LIKE '04%' OR Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c LIKE '0701%'))
		];

		System.debug(loggingLevel.error, 'PLIs:' + PLIs);
		for (Apttus_Config2__PriceListItem__c PLI: PLIs)
		{
			fullMapProductPLI.put(PLI.Apttus_Config2__ProductId__c,PLI);
		}
		Schema.DescribeFieldResult field = Apttus_Config2__PriceListItem__c.Apttus_Config2__PriceUom__c.getDescribe();
		Map<String,String> mapPicklist = new Map<String,String>();
		for (Schema.PicklistEntry f : field.getPicklistValues())
		{
			mapPicklist.put(f.getValue(), f.getLabel());
		}
		System.debug(loggingLevel.error, mapPicklist);
		// The next step is to build the list of TGRecords
		List<TGRecord> tgResults = new List<TGRecord>();
		System.debug(logginglevel.Error, 'ProcessTG: Ready to build TG Records');
		for (Account a : fullMapAccountProducts.keySet())
		{
			System.debug(loggingLevel.error, 'Account: ' + a);
			List<Product2> prds = (List<Product2>) fullMapAccountProducts.get(a);
			if (prds != null)
			{
				for (Product2 prd : prds)
				{
					if (prd.Name != 'Category Product')
					{
						System.debug(loggingLevel.error, 'Product: ' + prd);
						// access to the relevant records:
						// Agreement
						Apttus__APTS_Agreement__c agreement = fullMapAccountAgreement.get(a.Id);
						System.debug(logginglevel.error, 'Agreement: ' + agreement);
						// Agreement Line Item
						System.debug(logginglevel.Error, 'ProcessTG: fullMapAccountALIs: ' + fullMapAccountALIs);
						Map<Id,Apttus__AgreementLineItem__c> IdPrdALI= fullMapAccountALIs.get(a.Id);
						System.debug(loggingLevel.Error, 'IdPrdALI: ' + IdPrdALI);
						Apttus__AgreementLineItem__c ALI = fullMapAccountALIs.get(a.Id).get(prd.Id);
						System.debug(loggingLevel.Error, 'ALI: ' + ALI);
						// PLI
						Apttus_Config2__PriceListItem__c PLI = fullMapProductPLI.get(prd.Id);
						System.debug(loggingLevel.Error, 'PLI: ' + PLI);
						System.debug('PLI: ' + PLI);
						if (PLI != null)
						{
							// Creation of the record
							TGRecord record = new TGRecord();					
							// Account Number
							record.AccountNumber = a.SAP_Customer_ID__c;
							// Currency of the agreement
							record.currencyOfAgreement = agreement.CurrencyIsoCode;					
							// Transfer date
							record.transferDate = Date.TODAY();
							// Product
							record.ProductNumber = prd.ProductCode;
							// Status						
							record.Status = (PLI.APTS_Status__c!=null)?PLI.APTS_Status__c:'';
							// Comment
							string strComment = '';

							//Defect #22800
							List<Product2> specificAgreementListDelta = (productsAgreementListDeltaMap != null && productsAgreementListDeltaMap.containsKey(a.Id)) ? productsAgreementListDeltaMap.get(a.Id) : new List<Product2>();					
							if (productsPLIListDelta != null && productsPLIListDelta.contains(prd))
							{
								strComment = 'Updated Price';
							}
							else if (specificAgreementListDelta.contains(prd))
							{
								strComment = 'Updated CER';
							}
							else
							{
								strComment = 'Initial dataload';
							}
							record.comment = strComment;
							// UOM
							record.UOM = mapPicklist.get(PLI.Apttus_Config2__PriceUom__c);
							// Quantity, UOM & Net Price (fields that depend on CanOrderNonContractedProducts)
							Boolean canOrderNonContractedProductsValue = canOrderNonContractedProductsMap.get(a.Id);
							if (!canOrderNonContractedProductsValue)
							{						
								// APTS_GetPriceRest.GetPriceReturnObject ret = APTS_CERUtility.getPrice(a.Id);
								//Defect #22800
								if(ALI != null){
									record.netPrice = ALI.Apttus__NetPrice__c;						
									record.Quantity = ALI.Apttus__Quantity__c;
								}								
							}
							else
							{

								record.netPrice = PLI.Apttus_Config2__ListPrice__c;
								record.Quantity = 1;
							}
							tgResults.add(record);
						}
					}	
				}
			}
		}

		//Create error records
		if(lstErrorLogs.size() > 0){
			insert lstErrorLogs;
		}
		
		for (TGRecord record : tgResults)
		{
			System.debug(loggingLevel.error, 'TGRecord: ' + record);
		}
		return tgResults;
	}
}