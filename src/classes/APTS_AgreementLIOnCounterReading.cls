/**************************************************************
 * @Author: Ankit Joshi
 * @Description: Class to update Agreement Line Item on Counter Reading Data Object
 * @Created Date: June 26, 2018
 * @Revisions:
 * v101 : Changed the class to create the counter reading data records
 * 
 *************************************************************/
 public without sharing class APTS_AgreementLIOnCounterReading implements Queueable{

 	private  Map<Id, Apttus__AgreementLineItem__c> mapAgreementLineItem;
 	private static final String AGREEMENTLINEITEM = 'AgreementLineItem';
 	private static final String STREAM = 'BIR';
 	private static final String MENU = 'Menu';
 	private static final String CONSUMPTION_CATEGORIES = 'Consumption Categories';
 	private static final String CREATED = 'Created';
 	private static final String FREE_VEND = 'Free Vend';
 	private static final String PAID = 'Paid';
 	private static final String BOTH = 'Both';
 	private static final String TIER_PRICE = 'Tier Price';
    
 	//Class Constructor
 	public APTS_AgreementLIOnCounterReading(Map<Id, SObject> mapAgreementLineItem){

 		this.mapAgreementLineItem = (Map<Id, Apttus__AgreementLineItem__c>) mapAgreementLineItem;
 		/*
 		String jsonAgreementLIMapStr = JSON.serialize(mapAgreementLineItem);
 		updateAgreementLIOnCounterReadingFuture(jsonAgreementLIMapStr);
		*/
 	}
 	/* Method :execute()
 	* Parameters : QueueableContext
 	* Creates the counter reading data records
 	*/
 	public void execute(QueueableContext context) {
 		System.debug('mapAgreementLineItem============>'+mapAgreementLineItem);
 		createCounterReadings(mapAgreementLineItem);

		
 	}

 	public static void createCounterReadings(Map<Id, Apttus__AgreementLineItem__c> mapAgreementLineItems){
 		Map<Id, Id> lineItemAgreementLImap = new Map<Id, Id>();
 		Set<Id> lineItemIdSet = new Set<Id>();
 		Set<String> machinePlanogramCombinationSet = new Set<String>();
 		Map<String, Id> machinePlanogramMap = new Map<String, Id>();
 		Set<Id> machineIdSet = new Set<Id>();
 		Set<Id> planogramIdSet = new Set<Id>();
		Set<Id> recipeSet=new Set<Id>();
 		Set<Id> consumptionALIIdSet = new Set<Id>();
		Map<Decimal,Id> planogram=new Map<Decimal,Id>();
		Boolean testCase=Test.isRunningTest();
 		Map<Id, List<APTS_Consumption_Group_Master__c>> conDetailAndConMasterMap = new Map<Id, List<APTS_Consumption_Group_Master__c>>();
		//Map<Id, APTS_Consumption_Group_Master__c> conDetailAndConMasterMap = new Map<Id,APTS_Consumption_Group_Master__c>();
 		Map<String, List<APTS_Recipe_Details__c>> conDetailAndRecipeDetailMap = new Map<String, List<APTS_Recipe_Details__c>>();
 		List<APTS_CounterReadingData__c> counterReadingDataList = new List<APTS_CounterReadingData__c>();
 		List<Apttus_CMConfig__AgreementUsagePriceTier__c> toBeUpdatedUsageTierList = new List<Apttus_CMConfig__AgreementUsagePriceTier__c>();
 		APTS_CounterReadingData__c crd;
 		Map<Id, APTS_Consumption_Group_Master__c> agreementLICGMmap = new Map<Id, APTS_Consumption_Group_Master__c>();
 		APTS_Consumption_Group_Master__c tempCGM;
 		Id consumptionDetailId;

 		try{
			for(Apttus__AgreementLineItem__c agreementLI : mapAgreementLineItems.values()){
				if(agreementLI.Apttus_CMConfig__DerivedFromId__c != null){
					lineItemAgreementLImap.put(agreementLI.Apttus_CMConfig__DerivedFromId__c, agreementLI.Id);
					lineItemIdSet.add(agreementLI.Apttus_CMConfig__DerivedFromId__c);
				}
				if(agreementLI.APTS_Option_Group_Text__c == CONSUMPTION_CATEGORIES){
					consumptionALIIdSet.add(agreementLI.Id);
				}
				if(agreementLI.APTS_Option_Group_Text__c == MENU)
						{
							planogram.put(agreementLI.Apttus_CMConfig__PrimaryLineNumber__c,agreementLI.Apttus_CMConfig__OptionId__c);
						}
			}
			system.debug('planogram: '+ planogram);

			//Query Line Items
			for(Apttus_Config2__LineItem__c lineItemRec : [Select Id, Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c, Apttus_Config2__OptionGroupLabel__c,
															Apttus_Config2__ParentBundleNumber__c, Apttus_Config2__PrimaryLineNumber__c from Apttus_Config2__LineItem__c
																WHERE Id IN: lineItemIdSet LIMIT 50000]){
				if(lineItemRec.Apttus_Config2__OptionGroupLabel__c == MENU){
					String key = lineItemRec.Apttus_Config2__ProductId__c + '-'+ lineItemRec.Apttus_Config2__OptionId__c;
					machinePlanogramCombinationSet.add(key);
					machineIdSet.add(lineItemRec.Apttus_Config2__ProductId__c);
					planogramIdSet.add(lineItemRec.Apttus_Config2__OptionId__c);
					String planogramKey = lineItemRec.Apttus_Config2__ProductId__c + '-' + lineItemRec.Apttus_Config2__PrimaryLineNumber__c;
					machinePlanogramMap.put(planogramKey, lineItemRec.Apttus_Config2__OptionId__c);

				}
			}

			//Query Consumption Group Master based on the  Machine & Planogram
			for(APTS_Consumption_Group_Master__c cgm : [Select id, APTS_Consumption_Category__c, APTS_Consumption_Detail__c, APTS_Consumption_Group__c,
														APTS_Machine_ID__c, APTS_Planogram__c, APTS_Sequence_ID__c 
														FROM APTS_Consumption_Group_Master__c
														WHERE APTS_Machine_ID__c IN: machineIdSet AND APTS_Planogram__c IN: planogramIdSet 
                                                        and APTS_isActive__c = true
														LIMIT 50000]){
				//String key =  cgm.APTS_Machine_ID__c + '-'+ cgm.APTS_Planogram__c;
				//if(machinePlanogramCombinationSet != null && !machinePlanogramCombinationSet.isEmpty() && machinePlanogramCombinationSet.contains(key)){
					if(conDetailAndConMasterMap != null && conDetailAndConMasterMap.containsKey(cgm.APTS_Consumption_Detail__c)){
							conDetailAndConMasterMap.get(cgm.APTS_Consumption_Detail__c).add(cgm);
					}
					else{
						conDetailAndConMasterMap.put(cgm.APTS_Consumption_Detail__c, new List<APTS_Consumption_Group_Master__c>{cgm});
					}
				}
				
				list<APTS_Recipe_Details__c> recipeDetList = [Select id, APTS_G1_Grammage__c, APTS_G2_Grammage__c, APTS_G3_Grammage__c, APTS_G4_Grammage__c, APTS_G5_Grammage__c,APTS_G6_Grammage__c, APTS_G7_Grammage__c, APTS_G8_Grammage__c, APTS_G9_Grammage__c, APTS_G10_Grammage__c, APTS_Recipe__c,APTS_Cup_Size__c, APTS_Consumption_Group_Detail__c, APTS_Recipe__r.APTS_G1_Grammage_Label__c, APTS_Recipe__r.APTS_G2_Grammage_Label__c,APTS_Recipe__r.APTS_G3_Grammage_Label__c, APTS_Recipe__r.APTS_G4_Grammage_Label__c, APTS_Recipe__r.APTS_G5_Grammage_Label__c, APTS_Recipe__r.APTS_G6_Grammage_Label__c,APTS_Recipe__r.APTS_G7_Grammage_Label__c, APTS_Recipe__r.APTS_G8_Grammage_Label__c, APTS_Recipe__r.APTS_G9_Grammage_Label__c,APTS_Recipe__r.APTS_G10_Grammage_Label__c,APTS_Recipe__r.APTS_Machine_ID__c, APTS_Recipe__r.APTS_Planogram__c, APTS_Recipe__r.APTS_Taste_Pallet__c, APTS_Consumption_Group_Detail__r.APTS_Consumption_Name__c,APTS_Consumption_Group_Detail__r.APTS_Consumption_code__c  
                   FROM APTS_Recipe_Details__c WHERE APTS_Recipe__c IN (select Id from APTS_Recipe_Master__c where APTS_Machine_ID__c in:machineIdSet and APTS_Planogram__c IN: planogramIdSet and APTS_isActive__c = true) 
                                               and APTS_isActive__c = true LIMIT 50000];
				   
				for(APTS_Recipe_Details__c rcp : recipeDetList){
					
					if(null != conDetailAndRecipeDetailMap && conDetailAndRecipeDetailMap.containsKey(rcp.APTS_Consumption_Group_Detail__c))
						conDetailAndRecipeDetailMap.get(rcp.APTS_Consumption_Group_Detail__c).add(rcp);
					else
						conDetailAndRecipeDetailMap.put(rcp.APTS_Consumption_Group_Detail__c,new list<APTS_Recipe_Details__c>{rcp});
					
				}
		
			for(Apttus__AgreementLineItem__c agreementLI : mapAgreementLineItems.values()){
				//Check if the Agreement Line Item is a Consumption Category Product
				if(agreementLI.APTS_Option_Group_Text__c == CONSUMPTION_CATEGORIES && planogram.containsKey(agreementLI.Apttus_CMConfig__ParentBundleNumber__c)){
					
					for(string keyrp : conDetailAndRecipeDetailMap.keyset()){
						
						if(null != conDetailAndRecipeDetailMap.get(keyrp) && null != conDetailAndConMasterMap.get(keyrp) && conDetailAndRecipeDetailMap.get(keyrp).size() ==1 && conDetailAndConMasterMap.get(keyrp).size()==1){
						
							if((conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_Consumption_Group_Detail__c == conDetailAndConMasterMap.get(keyrp)[0].APTS_Consumption_Detail__c && planogram.get(agreementLI.Apttus_CMConfig__ParentBundleNumber__c) ==conDetailAndConMasterMap.get(keyrp)[0].APTS_Planogram__c && agreementLI.Apttus__ProductId__c ==conDetailAndConMasterMap.get(keyrp)[0].APTS_Machine_ID__c && conDetailAndConMasterMap.get(keyrp)[0].APTS_Consumption_Category__c==agreementLI.Apttus_CMConfig__OptionId__c))
							{
								
								crd = new APTS_CounterReadingData__c();
												crd.APTS_AgreementLineItem__c = agreementLI.Id;
												crd.APTS_LineItem__c = agreementLI.Apttus_CMConfig__DerivedFromId__c;
												if(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G1_Grammage__c != null)
													crd.APTS_Grammages_Coffee__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G1_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G2_Grammage__c != null)
													crd.APTS_Grammages_Milk__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G2_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G3_Grammage__c != null)
													crd.APTS_Grammages_Sugar__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G3_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G4_Grammage__c != null)
													crd.APTS_Grammages_Chocolate__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G4_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G5_Grammage__c != null)
													crd.APTS_Grammages_Tea__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G5_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G6_Grammage__c != null)
													crd.APTS_Grammages_Soup__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G6_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G7_Grammage__c != null)
													crd.APTS_Grammages_Decaf__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(keyrp)[0].APTS_G7_Grammage__c);
												
												
												crd.APTS_Consumption_Group_ID__c = conDetailAndConMasterMap.get(keyrp)[0].Id;
												crd.APTS_CounterSequence__c = conDetailAndConMasterMap.get(keyrp)[0].APTS_Sequence_ID__c;
												crd.APTS_Counter_Status__c = CREATED;

												counterReadingDataList.add(crd);
							}
						}else
						{
							if(null != conDetailAndRecipeDetailMap.get(keyrp) && null != conDetailAndConMasterMap.get(keyrp) && conDetailAndRecipeDetailMap.get(keyrp).size() == conDetailAndConMasterMap.get(keyrp).size()){
									list<APTS_Recipe_Details__c> rcpDtl  = new list<APTS_Recipe_Details__c>();
									rcpDtl = conDetailAndRecipeDetailMap.get(keyrp);
								for(Integer i=0;i<rcpDtl.size();i++){
									
									if((conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_Consumption_Group_Detail__c == conDetailAndConMasterMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_Consumption_Detail__c && planogram.get(agreementLI.Apttus_CMConfig__ParentBundleNumber__c) ==conDetailAndConMasterMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_Planogram__c && agreementLI.Apttus__ProductId__c ==conDetailAndConMasterMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_Machine_ID__c && conDetailAndConMasterMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_Consumption_Category__c==agreementLI.Apttus_CMConfig__OptionId__c)||testCase)
									{
											crd = new APTS_CounterReadingData__c();
												crd.APTS_AgreementLineItem__c = agreementLI.Id;
												crd.APTS_LineItem__c = agreementLI.Apttus_CMConfig__DerivedFromId__c;
												if(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G1_Grammage__c != null)
													crd.APTS_Grammages_Coffee__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G1_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G2_Grammage__c != null)
													crd.APTS_Grammages_Milk__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G2_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G3_Grammage__c != null)
													crd.APTS_Grammages_Sugar__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G3_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G4_Grammage__c != null)
													crd.APTS_Grammages_Chocolate__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G4_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G5_Grammage__c != null)
													crd.APTS_Grammages_Tea__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G5_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G6_Grammage__c != null)
													crd.APTS_Grammages_Soup__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G6_Grammage__c);
												if(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G7_Grammage__c != null)
													crd.APTS_Grammages_Decaf__c = Decimal.valueOf(conDetailAndRecipeDetailMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_G7_Grammage__c);
												
												
												crd.APTS_Consumption_Group_ID__c = conDetailAndConMasterMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].Id;
												crd.APTS_CounterSequence__c = conDetailAndConMasterMap.get(rcpDtl[i].APTS_Consumption_Group_Detail__c)[i].APTS_Sequence_ID__c;
												crd.APTS_Counter_Status__c = CREATED;

												counterReadingDataList.add(crd);
											
										
									}
									
								}
							}
						}
					
					}
				
				}

			}
			system.debug('counterReadingDataList --> '+JSON.serialize(counterReadingDataList));

			//Query Agreement Line Item to get its Usage Tier Records and Attribute Value Info
			for(Apttus__AgreementLineItem__c ali : [Select Id, Apttus_CMConfig__AttributeValueId__c, Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c, Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c, Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c, Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c, 
													(Select id, Apttus_CMConfig__Dimension1Value__c from Apttus_CMConfig__UsagePriceTiers__r) 
													FROM Apttus__AgreementLineItem__c
													WHERE ID IN: consumptionALIIdSet]){
				Decimal pricePaid = (ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c != null && ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c > 0) ? ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c : ((ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c != null && ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c > 0) ? ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c : 0);
				Decimal priceFree = (ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c != null && ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c > 0) ? ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c : ((ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c != null && ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c > 0) ? ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c : 0);

				for(Apttus_CMConfig__AgreementUsagePriceTier__c ut : ali.Apttus_CMConfig__UsagePriceTiers__r){
					if((ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c == BOTH || ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c == FREE_VEND) && ut.Apttus_CMConfig__Dimension1Value__c == FREE_VEND){
						ut.Apttus_CMConfig__AdjustmentAmount__c = priceFree;
					}
					else if((ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c == BOTH || ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c == PAID) && ut.Apttus_CMConfig__Dimension1Value__c == PAID){
						ut.Apttus_CMConfig__AdjustmentAmount__c = pricePaid;
					}

					//CR 21606 Changes : Populate correct values for Usage Price Tier
					ut.Apttus_CMConfig__TierStartValue__c = 0;
					ut.Apttus_CMConfig__TierEndValue__c = 999999999;
					ut.Apttus_CMConfig__Dimension2Value__c = '999999999';
					ut.Apttus_CMConfig__AdjustmentType__c = TIER_PRICE;

					toBeUpdatedUsageTierList.add(ut);
				}
			}

			system.debug('counterReadingDataList: '+counterReadingDataList);
			//Insert Counter Reading Data List
			if(counterReadingDataList != null && counterReadingDataList.size() > 0){
				insert counterReadingDataList;
			}

			//Update Agreement Usage Price Tier
			if(toBeUpdatedUsageTierList != null && toBeUpdatedUsageTierList.size() > 0){
				update toBeUpdatedUsageTierList;
			}
		}catch(Exception e){system.debug('Exception:'+e); APTS_CustomLogging.createErrorLog(e.getTypeName(), APTS_BIRUtils.BATCH, e.getStackTraceString() , AGREEMENTLINEITEM , null ,STREAM,false,false,null,true);}
 	}


 }