/**
* @author        Rey Austral - Accenture
* @date          March 21, 2017
* @description   Methods that will send data to click software
* @revision(s)   6.1.2018 Paul Aguiling: KTS-1715 Added integration logic for service materials and required parts
*                6.25.2018 Paul Aguiling: KTS-1867 Mapping added of grouping indicator for potential roundtrip
*                7.27.2018 Paul Aguiling: KTS-2005 Service MAterial mapping for IsLabour added
*/
public without sharing class TS_ClickTaskCreateOrUpdate {
    
    //Karen Hung 19/2/2021 DOO-5166
    public static Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null]);
    public static Boolean surveySettingEnabled = false;

    public void executeTaskCreateUpdate(List<Integration_Log__c> updatableIlogList) {
        CustomLogging.push('executeTaskCreateUpdate', 'TS_ClickTaskCreateOrUpdate');
        String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();
        String CONST_WOLI_CHILD_CR_TYPE = 'Counter Reading';
        Set<Id> woliId = new Set<Id>();
        Map<Id,Integration_Log__c> iLogMap = new Map<Id,Integration_Log__c>();
        
        for (Integration_Log__c ilog : updatableIlogList) {
            woliId.add(ilog.Work_Order_Line_Item__c);
            iLogMap.put(ilog.Work_Order_Line_Item__c,ilog);  
        }
        
        List<WorkOrderLineItem> woliList = [SELECT Case__r.CaseNumber, EarlyStart__c,EndDate__c,StartDate__c,WorkOrder.AccountId,ExecutingEngineer__c,Case__r.Service_Hours__c,
                                            Case__r.Customer_Case_ID__c, //Karen Hung KTS-2266 16.10.2018
                                            JDECrockeryVolumeSize__c,PhysicalAsset__r.JDECrockeryVolumeSize__c, //Karen Hung ALM-22316 10.12.2018
                                            WorkOrderLineItemType__c,JDELineItemNumber__c , ExcludedEngineer__c,ExcludedEngineer__r.Name,RequiredEngineer__c, RequiredEngineer__r.Name,
                                            Status, Quantity,PreferredEngineer__c ,StairNeeded__c, ScheduleManually__c,CreatedDate , PreferredEngineer__r.Name,
                                            AssetLineItem__c, Part_Notes__c, WorkOrderType__c, IgnoreCalendar__c,
                                            AssetLineItem__r.Apttus_Config2__CancelledDate__c,AssetLineItem__r.Apttus_Config2__InitialActivationDate__c,
                                            PhysicalAsset__r.InitialActivationDate__c,
                                            AssetLineItem__r.Name,RelateTo__c, LatestAppointmentTime__c, LastVisitatCustomer__c, //AssetLineItem__r.EntitlementWTS__c,                                         
                                            Assetlineitem__r.Apttus_Config2__ProductId__r.ProductCode,
                                            SLADate__c,Warranty__c,RecipeSoftware__c, RecipeText__c,
                                            Case__r.OutsideSLA__c, Case__r.SubType__c, Movement__c,//ScheduledDate__c, //added by Archi
                                            ReturnTask__c, //added by AD 10 nov 2017
                                            AccountLocation__r.Apttus_Config2__PostalCode__c,AccountLocation__r.Custom_Service_Hours__c,
                                            AccountLocation__r.Apttus_Config2__City__c,
                                            ParentWorkOrderLineItemId,
                                            OP_PreferredOperator__c, //Karen Hung 1.28.19 KTS-2285
                                            OP_PreferredOperator__r.Name, //Karen Hung 1.28.19 KTS-2285
                                            FirstRoutesalesVisit__c, // used for routesales   
                                            /// otc dependent fields 
                                            AccountLocation__r.Shipping_Street_Only__c,
                                            EarliestAppointmentTime__c,WorkOrderId,//AlternativeMachine__c,
                                            PhysicalAsset__c,
                                            PhysicalAsset__r.NextWTSDate__c, //AssetLineItem__r.NextWTSDate__c,
                                            AccountLocation__r.Name, //KTS-2145 xen Reyes 8.31.2018
                                            AccountLocation__r.SAP_Customer_ID__c,//Case__r.Account.AccountNumber, // modified by Archi 5 sep 2017
                                            AccountLocation__r.Screening_Required__c,Case__r.ProjectNumber__c,Case__r.Contact.Communication_Preference__c,
                                            AccountLocation__r.Upfront_Call_Needed__c,PricebookEntry.Product2.Name,PricebookEntry.Product2.ProductCode,
                                            PhysicalAsset__r.DeInstallationDate__c, //AssetLineItem__r.APTS_De_installation_Date__c,
                                            PhysicalAsset__r.ResponseTime__c,PhysicalAsset__r.ResponseTimeS15__c,//Karen Hung Apr 24, 2019 KTS-2698 ALM 6864
                                            SerialNumber__c,Case__r.Priority,BookAppointmentFinish__c,BookAppointmentStart__c,
                                            //AssetLineItem__r.Asset_Details__c,
                                            LeaveMachineAtCustomer__c,
                                            PhysicalAsset__r.LastWTSdate__c, //AssetLineItem__r.LastWTSdate__c,
                                            PhysicalAsset__r.MachineLastServiceDate__c,
                                            DependentWOLIID__c,// disabled by Archi ExternalMovement__c,
                                            Case__r.Account.Key_Account__c,Case__r.RequiresCostEstimate__c, 
                                            Case__r.CustomerScheduleDate__c,
                                            PreventiveMaintenancePerformedDate__c, Case__r.Account.WSONE_DATA__UltimateParentLookup__r.Key_Account__c,
                                            PhysicalAsset__r.AgreementRecordType__c,
                                            PhysicalAsset__r.SerialNumber__c, //AssetLineItem__r.Serial_Number__c,
                                            PhysicalAsset__r.ProductCode__c, // added 16 may 2018
                                            PhysicalAsset__r.OP_LastPerformingOperator__r.Name,// added 16 may 2018
                                            PhysicalAsset__r.IncludesWTSCoverage__c, // added 16 may 2018
                                            PhysicalAsset__r.WarrantyEndDate__c, // added 16 may 2018
                                            PhysicalAsset__r.WTSChangedBy__c , // added 16 may 2018
                                            PhysicalAsset__r.CommercialUsage__c,// added 16 may 2018
                                            PhysicalAsset__r.CustomerReferenceNumber__c,// added 16 may 2018
                                            PhysicalAsset__r.ConfigurationManualAgreementsURL__c,PhysicalAsset__r.ConfigurationFileURL__c ,
                                            
                                            PremiumCustomer__c,
                                            RemoveScheduleRestrictions__c, //Karen Hung 13-03-2019 KTS-2661
                                            AccountLocation__r.Shipping_Country_ISO__c,AccountLocation__r.Shipping_State__c,AccountLocation__r.Shipping_City__c,AccountLocation__r.Shipping_Street__c ,
                                            AccountLocation__r.Shipping_PostalCode__c,
                                            Case__r.AccountLocation__r.Name, //Xen Reyes 
                                            PhysicalAsset__r.LastPreventiveMaintenanceDate__c, //AssetLineItem__r.LastPreventiveMaintenanceDate__c,
                                            PhysicalAsset__r.InstallationDate__c, //AssetLineItem__r.Install_Date__c,
                                            Case__r.Account.Name,
                                            Case__r.Contact.Name,Case__r.Contact.Phone,Case__r.Contact.Email,
                                            //Case__r.Calendar__c, // moved to woli
                                            Calendar__c,
                                            PhysicalAsset__r.ServiceWindow__c, //AssetLineItem__r.Apttus_Config2__AttributeValueId__r.Service_windows__c,
                                            PhysicalAsset__r.TypeOfContract__c, //AssetLineItem__r.APTS_Type_of_Contract__c,
                                            IsCoffeeRunning__c,//Case__r.CoffeeIsRunning__c,
                                            PhysicalAsset__r.EndDate__c, //AssetLineItem__r.Apttus_Config2__EndDate__c,
                                            //PhysicalAsset__r.WaterfilterCoverage__c, //AssetLineItem__r.Apttus_Config2__AttributeValueId__r.Waterfilter_change_covered__c,
                                            Case__r.Account.Owner.Name,Case__r.Contact.Preferred_Language__c,Case__r.RepeatVisit__c,SmokingArea__c,Subject,Description,Case__r.Account.Segment__c,
                                            PricebookEntry.Pricebook2.Sales_Organization__c,
                                            EstimatePartCost__c,EstimateMaterialCost__c,EstimateLabor__c,EstimateTotalCost__c,Case__r.Re_active__c
                                            , RequiresStopover__c,         // added by Archi 13 feb 2018                                
                                            ConnectivityModuleSerialNumber__c,
                                            PaymentModuleSerialNumber__c, //ADDED XEN 5/15
                                            Case__r.PotentialRoundTrip__c, //KTS-1867 6.25.2018 Added by Paul Jarred 
                                            GroupingIndicator__c, //KTS-1867 6.25.2018 Added by Paul Jarred 
                                            FaultConfiguration__r.ProductCode__c, //KTS-1783 6.26.2018 Added by Paul Jarred
                                            FaultConfiguration__r.Product__r.Name, //DOO-4739 07.17.2020 Francis Allen Alindogan
                                            PhysicalAsset__r.Area__c, Area__c, CustomerReference__c, //KTS-1777 10.7.2018 Xen Reyes
                                            PhysicalAsset__r.SparePartCoverage__c,  PhysicalAsset__r.CallOutChargeCoverage__c,  PhysicalAsset__r.LabourChargeCoverage__c, //KTS-1964 10.7.2018 Xen Reyes
                                            AccountLocation__r.Shipping_House_Number__c, PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, //XEN REYES 18.09.2018 KTS-2176
                                            DisasterRecovery__c, //XEN REYES 9.20.2018 KTS-2179
                                            Re_active__c, //KTS-2189 XEN REYES 9.22.2018
                                            OutsideSLA__c, //XEN REYES 10.31.2018
                                            SendCounterReadings__c, CountersS10loaded__c, //XEN REYES Nov. 19, 2018
                                            PhysicalAsset__r.AdditionalDetails__c, //XEN REYES Nov. 20, 2018
                                            Case__c, Case__r.CostIndicationAsDiscussed__c, //XEN REYES Nov. 20, 2018
                                            UseConfigurationURLFileinTask__c, ConfigurationFileURL__c, ConfigurationManualAgreementsURL__c,  //XEN REYES Jan. 14, 2019
                                            Building__c, Floor__c, //XEN REYES R3.1 March 22, 2019
                                            CompletionCode__c, FaultCode__c, FaultLocationCategory__c, DefectCode__c, WorkingOnSFDC__c, ExternalCompletionNote__c, //XEN REYES August 20, 2019 DOO-733
                                            Case__r.ResponseProfile__c, //XEN REYES Nov. 26, 2019 DOO-2885
                                            IntervalWTS__c, Id, //Francis Alindogan 01/21/2020 DOO-3522
                                            Click_Priority__c, //Francis Alindogan DOO-3907 03.05.2020
                                            Route_Name__c, Unique_Number__c, //Karen Hung DOO-4273 16.03.2020
                                            AccountLocation__r.Truck_Needed__c, //XEN REYES DOO-4305 Mar. 31, 2020
                                            AccountLocation__r.House_Number_Supplement__c, //XEN REYES DOO-4462 May 7, 2020
                                            Replace_WTS__c,
                                            Waterfilter_Suggestion__c, //Francis Allen Alindogan DOO-4689 07.21.2020
                                            TechnicalInspectionNeeded__c, //Francis Allen Alindogan DOO-4534 09.09.2020
                                            ResponseProfile__c //DOO - 4921 Francis Allen Alindogan 10.14.2020
                                            FROM WorkOrderLineItem WHERE Id IN: woliId];
       
        Set<Id> relateToIds = new Set<Id>();
        Set<Id> physicalIDset = new Set<Id>();
        Set<Id> accountLocationIdSet = new Set<Id>();
        
        Boolean sendCounterReadings = false;
        Boolean countersLoaded = true;

        for (WorkOrderLineItem orderLine : woliList) {
            if(orderLine.RelateTo__c != null){
                relateToIds.add(orderLine.RelateTo__c); //USED FOR RETURN NEEDED
            }          
            
            if(orderLine.PhysicalAsset__c != null){
                physicalIDset.add(orderLine.PhysicalAsset__c);//USED FOR MACHINE HISTORY 
            }

            //XEN REYES DOO-4542 June 22, 2020
            if(orderLine.AccountLocation__c != null){
                accountLocationIdSet.add(orderLine.AccountLocation__c);
            }
        } 

        //used when return is needed and used for sending Required Parts w/ Parent Task
        //KTS-1715: Updates include WorkOrderLineItemType__c = required parts by Paul Aguiling 6.1.2018
        //Karen Hung 21.05.2020 DOO-4559 added PricebookEntry.Product2.ProductCode  in query
        //DOO-4769 XEN REYES August 18, 2020 - Added Unit_Price__c && DirectToCustomer__c
        List<WorkOrderLineItem> requiredWorkOrderLineItemsList = [SELECT PriceBookEntryID, PricebookEntry.Product2.Name, PricebookEntry.Product2Id, Quantity, ParentWorkOrderLineItemId, PricebookEntry.Product2.ProductCode, UnitPrice, Unit_Price__c, DirectToCustomer__c FROM WorkOrderLineItem WHERE (WorkOrderLineItemType__c=: Label.TS_WOLI_Status_Missing AND ParentWorkOrderLineItemId IN:relateToIds)OR (ParentWorkOrderLineItemId IN:woliList AND WorkOrderLineItemType__c =:Label.TS_Type_ReqSpareparts)]; 

        //used for service material in fixed cost                                                                    
        List<WorkOrderLineItem> childWorkOrderLineItemsList = [Select PriceBookEntryID, PricebookEntry.Product2.Name,PricebookEntry.Product2Id,Quantity,ParentWorkOrderLineItemId , PricebookEntry.UnitPrice,
                                                                    Warranty__c,MaterialCost__c,SparePartCost__c,JDELineItemNumber__c,WorkOrderLineItemType__c,SerialNumber__c, IsLabour__c
                                                                    from WorkOrderLineItem where 
                                                                    WorkOrderLineItemType__c=: Label.TS_Type_Service 
                                                                    //And IsLabour__c=FALSE //7.31.2018 KTS-2005 Removed by Paul Aguiling
                                                                    AND ParentWorkOrderLineItemId IN: woliList
                                                                    AND IsReadyToSummarize__c = false]; //XEN REYES Dec. 12, 2018    
        //used for machine history                                                                         
        //DOO - 271 Xen Reyes June 5, 2019                                                                      
        List<String> nonMachineHistoryRequiredTask = new List<String>{Label.TS_Activity_Type_S20,Label.TS_Activity_Type_S21,Label.TS_Activity_Type_S22,Label.TS_Activity_Type_S25};
        List<WorkOrderLineItem> woliMachineHistoryList = [SELECT Id, JDELineItemNumber__c, EndDate__c, Part_Notes__c, WorkOrderType__c, ExecutingEngineer__c, WorkOrderLineItemType__c, PhysicalAsset__c,                                                   ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c FROM WorkOrderLineItem 
                                                          WHERE PhysicalAsset__c IN: physicalIDset 
                                                          AND WorkOrderLineItemType__c =: Label.TS_Type_Task
                                                          AND Status =: Label.TS_WOLI_Status_Completed
                                                          AND WorkOrderType__c NOT IN: nonMachineHistoryRequiredTask 
                                                          AND EndDate__c != null 
                                                          ORDER by EndDate__c 
                                                          DESC LIMIT 3];
        //used for counter reading                                                
        /* List<WorkOrderLineItem> woliCRList = [SELECT Id, JDELineItemNumber__c, ParentWorkOrderLineItemId,OP_CounterSequence__c, OP_UniquecounterID__c, OP_LastPaidCounterReading__c, OP_LastFreeVendingCounterReading__c,
                                               OP_LastReadingDate__c, OP_AverageFreeConsumptions__c,OP_AveragePaidConsumptions__c, OP_ConsumptionGroup__c
                                               FROM WorkOrderLineItem 
                                               WHERE ParentWorkOrderLineItemId IN: woliList  
                                               AND WorkOrderLineItemType__c = :CONST_WOLI_CHILD_CR_TYPE 
                                               AND RecordTypeId =:CONST_WOLI_CHILD_CR_RT 
                                               //AND ParentWorkOrderLineItem.WorkOrderType__c =:Label.TS_Activity_Type_S10                                                                                                
                                               ORDER BY OP_CounterSequence__c ASC]; */

        /* XEN REYES Nov. 19, 2018 */
        List<APTS_CounterReadingData__c> woliCRList = new List<APTS_CounterReadingData__c>();
        Map<Id, List<APTS_CounterReadingData__c>> assetCounterReadingRegularListMap = new Map<Id, List<APTS_CounterReadingData__c>>();
        //if(sendCounterReadings && !countersLoaded){
        
        /* XEN REYES Mar 12, 2019 
           Additional filter for the query */
        if(!physicalIDset.isEmpty()){
            //DOO-2646 KAREN HUNG ADDED APTS_PriceType__c for Machine CounterReadingPriceType
            woliCRList = [SELECT Id, APTS_PriceType__c, APTS_Counter_Description__c, APTS_Current_Reading_ValuePaid__c, APTS_Current_Reading_ValueFree__c, APTS_Current_Reading_Date__c, APTS_AvgConsumptionFree__c, APTS_AvgConsumptionPaid__c, APTS_CounterSequence__c, TS_Physical_Asset__c, APTS_CounterID__c FROM APTS_CounterReadingData__c WHERE TS_Physical_Asset__c IN: physicalIDset AND APTS_Counter_Status__c = 'Active' AND APTS_CounterId__c != null ORDER BY APTS_CounterSequence__c ASC];  
        }

        //XEN REYES DOO-4542 June 22, 2020
        Map<Id, List<OperatingHourAssociation__c>> accLoc_OHA_Map = new Map<Id, List<OperatingHourAssociation__c>>();
        if(!accountLocationIdSet.isEmpty()){
            List<OperatingHourAssociation__c> calendar_list = [SELECT Id, Name, TechnicalNameClose__c, TechnicalNameOpen__c, CustomServiceHours__c, CustomServiceHoursDescription__c, Account_Location__c, Active__c, BusinessUnit__c FROM OperatingHourAssociation__c WHERE Active__c = true AND BusinessUnit__c = 'TCS' AND Account_Location__c IN: accountLocationIdSet];
            
            if(!calendar_list.isEmpty()){
                for(OperatingHourAssociation__c oha_var : calendar_list){
                    if(accLoc_OHA_Map.containsKey(oha_var.Account_Location__c)){
                        accLoc_OHA_Map.get(oha_var.Account_Location__c).add(oha_var);
                    } else {
                        accLoc_OHA_Map.put(oha_var.Account_Location__c, new List<OperatingHourAssociation__c>{oha_var});
                    }
                }
            }
        }
        
        if(!woliCRList.isEmpty()){
            for(APTS_CounterReadingData__c aptscr : woliCRList){
                if(assetCounterReadingRegularListMap.containsKey(aptscr.TS_Physical_Asset__c)){
                    assetCounterReadingRegularListMap.get(aptscr.TS_Physical_Asset__c).add(aptscr);
                } else {
                    assetCounterReadingRegularListMap.put(aptscr.TS_Physical_Asset__c, new List<APTS_CounterReadingData__c>{aptscr});
                }
            }
        }

        Id recordTypeId =  TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGREQPART);
        Id recordTypeMachineId =  TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGMAC);
        Id recordTypeMissingPartId =  TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_RegMissPart);
        Id recordTypeServiceMatId =  TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_RegServMat);
        Id recordTypeTaskId =  TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGTASK);
        Id recordTypeUsedPartId =  TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGUSEDPART);

        for (WorkOrderLineItem woli : woliList) {
            JDEServicesCallout.TaskCreateOrUpdate_element elem = new JDEServicesCallout.TaskCreateOrUpdate_element();
            
             //-----------------Work Order Line Item Object Mapping-------------------------------------
            elem.RoundTripFlag = woli.Case__r != null? woli.Case__r.PotentialRoundTrip__c : false;
            elem.RoundTripDepTask = woli.GroupingIndicator__c;
            elem.CallID = woli.JDELineItemNumber__c;
            elem.WOLIID = woli.Id;
            elem.CaseId = woli.Case__r.CaseNumber; // used to allow Click engineer refer to the case number
            elem.TaskType = woli.WorkOrderType__c; //woli.WorkOrderLineItemType__c;                    
            elem.OpenDate = formatDateTime(woli.CreatedDate);            
            elem.SLA = formatDateTime(woli.SLADate__c);
            elem.WarrantyEndDate = formatDate(woli.PhysicalAsset__r.WarrantyEndDate__c);//added 16 may 2018
            elem.StopOver = woli.RequiresStopover__c;//added by Archi 13 feb 2018

            //XEN REYES 9.20.2018 KTS-2179
            elem.DisasterRecovery = woli.DisasterRecovery__c;

            //Karen Hung 16.10.2018 KTS-2266
            if(woli.Case__r != null && woli.Case__r.Customer_Case_ID__c != null){
                elem.DRCaseID = woli.Case__r.Customer_Case_ID__c;
            }

            //Karen Hung Apr 24, 2019 KTS-2698 ALM 6864
            /* if(woli.WorkOrderType__c == 'S10' && woli.PhysicalAsset__c != null){ //if workorder type is corrective maintenance/s10
                if(woli.PhysicalAsset__r.ResponseTime__c != null){
                    elem.ResponseTime = Integer.valueOf(woli.PhysicalAsset__r.ResponseTime__c);                
                }
            }else if(woli.WorkOrderType__c == 'S15' && woli.PhysicalAsset__c != null){ //if 1st Line Corrective Maintenance/s15 
                if(woli.PhysicalAsset__r.ResponseTimeS15__c != null){
                    elem.ResponseTime = Integer.valueOf(woli.PhysicalAsset__r.ResponseTimeS15__c);    
                }
            }*/

            //DOO - 4921 Francis Allen Alindogan 10.14.2020
            String selectedResponseProfile;
            if(woli.ReturnTask__c  == true){
                if(woli.ResponseProfile__c != null) selectedResponseProfile = woli.ResponseProfile__c;
            } 
            else {
                if(woli.Case__r.ResponseProfile__c != null) selectedResponseProfile = woli.Case__r.ResponseProfile__c;
            }

            //XEN REYES Nov. 26, 2019 DOO- 2885
            Map<String,Integer> eodMapPairing = new Map<String,Integer>{'EOD1'=> 91, 'EOD2'=> 92, 'EOD3'=> 93, 'EOD4'=> 94};
            if(woli.WorkOrderType__c == 'S10'){
                if(selectedResponseProfile != null){
                    if(eodMapPairing.containsKey(selectedResponseProfile)){
                        elem.ResponseTime = eodMapPairing.get(selectedResponseProfile);
                    } else {
                        elem.ResponseTime = Integer.valueOf(selectedResponseProfile);
                    }
                } else if (woli.PhysicalAsset__c != null){
                    if(woli.PhysicalAsset__r.ResponseTime__c != null) {
                        elem.ResponseTime = Integer.valueOf(woli.PhysicalAsset__r.ResponseTime__c);                
                    }
                }

                //Francis Allen Alindogan DOO-4534 09.09.2020
                elem.TechnicalSpecialistNeeded = woli.TechnicalInspectionNeeded__c;
                
            } else if (woli.WorkOrderType__c == 'S15'){
                if(selectedResponseProfile != null){
                    if(eodMapPairing.containsKey(selectedResponseProfile)){
                        elem.ResponseTime = eodMapPairing.get(selectedResponseProfile);
                    } else {
                        elem.ResponseTime = Integer.valueOf(selectedResponseProfile);
                    }
                } else if (woli.PhysicalAsset__c != null){
                    if(woli.PhysicalAsset__r.ResponseTimeS15__c != null){ 
                        elem.ResponseTime = Integer.valueOf(woli.PhysicalAsset__r.ResponseTimeS15__c);
                    }
                }
            }

            //Karen Hung 16.03.2020 DOO-4273 populate RouteName and RouteNumber
            if(woli.WorkOrderType__c == 'S15'){
                elem.RouteName = woli.Route_Name__c;
                elem.RouteNumber = woli.Unique_Number__c;

                //XEN REYES DOO-4305 Mar. 31, 2020
                elem.TruckNeeded = woli.AccountLocation__r.Truck_Needed__c;     
            }


            System.debug('elem.ResponseTime: ' + elem.ResponseTime);
            System.debug('woli.PhysicalAsset__r.ResponseTime__c: ' + woli.PhysicalAsset__r.ResponseTime__c);

            //Karen Hung 10.12.2018 ALM-22316
            /* if(TS_Constants.ORDER_S40.equals(woli.WorkOrderType__c) && woli.Case__c != null && 
                (TS_Constants.CASE_SUBTYPE_SWAP.equals(woli.Case__r.SubType__c) || TS_Constants.ORDER_S40.equals(woli.Case__r.SubType__c))){ //if workordertype and case subtype is Installation
                elem.RecipeCrockerySize = woli.JDECrockeryVolumeSize__c;
            } else if(woli.PhysicalAsset__c != null){             
                elem.RecipeCrockerySize = woli.PhysicalAsset__r.JDECrockeryVolumeSize__c;
            } */
            
            //XEN REYES 11.09.2018 - 19.09.2018
            //elem.Status = woli.Status;
            if (woli.Status == Label.TS_Status_Canceled || woli.Status == Label.TS_Status_Open || woli.Status == Label.TS_Status_Completed) {
                elem.Status = woli.Status;
            }

            //XEN REYES August 20, 2019 DOO-733
            if(woli.Status == Label.TS_Status_Completed && woli.WorkingOnSFDC__c){
                elem.CompletionCode1 = woli.CompletionCode__c;
                elem.CompletionCode2 = woli.FaultCode__c;
                elem.CompletionCode3 = woli.DefectCode__c;
                elem.FaultLocationCategory = woli.FaultLocationCategory__c;
                elem.CompletionNotes = woli.ExternalCompletionNote__c;
            }

            //XEN REYES Nov. 20, 2018
            if(woli.Case__c != null){
                elem.CostValueDiscussed = woli.Case__r.CostIndicationAsDiscussed__c;
            }

            elem.SmokingArea = woli.SmokingArea__c;
            elem.StairNeeded = woli.StairNeeded__c;
            elem.ManualSchedule = woli.ScheduleManually__c;
            //elem.ScheduleDate = formatDate(woli.ScheduledDate__c); //Archi 14-9-2017
            elem.ScheduleDate = formatDate(woli.Case__r.CustomerScheduleDate__c); //Archi 20-04-2018       
            elem.NotNeedCalendar = woli.IgnoreCalendar__c; //change ScheduletoRequiredEngineer__c from to IgnoreCalendar__c
            elem.WorkOrdeID = woli.WorkOrderId;
            //elem.RecordType = recordTypeId;//'0129E0000004ZkR';//woli.RecordTypeId;
            elem.EarlyStart = formatDateTime(woli.EarlyStart__c);//formatDateTime(woli.WorkOrder.EarliestAppointmentTime__c);

            elem.EstimatePartCost = woli.EstimatePartCost__c;
            elem.EstimateMaterialCost = woli.EstimateMaterialCost__c;
            elem.EstimateLabor = woli.EstimateLabor__c;
            elem.EstimateTotalCost = woli.EstimateTotalCost__c;
            
            if (!String.isBlank(woli.ExcludedEngineer__c)) {
                JDEServicesCallout.ExcludedEngineers_element excludedEngr = new JDEServicesCallout.ExcludedEngineers_element();
                excludedEngr.EngineerID = new List<String>();
                excludedEngr.EngineerID.add(woli.ExcludedEngineer__r.Name);
                elem.ExcludedEngineers = excludedEngr;
            }

             //Karen Hung 16.03.2020 DOO-4273 populate required / preferred engineer
            if (!String.isBlank(woli.RequiredEngineer__c)) {
                JDEServicesCallout.RequiredEngineers_element reqEngr = new JDEServicesCallout.RequiredEngineers_element();
                reqEngr.EngineerID = new List<String>();
                reqEngr.EngineerID.add(woli.RequiredEngineer__r.Name);
                elem.RequiredEngineers = reqEngr;
            }else if(!String.isBlank(woli.OP_PreferredOperator__c) && woli.WorkOrderType__c == 'S15'){ // populate only preferred if required is blank for s15
                JDEServicesCallout.PreferredEngineers_element prefEngr = new JDEServicesCallout.PreferredEngineers_element();
                prefEngr.EngineerID = new List<String>();
                prefEngr.EngineerID.add(woli.OP_PreferredOperator__r.Name);
                elem.PreferredEngineers = prefEngr;
            }

            //Karen Hung 1.18.19 KTS-2285 //populate preferred regardless of required engineer on non s15 
            if (!String.isBlank(woli.PreferredEngineer__c) && woli.WorkOrderType__c != 'S15' ) {
                JDEServicesCallout.PreferredEngineers_element prefEngr = new JDEServicesCallout.PreferredEngineers_element();
                prefEngr.EngineerID = new List<String>();
                prefEngr.EngineerID.add(woli.PreferredEngineer__r.Name);
                elem.PreferredEngineers = prefEngr;
            }

            //XR 10.7.2018 KTS-1777
            if(woli.Case__r.SubType__c == 'S40' || woli.Case__r.SubType__c == 'Movement'){
                elem.MachineArea = woli.Area__c != null ? woli.Area__c.left(64) : ''; //Karen Hung May 7, 2019 DOO-57 trim to 64 char
                elem.IntCustomerReference = woli.CustomerReference__c != null ? woli.CustomerReference__c.left(128) : ''; //DOO-2633 KAREN HUNG 28.10.2019 ALIGN LENGTH WITH CLICK - 128 char

                /* XEN REYES R3.1 March 22, 2019 */
                elem.Building = woli.Building__c != null ? woli.Building__c.left(64) : ''; //Karen Hung May 7, 2019 DOO-57 trim to 64 char
                elem.Floor = woli.Floor__c != null ? woli.Floor__c.left(64) : ''; //Karen Hung May 7, 2019 DOO-57 trim to 64 char

            } else if(woli.PhysicalAsset__c != null){
                elem.MachineArea = woli.PhysicalAsset__r.Area__c != null ? woli.PhysicalAsset__r.Area__c.left(64) : ''; //Karen Hung May 7, 2019 DOO-57 trim to 64 char
                elem.IntCustomerReference = woli.PhysicalAsset__r.CustomerReferenceNumber__c != null ? woli.PhysicalAsset__r.CustomerReferenceNumber__c.left(128) : ''; //DOO-2633 KAREN HUNG 28.10.2019 ALIGN LENGTH WITH CLICK - 128 char

                /* XEN REYES R3.1 March 22, 2019 */
                elem.Building = woli.PhysicalAsset__r.Building__c != null ? woli.PhysicalAsset__r.Building__c.left(64) : ''; //Karen Hung May 7, 2019 DOO-57 trim to 64 char
                elem.Floor =  woli.PhysicalAsset__r.Floor__c != null ? woli.PhysicalAsset__r.Floor__c.left(64) : ''; //Karen Hung May 7, 2019 DOO-57 trim to 64 char
            }

            //Francis Alindogan DOO-3907 03.05.2020
            if(woli.Click_Priority__c != null){
                elem.Priority = woli.Click_Priority__c;
            }
            
            //Francis Allen Alindogan DOO-4689 07.21.2020
            if(woli.Waterfilter_Suggestion__c != null){
                elem.WFSuggestion = woli.Waterfilter_Suggestion__c;            
            }

            //-----------------Physical Asset Object Mapping-------------------------------------//
            //KTS-1964 13.8.2018 Xen Reyes
            elem.SparePartCoverage = String.valueOf(woli.PhysicalAsset__r.SparePartCoverage__c);
            elem.LabourChargeCoverage = String.valueOf(woli.PhysicalAsset__r.CallOutChargeCoverage__c);
            elem.CallOutChargeCoverage = String.valueOf(woli.PhysicalAsset__r.LabourChargeCoverage__c);

            //XEN REYES 18.09.2018 KTS-2176 > XEN REYES Modified for R3.1
            /* elem.Building = woli.PhysicalAsset__r.Building__c;
            elem.Floor = woli.PhysicalAsset__r.Floor__c; */
            
            //-----------------Account Location Object Mapping-------------------------------------          
            
            elem.Postcode = woli.AccountLocation__r.Apttus_Config2__PostalCode__c ;
            elem.Country =  woli.AccountLocation__r.Shipping_Country_ISO__c;     
            elem.City =    woli.AccountLocation__r.Apttus_Config2__City__c;
            elem.Street =  woli.AccountLocation__r.Shipping_Street_Only__c;              
            elem.State =  woli.AccountLocation__r.Shipping_State__c;
            //elem.CitySubdivision = 

            //XEN REYES 18.09.2018 KTS-2176
            elem.StreetNumber = woli.AccountLocation__r.Shipping_House_Number__c;
            
            //XEN REYES DOO-4462 May 7, 2020
            elem.HouseNumSupplement = woli.AccountLocation__r.House_Number_Supplement__c;

            elem.ScreeningRequired = woli.AccountLocation__r.Screening_Required__c;
            
            //XEN REYES March 14,. 2019 KTS-2661/ALM 5510
            //elem.UpfrontCallNeeded = woli.AccountLocation__r.Upfront_Call_Needed__c; 
            if(woli.RemoveScheduleRestrictions__c){ 
                elem.UpfrontCallNeeded = false;
            } else {
                elem.UpfrontCallNeeded = woli.AccountLocation__r.Upfront_Call_Needed__c; 
            }

            //elem.AlternativeMachine  = woli.AlternativeMachine__c; //v//disabled per remco request 16 may 2018
            //-----------------Work Order Object Mapping-------------------------------------
           
            elem.SFPriority = woli.Case__r.Priority;
            elem.FaultConfiguration = woli.FaultConfiguration__r.ProductCode__c;//oli.WorkOrder.FaultConfiguration__c; error when passing in click
            elem.FaultConfigurationDescription = woli.FaultConfiguration__r.Product__r.Name; //DOO-4739 07.17.2020 Francis Allen Alindogan

            //elem.Context = woli.WorkOrder.Description;
            elem.IsCoffeeRunning = woli.IsCoffeeRunning__c;//woli.Case__r.CoffeeIsRunning__c;            
            elem.RepeatVisit = woli.Case__r.RepeatVisit__c;
            //elem.Complaint = woli.WorkOrder.Complaint__c;
            
            /*  updated #1 by Archi per Remco request, the calendar__c 
                Xen Reyes DOO-4542 JUNE 22, 2020 Removed due to the new Customer Calendar implementation
            */
            /* if(!woli.AccountLocation__r.Custom_Service_Hours__c){
                elem.Calendar = woli.Calendar__c;
            } else {

                //XEN REYES March 14,. 2019 KTS-2661/ALM 5510
                if(woli.RemoveScheduleRestrictions__c){
                    elem.CalendarName = '';
                } else {
                    elem.CalendarName = (String) woli.Calendar__c;
                }
            } */

            //Xen Reyes DOO-4542 JUNE 22, 2020 New Customer Calendar implementation
            if(woli.AccountLocation__c != null && accLoc_OHA_Map.containsKey(woli.AccountLocation__c)){
                List<OperatingHourAssociation__c> calendar_list = accLoc_OHA_Map.get(woli.AccountLocation__c);

                if(!calendar_list.isEmpty()){
                    for(OperatingHourAssociation__c oha_var : calendar_list){
                        if(oha_var.CustomServiceHours__c == false){
                            if(oha_var.TechnicalNameClose__c != 'XCustClosedHrs_MoO_TuO_WeO_ThO_FrO') elem.ExceptionCalendar = oha_var.TechnicalNameClose__c;
                            elem.Calendar = oha_var.TechnicalNameOpen__c;
                            elem.CalendarName = '';
                        } else {
                            elem.Calendar = '';
                            elem.ExceptionCalendar = '';
                            elem.CalendarName = oha_var.CustomServiceHoursDescription__c;
                        }

                        break;
                    }
                }
            }

            //XEN REYES March 14,. 2019 KTS-2661/ALM 5510
            if(woli.RemoveScheduleRestrictions__c){
                elem.CalendarName = '';
            }

            //XEN REYES April 26, 2019 ALM 
            if(woli.IgnoreCalendar__c){
                elem.Calendar = '';
                elem.CalendarName = '';
            }

            elem.ProjectID = String.valueOf( woli.Case__r.ProjectNumber__c );
            elem.WorkOrderNumber = woli.WorkOrderId; //updated by shashank
            
            if (woli.BookAppointmentFinish__c !=null && woli.BookAppointmentStart__c !=null ){
                elem.AppointmentStart  = formatDateTime(woli.BookAppointmentStart__c);
                elem.AppointmentFinish = formatDateTime(woli.BookAppointmentFinish__c);
                
                //XEN REYES September 3, 2019 DOO-853
                elem.IsAppointment = true;
            }
            else  {
                if (woli.EarliestAppointmentTime__c!=null && woli.LatestAppointmentTime__c!=null && woli.OutsideSLA__c == true){ //XEN REYES 10.31.2018 Updated: woli.Case__r.OutsideSLA__c == true
                    elem.AppointmentStart  = formatDateTime(woli.EarliestAppointmentTime__c);
                    elem.AppointmentFinish = formatDateTime(woli.LatestAppointmentTime__c);

                    //XEN REYES September 3, 2019 DOO-853
                    elem.IsAppointment = true;  
                }
                else {
                    if (woli.EarlyStart__c!=null){
                        elem.AppointmentStart  = formatDateTime(woli.EarlyStart__c);
                    }
                    else {
                        elem.AppointmentStart = formatDateTime(woli.CreatedDate);
                    }                   
                    elem.AppointmentFinish = formatDateTime(woli.SLADate__c);

                    //XEN REYES September 3, 2019 DOO-853
                    elem.IsAppointment = false;  
                }
            }
            
            System.debug('AppointmentStart sent to Click:: ' + elem.AppointmentStart );
            System.debug('AppointmentFinish sent to Click: ' + elem.AppointmentFinish );
            ///-------------------------------------------//
               
            //----------------service ordernotes mapping-----------------//
            if (!String.isBlank(woli.Subject)) {
                JDEServicesCallout.ServiceOrderNotes_element service = new JDEServicesCallout.ServiceOrderNotes_element();
                service.ServiceOrderNote = new List<JDEServicesCallout.ServiceOrderNote_element>();
                JDEServicesCallout.ServiceOrderNote_element serviceNote = new JDEServicesCallout.ServiceOrderNote_element();
                serviceNote.Name = woli.Subject;
                //Karen Hung May 6, 2019 DOO-58 ALM6763 to limit description to 4000 characters
                if(!String.isBlank(woli.Description)){
                    serviceNote.Description = woli.Description.left(4000 -(woli.Subject != null ? woli.Subject.length() : 0));
                }
                service.ServiceOrderNote.add(serviceNote);           
                elem.ServiceOrderNotes = service; 
            }
                   
            //-----------------//           
            elem.isReturn = woli.ReturnTask__c;
            
            //-----------------Contact Object Mapping-------------------------------------
            elem.ContactName = woli.Case__r.Contact.Name;
            elem.CustomerEmail = woli.Case__r.Contact.Email;
            elem.ContactPhoneNumber = woli.Case__r.Contact.Phone;
            elem.CustomerLastVisit = formatDate(woli.PhysicalAsset__r.MachineLastServiceDate__c) ;//String.valueOf(woli.LastVisitatCustomer__c);
            //elem.PreferredWayContact = woli.Case__r.Contact.Communication_Preference__c;

            //-----------------Machine definition-------------------------------------
            JDEServicesCallout.MachineList_element MachineList = new JDEServicesCallout.MachineList_element();
            MachineList.Machine = new List<JDEServicesCallout.Machine_element>();
            JDEServicesCallout.Machine_element mac = new JDEServicesCallout.Machine_element();
            mac.Name = woli.PricebookEntry.Product2.Name;//woli.AssetLineItem__r.Serial_Number__c;
            mac.MachineType = woli.pricebookentry.product2.ProductCode;
            mac.OperatorContact =woli.PhysicalAsset__r.OP_LastPerformingOperator__r.Name ; // added 16 may 2018
            mac.MachineInternalNumber = woli.PhysicalAsset__r.CustomerReferenceNumber__c != null ? woli.PhysicalAsset__r.CustomerReferenceNumber__c.left(128) : ''; //added 16 may 2018 //DOO-2633 KAREN HUNG 28.10.2019 ALIGN LENGTH WITH CLICK - 128 char
            mac.WTSOwner = woli.PhysicalAsset__r.WTSChangedBy__c ;
            mac.AssetID = woli.PhysicalAsset__c;
            mac.NextFilterChangeDate = formatDateTime(woli.PhysicalAsset__r.NextWTSDate__c);             
            mac.InstallDate = formatDateTime(woli.PhysicalAsset__r.InitialActivationDate__c);
            mac.DeInstallDate = formatDateTime(woli.PhysicalAsset__r.DeInstallationDate__c);
            mac.LeaveAtCustomer = woli.LeaveMachineAtCustomer__c;            
            mac.FilterChangeDate = formatDateTime(woli.PhysicalAsset__r.LastWTSdate__c);

            mac.Instructions = woli.PhysicalAsset__r.AdditionalDetails__c; //XEN REYES Nov. 20, 2018
                        
            //Francis Alindogan 01.21.2019 DOO-3522
            mac.WTSIntervalDefault = String.valueOf(TS_CloseTaskWOLIController.getWTSInterval(woli.Id));

            //Karen Hung 16.04.2020 DOO-4360 POPULATE MACHINE LOCATION DETAILS FOR S15
            if(woli.WorkOrderType__c == TS_CONSTANTS.WO_TYPE_S15_1STLINECM){
                mac.MachineInternalNumber = woli.PhysicalAsset__r.CustomerReferenceNumber__c != null ? woli.PhysicalAsset__r.CustomerReferenceNumber__c.left(128) : '';
                mac.Building = woli.PhysicalAsset__r.Building__c  != null ?  woli.PhysicalAsset__r.Building__c.left(64) : '';
                mac.Floor = woli.PhysicalAsset__r.Floor__c != null ?  woli.PhysicalAsset__r.Floor__c.left(64) : '';
                mac.Area = woli.PhysicalAsset__r.Area__c != null ?  woli.PhysicalAsset__r.Area__c.left(64) : '';
            }
 
            //-------------machine history----------------------------
            List<JDEServicesCallout.History_element> historyElementList = new List <JDEServicesCallout.History_element>();
                JDEServicesCallout.History_element histelement = new  JDEServicesCallout.History_element();
                    List<JDEServicesCallout.HistoryItem_element> histitemelementlist = new List<JDEServicesCallout.HistoryItem_element> ();
                        for (WorkOrderLineItem histWoli: woliMachineHistoryList){

                                if (histWoli.PhysicalAsset__c == woli.PhysicalAsset__c && histWoli.EndDate__c!=null){
                                    JDEServicesCallout.HistoryItem_element hisitemelement = new JDEServicesCallout.HistoryItem_element();
                                    hisitemelement.WorkDate = formatDateTime(histWoli.EndDate__c); //this is a required field
                                    //hisitemelement.PartNotes = histWoli.PartNotes__c;
                                    hisitemelement.PartNotes = histWoli.Part_Notes__c; // Xen Reyes Feb. 4, 2019
                                    hisitemelement.TaskType = histWoli.WorkOrderType__c;
                                    hisitemelement.ServConfig = histWoli.JDELineItemNumber__c; //9.27.2018 Xen Reyes
                                    //hisitemelement.Engineer= histWoli.ExecutingEngineer__c;                                             
                                    hisitemelement.Engineer= histWoli.ExecutingEngineer__r.EmployeeFirstName__c + ' ' + histWoli.ExecutingEngineer__r.EmployeeLastName__c;
                                    hisitemelement.CallID= histWoli.JDELineItemNumber__c; //KTS-20179 Xen Reyes 21.8.2018
                                    histitemelementlist.add(hisitemelement);
                                }
                            }
            histelement.HistoryItem = histitemelementlist;
            historyElementList.add(histelement);
            mac.History = historyElementList;
            /////////---------------------------------------///////////

            //------------------- Counter reading mapping-------------------------------------
            /* if (woli.PhysicalAsset__r.AgreementRecordType__c == 'Consumption Model'){ 
                //woli.WorkOrderType__c ==Label.TS_Activity_Type_S10
                //woli.status == Label.TS_WOLI_Status_Dispatched
            } */

            //KTS-2232 XEN REYES Oct. 16 2018
            if(!woliCRList.isEmpty()){
                JDEServicesCallout.CounterReadings_element machineCounterReadings = new JDEServicesCallout.CounterReadings_element();
                List<JDEServicesCallout.CounterReading_element> machineCounterReadingList = new List<JDEServicesCallout.CounterReading_element>();
                 
                /* for (WorkOrderLineItem wolicr: woliCRList){
                    if (wolicr.ParentWorkOrderLineItemId == woli.Id) {  
                        JDEServicesCallout.CounterReading_element crel = new  JDEServicesCallout.CounterReading_element();
                        
                        crel.Name=wolicr.OP_ConsumptionGroup__c;//wolicr.OP_UniquecounterID__c;//
                        crel.LastPaid=Integer.valueOf(wolicr.OP_LastPaidCounterReading__c);//
                        crel.LastFree=Integer.valueOf(wolicr.OP_LastFreeVendingCounterReading__c);//
                        crel.LastReadingDate=formatDateTime(wolicr.OP_LastReadingDate__c);
                        if (wolicr.OP_AverageFreeConsumptions__c!=null) crel.AverageFreeDrinks=Integer.valueOf(wolicr.OP_AverageFreeConsumptions__c.replaceall('\\.',''));//
                        if (wolicr.OP_AveragePaidConsumptions__c!=null) crel.AveragePaidDrinks=Integer.valueOf(wolicr.OP_AveragePaidConsumptions__c.replaceall('\\.',''));// 
                        if (wolicr.OP_CounterSequence__c!=null) crel.Sequence = wolicr.OP_CounterSequence__c.intValue()  ;
                        crel.JDELineItemNumber      = wolicr.JDELineItemNumber__c;               
                        machineCounterReadingList.add(crel);
                    }

                } */

                /* XEN REYES Nov. 19, 2018 */
                if(assetCounterReadingRegularListMap.containsKey(woli.PhysicalAsset__c)){
                                       
                    for (APTS_CounterReadingData__c cr : assetCounterReadingRegularListMap.get(woli.PhysicalAsset__c)){             
                            JDEServicesCallout.CounterReading_element crel = new  JDEServicesCallout.CounterReading_element();
                            
                            crel.Name = String.valueOf(cr.APTS_Counter_Description__c);
                            crel.LastPaid = cr.APTS_Current_Reading_ValuePaid__c;
                            crel.LastFree = cr.APTS_Current_Reading_ValueFree__c;
                            crel.UniqueID = String.valueOf(cr.APTS_CounterID__c);
                            crel.CounterReadingDataRecordId = String.valueOf(cr.Id);
                        	                            
                            if (cr.APTS_Current_Reading_Date__c != null) crel.LastReadingDate = formatDateTime(cr.APTS_Current_Reading_Date__c.date());

                            //if (cr.APTS_AvgConsumptionFree__c != null) crel.AverageFreeDrinks = String.valueOf(cr.APTS_AvgConsumptionFree__c).replaceall('\\.','');
                            if (cr.APTS_AvgConsumptionFree__c != null) crel.AverageFreeDrinks = cr.APTS_AvgConsumptionFree__c; //XEN REYES Dec. 18, 2018

                            //if (cr.APTS_AvgConsumptionPaid__c != null) crel.AveragePaidDrinks = String.valueOf(cr.APTS_AvgConsumptionPaid__c).replaceall('\\.','');
                            if (cr.APTS_AvgConsumptionPaid__c != null) crel.AveragePaidDrinks = cr.APTS_AvgConsumptionPaid__c; //XEN REYES Dec. 18, 2018

                            if (cr.APTS_CounterSequence__c != null) crel.Sequence = Integer.valueOf(cr.APTS_CounterSequence__c);
                            machineCounterReadingList.add(crel);
                    }
                    mac.CounterReadingPriceType = assetCounterReadingRegularListMap.get(woli.PhysicalAsset__c)[0].APTS_PriceType__c; //DOO-2646 KAREN HUNG get price type of the first CR for now
                }
                /* XEN REYES Nov. 19, 2018 */
				
                machineCounterReadings.CounterReading = machineCounterReadingList;
                System.debug('TS executeTaskCreateUpdate counter reading list : '+ machineCounterReadingList);
                mac.CounterReadings = machineCounterReadings;
            }
            ///-------------------------------------------//   

            /* 
            //-----------------Configurations Mapping---------------//
            JDEServicesCallout.Configurations_element config = new JDEServicesCallout.Configurations_element();
            config.Configuration = List<String>();
            config.Configuration.add(woli.AssetLineItem__r.Configuration);
            mac.Configurations = config;
            //------------------------------------------------------//
            */

            //------------------Machine attributes -------------------//
            //mac.SerialNr =  woli.AssetLineItem__r.Serial_Number__c;//woli.SerialNumber__c;
            mac.SerialNr =  woli.PhysicalAsset__r.SerialNumber__c;
            mac.JobType = woli.Warranty__c;// 
            //mac.LastVisitEngineer = woli.PreviousEngineer__c;
            //mac.Instructions = woli.AssetLineItem__r.
            mac.CommercialMachine = woli.PhysicalAsset__r.CommercialUsage__c;            
            //mac.MachineAge = formatDateTime(woli.AssetLineItem__r.Apttus_Config2__InitialActivationDate__c);
            mac.MachineAge = formatDateTime(woli.PhysicalAsset__r.InitialActivationDate__c);
            //mac.LastPrevMaintDate = formatDateTime(woli.AssetLineItem__r.LastPreventiveMaintenanceDate__c);
            mac.LastPrevMaintDate = formatDateTime(woli.PhysicalAsset__r.LastPreventiveMaintenanceDate__c);
            
            //mac.LastInstallDate = formatDateTime(woli.AssetLineItem__r.Install_Date__c);
            mac.LastInstallDate = formatDateTime(woli.PhysicalAsset__r.InstallationDate__c);
            //mac.MachineWeight = woli.AssetLineItem__r.            
            //mac.LastTelemetryStatus = woli.AssetLineItem__r.LastTelemetryStatus__c;
            //mac.LastTelemetryDate = formatDateTime(woli.AssetLineItem__r.LastTelemetryDate__c);
            //---------------------------------------------------------//

            /* 
            //-------------------------Ingredients Mapping---------------------------------------//
            mac.Ingredients = new List<JDEServicesCallout.Ingredients_element>();
            JDEServicesCallout.Ingredients_element ingeElem = new JDEServicesCallout.Ingredients_element();
            ingeElem.IngredientItem = new List<JDEServicesCallout.IngredientItem_element>();
            JDEServicesCallout.IngredientItem_element ingre = new JDEServicesCallout.IngredientItem_element();
            ingre.ID = '';
            ingre.Ingredient = '';
            ingre.Unity = '';
            ingre.CurrentCount = '';
            ingeElem.IngredientItem.add(ingre);
            mac.Ingredients.add(ingeElem);
            //------------------------------------------------------------------------------------//
            Safety Checks Mapping
            JDEServicesCallout.SafetyChecks_element safetyElement = new JDEServicesCallout.SafetyChecks_element();
            safetyElement.SafetyCheck = new List<String>();
            safetyElement.SafetyCheck.add(woli.SafetyCheck__c);
            mac.SafetyChecks = safetyElement;
            */
            MachineList.Machine.add(mac);
            elem.MachineList = MachineList;

            //added 16 may 18 per Remco request
            /* if (woli.WorkOrderType__c.equals(Label.TS_Activity_Type_S40)) {
                elem.RecipeText = woli.PhysicalAsset__r.ConfigurationManualAgreementsURL__c ; 
                elem.RecipeSoftware = woli.PhysicalAsset__r.ConfigurationFileURL__c ;
            }
            else {
                elem.RecipeText =  woli.RecipeText__c; 
                elem.RecipeSoftware = woli.RecipeSoftware__c;
            } */

            //XEN REYES Jan. 14, 2019 KTS-2478
            if(woli.UseConfigurationURLFileinTask__c){
                elem.RecipeSoftware = woli.ConfigurationFileURL__c;
                elem.RecipeText =  woli.ConfigurationManualAgreementsURL__c;
                elem.RecipeCrockerySize = woli.JDECrockeryVolumeSize__c != null ? woli.JDECrockeryVolumeSize__c.left(64) : ''; //DOO-2633 KAREN HUNG 28.10.2019 ALIGN LENGTH WITH CLICK
            } else {

                //INC0141853 / KTS-2931 XEN REYES January 16, 2019
                if(woli.PhysicalAsset__c != null){
                    elem.RecipeText = woli.PhysicalAsset__r.ConfigurationManualAgreementsURL__c;
                    elem.RecipeSoftware = woli.PhysicalAsset__r.ConfigurationFileURL__c;
                    elem.RecipeCrockerySize = woli.PhysicalAsset__r.JDECrockeryVolumeSize__c !=null ? woli.PhysicalAsset__r.JDECrockeryVolumeSize__c.left(64) : ''; 
                } else {
                    elem.RecipeSoftware = woli.ConfigurationFileURL__c;
                    elem.RecipeText =  woli.ConfigurationManualAgreementsURL__c;
                    elem.RecipeCrockerySize = woli.JDECrockeryVolumeSize__c != null ? woli.JDECrockeryVolumeSize__c.left(64) : '';
                }
                
            }              

            //-----------------Account Object Mapping-------------------------------------
            //elem.Customer = woli.Case__r.AccountLocation__r.Name ; //XR KTS-2025 6.08.2018 Previous: Case__r.Account.Name
            elem.Customer = woli.AccountLocation__r.Name;// Update By Ritesh Kumar 03-09-2018 Previous : woli.Case__r.AccountLocation__r.Name
            elem.CustomerNumber =  woli.AccountLocation__r.SAP_Customer_ID__c;// woli.Case__r.Account.AccountNumber;  //modified by Archi 5 september 2017 as per TSWS-360
            elem.PremiumCustomer = woli.PremiumCustomer__c;// woli.Case__r.Account.WSONE_DATA__UltimateParentLookup__r.Key_Account__c  ? woli.Case__r.Account.WSONE_DATA__UltimateParentLookup__r.Key_Account__c : woli.Case__r.Account.Key_Account__c;           
            //elem.CustomerType = woli.WorkOrder.Account.Customer_Type__c;//commented red 
            //elem.CustomerSegment = woli.Case__r.Account.Segment__c;

            //-----------------Required Parts Mapping-------------------------------------  
            //if (!String.isBlank(woli.RelateTo__c) && !requiredWorkOrderLineItemsList.isEmpty()) { Commented for now 6.1.2018 by Paul Jarred
            
            //DOO-4490 May 14, 2020 Xen Reyes
            elem.HasRequiredParts = false;

            if (!requiredWorkOrderLineItemsList.isEmpty()) { //XEN REYES March 14,. 2019 KTS-2661/ALM 5510
                
                //Removed DOO-4490 May 14, 2020 Xen Reyes
                //&& woli.RemoveScheduleRestrictions__c == false
                
                //6.18.2018 Updated by Paul Aguiling START
                String woliParentId = !String.isBlank(woli.RelateTo__c)? woli.RelateTo__c : woli.Id;
                JDEServicesCallout.RequiredParts_element result = new JDEServicesCallout.RequiredParts_element();
                result.RequiredPart = new List<JDEServicesCallout.RequiredPart_element>();

                //DOO-593 Xen Reyes - July 9, 2019
                Set<String> SET_DUPE_CHECKER = new Set<String>();

                for(WorkOrderLineItem woliChild: requiredWorkOrderLineItemsList) {           
                    if (woliChild.ParentWorkOrderLineItemId == woliParentId) {
                        JDEServicesCallout.RequiredPart_element elemPart = new JDEServicesCallout.RequiredPart_element();

                        //Karen Hung 21.05.2020 DOO-4559 add product code in product description
                        String PRODUCT_NAME = woliChild.PricebookEntry.Product2.Name + ' - ' + woliChild.PricebookEntry.Product2.ProductCode;
                        elemPart.Name = PRODUCT_NAME;
                        if(SET_DUPE_CHECKER.CONTAINS(PRODUCT_NAME)){
                            continue;
                        }

                        elemPart.RequiredPartID = String.valueOf( woliChild.PricebookEntry.Product2Id );
                        elemPart.Quantity = Integer.valueOf(woliChild.Quantity);
                        elemPart.PriceBookEntryID = woliChild.PriceBookEntryID;

                        //DOO-4769 XEN REYES August 18, 2020 - Added Unit_Price__c && DirectToCustomer__c
                        elemPart.Cost = woliChild.Unit_Price__c != null ? Decimal.valueOf(woliChild.Unit_Price__c) : woliChild.UnitPrice;
                        elemPart.DirectToCustomer = woliChild.DirectToCustomer__c;

                        SET_DUPE_CHECKER.ADD(PRODUCT_NAME);
                        result.RequiredPart.add(elemPart);
                    } 
                }

                elem.RequiredParts = result;
                //elem.RequiredParts = getRequiredParts(requiredWorkOrderLineItemsList, woli.RelateTo__c);
                //6.18.2018 Updated by Paul Aguiling END

                //DOO-4490 May 14, 2020 Xen Reyes
                if(!woli.RemoveScheduleRestrictions__c) elem.HasRequiredParts = true;

            } 
            
            //XEN REYES March 14,. 2019 KTS-2661/ALM 5510
            //Removed DOO-4490 May 14, 2020 Xen Reyes
            /* else if(!requiredWorkOrderLineItemsList.isEmpty() && woli.RemoveScheduleRestrictions__c){
                JDEServicesCallout.RequiredParts_element result = new JDEServicesCallout.RequiredParts_element();
                result.RequiredPart = new List<JDEServicesCallout.RequiredPart_element>();
                elem.RequiredParts = result;
            } */


            /* Warehouse Ingredients
            JDEServicesCallout.WarehouseIngredients_element wareHouseIngre = new JDEServicesCallout.WarehouseIngredients_element();
            wareHouseIngre.WarehouseItem = new List<JDEServicesCallout.WarehouseItem_element>();
            JDEServicesCallout.WarehouseItem_element wareHouseElem = new JDEServicesCallout.WarehouseItem_element();
            wareHouseElem.Name = '';
            wareHouseElem.Unity = '';
            wareHouseElem.CurrentCount = '';
            wareHouseIngre.WarehouseItem.add(wareHouseElem);
            elem.WarehouseIngredients = wareHouseIngre;
            */

            //-----------------Task Mapping-------------------------------------
            //elem.IsSaleCycleInProgress = ;

            //-----------------Agreement Line Item Mapping-------------------------------------
            //elem.ContractDetails = woli.AssetLineItem__r.Apttus_Config2__AttributeValueId__r.Service_windows__c;
            elem.ContractDetails = woli.PhysicalAsset__r.ServiceWindow__c;

            //elem.ContractType = woli.AssetLineItem__r.APTS_Type_of_Contract__c;

             if (!(woli.WorkOrderType__c.equals(Label.TS_Activity_Type_S40)||woli.WorkOrderType__c.equals(Label.TS_Activity_Type_S41))) {
                elem.ContractType = woli.PhysicalAsset__r.TypeOfContract__c;
            }
            
            //elem.ContractEndDate = formatDateTime(woli.AssetLineItem__r.Apttus_Config2__EndDate__c);
            elem.ContractEndDate = formatDateTime(woli.PhysicalAsset__r.EndDate__c);
            // otc dependent fields              
            /*if (!String.isBlank(woli.AssetLineItem__r.Apttus_Config2__AttributeValueId__c)){
                //elem.WaterFilterCovered = Boolean.valueOf( woli.AssetLineItem__r.Apttus_Config2__AttributeValueId__r.Waterfilter_change_covered__c );    
                elem.WaterFilterCovered = Boolean.valueOf(woli.PhysicalAsset__r.WaterfilterCoverage__c);    
            }*/
            
            elem.WaterFilterCovered = woli.PhysicalAsset__r.IncludesWTSCoverage__c;    // added 16 may 18
            //-----------------Case Mapping-------------------------------------
            elem.CostEstimateMandatory = woli.Case__r.RequiresCostEstimate__c;
            elem.AccountManager = woli.Case__r.Account.Owner.Name;
            elem.CustomerPreferredLanguage=woli.Case__r.Contact.Preferred_Language__c;// added 16 may 18
            
            //KTS-2189 XEN REYES 9.22.2018
            elem.Reactive = woli.Re_active__c; //woli.Case__r.Re_active__c;
            //----------------
           
            elem.DependentWOLI = woli.DependentWOLIID__c;

           IF ((woli.Movement__c && woli.WorkOrderLineItemType__c.equals(Label.TS_Type_Task) )|| woli.case__r.SubType__c.equals('Movement')) {
            elem.Movement = TRUE;
           }
            
            ///----///
            elem.RT_Missingparts = recordTypeMissingPartId;
            elem.RT_Machine = recordTypeMachineId;
            elem.RT_ServiceMaterial = recordTypeServiceMatId;
            elem.RT_Task = recordTypeTaskId;
            elem.RT_UsedPart = recordTypeUsedPartId;
            elem.RT_CounterReading = CONST_WOLI_CHILD_CR_RT; //XEN REYES Nov. 20, 2018
            
            JDEServicesCallout.ServiceMaterials_element serviceMaterials = new JDEServicesCallout.ServiceMaterials_element();
            serviceMaterials.ServiceMaterial = new List<JDEServicesCallout.ServiceMaterial_element>();

            for(WorkOrderLineItem woliChild: childWorkOrderLineItemsList) {           
                if (woliChild.ParentWorkOrderLineItemId == woli.Id) {                   
                    JDEServicesCallout.ServiceMaterial_element elemPart = new JDEServicesCallout.ServiceMaterial_element();
                    elemPart.Name = woliChild.PricebookEntry.Product2.Name;
                    elemPart.Cost = String.valueOf( woliChild.PricebookEntry.UnitPrice );                       
                    elemPart.Warranty = woliChild.Warranty__c;
                    elemPart.Quantity = String.valueOf( woliChild.Quantity );
                    elemPart.JDELineItemNumber = woliChild.JDELineItemNumber__c;  
                    elemPart.PriceBookEntryID = woliChild.PriceBookEntryID; //6.18.2018 Added by Paul Aguiling   
                    elemPart.IsLabour = woliChild.IsLabour__c; //KTS-2005 7.27.2018 Added by Paul Aguiling                           
                    serviceMaterials.ServiceMaterial.add(elemPart);                    
                } 
            }

            if (!serviceMaterials.ServiceMaterial.isEmpty()) {
                elem.ServiceMaterials = serviceMaterials;
            }           

            Integration_Log__c currentLog = iLogMap.get(woli.Id);
            try {
                
                JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
                currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
                currentLog.Target_System_Processed_TimeStamp__c = Datetime.now();
                if(!Test.isRunningTest()) System.debug(port.TaskCreateOrUpdate(elem));

            } catch(Exception ex) {
                currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                currentLog.Integration_Message__c = ex.getMessage();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            }            
            
        }

        try {
            //if (Schema.sObjectType.Integration_Log__c.isUpdateable()) {
            if(!iLogMap.isEmpty()){
                update iLogMap.values();
            }
            //}
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        CustomLogging.pop();
    }


    public void executeClickNotification(List<Integration_Log__c> updatableIlogList) {
        CustomLogging.push('executeClickNotification', 'TS_ClickTaskCreateOrUpdate');
        Set<Id> woliId = new Set<Id>();
        Map<Id,Integration_Log__c> iLogMap = new Map<Id,Integration_Log__c>();
        for (Integration_Log__c ilog : updatableIlogList) {
            woliId.add(ilog.Work_Order_Line_Item__c);
            iLogMap.put(ilog.Work_Order_Line_Item__c,ilog);
        }

        List<WorkOrderLineItem> woliList = [Select Id,JDELineItemNumber__c 
                    from WorkOrderLineItem where id IN: woliId];

        Set<Id> accountId = new Set<Id>();
      

        for (WorkOrderLineItem woli : woliList) {                        
            Integration_Log__c currentLog = iLogMap.get(woli.Id);            
            try {
                JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
                currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
                currentLog.Target_System_Processed_TimeStamp__c = Datetime.now();
                if(!Test.isRunningTest()) System.debug(port.NotifyUpdate(woli.JDELineItemNumber__c, 1));

            } catch(Exception ex) {
                currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                currentLog.Integration_Message__c = ex.getMessage();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            }            
            
        }

        try {
            if (Schema.sObjectType.Integration_Log__c.isUpdateable()) {
                update iLogMap.values();
            }
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }

        CustomLogging.pop();
    }


    public JDEServicesCallout.RequiredParts_element getRequiredParts(List<WorkOrderLineItem> requireWOLIList, String wolidId) {
        JDEServicesCallout.RequiredParts_element result = new JDEServicesCallout.RequiredParts_element();
        result.RequiredPart = new List<JDEServicesCallout.RequiredPart_element>();
        for(WorkOrderLineItem woli: requireWOLIList) {           
            if (woli.ParentWorkOrderLineItemId == wolidId) {
                JDEServicesCallout.RequiredPart_element elemPart = new JDEServicesCallout.RequiredPart_element();
                elemPart.Name = woli.PricebookEntry.Product2.Name;
                elemPart.RequiredPartID = String.valueOf( woli.PricebookEntry.Product2Id );
                elemPart.Quantity = Integer.valueOf(woli.Quantity);
                result.RequiredPart.add(elemPart);
            } 
        }

        return result;
    }

    public String formatDateTime(DateTime valueDateTime) {
        String result = null;
        if (valueDateTime != null) {

            //XEN REYES Dec. 20, 2018 - https://docs.oracle.com/javase/6/docs/api/java/text/SimpleDateFormat.html
            //According to the documentation on SimpleDateFormat you should use lower-case y to represent year. The behavior of upper-case Y is not documented on that page.
            //result = valueDateTime.format('YYYY-MM-dd') + 'T' + valueDateTime.format('HH:mm:ss');
            result = valueDateTime.format('yyyy-MM-dd') + 'T' + valueDateTime.format('HH:mm:ss');
        }
        return result;
    }

    public String formatDate(Date valueDate) {      
        String result = null;
        if (valueDate != null) {
             result = String.valueOf(valueDate).remove(' 00:00:00') + 'T17:00:00';
        }
        return result;
    }
   
    /******************************************************************************
    * @author         Archi Delphinanto
    * @date           March 2018
    * @description    Mapping SF-Click for Counter Reading, used for counter reading, counter reading FUP, operating task, and routesales
    * @revision(s)
    ******************************************************************************/ 
    public void executeOperationalTask(List<Integration_Log__c> updatableIlogList, String operatingTaskType ) {
        CustomLogging.push('executeOperationalTask', 'TS_ClickTaskCreateOrUpdate');
        
            //Specific labels for operating task and counter reading
            String OPERATING_TASKTYPE = 'operatingtask';
            String COUNTER_TASKTYPE = 'counterreading';
            String ROUTESALES_TASKTYPE = 'routesales';
            String LARGE_TASKTYPE = 'Large'; //ALM 6243 XEN REYES March 26, 2019
      
            String CONST_OPERATING_TASK_RT = 'Operating Task';
            String CONST_COUNTER_READING_RT = 'Counter Reading';
            String CONST_COUNTER_READING_TASK_RT ='Counter Reading Task';
            String CONST_ROUTESALES_TASK_RT = 'Routesales Task';
            
            Set<Id> woliIdSet = new Set<Id>();
            Map<Id,Integration_Log__c> iLogMap = new Map<Id,Integration_Log__c>();
            for (Integration_Log__c ilog : updatableIlogList) {
                woliIdSet.add(ilog.Work_Order_Line_Item__c);
                iLogMap.put(ilog.Work_Order_Line_Item__c,ilog);
            }

          List<WorkOrderLineItem> woliList = [SELECT Id, RecordTypeId, JDELineItemNumber__c, WorkOrderType__c, CreatedDate, SLADate__c, EarlyStart__c,
                                              AccountLocation__r.Apttus_Config2__PostalCode__c , AccountLocation__r.Shipping_Country_ISO__c, AccountLocation__r.Apttus_Config2__City__c, AccountLocation__r.Shipping_Street_Only__c,
                                              AccountLocation__r.Shipping_State__c,  Building__c , Floor__c, AccountLocation__r.SAP_Customer_ID__c, ReturnTask__c,
                                              AccountLocation__r.Name, //XR KTS-2022 6.08.2018
                                              PhysicalAsset__r.ServiceWindow__c, PhysicalAsset__r.TypeOfContract__c, AccountLocation__r.Upfront_Call_Needed__c, PhysicalAsset__r.EndDate__c, // AlternativeMachine__c
                                              PhysicalAsset__r.WTSChangedBy__c, //added 16 may 2018
                                              PhysicalAsset__r.CustomerReferenceNumber__c,//added 16 may 2018
                                              Case__c,Case__r.RepeatVisit__c,Area__c,
                                              StairNeeded__c, WorkOrderId, SmokingArea__c, AccountLocation__r.Screening_Required__c, 
                                              Subject, Description, ScheduleManually__c, IgnoreCalendar__c, Movement__c,     
                                              FirstRoutesalesVisit__c, //used for routesales          
                                              PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.OP_LastPerformingOperator__r.Name,
                                              PricebookEntry.Product2.Name, pricebookentry.product2.ProductCode, PhysicalAsset__c, PhysicalAsset__r.NextWTSDate__c, 
                                              PhysicalAsset__r.DeInstallationDate__c, LeaveMachineAtCustomer__c, PhysicalAsset__r.LastWTSdate__c, PhysicalAsset__r.SerialNumber__c, PhysicalAsset__r.InitialActivationDate__c,PhysicalAsset__r.Area__c,
                                              PhysicalAsset__r.LastPreventiveMaintenanceDate__c, PhysicalAsset__r.InstallationDate__c, WorkOrderLineItemType__c, OP_IsHoliday__c, MachineCare__c, OP_247Customer__c, OP_TimeIndicator__c,
                                              AccountLocation__r.Shipping_House_Number__c, //XEN REYES 18.09.2018 KTS-2176
                                              Re_active__c, //KTS-2189 XEN REYES 9.22.2018
                                              PhysicalAsset__r.AdditionalDetails__c, //XEN REYES Nov. 20, 2018
                                              Status, //XEN REYES Jan. 4, 2019
                                              OP_PreferredOperator__c, //XEN REYES Jan. 11, 2019
                                              OP_PreferredOperator__r.Name, //XEN REYES Jan. 11, 2019
                                              RequiredEngineer__c, //Karen Hung 17.03.2020 DOO-4273
                                              RequiredEngineer__r.Name, //Karen Hung 17.03.2020 DOO-4273
                                              PreferredEngineer__c, //XEN REYES Jan. 14, 2019
                                              PreferredEngineer__r.Name, //XEN REYES Jan. 14, 2019
                                              Case__r.CaseNumber, //XEN REYES Jan. 14, 2019
                                              SendCounterReadingsOperating__c, //ALM 6243 XEN REYES March 26, 2019
                                              AccountLocation__r.Custom_Service_Hours__c, Calendar__c, //Karen Hung 28.03.2019 KTS-2673 ALM-6277
                                              Route_Name__c, Unique_Number__c, //Karen Hung 17.03.2020 DOO-4273
                                              AccountLocation__r.House_Number_Supplement__c //XEN REYES DOO-4462 May 7, 2020
                                              FROM WorkOrderLineItem WHERE id IN: woliIdSet];
        
         Id operatingTask_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_OPERATING_TASK_RT).getRecordTypeId();
         Id counterReading_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_COUNTER_READING_RT).getRecordTypeId();
         Id counterReadingTask_RT_Id =Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_COUNTER_READING_TASK_RT).getRecordTypeId();
         Id routesalesTask_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_ROUTESALES_TASK_RT).getRecordTypeId();

        /* List<WorkOrderLineItem> woliCRList;
        if (operatingTaskType.equals(COUNTER_TASKTYPE)){
            woliCRList = [Select Id, JDELineItemNumber__c, ParentWorkOrderLineItemId,OP_CounterSequence__c, OP_UniquecounterID__c, OP_LastPaidCounterReading__c, OP_LastFreeVendingCounterReading__c,
                                                OP_LastReadingDate__c, OP_AverageFreeConsumptions__c,OP_AveragePaidConsumptions__c, OP_ConsumptionGroup__c
                                               FROM WorkOrderLineItem 
                                               WHERE ParentWorkOrderLineItemId IN: woliIdSet ORDER BY OP_CounterSequence__c ASC];
        } */

        /* XEN REYES Nov. 19, 2018 */
        Set<Id> physicalAssetIdSet = new Set<Id>();
        List<APTS_CounterReadingData__c> woliCounterReadingList = new List<APTS_CounterReadingData__c>();
        Map<Id, List<APTS_CounterReadingData__c>> assetCounterReadingListMap = new Map<Id, List<APTS_CounterReadingData__c>>();

        //XEN REYES DOO-4542 June 22, 2020
        Set<Id> accountLocationIdSet = new Set<Id>();

        if(!woliList.isEmpty()){
            for(WorkOrderLineItem woli : woliList){
                physicalAssetIdSet.add(woli.PhysicalAsset__c);

                //XEN REYES DOO-4542 June 22, 2020
                if(woli.AccountLocation__c != null){
                    accountLocationIdSet.add(woli.AccountLocation__c);
                }
            }
        }

        if ((operatingTaskType.equals(COUNTER_TASKTYPE) || operatingTaskType.equals(OPERATING_TASKTYPE))
            && !physicalAssetIdSet.isEmpty()){

            /* XEN REYES Mar 12, 2019 
            Additional filter for the query */
            //DOO-2646 KAREN HUNG 28.10.2019 ADDED APTS_PriceType__c IN QUERY
            woliCounterReadingList = [SELECT Id, APTS_PriceType__c, APTS_Counter_Description__c, APTS_Current_Reading_ValuePaid__c, APTS_Current_Reading_ValueFree__c, APTS_Current_Reading_Date__c, APTS_AvgConsumptionFree__c, APTS_AvgConsumptionPaid__c, APTS_CounterSequence__c, TS_Physical_Asset__c, APTS_CounterID__c FROM APTS_CounterReadingData__c WHERE TS_Physical_Asset__c IN: physicalAssetIdSet AND APTS_Counter_Status__c = 'Active' AND APTS_CounterId__c != null ORDER BY APTS_CounterSequence__c ASC];

            if(!woliCounterReadingList.isEmpty()){
                for(APTS_CounterReadingData__c aptscr : woliCounterReadingList){
                    if(assetCounterReadingListMap.containsKey(aptscr.TS_Physical_Asset__c)){
                        assetCounterReadingListMap.get(aptscr.TS_Physical_Asset__c).add(aptscr);
                    } else {
                        assetCounterReadingListMap.put(aptscr.TS_Physical_Asset__c, new List<APTS_CounterReadingData__c>{aptscr});
                    }
                }
            }
        }

        //XEN REYES DOO-4542 June 22, 2020
        Map<Id, List<OperatingHourAssociation__c>> accLoc_OHA_Map = new Map<Id, List<OperatingHourAssociation__c>>();
        if(!accountLocationIdSet.isEmpty()){
            List<OperatingHourAssociation__c> calendar_list = [SELECT Id, Name, TechnicalNameClose__c, TechnicalNameOpen__c, CustomServiceHours__c, CustomServiceHoursDescription__c, Account_Location__c, Active__c, BusinessUnit__c FROM OperatingHourAssociation__c WHERE Active__c = true AND BusinessUnit__c = 'Routesales' AND Account_Location__c IN: accountLocationIdSet];
            
            if(!calendar_list.isEmpty()){
                for(OperatingHourAssociation__c oha_var : calendar_list){
                    if(accLoc_OHA_Map.containsKey(oha_var.Account_Location__c)){
                        accLoc_OHA_Map.get(oha_var.Account_Location__c).add(oha_var);
                    } else {
                        accLoc_OHA_Map.put(oha_var.Account_Location__c, new List<OperatingHourAssociation__c>{oha_var});
                    }
                }
            }
        }
        
        /* XEN REYES Nov. 19, 2018 */
        if (!woliList.isEmpty()) {
            for (WorkOrderLineItem woli : woliList) {                        
                Integration_Log__c currentLog = iLogMap.get(woli.Id);            
                JDEServicesCallout.TaskCreateOrUpdate_element elem = new JDEServicesCallout.TaskCreateOrUpdate_element();
                
                //mapping element elem here
                elem.CallID = woli.JDELineItemNumber__c; 
                elem.WOLIID = woli.Id;
                elem.TaskType = woli.WorkOrderType__c;
                elem.OpenDate= formatDateTime(woli.CreatedDate);
                elem.EarlyStart= formatDateTime(woli.EarlyStart__c);
                elem.SLA=formatDateTime(woli.SLADate__c);

                elem.Postcode = woli.AccountLocation__r.Apttus_Config2__PostalCode__c ;
                elem.Country =  woli.AccountLocation__r.Shipping_Country_ISO__c;     
                elem.City =    woli.AccountLocation__r.Apttus_Config2__City__c;
                elem.Street =  woli.AccountLocation__r.Shipping_Street_Only__c;              
                elem.State =  woli.AccountLocation__r.Shipping_State__c;
               
                elem.Building= woli.PhysicalAsset__r.Building__c != null ? woli.PhysicalAsset__r.Building__c.left(64) : '';  //Karen Hung May 7, 2019 DOO-57 trim to 64 char
                elem.Floor= woli.PhysicalAsset__r.Floor__c != null ? woli.PhysicalAsset__r.Floor__c.left(64) : ''; //Karen Hung May 7, 2019 DOO-57 trim to 64 char

                //XEN REYES DOO-4462 May 7, 2020
                elem.HouseNumSupplement = woli.AccountLocation__r.House_Number_Supplement__c;

                //XEN REYES Jan. 4, 2019, Karen Hung 2/25/2019 KTS-2639 added status= completed for Operating task and Routesales Task
                if (((woli.Status == Label.TS_Status_Canceled || woli.Status == TS_Constants.STATUS_COMPLETED) && woli.RecordTypeId == operatingTask_RT_Id) ||
                    (woli.Status == TS_Constants.STATUS_COMPLETED && woli.RecordTypeId == routesalesTask_RT_Id) ||
                    (woli.Status == Label.TS_Status_Canceled && woli.RecordTypeId == counterReadingTask_RT_Id)) { //Karen Hung DOO-1808 add canceled counter s22 scenario
                    elem.Status = woli.Status;
                }

                //PREFERRED ENGINEER ASSIGNMENT - Jan. 14, 2019
                JDEServicesCallout.PreferredEngineers_element prefEngr = new JDEServicesCallout.PreferredEngineers_element();
                prefEngr.EngineerID = new List<String>();

                if(operatingTaskType == ROUTESALES_TASKTYPE){
                    if (!String.isBlank(woli.PreferredEngineer__c)){
                        prefEngr.EngineerID.add(woli.PreferredEngineer__r.Name);
                        elem.PreferredEngineers = prefEngr;
                    }

                    /*  Karen Hung 28.03.2019, the calendar__c KTS-2673 ALM-6277
                        Xen Reyes DOO-4542 JUNE 22, 2020 Removed due to the new Customer Calendar implementation
                    */
                    /* if(!woli.AccountLocation__r.Custom_Service_Hours__c){
                        elem.Calendar = woli.Calendar__c;
                    } else {
                        elem.CalendarName = (String) woli.Calendar__c;
                    } */

                    //Xen Reyes DOO-4542 JUNE 22, 2020 New Customer Calendar implementation
                    if(woli.AccountLocation__c != null && accLoc_OHA_Map.containsKey(woli.AccountLocation__c)){
                        List<OperatingHourAssociation__c> calendar_list = accLoc_OHA_Map.get(woli.AccountLocation__c);

                        if(!calendar_list.isEmpty()){
                            for(OperatingHourAssociation__c oha_var : calendar_list){
                                if(oha_var.CustomServiceHours__c == false){
                                    if(oha_var.TechnicalNameClose__c != 'XCustClosedHrs_MoO_TuO_WeO_ThO_FrO') elem.ExceptionCalendar = oha_var.TechnicalNameClose__c;
                                    elem.Calendar = oha_var.TechnicalNameOpen__c;
                                    elem.CalendarName = '';
                                } else {
                                    elem.Calendar = '';
                                    elem.ExceptionCalendar = '';
                                    elem.CalendarName = oha_var.CustomServiceHoursDescription__c;
                                }
        
                                break;
                            }
                        }
                    }

                } else {
                    //Karen Hung 17.03.2020 DOO-4273 populate preferred operator regardless of required engineer for non s22s, populate preferred op for s22 if required engineer is blank
                    if (!String.isBlank(woli.OP_PreferredOperator__c) && woli.WorkOrderType__c != 'S22' || (woli.WorkOrderType__c == 'S22' && String.isBlank(woli.RequiredEngineer__c) && !String.isBlank(woli.OP_PreferredOperator__c))){  
                        prefEngr.EngineerID.add(woli.OP_PreferredOperator__r.Name);
                        elem.PreferredEngineers = prefEngr;
                    }
                }


                //Karen Hung 17.03.2020 DOO-4273 populate required for s22s
                if (!String.isBlank(woli.RequiredEngineer__c) && woli.WorkOrderType__c == 'S22') {
                    JDEServicesCallout.RequiredEngineers_element reqEngr = new JDEServicesCallout.RequiredEngineers_element();
                    reqEngr.EngineerID = new List<String>();
                    reqEngr.EngineerID.add(woli.RequiredEngineer__r.Name);
                    elem.RequiredEngineers = reqEngr;
                }/*else if(!String.isBlank(woli.OP_PreferredOperator__c) && woli.WorkOrderType__c == 'S22'){ // populate only preferred if required is blank for s15/s22
                    prefEngr.EngineerID = new List<String>();
                    prefEngr.EngineerID.add(woli.OP_PreferredOperator__r.Name);
                    elem.PreferredEngineers = prefEngr;
                }*/

                //XEN REYES Jan. 11, 2019
                /* if(woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S21_COUNTERREADING || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP){
                    if (!String.isBlank(woli.OP_PreferredOperator__c)) {
                        JDEServicesCallout.PreferredEngineers_element prefEngr = new JDEServicesCallout.PreferredEngineers_element();
                        prefEngr.EngineerID = new List<String>();
                        prefEngr.EngineerID.add(woli.OP_PreferredOperator__r.Name);
                        elem.PreferredEngineers = prefEngr;
                    }
                } */

                //XEN REYES 18.09.2018 KTS-2176
                elem.StreetNumber = woli.AccountLocation__r.Shipping_House_Number__c;

                //KTS-2189 XEN REYES 9.22.2018
                elem.Reactive = woli.Re_active__c; //woli.Case__r.Re_active__c;

                elem.CustomerNumber = woli.AccountLocation__r.SAP_Customer_ID__c;      
                elem.Customer = woli.AccountLocation__r.Name ; //XR KTS-2022 6.08.2018

                elem.IsReturn=woli.ReturnTask__c;
                //elem.Customer=woli.Case__r.Account.Name;
                //elem.ContactName = woli.Case__r.Contact.Name;
                //elem.CustomerEmail = woli.Case__r.Contact.Email;
                //elem.ContactPhoneNumber = woli.Case__r.Contact.Phone;

                 elem.ContractDetails=woli.PhysicalAsset__r.ServiceWindow__c;
                 //elem.SFPriority=woli.Case__r.Priority;
                 elem.ContractType=woli.PhysicalAsset__r.TypeOfContract__c;
                 //elem.PremiumCustomer=;
                 //elem.UpfrontCallNeeded=woli.AccountLocation__r.Upfront_Call_Needed__c; Karen Hung 11/14/18
                 //elem.CostEstimateMandatory=woli.Case__r.RequiresCostEstimate__c;
                 //elem.IsCoffeeRunning=woli.Case__r.CoffeeIsRunning__c;  
                 //elem.AlternativeMachine=woli.AlternativeMachine__c; //disabled per remco request 16 may 2018
                 elem.ContractEndDate=formatDateTime(woli.PhysicalAsset__r.EndDate__c);
                 //elem.WaterFilterCovered=;
                 //elem.AccountManager=woli.Case__r.Account.Owner.Name;
               
                 /// filtered the case as on Operating TAsk and Counter Reading task ... no Case is generated.
                 if (woli.Case__c!=null) {
                    elem.RepeatVisit=woli.Case__r.RepeatVisit__c;
                 }

                 //Karen Hung 12.11.2018 
                 if(woli.PhysicalAsset__c != null){
                    elem.MachineArea = woli.PhysicalAsset__r.Area__c != null ? woli.PhysicalAsset__r.Area__c.left(64) : ''; //Karen Hung May 7, 2019 DOO-57 trim to 64 char
                    elem.IntCustomerReference = woli.PhysicalAsset__r.CustomerReferenceNumber__c != null ? woli.PhysicalAsset__r.CustomerReferenceNumber__c.left(128) : ''; //DOO-2633 KAREN HUNG 28.10.2019 ALIGN LENGTH WITH CLICK - 128 char
                 }

                
                 //Karen Hung 17.03.2020 DOO-4273 populate RouteName and RouteNumber
                if(woli.WorkOrderType__c == 'S22'){
                    elem.RouteName = woli.Route_Name__c;
                    elem.RouteNumber = woli.Unique_Number__c;
                }
                 
                 elem.StairNeeded=woli.StairNeeded__c;
                 elem.WorkOrdeID=woli.WorkOrderId;
                 elem.SmokingArea=woli.SmokingArea__c;
                 //elem.CustomerSegment = woli.Case__r.Account.Segment__c;
                 elem.ScreeningRequired = woli.AccountLocation__r.Screening_Required__c;

                 //service order note //Karen Hung DOO-5101 22.12.2020 updated Criteria
                 if (!String.isBlank(woli.Subject) || !String.isBlank(woli.Description)) {
                        JDEServicesCallout.ServiceOrderNotes_element service = new JDEServicesCallout.ServiceOrderNotes_element();
                        service.ServiceOrderNote = new List<JDEServicesCallout.ServiceOrderNote_element>();
                        JDEServicesCallout.ServiceOrderNote_element serviceNote = new JDEServicesCallout.ServiceOrderNote_element();
                        serviceNote.Name = woli.Subject;
                        //Karen Hung May 6, 2019 DOO-58 ALM6763 to limit description to 4000 characters
                        if(!String.isBlank(woli.Description)){
                            serviceNote.Description = woli.Description.left(4000 -(woli.Subject != null ? woli.Subject.length() : 0));
                        }
                        service.ServiceOrderNote.add(serviceNote);           
                        elem.ServiceOrderNotes = service; 
                  }
         
                 elem.WorkOrderNumber=woli.WorkOrderId;
                              
                 elem.NotNeedCalendar=woli.IgnoreCalendar__c;
                 elem.Movement=woli.Movement__c;
                 /*
                 //elem.PreferredWayContact=woli.Case__r.Contact.Communication_Preference__c;
                 //These record types are not used for S20, S21
                 //elem.RT_ServiceMaterial=;
                 //elem.RT_UsedPart=;
                 //elem.RT_Missingparts=;
                 //elem.RT_Task=;
                 //elem.RT_Machine=;
                 */
                 elem.RT_OperatingTask=operatingTask_RT_Id;
                 elem.RT_CounterReading=counterReading_RT_Id;
                 elem.RT_CounterReadingTask=counterReadingTask_RT_Id;

                  if (operatingTaskType != ROUTESALES_TASKTYPE) {
                    // elements that are not needed for routesales tasks.    
                    elem.ManualSchedule=woli.ScheduleManually__c;       

                    //Machine List starts here
                    JDEServicesCallout.MachineList_element machineListElement = new JDEServicesCallout.MachineList_element();
                    List <JDEServicesCallout.Machine_element> machineList = new List <JDEServicesCallout.Machine_element>();
                            
                    JDEServicesCallout.Machine_element machineElement = new JDEServicesCallout.Machine_element();
                    // machine element
                    machineElement.Name = woli.PricebookEntry.Product2.Name;
                    machineElement.MachineType = woli.pricebookentry.product2.ProductCode;
                    machineElement.AssetID = woli.PhysicalAsset__c;
                    machineElement.NextFilterChangeDate = formatDateTime(woli.PhysicalAsset__r.NextWTSDate__c); 
                    machineElement.InstallDate = formatDateTime(woli.PhysicalAsset__r.InitialActivationDate__c);
                    machineElement.DeInstallDate = formatDateTime(woli.PhysicalAsset__r.DeInstallationDate__c);
                    machineElement.LeaveAtCustomer = woli.LeaveMachineAtCustomer__c;
                    machineElement.FilterChangeDate = formatDateTime(woli.PhysicalAsset__r.LastWTSdate__c);
                    //machineElement.Location;//woli.AssetLineItem__r.Asset_Details__c;
                    machineElement.SerialNr=woli.PhysicalAsset__r.SerialNumber__c;
                    //machineElement.Ingredients;
                    //machineElement.Instructions;
                    
                    machineElement.MachineAge=formatDateTime(woli.PhysicalAsset__r.InitialActivationDate__c);
                    //machineElement.MachineWeight;
                    //machineElement.JobType;
                    //machineElement.LastVisitEngineer=woli.PreviousEngineer__c;
                    machineElement.LastPrevMaintDate=formatDateTime(woli.PhysicalAsset__r.LastPreventiveMaintenanceDate__c);
                    machineElement.LastInstallDate=formatDateTime(woli.PhysicalAsset__r.InstallationDate__c);
                    
                    //machineElement.SafetyChecks;
                    //machineElement.Actions;
                    //machineElement.CommercialMachine;
                    //machineElement.Configurations;
                    //machineElement.LastTelemetryDate;
                    //machineElement.LastTelemetryStatus;
                    //machineElement.History;// commented Red

                    //List <JDEServicesCallout.Activities_element> activities = new List<JDEServicesCallout.Activities_element>();
                    JDEServicesCallout.Activities_element activities = new JDEServicesCallout.Activities_element();
                    //JDEServicesCallout.Activities_element activity = new JDEServicesCallout.Activities_element ();
                    //activity =  woli.WorkOrderLineItemType__c;//'Counter'  ;
                    activities.activity = woli.WorkOrderLineItemType__c;
                    //System.debug('activity type: ' +woli.WorkOrderLineItemType__c);
                    
                    machineElement.Activities = activities; 
                    machineElement.IsHoliday = woli.OP_IsHoliday__c;                 
                    machineElement.OperatingType = woli.MachineCare__c;                                                
                    machineElement.FullWorkingDays = woli.OP_247Customer__c;//is it 24 /7 or not                 
                    machineElement.TimeIndicator = woli.OP_TimeIndicator__c;                                
                    machineElement.WTSOwner = woli.PhysicalAsset__r.WTSChangedBy__c ;
                    machineElement.OperatorContact =woli.PhysicalAsset__r.OP_LastPerformingOperator__r.Name ; // added may 16 2018
                    machineElement.MachineInternalNumber = woli.PhysicalAsset__r.CustomerReferenceNumber__c != null ? woli.PhysicalAsset__r.CustomerReferenceNumber__c.left(128) : '';//added 16 may 2018 //DOO-2633 KAREN HUNG 28.10.2019 ALIGN LENGTH WITH CLICK - 128 char

                    machineElement.Instructions = woli.PhysicalAsset__r.AdditionalDetails__c; //XEN REYES Nov. 20, 2018

                    //ALM 6243 XEN REYES March 26, 2019
                    machineElement.PerformCounterReading = woli.SendCounterReadingsOperating__c;

                    //Karen Hung DOO-4360 POPULATE MACHINE LOCATION DETAILS FOR S22
                    if(woli.WorkOrderType__c == TS_CONSTANTS.WO_TYPE_S22_COUNTERREADINGFUP){
                        machineElement.MachineInternalNumber = woli.PhysicalAsset__r.CustomerReferenceNumber__c != null ? woli.PhysicalAsset__r.CustomerReferenceNumber__c.left(128) : '';
                        machineElement.Building = woli.PhysicalAsset__r.Building__c != null ? woli.PhysicalAsset__r.Building__c.left(64) : '';
                        machineElement.Floor = woli.PhysicalAsset__r.Floor__c != null ? woli.PhysicalAsset__r.Floor__c.left(64) : '';
                        machineElement.Area = woli.PhysicalAsset__r.Area__c  != null ? woli.PhysicalAsset__r.Area__c.left(64) : '' ;
                    }
                    

                    /* SEND COUNTER READING TASK ON COUNTER READING TASK & OPERATING TASK (Selected scenario)
                       For Operating task, L task within the first 10 working days of the month 
                       ALM 6243: Operating Updates to process counter readings correctly
                       March 26, 2019 */
                    if (operatingTaskType.equals(COUNTER_TASKTYPE) || 
                        (operatingTaskType.equals(OPERATING_TASKTYPE) && woli.WorkOrderLineItemType__c == LARGE_TASKTYPE && woli.SendCounterReadingsOperating__c)) {

                        //SET COUNTER READING             
                        JDEServicesCallout.CounterReadings_element machineCounterReadings = new JDEServicesCallout.CounterReadings_element();
                        List<JDEServicesCallout.CounterReading_element> machineCounterReadingList = new List<JDEServicesCallout.CounterReading_element>();

                        /* XEN REYES Nov. 19, 2018 */
                        if(!woliCounterReadingList.isEmpty() && assetCounterReadingListMap.containsKey(woli.PhysicalAsset__c)){
                            for (APTS_CounterReadingData__c cr : assetCounterReadingListMap.get(woli.PhysicalAsset__c)){
                                	                                    
                                    JDEServicesCallout.CounterReading_element crel = new  JDEServicesCallout.CounterReading_element();
                                	                                    
                                    crel.Name = String.valueOf(cr.APTS_Counter_Description__c);
                                    crel.LastPaid = cr.APTS_Current_Reading_ValuePaid__c;
                                    crel.LastFree = cr.APTS_Current_Reading_ValueFree__c;
                                    crel.UniqueID = String.valueOf(cr.APTS_CounterID__c);
                                    crel.CounterReadingDataRecordId = String.valueOf(cr.Id);
                                    
                                    if (cr.APTS_Current_Reading_Date__c != null) crel.LastReadingDate = formatDateTime(cr.APTS_Current_Reading_Date__c.date());

                                    //if (cr.APTS_AvgConsumptionFree__c != null) crel.AverageFreeDrinks = String.valueOf(cr.APTS_AvgConsumptionFree__c).replaceall('\\.','');
                                    if (cr.APTS_AvgConsumptionFree__c != null) crel.AverageFreeDrinks = cr.APTS_AvgConsumptionFree__c; //XEN REYES Dec. 18, 2018

                                    //if (cr.APTS_AvgConsumptionPaid__c != null) crel.AveragePaidDrinks = String.valueOf(cr.APTS_AvgConsumptionPaid__c).replaceall('\\.','');
                                    if (cr.APTS_AvgConsumptionPaid__c != null) crel.AveragePaidDrinks = cr.APTS_AvgConsumptionPaid__c; //XEN REYES Dec. 18, 2018
                                    
                                    if (cr.APTS_CounterSequence__c != null) crel.Sequence = Integer.valueOf(cr.APTS_CounterSequence__c);

                                    machineCounterReadingList.add(crel);
                            }
                             machineElement.CounterReadingPriceType = assetCounterReadingListMap.get(woli.PhysicalAsset__c)[0].APTS_PriceType__c; //DOO-2646 KAREN HUNG get price type of the first CR for now
                        }
                        /* XEN REYES Nov. 19, 2018 */
                        machineCounterReadings.CounterReading = machineCounterReadingList;
                        machineElement.CounterReadings = machineCounterReadings;
                        System.debug('TS executeoperational counter reading list : '+ machineCounterReadingList);
                    }
                                               
                    //END MACHINE ELEMENT
                    machineList.add(machineElement);
                    machineListElement.Machine = machineList;  
                    elem.MachineList = machineListElement;  
                }
                
                else {
                    elem.Firstvisit = woli.FirstRoutesalesVisit__c;
                    elem.CaseId = woli.Case__r.CaseNumber; //XEN REYES Jan. 14, 2019
                }

                System.debug('elem executeoperational : ' + elem);

                try {
                    JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
                    currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
                    currentLog.Target_System_Processed_TimeStamp__c = Datetime.now();
                    System.debug(port.TaskCreateOrUpdate(elem));
                    System.debug('Chi: TaskCreateOrUpdate-executeoperationaltask--> elem' + elem);

                } catch(Exception ex) {
                    currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                    currentLog.Integration_Message__c = ex.getMessage();
                    System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                }            
            }
        }

        if (!iLogMap.isEmpty() && Schema.sObjectType.Integration_Log__c.isUpdateable()) {
              try {
                update iLogMap.values();
            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }

        CustomLogging.pop();
    }

    /******************************************************************************
    * @author         Abram Vixen Reyes
    * @date           January 2020
    * @description    Mapping SF-Click for Route Operating (Route)
    * @revision(s)
    ******************************************************************************/ 
    public void executeOperationalTask_Route (List<Integration_Log__c> updatableIlogList) {
        CustomLogging.push('executeOperationalTask_Route', 'TS_ClickTaskCreateOrUpdate');
        
        String OPERATING_TASKTYPE = 'operatingtask';
        String COUNTER_TASKTYPE = 'counterreading';
        String ROUTESALES_TASKTYPE = 'routesales';
        String LARGE_TASKTYPE = 'Large';

        String CONST_OPERATING_TASK_RT = 'Operating Task';
        String CONST_COUNTER_READING_RT = 'Counter Reading';
        String CONST_COUNTER_READING_TASK_RT ='Counter Reading Task';
        String CONST_ROUTESALES_TASK_RT = 'Routesales Task';
        
        Set<Id> woIdSet = new Set<Id>();
        Set<Id> routeIdSet = new Set<Id>();
        Map<Id,Integration_Log__c> iLogMap = new Map<Id,Integration_Log__c>();
        Map<Id, Route__c> route_map = new Map<Id, Route__c>();
        Map<String, List<WorkOrderLineItem>> woIdwoliListMap = new Map<String, List<WorkOrderLineItem>>();
        for (Integration_Log__c ilog : updatableIlogList) {
            woIdSet.add(ilog.Work_Order__c);
            iLogMap.put(ilog.Work_Order__c, ilog);
        }
		
        //Karen Hung 18/2/2021 DOO-5166 feature flag
        if(!featureFlags.isEmpty()){
            for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                if(flag.Enable__c && !Test.isRunningTest()){                       
                    if(flag.QualifiedApiName == 'DOO_5166_Indicate_Survey'){
                        surveySettingEnabled = true;
                    }    
                }                
            }
        }
        //Karen Hung DOO-4886 8.10.2020 Added planned duration in query
        Map<Id, WorkOrder> wo_map = new Map<Id, WorkOrder>([SELECT Id, Route_Id__c, Route_Name__c, Route_Number__c, WorkOrderNumber, CreatedDate, Account_Location__c,Enabled_Survey_in_Click__c,Account_Location__r.Third_Party_Resource__c,Account_Location__r.Third_Party_Resource__r.Name, Account_Location__r.Apttus_Config2__PostalCode__c, Account_Location__r.Shipping_Country_ISO__c, Account_Location__r.Apttus_Config2__City__c, Account_Location__r.Shipping_Street_Only__c, Account_Location__r.Shipping_State__c, Account_Location__r.Shipping_House_Number__c, Account_Location__r.SAP_Customer_ID__c, Account_Location__r.Name, Account_Location__r.Screening_Required__c, Account_Location__r.MTTOLocationSpecific__c, Actual_Duration__c, Planned_Duration__c, Early_Start_Date__c, SLA_Date__c, Preferred_Operator__c, Preferred_Operator__r.Name, Required_Operator__c, Required_Operator__r.Name, Status,
        Account_Location__r.Truck_Needed__c, //XEN REYES DOO-4305 Mar. 31, 2020
        Account_Location__r.House_Number_Supplement__c //XEN REYES DOO-4462 May 7, 2020
        FROM WorkOrder WHERE Id IN: woIdSet]);

        //GET ALL ROUTE FROM WORK ORDER AND QUERY
        /* if(!wo_map.isEmpty()){
            Set<Id> routeSet = new Set<Id>();
            for(WorkOrder wo_var : wo_map.values()){
                if(wo_var.Route_Id__c != null) routeSet.add(wo_var.Route_Id__c);
            }

            if(!routeSet.isEmpty()){
                route_map = new Map<Id, Route__c>([SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Preferred_Operator__r.Name, Required_Operator__c, Required_Operator__r.Name FROM Route__c WHERE Id IN: routeSet]);
            }
        } */                                    

        List<WorkOrderLineItem> woliList = [SELECT Id, RecordTypeId, JDELineItemNumber__c, WorkOrderType__c, CreatedDate, SLADate__c, EarlyStart__c,
                                            AccountLocation__r.Apttus_Config2__PostalCode__c , AccountLocation__r.Shipping_Country_ISO__c, AccountLocation__r.Apttus_Config2__City__c, AccountLocation__r.Shipping_Street_Only__c,
                                            AccountLocation__r.Shipping_State__c,  Building__c , Floor__c, AccountLocation__r.SAP_Customer_ID__c, ReturnTask__c,
                                            AccountLocation__r.Name, AccountLocation__r.Third_Party_Resource__r.Name, //Karen Hung DOO-5166 
											Enabled_Survey_in_Click__c, WorkOrder.Enabled_Survey_in_Click__c, //Karen Hung DOO-5166 
                                            PhysicalAsset__r.ServiceWindow__c, PhysicalAsset__r.TypeOfContract__c, AccountLocation__r.Upfront_Call_Needed__c, PhysicalAsset__r.EndDate__c, // AlternativeMachine__c
                                            PhysicalAsset__r.WTSChangedBy__c,
                                            PhysicalAsset__r.CustomerReferenceNumber__c,
                                            Case__c,Case__r.RepeatVisit__c,Area__c,
                                            StairNeeded__c, WorkOrderId, SmokingArea__c, AccountLocation__r.Screening_Required__c, 
                                            Subject, Description, ScheduleManually__c, IgnoreCalendar__c, Movement__c,     
                                            FirstRoutesalesVisit__c,        
                                            PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.OP_LastPerformingOperator__r.Name,
                                            PricebookEntry.Product2.Name, pricebookentry.product2.ProductCode, PhysicalAsset__c, PhysicalAsset__r.NextWTSDate__c, 
                                            PhysicalAsset__r.DeInstallationDate__c, LeaveMachineAtCustomer__c, PhysicalAsset__r.LastWTSdate__c, PhysicalAsset__r.SerialNumber__c, PhysicalAsset__r.InitialActivationDate__c,PhysicalAsset__r.Area__c,
                                            PhysicalAsset__r.LastPreventiveMaintenanceDate__c, PhysicalAsset__r.InstallationDate__c, WorkOrderLineItemType__c, OP_IsHoliday__c, MachineCare__c, OP_247Customer__c, OP_TimeIndicator__c,
                                            AccountLocation__r.Shipping_House_Number__c,
                                            Re_active__c, PhysicalAsset__r.AdditionalDetails__c,
                                            Status, OP_PreferredOperator__c, OP_PreferredOperator__r.Name,
                                            PreferredEngineer__c, PreferredEngineer__r.Name,
                                            Case__r.CaseNumber, SendCounterReadingsOperating__c, AccountLocation__r.Custom_Service_Hours__c, Calendar__c, Sequence_Number__c
                                            FROM WorkOrderLineItem WHERE WorkOrderId IN: woIdSet ORDER BY Sequence_Number__c ASC NULLS LAST];

        Id operatingTask_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_OPERATING_TASK_RT).getRecordTypeId();
        Id counterReading_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_COUNTER_READING_RT).getRecordTypeId();
        Id counterReadingTask_RT_Id =Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_COUNTER_READING_TASK_RT).getRecordTypeId();
        Id routesalesTask_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_ROUTESALES_TASK_RT).getRecordTypeId();
        Id warehouseSurvey_RT_Id =  Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('OPG_Warehouse').getRecordTypeId();
        Id machineSurvey_RT_Id =  Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('OPG_Machine').getRecordTypeId();

        Set<Id> physicalAssetIdSet = new Set<Id>();
        List<APTS_CounterReadingData__c> woliCounterReadingList = new List<APTS_CounterReadingData__c>();
        Map<Id, List<APTS_CounterReadingData__c>> assetCounterReadingListMap = new Map<Id, List<APTS_CounterReadingData__c>>();

        //GET THE PHYSICAL ASSET OF EACH OPERATING TASK
        if(!woliList.isEmpty()){
            for(WorkOrderLineItem woli : woliList){
                physicalAssetIdSet.add(woli.PhysicalAsset__c); 
            }

            //GET THE COUNTER READING ATTRIBUTES OF EACH MACHINE
            if (!physicalAssetIdSet.isEmpty()){

                woliCounterReadingList = [SELECT Id, APTS_PriceType__c, APTS_Counter_Description__c, APTS_Current_Reading_ValuePaid__c, APTS_Current_Reading_ValueFree__c, APTS_Current_Reading_Date__c, APTS_AvgConsumptionFree__c, APTS_AvgConsumptionPaid__c, APTS_CounterSequence__c, TS_Physical_Asset__c, APTS_CounterID__c FROM APTS_CounterReadingData__c WHERE TS_Physical_Asset__c IN: physicalAssetIdSet AND APTS_Counter_Status__c = 'Active' AND APTS_CounterId__c != null ORDER BY APTS_CounterSequence__c ASC];

                if(!woliCounterReadingList.isEmpty()){
                    for(APTS_CounterReadingData__c aptscr : woliCounterReadingList){
                        if(assetCounterReadingListMap.containsKey(aptscr.TS_Physical_Asset__c)){
                            assetCounterReadingListMap.get(aptscr.TS_Physical_Asset__c).add(aptscr);
                        } else {
                            assetCounterReadingListMap.put(aptscr.TS_Physical_Asset__c, new List<APTS_CounterReadingData__c>{aptscr});
                        }
                    }
                }
            }

            //GROUP OPERATING TASK PER WORK ORDER
            for(WorkOrderLineItem wo_var : woliList){
                if(woIdwoliListMap.containsKey(wo_var.WorkOrderId)){
                    woIdwoliListMap.get(wo_var.WorkOrderId).add(wo_var);
                } else {
                    woIdwoliListMap.put(wo_var.WorkOrderId, new List<WorkOrderLineItem>{wo_var});
                }
            }

            //CREATE MESSAGE FOR EACH BUNDLE
            if(!woIdwoliListMap.isEmpty()){
                for(String wo_id : woIdwoliListMap.keySet()){
                    
                    //GET INTEGRATION LOG / WORK ORDER / ROUTE RECORD
                    Integration_Log__c currentLog = iLogMap.get(wo_id);   
                    WorkOrder wo_var = wo_map.get(wo_id);

                    //CREATE TASK ELEMENT
                    JDEServicesCallout.TaskCreateOrUpdate_element elem = new JDEServicesCallout.TaskCreateOrUpdate_element();

                    elem.CallID = String.valueOf('RT-' + wo_var.WorkOrderNumber);
                    elem.WorkOrdeID = wo_var.Id;
                    elem.TaskType = 'S20';
                    elem.OpenDate= formatDateTime(wo_var.CreatedDate);
                    elem.EarlyStart= formatDateTime(wo_var.Early_Start_Date__c);
                    elem.SLA = formatDateTime(wo_var.SLA_Date__c);
                    elem.Postcode = wo_var.Account_Location__r.Apttus_Config2__PostalCode__c ;
                    elem.Country = wo_var.Account_Location__r.Shipping_Country_ISO__c;     
                    elem.City = wo_var.Account_Location__r.Apttus_Config2__City__c;
                    elem.Street = wo_var.Account_Location__r.Shipping_Street_Only__c;            
                    elem.State = wo_var.Account_Location__r.Shipping_State__c;
                    elem.StreetNumber = wo_var.Account_Location__r.Shipping_House_Number__c;
                    elem.CustomerNumber = wo_var.Account_Location__r.SAP_Customer_ID__c;      
                    elem.Customer = wo_var.Account_Location__r.Name;
                    elem.ScreeningRequired = wo_var.Account_Location__r.Screening_Required__c;
                    elem.WorkOrderNumber = wo_var.Id;
                    elem.RT_OperatingTask = operatingTask_RT_Id;
                    elem.RT_CounterReading = counterReading_RT_Id;
                    elem.RT_CounterReadingTask = counterReadingTask_RT_Id;
                    
                    //Karen Hung DOO-5166 18/2/2021
                    if(surveySettingEnabled && wo_var.Enabled_Survey_in_Click__c != null){
                        elem.Survey = wo_var.Enabled_Survey_in_Click__c;
                        elem.RT_WarehouseSurvey = warehouseSurvey_RT_Id;
                        elem.RT_MachineSurvey = machineSurvey_RT_Id;
                        elem.Interviewee = wo_var.Account_Location__r.Third_Party_Resource__r?.Name;
                    }
                    
                    //XEN REYES DOO-4305 Mar. 31, 2020
                    elem.TruckNeeded = wo_var.Account_Location__r.Truck_Needed__c;
                    if(wo_var.Account_Location__r.Truck_Needed__c){
                        elem.CallID = String.valueOf('OR-' + wo_var.WorkOrderNumber);
                    }
                    
                    //Karen Hung DOO-3116 Feb 7, 2020
                    if(wo_var.Status == TS_Constants.STATUS_CANCELED){
                        elem.Status = wo_var.Status; 
                    }

                    /*if(wo_var.Actual_Duration__c != null){
                        elem.MTTO = String.valueOf(Math.ceil(wo_var.Actual_Duration__c * 3600));
                    }*/
                    //Karen Hung 8.10.2020 DOO-4886 changed actual duration to planned duration
                    if(wo_var.Planned_Duration__c != null){
                        elem.MTTO = String.valueOf(Math.ceil(wo_var.Planned_Duration__c * 3600));
                    }                    

                    elem.RouteName = wo_var.Route_Name__c;
                    elem.RouteNumber = wo_var.Route_Number__c;

                    //XEN REYES DOO-4462 May 7, 2020
                    elem.HouseNumSupplement = wo_var.Account_Location__r.House_Number_Supplement__c;

                    //SET REQUIRED ENGINEER Francis Alindogan DOO-3869 02/10/2020
                    if (!String.isBlank(wo_var.Required_Operator__c)){
                        JDEServicesCallout.RequiredEngineers_element reqdEngr = new JDEServicesCallout.RequiredEngineers_element();
                        reqdEngr.EngineerID = new List<String>();

                        reqdEngr.EngineerID.add(wo_var.Required_Operator__r.Name);
                        elem.RequiredEngineers = reqdEngr;
                    }
                    //SET PREFERRED ENGINEER
                    else if (!String.isBlank(wo_var.Preferred_Operator__c)){
                        JDEServicesCallout.PreferredEngineers_element prefEngr = new JDEServicesCallout.PreferredEngineers_element();
                        prefEngr.EngineerID = new List<String>();

                        prefEngr.EngineerID.add(wo_var.Preferred_Operator__r.Name);
                        elem.PreferredEngineers = prefEngr;       
                    }

                    elem.References = true;
                    
                    //CREATE MACHINE ACTION ELEMENT
                    JDEServicesCallout.MachineList_element machineListElement = new JDEServicesCallout.MachineList_element();
                    List<JDEServicesCallout.Machine_element> machineList = new List <JDEServicesCallout.Machine_element>();
                    for(WorkOrderLineItem woli : woIdwoliListMap.get(wo_id)){
                        JDEServicesCallout.Machine_element machineElement = new JDEServicesCallout.Machine_element();
                        machineElement.AssetID = String.valueOf(woli.PhysicalAsset__c) + '-' + String.valueOf(woli.Id);
                        machineList.add(machineElement);
                    }
                    
                    //machineListElement.Machine = new List<JDEServicesCallout.Machine_element>{machineList[0]};
                    machineListElement.Machine = machineList;
                    elem.MachineList = machineListElement;
                    
                    System.debug('machineList: ' + machineList);

                    //SEND MESSAGE IN CLICK
                    try {
                        JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
                        currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
                        currentLog.Target_System_Processed_TimeStamp__c = Datetime.now();
                        System.debug(port.TaskCreateOrUpdate_Route(elem));

                    } catch(Exception ex) {
                        currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                        currentLog.Integration_Message__c = ex.getMessage();
                        System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                    }  
                }

                //UPDATE INTEGRATION LOGS
                if (!iLogMap.isEmpty() && Schema.sObjectType.Integration_Log__c.isUpdateable()) {
                    try {
                        update iLogMap.values();
                    } catch(Exception ex) {
                        CustomLogging.debugException(ex);
                        CustomLogging.pop();
                    }
                }
            }
        }

        CustomLogging.pop();
    }

    /******************************************************************************
    * @author         Abram Vixen Reyes
    * @date           January 2020
    * @description    Mapping SF-Click for Route Operating (Route)
    * @revision(s)
    ******************************************************************************/ 
    public void executeOperationalTask_RouteItem (List<Integration_Log__c> updatableIlogList) {
        CustomLogging.push('executeOperationalTask_RouteItem', 'TS_ClickTaskCreateOrUpdate');
        
        String OPERATING_TASKTYPE = 'operatingtask';
        String COUNTER_TASKTYPE = 'counterreading';
        String ROUTESALES_TASKTYPE = 'routesales';
        String LARGE_TASKTYPE = 'Large';

        String CONST_OPERATING_TASK_RT = 'Operating Task';
        String CONST_COUNTER_READING_RT = 'Counter Reading';
        String CONST_COUNTER_READING_TASK_RT ='Counter Reading Task';
        String CONST_ROUTESALES_TASK_RT = 'Routesales Task';
        
        List<WorkOrderLineItem> WOforIntegration = new List<WorkOrderLineItem>();
        Set<Id> woliIdSet = new Set<Id>();
        Set<Id> woIdSet = new Set<Id>();
        Set<Id> routeIdSet = new Set<Id>();
        Map<Id, WorkOrder> wo_map = new Map<Id, WorkOrder>();
        Map<Id,Integration_Log__c> iLogMap = new Map<Id,Integration_Log__c>();
        Map<Id, Route__c> route_map = new Map<Id, Route__c>();
        Map<String, List<WorkOrderLineItem>> woIdwoliListMap = new Map<String, List<WorkOrderLineItem>>();
        
        System.debug('updatableIlogList Route: ' + updatableIlogList);
        
        //Karen Hung 18/2/2021 DOO-5166 feature flag
        if(!featureFlags.isEmpty()){
            for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                if(flag.Enable__c && !Test.isRunningTest()){                       
                    if(flag.QualifiedApiName == 'DOO_5166_Indicate_Survey'){
                        surveySettingEnabled = true;
                    }    
                }                
            }
        }

        for (Integration_Log__c ilog : updatableIlogList) {
            woliIdSet.add(ilog.Work_Order_Line_Item__c);
            iLogMap.put(ilog.Work_Order_Line_Item__c, ilog);
        }                                            

        List<WorkOrderLineItem> woliList = [SELECT Id, RecordTypeId, JDELineItemNumber__c, WorkOrderType__c, CreatedDate, SLADate__c, EarlyStart__c,
                                            AccountLocation__r.Apttus_Config2__PostalCode__c , AccountLocation__r.Shipping_Country_ISO__c, AccountLocation__r.Apttus_Config2__City__c, AccountLocation__r.Shipping_Street_Only__c,
                                            AccountLocation__r.Shipping_State__c,  Building__c , Floor__c, AccountLocation__r.SAP_Customer_ID__c, ReturnTask__c,
                                            AccountLocation__r.Name,AccountLocation__r.Third_Party_Resource__c, AccountLocation__r.Third_Party_Resource__r.Name, //Karen Hung DOO-5166 
                                            Enabled_Survey_in_Click__c, WorkOrder.Enabled_Survey_in_Click__c, //Karen Hung DOO-5166 
                                            PhysicalAsset__r.ServiceWindow__c, PhysicalAsset__r.TypeOfContract__c, AccountLocation__r.Upfront_Call_Needed__c, PhysicalAsset__r.EndDate__c, // AlternativeMachine__c
                                            PhysicalAsset__r.WTSChangedBy__c,
                                            PhysicalAsset__r.CustomerReferenceNumber__c,
                                            Case__c,Case__r.RepeatVisit__c,Area__c,
                                            StairNeeded__c, WorkOrderId, SmokingArea__c, AccountLocation__r.Screening_Required__c, 
                                            Subject, Description, ScheduleManually__c, IgnoreCalendar__c, Movement__c,     
                                            FirstRoutesalesVisit__c,        
                                            PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.OP_LastPerformingOperator__r.Name,
                                            PricebookEntry.Product2.Name, pricebookentry.product2.ProductCode, PhysicalAsset__c, PhysicalAsset__r.NextWTSDate__c, 
                                            PhysicalAsset__r.DeInstallationDate__c, LeaveMachineAtCustomer__c, PhysicalAsset__r.LastWTSdate__c, PhysicalAsset__r.SerialNumber__c, PhysicalAsset__r.InitialActivationDate__c,PhysicalAsset__r.Area__c,
                                            PhysicalAsset__r.LastPreventiveMaintenanceDate__c, PhysicalAsset__r.InstallationDate__c, WorkOrderLineItemType__c, OP_IsHoliday__c, MachineCare__c, OP_247Customer__c, OP_TimeIndicator__c,
                                            AccountLocation__r.Shipping_House_Number__c,
                                            Re_active__c, PhysicalAsset__r.AdditionalDetails__c,
                                            Status, OP_PreferredOperator__c, OP_PreferredOperator__r.Name,
                                            PreferredEngineer__c, PreferredEngineer__r.Name,
                                            Case__r.CaseNumber, SendCounterReadingsOperating__c, AccountLocation__r.Custom_Service_Hours__c, Calendar__c, Sequence_Number__c,                                            
                                            Replace_WTS__c, //Francis Allen Alindogan DOO-4786 07.28.2020
                                            Waterfilter_Suggestion__c, //Francis Allen Alindogan DOO-4786 07.28.2020
                                            WorkOrder.Task_Activity_Type__c  // Francis Allen Alindogan 04/03/2020                                            
                                            FROM WorkOrderLineItem WHERE Id IN: woliIdSet ORDER BY Sequence_Number__c ASC NULLS LAST];
        
        if(!woliList.isEmpty()){
            for(WorkOrderLineItem woli_var: woliList){
                woIdSet.add(woli_var.WorkOrderId);
            }
        }
        
        if(!woIdSet.isEmpty()){
            //Karen Hung DOO-4886 added planned duration field
            wo_map = new Map<Id, WorkOrder>([SELECT Id, Route_Id__c, Route_Name__c, Route_Number__c, WorkOrderNumber, CreatedDate, Account_Location__c,Enabled_Survey_in_Click__c, Account_Location__r.Third_Party_Resource__c, Account_Location__r.Third_Party_Resource__r.Name,Account_Location__r.Apttus_Config2__PostalCode__c, Account_Location__r.Shipping_Country_ISO__c,Account_Location__r.Apttus_Config2__City__c, Account_Location__r.Shipping_Street_Only__c, Account_Location__r.Shipping_State__c, Account_Location__r.Shipping_House_Number__c, Account_Location__r.SAP_Customer_ID__c, Account_Location__r.Name, Account_Location__r.Screening_Required__c, Account_Location__r.MTTOLocationSpecific__c, Actual_Duration__c, Planned_Duration__c, Early_Start_Date__c, SLA_Date__c, Preferred_Operator__c, Preferred_Operator__r.Name, Status, Required_Operator__c,Required_Operator__r.Name,
            Account_Location__r.Truck_Needed__c, //XEN REYES DOO-4305 Mar. 31, 2020
            Account_Location__r.House_Number_Supplement__c //XEN REYES DOO-4462 May 7, 2020
            FROM WorkOrder WHERE Id IN: woIdSet]);

            //GET ALL ROUTE FROM WORK ORDER AND QUERY
            /* if(!wo_map.isEmpty()){
                Set<Id> routeSet = new Set<Id>();
                for(WorkOrder wo_var : wo_map.values()){
                    if(wo_var.Route_Id__c != null) routeSet.add(wo_var.Route_Id__c);
                }

                if(!routeSet.isEmpty()){
                    route_map = new Map<Id, Route__c>([SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Preferred_Operator__r.Name, Required_Operator__c, Required_Operator__r.Name FROM Route__c WHERE Id IN: routeSet]);
                }
            } */
        }
        
        Id operatingTask_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_OPERATING_TASK_RT).getRecordTypeId();
        Id counterReading_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_COUNTER_READING_RT).getRecordTypeId();
        Id counterReadingTask_RT_Id =Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_COUNTER_READING_TASK_RT).getRecordTypeId();
        Id routesalesTask_RT_Id = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_ROUTESALES_TASK_RT).getRecordTypeId();
        Id machineSurvey_RT_Id = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('OPG_Machine').getRecordTypeId();
        Id warehouseSurvey_RT_Id = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('OPG_Warehouse').getRecordTypeId();

        Set<Id> physicalAssetIdSet = new Set<Id>();
        List<APTS_CounterReadingData__c> woliCounterReadingList = new List<APTS_CounterReadingData__c>();
        Map<Id, List<APTS_CounterReadingData__c>> assetCounterReadingListMap = new Map<Id, List<APTS_CounterReadingData__c>>();

        //GET THE PHYSICAL ASSET OF EACH OPERATING TASK
        if(!woliList.isEmpty()){
            for(WorkOrderLineItem woli : woliList){
                physicalAssetIdSet.add(woli.PhysicalAsset__c); 
            }

            //GET THE COUNTER READING ATTRIBUTES OF EACH MACHINE
            if (!physicalAssetIdSet.isEmpty()){

                woliCounterReadingList = [SELECT Id, APTS_PriceType__c, APTS_Counter_Description__c, APTS_Current_Reading_ValuePaid__c, APTS_Current_Reading_ValueFree__c, APTS_Current_Reading_Date__c, APTS_AvgConsumptionFree__c, APTS_AvgConsumptionPaid__c, APTS_CounterSequence__c, TS_Physical_Asset__c, APTS_CounterID__c FROM APTS_CounterReadingData__c WHERE TS_Physical_Asset__c IN: physicalAssetIdSet AND APTS_Counter_Status__c = 'Active' AND APTS_CounterId__c != null ORDER BY APTS_CounterSequence__c ASC];

                if(!woliCounterReadingList.isEmpty()){
                    for(APTS_CounterReadingData__c aptscr : woliCounterReadingList){
                        if(assetCounterReadingListMap.containsKey(aptscr.TS_Physical_Asset__c)){
                            assetCounterReadingListMap.get(aptscr.TS_Physical_Asset__c).add(aptscr);
                        } else {
                            assetCounterReadingListMap.put(aptscr.TS_Physical_Asset__c, new List<APTS_CounterReadingData__c>{aptscr});
                        }
                    }
                }
            }

            //GROUP OPERATING TASK PER WORK ORDER
            for(WorkOrderLineItem wo_var : woliList){
                if(woIdwoliListMap.containsKey(wo_var.WorkOrderId)){
                    woIdwoliListMap.get(wo_var.WorkOrderId).add(wo_var);
                } else {
                    woIdwoliListMap.put(wo_var.WorkOrderId, new List<WorkOrderLineItem>{wo_var});
                }
            }

            //CREATE MESSAGE FOR EACH BUNDLE
            if(!woIdwoliListMap.isEmpty()){
                for(String wo_id : woIdwoliListMap.keySet()){

                    //WORK ORDER / ROUTE RECORD                    
                    WorkOrder wo_var = wo_map.get(wo_id);

                    //CREATE TASK ELEMENT
                    JDEServicesCallout.TaskCreateOrUpdate_element elem = new JDEServicesCallout.TaskCreateOrUpdate_element();
                    
                    elem.CallID = String.valueOf('RT-' + wo_var.WorkOrderNumber);
                    elem.WorkOrdeID = wo_var.Id;
                    elem.TaskType = 'S20';
                    elem.OpenDate= formatDateTime(wo_var.CreatedDate);
                    elem.EarlyStart= formatDateTime(wo_var.Early_Start_Date__c);
                    elem.SLA = formatDateTime(wo_var.SLA_Date__c);
                    elem.Postcode = wo_var.Account_Location__r.Apttus_Config2__PostalCode__c ;
                    elem.Country = wo_var.Account_Location__r.Shipping_Country_ISO__c;     
                    elem.City = wo_var.Account_Location__r.Apttus_Config2__City__c;
                    elem.Street = wo_var.Account_Location__r.Shipping_Street_Only__c;              
                    elem.State = wo_var.Account_Location__r.Shipping_State__c;
                    elem.StreetNumber = wo_var.Account_Location__r.Shipping_House_Number__c;
                    elem.CustomerNumber = wo_var.Account_Location__r.SAP_Customer_ID__c;      
                    elem.Customer = wo_var.Account_Location__r.Name;
                    elem.ScreeningRequired = wo_var.Account_Location__r.Screening_Required__c;
                    elem.WorkOrderNumber = wo_var.Id;
                    elem.RT_OperatingTask = operatingTask_RT_Id;
                    elem.RT_CounterReading = counterReading_RT_Id;
                    elem.RT_CounterReadingTask = counterReadingTask_RT_Id;
                    

                    //XEN REYES DOO-4305 Mar. 31, 2020
                    elem.TruckNeeded = wo_var.Account_Location__r.Truck_Needed__c;
                    if(wo_var.Account_Location__r.Truck_Needed__c){
                        elem.CallID = String.valueOf('OR-' + wo_var.WorkOrderNumber);
                    }

                    /*if(wo_var.Actual_Duration__c != null){
                        elem.MTTO = String.valueOf(Math.ceil(wo_var.Actual_Duration__c * 3600));
                    }*/
                    //Karen Hung 8.10.2020 DOO-4886 changed actual duration to planned duration
                    if(wo_var.Planned_Duration__c != null){
                        elem.MTTO = String.valueOf(Math.ceil(wo_var.Planned_Duration__c * 3600));
                    }
                    
                    //Karen Hung DOO-5166 18/2/2021
                    if(surveySettingEnabled && wo_var.Enabled_Survey_in_Click__c != null){
                    	elem.Survey = wo_var.Enabled_Survey_in_Click__c;
                        elem.Interviewee = wo_var.Account_Location__r.Third_Party_Resource__r?.Name;
                    }                                        
                    
                    elem.RouteName = wo_var.Route_Name__c;
                    elem.RouteNumber = wo_var.Route_Number__c;
                    
                    //XEN REYES DOO-4462 May 7, 2020
                    elem.HouseNumSupplement = wo_var.Account_Location__r.House_Number_Supplement__c;

                    //SET REQUIRED ENGINEER Francis Alindogan DOO-3869 02/10/2020
                    if (!String.isBlank(wo_var.Required_Operator__c)){
                        JDEServicesCallout.RequiredEngineers_element reqdEngr = new JDEServicesCallout.RequiredEngineers_element();
                        reqdEngr.EngineerID = new List<String>();

                        reqdEngr.EngineerID.add(wo_var.Required_Operator__r.Name);
                        elem.RequiredEngineers = reqdEngr;
                    }
                    //SET PREFERRED ENGINEER
                    else if (!String.isBlank(wo_var.Preferred_Operator__c)){
                        JDEServicesCallout.PreferredEngineers_element prefEngr = new JDEServicesCallout.PreferredEngineers_element();
                        prefEngr.EngineerID = new List<String>();

                        prefEngr.EngineerID.add(wo_var.Preferred_Operator__r.Name);
                        elem.PreferredEngineers = prefEngr;       
                    }

                    //CREATE MACHINE ACTION ELEMENT
                    for(WorkOrderLineItem woli : woIdwoliListMap.get(wo_id)){

                        JDEServicesCallout.MachineList_element machineListElement = new JDEServicesCallout.MachineList_element();
                        List<JDEServicesCallout.Machine_element> machineList = new List <JDEServicesCallout.Machine_element>();

                        JDEServicesCallout.Machine_element machineElement = new JDEServicesCallout.Machine_element();
                        machineElement.WOLIID = woli.JDELineItemNumber__c;
                        machineElement.SequenceNumber = String.valueOf(woli.Sequence_Number__c);
                        machineElement.Name = woli.PricebookEntry.Product2.Name;
                        machineElement.MachineType = woli.pricebookentry.product2.ProductCode;
                        machineElement.AssetID = String.valueOf(woli.PhysicalAsset__c) + '-' + String.valueOf(woli.Id);
                        machineElement.NextFilterChangeDate = formatDateTime(woli.PhysicalAsset__r.NextWTSDate__c); 
                        machineElement.InstallDate = formatDateTime(woli.PhysicalAsset__r.InitialActivationDate__c);
                        machineElement.DeInstallDate = formatDateTime(woli.PhysicalAsset__r.DeInstallationDate__c);
                        machineElement.LeaveAtCustomer = woli.LeaveMachineAtCustomer__c;
                        machineElement.FilterChangeDate = formatDateTime(woli.PhysicalAsset__r.LastWTSdate__c);
                        machineElement.SerialNr = woli.PhysicalAsset__r.SerialNumber__c;
                        machineElement.MachineAge = formatDateTime(woli.PhysicalAsset__r.InitialActivationDate__c);
                        machineElement.LastPrevMaintDate = formatDateTime(woli.PhysicalAsset__r.LastPreventiveMaintenanceDate__c);
                        machineElement.LastInstallDate = formatDateTime(woli.PhysicalAsset__r.InstallationDate__c);
                        machineElement.IsHoliday = woli.OP_IsHoliday__c;                 
                        machineElement.OperatingType = woli.MachineCare__c;                                                
                        machineElement.FullWorkingDays = woli.OP_247Customer__c;           
                        machineElement.TimeIndicator = woli.OP_TimeIndicator__c;                                
                        machineElement.WTSOwner = woli.PhysicalAsset__r.WTSChangedBy__c ;
                        machineElement.OperatorContact = woli.PhysicalAsset__r.OP_LastPerformingOperator__r.Name;
                        machineElement.MachineInternalNumber = woli.PhysicalAsset__r.CustomerReferenceNumber__c != null ? woli.PhysicalAsset__r.CustomerReferenceNumber__c.left(128) : '';
                        machineElement.Instructions = woli.PhysicalAsset__r.AdditionalDetails__c;
                        machineElement.PerformCounterReading = woli.SendCounterReadingsOperating__c;
                        
                        //Karen Hung DOO-5166 18/2/2021
                        if(surveySettingEnabled && woli.Enabled_Survey_in_Click__c != null){
                            machineElement.Survey = woli.Enabled_Survey_in_Click__c;
                            machineElement.RT_MachineSurvey = machineSurvey_RT_Id;
                        	machineElement.RT_WarehouseSurvey = warehouseSurvey_RT_Id;
                            machineElement.Interviewee = woli.AccountLocation__r.Third_Party_Resource__r?.Name;
                        }

                        //Francis Alindogan DOO-3869 02/10/2020
                        machineElement.Building = woli.PhysicalAsset__r.Building__c != null ? woli.PhysicalAsset__r.Building__c.left(64) : '';
                        machineElement.Floor = woli.PhysicalAsset__r.Floor__c != null ? woli.PhysicalAsset__r.Floor__c.left(64) : '';
                        machineElement.Area = woli.PhysicalAsset__r.Area__c != null ? woli.PhysicalAsset__r.Area__c.left(64) : '';

                        //Karen Hung DOO-3116 Feb 7, 2020
                        if(woli.Status == TS_Constants.STATUS_CANCELED){
                            machineElement.Status = woli.Status;
                        }                        

                        //Francis Allen Alindogan DOO-4786 07.28.2020
                        if(woli.Waterfilter_Suggestion__c != null){
                            machineElement.WFSuggestion = woli.Waterfilter_Suggestion__c;            
                        }

                        //SET ACTIVITY TYPE
                        JDEServicesCallout.Activities_element activities = new JDEServicesCallout.Activities_element();
                        activities.activity = woli.WorkOrderLineItemType__c;
                        machineElement.Activities = activities; 

                        //SET COUNTER READING
                        if(woli.WorkOrderLineItemType__c == LARGE_TASKTYPE && woli.SendCounterReadingsOperating__c){
                            if(!woliCounterReadingList.isEmpty() && assetCounterReadingListMap.containsKey(woli.PhysicalAsset__c)){
                                
                                JDEServicesCallout.CounterReadings_element machineCounterReadings = new JDEServicesCallout.CounterReadings_element();
                                List<JDEServicesCallout.CounterReading_element> machineCounterReadingList = new List<JDEServicesCallout.CounterReading_element>();

                                for (APTS_CounterReadingData__c cr : assetCounterReadingListMap.get(woli.PhysicalAsset__c)){
                                                                            
                                        JDEServicesCallout.CounterReading_element crel = new  JDEServicesCallout.CounterReading_element();
                                                                            
                                        crel.Name = String.valueOf(cr.APTS_Counter_Description__c);
                                        crel.LastPaid = cr.APTS_Current_Reading_ValuePaid__c;
                                        crel.LastFree = cr.APTS_Current_Reading_ValueFree__c;
                                        crel.UniqueID = String.valueOf(cr.APTS_CounterID__c);
                                        crel.CounterReadingDataRecordId = String.valueOf(cr.Id);
                                        
                                        if (cr.APTS_Current_Reading_Date__c != null) crel.LastReadingDate = formatDateTime(cr.APTS_Current_Reading_Date__c.date());
                                        if (cr.APTS_AvgConsumptionFree__c != null) crel.AverageFreeDrinks = cr.APTS_AvgConsumptionFree__c;
                                        if (cr.APTS_AvgConsumptionPaid__c != null) crel.AveragePaidDrinks = cr.APTS_AvgConsumptionPaid__c;
                                        if (cr.APTS_CounterSequence__c != null) crel.Sequence = Integer.valueOf(cr.APTS_CounterSequence__c);

                                        machineCounterReadingList.add(crel);
                                }
                                machineElement.CounterReadingPriceType = assetCounterReadingListMap.get(woli.PhysicalAsset__c)[0].APTS_PriceType__c;
                                machineCounterReadings.CounterReading = machineCounterReadingList;
                                machineElement.CounterReadings = machineCounterReadings;

                                System.debug('machineElement.CounterReadings: ' + machineElement.CounterReadings);
                                System.debug('machineCounterReadingList: ' + machineCounterReadingList);
                            }
                        }

                        machineList.add(machineElement);
                        machineListElement.Machine = machineList;
                        elem.MachineList = machineListElement;
                        
                        System.debug('machineList: ' + machineList);
                        
                        //SEND MESSAGE IN CLICK
                        Integration_Log__c currentLog = iLogMap.get(woli.Id);
                        
                        try {
                            JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
                            currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
                            currentLog.Target_System_Processed_TimeStamp__c = Datetime.now();
                            System.debug(port.TaskCreateOrUpdate_Route(elem));

                            if(woli.WorkOrder.Task_Activity_Type__c != null){
                                system.debug('checkIntegration1');
                                WOforIntegration.add(woli);
                            }

                        } catch(Exception ex) {
                            currentLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                            currentLog.Integration_Message__c = ex.getMessage();
                            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                        }                      
                    }
                }

                //UPDATE INTEGRATION LOGS
                if (!iLogMap.isEmpty() && Schema.sObjectType.Integration_Log__c.isUpdateable()) {
                    try {
                        update iLogMap.values();
                    } catch(Exception ex) {
                        CustomLogging.debugException(ex);
                        CustomLogging.pop();
                    }
                }

                //CHECK IF THERE ARE FOR WORKORDERS FOR INTEGRATION
                if(WOforIntegration != null && WOforIntegration.size() > 0){
                    system.debug('checkIntegration2');
                    WorkOrderTriggerHandler.checkForIntegration(WOforIntegration);
                }
            }
        }

        CustomLogging.pop();
    }
}