/**********************************************************************
Name: aptsBillingSettings
Date: 07 July 2020
Author: Venky Muppalaneni
Change Verison History: 
**********************************************************************/
import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAssetOptions from '@salesforce/apex/APTS_CreateConversionOrderController.getAssetOptions';
import { refreshApex } from '@salesforce/apex';
import emtyStartDateWarning from '@salesforce/label/c.APTS_BillingSettingStartDateWarining';
import startDateWarning from '@salesforce/label/c.APTS_ModifyDiscountStartDate';


const columns = [        
    { label:'Asset Name',sortable:true, fieldName: 'assetLink', type: 'url', typeAttributes: {label: {fieldName: 'assetLine.Name'}, tooltip:'Go to detail page', target: '_blank'}},
	{ label: 'Charge Type', fieldName: 'assetLine.Apttus_Config2__ChargeType__c', type: 'text'} ,
	{ label: 'Billing Cycle Start', fieldName: 'Apttus_Config2__BillingCycleStart__c', type: 'text', cellAttributes:{  
        class:{  
            fieldName: `preferenceModified`
        },
        alignment: `left`
    }} ,
	{ label: 'Billing Day of Month', fieldName: 'Apttus_Config2__BillingDayOfMonth2__c', type: 'text' , cellAttributes:{  
        class:{  
            fieldName: `preferenceModified`
        },
        alignment: `left`
    }} ,
    { label: 'Billing Frequency', fieldName: 'assetLine.Apttus_Config2__BillingFrequency__c', type: 'text' , cellAttributes:{  
        class:{  
            fieldName: `frequencyModified`
        },
        alignment: `left`
    }} ,     
    { label: 'Original Start Date', fieldName: 'assetLine.Apttus_Config2__OriginalStartDate__c', type: 'date'} ,
    { label: 'Start Date', fieldName: 'assetLine.Apttus_Config2__StartDate__c', type: 'date', cellAttributes:{  
        class:{  
            fieldName: `startDateModified`
        },
        alignment: `left`
    }} ,
    { label: 'End Date', fieldName: 'assetLine.Apttus_Config2__EndDate__c', type: 'date'},
	{ label: 'Next Invoice Date', fieldName: 'nextInvoicedDate', type: 'date'} ,
	{ label: 'Billing Rule', fieldName: 'assetLine.Apttus_Config2__BillingRule__c', type: 'text'}      
]; 


export default class AptsBillingSettings extends LightningElement {
    columns = columns;
    @api assetId;
    allRecords ;
    initalRecords ;
    selectedAssetOptions;
    filterAssetOptions;
    cascadeButtonLabel;
    //INPUT
    selectedStartDate;
    selectedBillingFrequency;
    selectedChargeType;
    billingPreFilter;
    selectedBillingPref;
    isLoaded;
    showTable;
    @track notification = {};
    orderCreated;
    orderInProgress;
    updatedAssetOptionMap = new Map();

    @wire(getAssetOptions, { bundelHeaderId: '$assetId' })
    wiredAssets({ error, data }) {
        if(data){                
            let recs = [];    
            this.initalRecords = new Map();        
            for(let i=0; i<data.length; i++){
                if(!this.billingPreFilter && data[i] && data[i].assetLine
                    && data[i].assetLine.Apttus_Config2__AccountId__r && data[i].assetLine.Apttus_Config2__AccountId__r.Sales_Organization__c){
                    this.billingPreFilter = `APTS_SalesOrg__c= '${data[i].assetLine.Apttus_Config2__AccountId__r.Sales_Organization__c}'`;                        
                }
                let asset = {};                   
                let rowKeys = Object.keys(data[i]);                    
                //iterate 
                rowKeys.forEach((rowKey) => {                        
                    //get the value of each Key from row
                    const rowValue = data[i][rowKey];                        
                    //check if the value is a object -- ex: assetRecord
                    if(rowValue.constructor === Object){                            
                        //if it's an object flatten it
                        this._flatten(rowValue, asset, rowKey)        
                    }else{                            
                        //if it’s a not Object
                        asset[rowKey] = rowValue;
                    }                        
                });                    
                asset.rowNumber = ''+(i+1);
                asset.assetLink = '/'+data[i].assetLine.Id;
                asset.Apttus_Config2__BillingCycleStart__c = data[i].assetLine.Apttus_Config2__BillingPreferenceId__r ? data[i].assetLine.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c : "";  
                asset.Apttus_Config2__BillingDayOfMonth2__c = data[i].assetLine.Apttus_Config2__BillingPreferenceId__r ? data[i].assetLine.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingDayOfMonth2__c : "";  
                asset = Object.assign(asset, data[i]); 
                let baseAsset = {}; 
                this.initalRecords.set(asset.assetLine.Id, Object.assign(baseAsset, asset));           
                recs.push(asset);
            }                               
            this.allRecords = recs;
            // dispaly table only if there is any records
            if(this.allRecords && this.allRecords.length > 0){
                this.showTable = true;
            }      
            this.isLoaded = true;                         
        }else{
            this.error = error;
        } 
    }  
    
    // To Flaten object values 
    _flatten = (objRec, asset, parentKey) => {        
        let keys = Object.keys(objRec);
        keys.forEach((key) => {
            let finalKey = parentKey + '.'+ key;
            asset[finalKey] = objRec[key];
        })
    }
    
    get options() {
        return [
            { label: 'Hourly', value: 'Hourly' },
            { label: 'Daily', value: 'Daily' },
            { label: 'Monthly', value: 'Monthly' },
			{ label: 'Quarterly', value: 'Quarterly' },
            { label: 'Half Yearly', value: 'Half Yearly' },
            { label: 'Yearly', value: 'Yearly' },
			{ label: 'One Time', value: 'One Time' }
        ];
    }
    get chargeType() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Rental Fee', value: 'Rental Fee' },
            // { label: 'Usage Fee', value: 'Usage Fee' },
            { label: 'Service Fee', value: 'Service Fee' },
			{ label: 'Additional Service Fee', value: 'Additional Service Fee' }
            // { label: 'Sales Price', value: 'Sales Price' }
        ];
    }

    handleDateChange(event) {
        this.selectedStartDate = event.target.value;
        this.enableCascade();
    }

    handleBillFrequencyChange(event) {
        this.selectedBillingFrequency = event.target.value;    
        this.enableCascade();  
    }    
    handleChargeTypeChange(event) {
        this.selectedChargeType = event.target.value;   
        this.enableCascade();  
    }


    enableCascade(){
        this.cascadeButtonLabel = undefined;
        if((this.selectedBillingFrequency && this.selectedChargeType) ||  this.selectedBillingPref){
            this.cascadeButtonLabel = 'Cascade';
        }
    }

    handleCascade(event) {       
        this.selectedAssetOptions=this.filterAssetOptions;  
        // Convert array to Hashmap
        if(this.allRecords){
            let assetOptions = this.allRecords;
            let selectedOptionMap = assetOptions.reduce(function(map, obj) {
                map[obj[`assetLine.Id`]] = obj;
                return map;
            }, {});  
                          
            if(!this.selectedStartDate){
                this.showNotification(false, `${emtyStartDateWarning}`, 'Start Date Not Changed', 'warning', `sticky`);
            }             
            
            let modifiedData = []; 
            let inValidLineItem=false; 
            let changedData=[];
            this.allRecords.forEach(ele => {      
                if((this.selectedStartDate<ele[`assetLine.Apttus_Config2__OriginalStartDate__c`] || this.selectedStartDate>ele[`assetLine.Apttus_Config2__EndDate__c`]) && (ele[`assetLine.Apttus_Config2__ChargeType__c`] === this.selectedChargeType ||this.selectedChargeType=="All" ) ){
                    this.showNotification(false,`${startDateWarning}`,'','error','sticky');
                    inValidLineItem=true;
                    
                }
                if(ele[`assetLine.Id`] in selectedOptionMap  && !inValidLineItem){
                  
                    if(this.selectedBillingFrequency && this.selectedChargeType && (ele[`assetLine.Apttus_Config2__ChargeType__c`] === this.selectedChargeType ||this.selectedChargeType=="All" ) ){
                        // Assign new Value
                        ele[`assetLine.Apttus_Config2__BillingFrequency__c`] = this.selectedBillingFrequency ;
                        if(this.initalRecords.get(ele[`assetLine.Id`]).assetLine.Apttus_Config2__BillingFrequency__c !=
                        this.selectedBillingFrequency  ){
                            ele.frequencyModified = 'slds-is-edited slds-text-color_success'; 
                        }else{
                            ele.frequencyModified = '';
                        }
                        if(this.selectedStartDate){
                            // Assign new Value
                            ele[`assetLine.Apttus_Config2__StartDate__c`] = this.selectedStartDate ;
                            if(this.initalRecords.get(ele[`assetLine.Id`]).assetLine.Apttus_Config2__StartDate__c !=
                            this.selectedStartDate  ){
                                ele.startDateModified = 'slds-is-edited slds-text-color_success'; 
                            }else{
                                ele.startDateModified = '';
                            }
                        }
                    }

                    if(this.selectedBillingPref){
                        // Assign new Value
                        ele.Apttus_Config2__BillingPreferenceId__c =  this.selectedBillingPref.Id;   
                        ele[`Apttus_Config2__BillingCycleStart__c`] = this.selectedBillingPref.Apttus_Config2__BillingCycleStart__c ;
                        ele[`Apttus_Config2__BillingDayOfMonth2__c`] = this.selectedBillingPref.Apttus_Config2__BillingDayOfMonth2__c ;                    

                        if(this.initalRecords.get(ele[`assetLine.Id`]).assetLine.Apttus_Config2__BillingPreferenceId__c !=
                        this.selectedBillingPref.Id){
                            ele.preferenceModified = 'slds-is-edited slds-text-color_success'; 
                        }else{
                            ele.preferenceModified = '';
                        }                       
                    } 

                    if(this.selectedStartDate && this.selectedBillingPref){
                        // Assign new Value
                        ele[`assetLine.Apttus_Config2__StartDate__c`] = this.selectedStartDate ;
                        if(this.initalRecords.get(ele[`assetLine.Id`]).assetLine.Apttus_Config2__StartDate__c !=
                        this.selectedStartDate  ){
                            ele.startDateModified = 'slds-is-edited slds-text-color_success'; 
                        }else{
                            ele.startDateModified = '';
                        }
                    }
                    
                    if(ele.preferenceModified === 'slds-is-edited slds-text-color_success' || ele.frequencyModified === 'slds-is-edited slds-text-color_success'){
                        let rec = {}
                        rec.Id = ele.assetLine.Id;
                        rec.startDate = ele[`assetLine.Apttus_Config2__StartDate__c`];
                        rec.billingPreferenceId = ele.Apttus_Config2__BillingPreferenceId__c;
                        rec.billingFrequency = ele[`assetLine.Apttus_Config2__BillingFrequency__c`];
                        this.updatedAssetOptionMap.set(rec.Id, rec);
                    } else if(this.updatedAssetOptionMap.has(ele.assetLine.Id)){
                        this.updatedAssetOptionMap.delete(ele.assetLine.Id);
                    } 
                    
                  
                    changedData.push(ele);               
                }                
                modifiedData.push(ele); 
            });    
            this.allRecords = modifiedData;  
            if(!inValidLineItem){ 
            let changedRecords;
            if(Array.from(this.updatedAssetOptionMap.values() ).length > 0){
                changedRecords = Array.from(this.updatedAssetOptionMap.values());
            }
            this.dispatchEvent(
                new CustomEvent("selectedassets", {
                    bubbles:true,
                    composed:true,
                    detail: changedRecords
                })
            );  
            this.template.querySelector('c-apts-lwc-datatable').setRecordsToDisplay(); 
            }          
        }
    }

    handleAllSelectedRows(event) {
        const selectedRows = event.detail;  
        this.selectedAssetOptions = undefined;            
        if(selectedRows && selectedRows.length > 0 ){
            this.selectedAssetOptions =  selectedRows;   
            this.enableCascade();         
        }   
    }     

    handleSelected(event){
        this.selectedBillingPref = undefined;
        let res = JSON.stringify(event.detail);
        if(event && !res.includes('Remove Selected')){
            this.selectedBillingPref = event.detail;            
        }        
        this.enableCascade();
    }
    
    reset(){
        this.isLoaded = false;
        setTimeout(() => {refreshApex(this.wiredAssets); this.isLoaded = true;}, 1000);   
            
    }

    showNotification(isCustom, message, title, variant, mode) {
        if(isCustom){
            this.notification.show = true;
            this.notification.message = `${message}`;
            this.notification.title = `${title}`;
            if(variant === 'warning'){
                this.notification.style = `slds-notify slds-notify_toast slds-theme_warning`;
            }
            if(variant === 'error'){
                this.notification.style = `slds-notify slds-notify_toast slds-theme_error`;
            }
            if(variant === 'success'){
                this.notification.style = `slds-notify slds-notify_toast slds-theme_success`;
            } 
        } else{
            const evt = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            });
            this.dispatchEvent(evt);
        }               
    } 
    
    hideNotification() {
        this.notification.show = false;
    }     
    
}