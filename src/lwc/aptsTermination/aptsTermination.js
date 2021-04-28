/**********************************************************************
Name: aptsTermination
Date: 09 July 2020
Author: Venky Muppalaneni
Change Verison History: 
**********************************************************************/
import { LightningElement, api } from 'lwc';
import getOptionLines from '@salesforce/apex/APTS_CreateConversionOrderController.getOptionLinesForTermination';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import dateWarning from '@salesforce/label/c.APTS_ModifyDiscountStartDate';
const columns = [    
    { label:'Asset Name',sortable:true, fieldName: 'assetLink', type: 'url', typeAttributes: {label: {fieldName: 'name'}, tooltip:'Go to detail page', target: '_blank'}},
    { label: 'Charge Type', fieldName: 'chargeType', type: 'text'} ,
    { label: 'Original Start Date', fieldName: 'originalStartDate', type: 'date'} ,
	{ label: 'Asset End Date', fieldName: 'assetEndDate', type: 'date'} ,
	{ label: 'Last Invoiced Period', fieldName: 'lastInvoicedPeriod', type: 'date'} ,
	{ label: 'Next Invoice Date', fieldName: 'nextInvoiceDate', type: 'date'}    
]; 



export default class AptsTermination extends LightningElement {
    @api recordId;
    columns = columns;
    initalRecords;
    allRecords;
    isLoaded;
    terminationDate;
    assetStartDate;
    disabledTerminate=true;
    orderStatus;
    nextInvoiceDate;
    dataChangedClass= 'slds-is-edited slds-text-color_success customFontChanged';
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
                    recs.push(asset);
                    if(!this.assetStartDate){
                        this.assetStartDate=data[i].originalStartDate;
                    }
                    else if(this.assetStartDate<data[i].originalStartDate){
                        this.assetStartDate=data[i].originalStartDate;
                    }
                    if(!this.nextInvoiceDate){
                        this.nextInvoiceDate=data[i].nextInvoiceDate;
                    }
                    else if(this.nextInvoiceDate<data[i].nextInvoiceDate){
                        this.nextInvoiceDate=data[i].nextInvoiceDate;
                    }

                }
                
                this.allRecords = recs;
                this.isLoaded=true;
            }else{
                this.error = error;
            } 
          
        });
    } 

    handleTerminationDateChange(event) {
        this.terminationDate = event.detail.value;
        if(this.terminationDate){
            this.disabledTerminate=false;
        }
        else{
            this.disabledTerminate=true;
        }
    }

    handleTerminate(event) { 
        let inValidLineItem=false;
        if(!this.terminationDate){
            inValidLineItem=true;
        }
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); 
        var yyyy = today.getFullYear();
        today = yyyy + '-' + mm + '-' + dd;
        if(this.terminationDate<this.assetStartDate || this.terminationDate>today){
            this.showToast(false,`${dateWarning.replace("end", "current").replace("start","end")}`,'error','sticky');
            inValidLineItem=true;
        }
        else if(this.terminationDate<this.nextInvoiceDate){
            this.showToast(false,'Please be aware that your end date deviates from your last invoiced period end date. This will result into a superseded billing schedule where the system will create a credit note for the remaining cancelled period by applying pro-ration treatment.','warning','sticky');
            
        }
        if(!inValidLineItem){
            this.disabledTerminate=true;
            this.orderStatus=true;
            this.dispatchEvent(
                new CustomEvent("termination", {
                bubbles:true,
                composed:true,
                detail: this.terminationDate
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