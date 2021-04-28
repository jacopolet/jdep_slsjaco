/**********************************************************************
Name: aptsRenewal
Date: 09 July 2020
Author: Venky Muppalaneni
Change Verison History: 
**********************************************************************/
import { LightningElement, api } from 'lwc';
import getOptionLines from '@salesforce/apex/APTS_CreateConversionOrderController.getOptionLinesForRenewal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
const columns = [    
    { label:'Asset Name',sortable:true, fieldName: 'assetLink', type: 'url', typeAttributes: {label: {fieldName: 'name'}, tooltip:'Go to detail page', target: '_blank'}},
	{ label: 'Charge Type', fieldName: 'chargeType', type: 'text'} ,
	{ label: 'Billing Cycle Start', fieldName: 'billingCycleStart', type: 'text'} ,
	{ label: 'Billing Day of Month', fieldName: 'billingDayOfMonth', type: 'text'} ,
    { label: 'Start Date', fieldName: 'assetStartDate', type: 'date'} ,
    { label: 'End Date', fieldName: 'assetEndDate', type: 'date'} ,
	{ label: 'Next Invoice Date', fieldName: 'nextInvoiceDate', type: 'date'} ,
	{ label: 'Billing Rule', fieldName: 'billingRule', type: 'text'}     
]; 

export default class AptsModifyDiscounts extends LightningElement {
    @api recordId;
    columns = columns;
    isLoaded;
    initalRecords;
    disabledRenewal=true;
    allRecords; 
    renewalDate;
    assetEndDate;
    connectedCallback() {
        this.isLoaded=false;
        getOptionLines( {recordId: this.recordId} )
        .then((data) => {
            if(data){
                this.initalRecords = new Map(); 
                let recs = [];
                for(let i=0; i<data.length; i++){
                    let asset = {};
                    asset.rowNumber = ''+(i+1);
                    asset.assetLink = '/'+data[i].id;
                    asset = Object.assign(asset, data[i]);    
                    this.initalRecords.set(asset.id, Object.assign({},asset));
                    if(!this.assetEndDate){
                        this.assetEndDate=data[i].assetEndDate;
                    }
                    else if(this.assetEndDate<data[i].assetEndDate){
                        this.assetEndDate=data[i].assetEndDate;
                    }
                            
                    recs.push(asset);
                }
                this.allRecords = recs;
                this.isLoaded=true;
            }else{
                this.error = error;
            } 
               
                
        });
    }

    handleRenewalDateChange(event) {
        this.renewalDate = event.detail.value;
      
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); 
        var yyyy = today.getFullYear();
        today = yyyy + '-' + mm + '-' + dd;
        let inValidLineItem=false;
        if(this.renewalDate<this.assetEndDate){
            this.showToast(false,`The renewal date cannot be earlier than the asset end date.`,'error','sticky');
            inValidLineItem=true;
        }
        else if(this.renewalDate<=today){
            this.showToast(false,`The renewal date cannot be today or in the past.`,'error','sticky');
            inValidLineItem=true;
        }
        else if(this.renewalDate>today){
            this.showToast(false,`You are now updating your asset to a renewal date in the future. This means that your new start date will also move to a new date in the future. Please be aware that if you proceed you cannot modify your existing Pending Billing Schedules anymore.`,'warning','sticky');
           
        }
        if(this.renewalDate && !inValidLineItem){
            this.disabledRenewal=false;
        }
        else{
            this.disabledRenewal=true;
        }
    }
    handleRenewal(event) { 
        let inValidLineItem=false;
        if(!this.renewalDate){
            inValidLineItem=true;
        } 
       
        if(!inValidLineItem){
            this.disabledRenewal=true;
            this.dispatchEvent(
                new CustomEvent("termination", {
                bubbles:true,
                composed:true,
                detail: this.renewalDate
                })
            );
          
        }  
    }
    showToast(title,message,variant,mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant:variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }
        
}