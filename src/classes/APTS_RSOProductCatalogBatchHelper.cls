/*************************************************************
@Name: APTS_RSOProductCatalogBatchHelper
@Author: Raul Orozco
@CreateDate: 17-05-2018
@Description: Helper class for RSO Product Catalog batch. 
@UsedBy: APTS_RSOProductCatalogBatch
******************************************************************/
public without sharing class APTS_RSOProductCatalogBatchHelper {
	//String constants
	private static final String ROUTESALES = 'Routesales';
	private static final String DIRECT = 'Direct';
	private static final String OPERATING = 'Operating';

	public static void createRSOProductCatalogRecords(List<Apttus_Config2__PriceListItem__c> lstPLI){
		List<APTS_RSO_Product_Catalog__c> lstRecordsUpsert = new List<APTS_RSO_Product_Catalog__c>();
		List<APTS_Error_Object__c> lstErrorLogs = new List<APTS_Error_Object__c>();
		Set<String> setRegions = new Set<String>();
		Set<String> setProducts = new Set<String>();
		APTS_Sales_Org_Data__c tempSOD;
		String strExternalId;

		//Get the list of Regions and products
		for(Apttus_Config2__PriceListItem__c currentPLI : lstPLI){
			if(currentPLI.Apttus_Config2__PriceListId__r.APTS_Region__c != null){
				setRegions.add(currentPLI.Apttus_Config2__PriceListId__r.APTS_Region__c.remove('SAP_'));
			}
			
			if(currentPLI.Apttus_Config2__ProductId__c != null){
				setProducts.add(currentPLI.Apttus_Config2__ProductId__c);
			}
		}

		//Get Sales Org Data info
		List<APTS_Sales_Org_Data__c> lstSOD =
		[
			SELECT Id,
			APTS_Sales_Org_Data_Name__c,			
			APTS_Product__c,
			APTS_Product__r.ProductCode,
			APTS_Product__r.APTS_Sales_Catalog__c,
			tolabel(APTS_Product__r.Family),
			tolabel(APTS_Product__r.APTS_Product_Family2__c),
			tolabel(APTS_Product__r.APTS_Product_Family3__c),
			APTS_Selling_Unit__c,
			tolabel(APTS_Selling_Unit__c) UOM_Label
			FROM APTS_Sales_Org_Data__c
			WHERE APTS_Product__c IN :setProducts
			AND APTS_Sales_Org_Data_Name__c IN :setRegions
		];

		//Create SOD map
		Map<String,APTS_Sales_Org_Data__c> mapSOD = new Map<String,APTS_Sales_Org_Data__c>();

		for(APTS_Sales_Org_Data__c currentSOD : lstSOD){
			mapSOD.put(currentSOD.APTS_Product__c + '-' + 'SAP_' + currentSOD.APTS_Sales_Org_Data_Name__c, currentSOD);
		}

		//Loop through PLI records
		for(Apttus_Config2__PriceListItem__c currentPLI : lstPLI){
			//Find the corresponding SOD record
			tempSOD = mapSOD.get(currentPLI.Apttus_Config2__ProductId__c + '-' + currentPLI.Apttus_Config2__PriceListId__r.APTS_Region__c);

			if(tempSOD != null){
				if(currentPLI.Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c == ROUTESALES){
				
					strExternalId = tempSOD.APTS_Product__c + tempSOD.APTS_Sales_Org_Data_Name__c + ROUTESALES;

					lstRecordsUpsert.add(
							new APTS_RSO_Product_Catalog__c(
								APTS_Product__c = tempSOD.APTS_Product__c,
								APTS_Type__c = ROUTESALES,
								APTS_Product_Code__c = tempSOD.APTS_Product__r.ProductCode,
								APTS_Region__c = 'SAP_' + tempSOD.APTS_Sales_Org_Data_Name__c,
								APTS_RSO_External_Id__c = strExternalId,
								APTS_Selling_UOM__c = (String)tempSOD.get('UOM_Label'),
								APTS_Category_Text__c = lastHierarchyLevel(tempSOD.APTS_Product__r.Family),
								APTS_Sub_Category_Text__c = lastHierarchyLevel(tempSOD.APTS_Product__r.APTS_Product_Family2__c),
								APTS_Sub_Sub_Category_Text__c = lastHierarchyLevel(tempSOD.APTS_Product__r.APTS_Product_Family3__c),
								APTS_Price_List_Item__c = currentPLI.Id,
								APTS_Sales_Org_Data__c = tempSOD.Id

							)
					);
				}else if(currentPLI.Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c == DIRECT){

					

					if(
						tempSOD.APTS_Product__r.APTS_Sales_Catalog__c != null && 
						(
							tempSOD.APTS_Product__r.APTS_Sales_Catalog__c.startsWith('01') ||
							tempSOD.APTS_Product__r.APTS_Sales_Catalog__c.startsWith('02') ||
							tempSOD.APTS_Product__r.APTS_Sales_Catalog__c.startsWith('03')
						)
					){
						strExternalId = tempSOD.APTS_Product__c + tempSOD.APTS_Sales_Org_Data_Name__c + OPERATING;

						lstRecordsUpsert.add(
							new APTS_RSO_Product_Catalog__c(
								APTS_Product__c = tempSOD.APTS_Product__c,
								APTS_Type__c = OPERATING,
								APTS_Product_Code__c = tempSOD.APTS_Product__r.ProductCode,
								APTS_Region__c = 'SAP_' + tempSOD.APTS_Sales_Org_Data_Name__c,
								APTS_RSO_External_Id__c = strExternalId,
								APTS_Selling_UOM__c = (String)tempSOD.get('UOM_Label'),
								APTS_Category_Text__c = lastHierarchyLevel(tempSOD.APTS_Product__r.Family),
								APTS_Sub_Category_Text__c = lastHierarchyLevel(tempSOD.APTS_Product__r.APTS_Product_Family2__c),
								APTS_Sub_Sub_Category_Text__c = lastHierarchyLevel(tempSOD.APTS_Product__r.APTS_Product_Family3__c),
								APTS_Price_List_Item__c = currentPLI.Id,
								APTS_Sales_Org_Data__c = tempSOD.Id
							)
						);
					}
				}
			}
		}

		//Upsert records
		if(lstRecordsUpsert.size() > 0){
			Schema.SObjectField ftoken = APTS_RSO_Product_Catalog__c.Fields.APTS_RSO_External_Id__c;
			List<Database.upsertResult> urList = Database.upsert(lstRecordsUpsert,ftoken,false);

			// Iterate through each returned result
			for (Database.UpsertResult ur : urList) {
			    if (ur.isSuccess()) {
			        if(ur.isCreated()){
			        	// Operation was successful, so get the ID of the record that was processed
			        	System.debug('Successfully created RSO. RSO Id: ' + ur.getId());
		        	}else{
		        		// Operation was successful, so get the ID of the record that was processed
			        	System.debug('Successfully updated RSO. RSO Id: ' + ur.getId());
		        	}			        
			    }
			    else {
			        // Operation failed, so get all errors                
			        for(Database.Error err : ur.getErrors()) {
			            System.debug('The following error has occurred.');                    
			            System.debug(err.getStatusCode() + ': ' + err.getMessage());
			            System.debug('RSO fields that affected this error: ' + err.getFields());

			            lstErrorLogs.add(new APTS_Error_Object__c(
                                    APTS_Error_Date__c = System.today(),
                                    APTS_Error_Description__c = 'Error upsert RSO',
                                    APTS_Error_Level__c = 'Error',
                                    APTS_Error_Name__c = 'DML Error',
                                    APTS_Parent_ID__c = ur.getId(),
                                    APTS_Stream__c = 'CLM',
                                    APTS_Parent_Object_Name__c = 'APTS_RSO_Product_Catalog__c',
                                    APTS_Description_Of_Error__c = err.getStatusCode() + ': ' + err.getMessage()
                                  ));
			        }
			    }
			}
		}

		//Log errors
		if(lstErrorLogs.size() > 0){
			insert lstErrorLogs;
		}
	}

	public static String lastHierarchyLevel(String hierarchy){		
		String level = '';

		if(String.isNotEmpty(hierarchy)){
			List<String> splitString = hierarchy.split('\\|');

			if(splitString.size() == 1){
				level = splitString[0];
			}else if(splitString.size() == 2){
				level = splitString[1];
			}else if(splitString.size() == 3){
				level = splitString[2];
			}else if(splitString.size() > 3){
				level = splitString[2] + '|' + splitString[3];
			}
		}	

		return level;
	}

	public static void createRoutesalesRecords(List<APTS_RSO_Product_Catalog__c> lstRSO){
		//List of variables
		Set<String> setRegions = new Set<String>();
		Set<String> setExternalIds = new Set<String>();
		Set<String> setExternalIdsRoutesales = new Set<String>();
		List<APTS_Error_Object__c> lstErrorLogs = new List<APTS_Error_Object__c>();
		List<APTS_RSO_Product_Catalog__c> lstRSOCloned = new List<APTS_RSO_Product_Catalog__c>();
		APTS_RSO_Product_Catalog__c tempRSORecord = new APTS_RSO_Product_Catalog__c();

		//Get regions list
		for(APTS_RSO_Product_Catalog__c currentRSO : lstRSO){
			setRegions.add(currentRSO.APTS_Region__c);
			setExternalIds.add(currentRSO.APTS_RSO_External_Id__c);
		}

		List<Apttus_Config2__PriceList__c> lstPL =
		[
			SELECT Id,
			APTS_Region__c,
			APTS_PriceList_Type__c
			FROM Apttus_Config2__PriceList__c
			WHERE APTS_Region__c IN :setRegions
			AND APTS_PriceList_Type__c = 'Routesales'
		];

		//Set with regions that have a Routesales PL
		Set<String> setRegionsRoutesales = new Set<String>();

		for(Apttus_Config2__PriceList__c currentPL : lstPL){
			setRegionsRoutesales.add(currentPL.APTS_Region__c);
		}

		//Change external ids to Routesales ones
		for(String currentId : setExternalIds){
			setExternalIdsRoutesales.add(currentId.replace('Operating','Routesales'));
		}

		//Get list of Routesales records
		List<APTS_RSO_Product_Catalog__c> lstRSORoutesales = 
		[ 
			SELECT Id,
			APTS_RSO_External_Id__c 
			FROM APTS_RSO_Product_Catalog__c
			WHERE APTS_RSO_External_Id__c IN :setExternalIdsRoutesales 
			AND APTS_Cloned_Operating__c = false
		];

		//Create a set with the External ids of related Routesales records existent
		Set<String> setRoutesalesCreated = new Set<String>();

		for(APTS_RSO_Product_Catalog__c currentRSO : lstRSORoutesales){
			setRoutesalesCreated.add(currentRSO.APTS_RSO_External_Id__c);
		}

		system.debug(LoggingLevel.Error,'setRegions::::::' + JSON.serializepretty(setRegions));

		system.debug(LoggingLevel.Error,'setRoutesalesCreated::::::' + JSON.serializepretty(setRoutesalesCreated));

		//Loop through RSO records
		for(APTS_RSO_Product_Catalog__c currentRSO : lstRSO){
			system.debug(LoggingLevel.Error,'currentRSO::::::' + JSON.serializepretty(currentRSO));
			//Check if a related Routesales record exists
			if(!setRoutesalesCreated.contains(currentRSO.APTS_RSO_External_Id__c.replace('Operating','Routesales'))){
				//Check if the a Routesales PL exists for the Region
				if(!setRegionsRoutesales.contains(currentRSO.APTS_Region__c)){
					//Create cloned record, change type to Routesales, clean PLI field, change External Id, cloned operating = true
					tempRSORecord = currentRSO.clone(false,true,false,false);
					tempRSORecord.APTS_Type__c = ROUTESALES;
					tempRSORecord.APTS_Price_List_Item__c = null;
					tempRSORecord.APTS_RSO_External_Id__c = currentRSO.APTS_RSO_External_Id__c.replace('Operating','Routesales');
					tempRSORecord.APTS_Cloned_Operating__c = true;
					lstRSOCloned.add(tempRSORecord);
				}
			}
		}

		system.debug(LoggingLevel.Error,'List of records::::::' + JSON.serializepretty(lstRSOCloned));

		//Upsert newly created records
		if(!lstRSOCloned.isEmpty()){
			Schema.SObjectField ftoken = APTS_RSO_Product_Catalog__c.Fields.APTS_RSO_External_Id__c;
			List<Database.upsertResult> urList = Database.upsert(lstRSOCloned,ftoken,false);

			// Iterate through each returned result
			for (Database.UpsertResult ur : urList) {
			    if (ur.isSuccess()) {
			        if(ur.isCreated()){
			        	// Operation was successful, so get the ID of the record that was processed
			        	System.debug('Successfully created RSO. RSO Id: ' + ur.getId());
		        	}else{
		        		// Operation was successful, so get the ID of the record that was processed
			        	System.debug('Successfully updated RSO. RSO Id: ' + ur.getId());
		        	}			        
			    }
			    else {
			        // Operation failed, so get all errors                
			        for(Database.Error err : ur.getErrors()) {
			            System.debug('The following error has occurred.');                    
			            System.debug(err.getStatusCode() + ': ' + err.getMessage());
			            System.debug('RSO fields that affected this error: ' + err.getFields());

			            lstErrorLogs.add(new APTS_Error_Object__c(
                                    APTS_Error_Date__c = System.today(),
                                    APTS_Error_Description__c = 'Error upsert RSO, Routesales method',
                                    APTS_Error_Level__c = 'Error',
                                    APTS_Error_Name__c = 'DML Error',
                                    APTS_Parent_ID__c = ur.getId(),
                                    APTS_Stream__c = 'CLM',
                                    APTS_Parent_Object_Name__c = 'APTS_RSO_Product_Catalog__c',
                                    APTS_Description_Of_Error__c = err.getStatusCode() + ': ' + err.getMessage()
                                  ));
			        }
			    }
			}
		}

		//Log errors
		if(lstErrorLogs.size() > 0){
			insert lstErrorLogs;
		}
	}
}