/**********************************************************************
Name: aptsConverionOrderSelection
Date: 06 July 2020
Author: Sai Sagar
Change Verison History: 
**********************************************************************/
import { LightningElement, wire, track ,api} from "lwc";
import getConversionOrderOptions from "@salesforce/apex/APTS_CreateConversionOrderController.getConversionOrderOptions";

const columns = [
  {
    label: "What type of Action do you want to perform ? ",
    fieldName: "APTS_Description__c",
    type: "text"
  }
]; 

export default class AptsConverionOrderSelection extends LightningElement {
  @api enabledSelections;
  @api isLoaded;
  @track columns = columns;
  @track selectedActions;
  @track recordsToDisplay = [];
  @track selectedActions = [];
  @wire(getConversionOrderOptions)
  wOptions({ error, data }) {  
    if (data) {
      let actions = [];
      for (let i in data) {
        let action = {};
        action.label = data[i].APTS_Description__c;
        action.value = data[i].MasterLabel;
        actions.push(action);
      } 
      this.recordsToDisplay = actions;
    } else {
      this.error = error;
    }
  }

  /* getSelectedRows(event) {
         const selectedRows = event.detail.selectedRows;
         let selectedRecordIds = [];
         // Display that fieldName of the selected rows
         for (let i = 0; i < selectedRows.length; i++){
             
             selectedRecordIds.push(selectedRows[i].MasterLabel);
         }
         console.log(selectedRecordIds);
         this.dispatchEvent(new CustomEvent('selectactions', {detail: selectedRecordIds})); //Send records to display on table to the parent component        
     }  */
  handleChange(event) { 
    this.selectedActions= [];
    this.selectedActions.push(event.detail.value);
    // if (event.target.checked)   {

    //     this.template.querySelectorAll("lightning-input").forEach(function(element) {
    //         if ((event.target.name == "Discounts" || event.target.name == "Billing Settings") && (element.name == "Renewal" || element.name == "Termination")) {
    //             element.disabled = true;
    //         }
    //         if (event.target.name == "Renewal" && (element.name == "Billing Settings" || element.name == "Termination" || element.name == "Discounts")) {
    //             element.disabled = true;
    //         }

    //         if (event.target.name == "Termination" && (element.name == "Billing Settings" || element.name == "Renewal" || element.name == "Discounts")) {
    //             element.disabled = true;
    //         }
    //     });
    // } else {
    //     this.selectedActions.pop(event.target.name);
    //     if (this.selectedActions.length == 0) {
    //         this.template.querySelectorAll("lightning-input").forEach(function(element) {
    //             element.disabled = false;
    //         });
    //     }
    // }
    this.dispatchEvent(
      new CustomEvent("selectactions", {
        detail: this.selectedActions
      })
    );
  }
}