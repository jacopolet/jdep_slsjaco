/**********************************************************************
Name: aptsAssetConversionOrder
Date: 06 July 2020
Author: Sai Sagar
Change Verison History: 
* V100 05/11/2020 Renuka: DQ-3907- Adding Credit Proposal checkbox
v101-21/jan/2021 CTC change for trial
**********************************************************************/
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AptsAssetConversionOrder extends LightningElement {
    @api selectedActions;
	@api selectedAccountId;
	@api selectedAssetId;
	@api credit;
	@api casefilter;
	@track discountsEnabled=false;
	@track billSettingsEnabled=false;
	@track Termination=false;
	@track Status=false;
	@track Renewal=false;
	@track modifyOptions=false;
	@track currentContent
	@track contractChange = false;
	assetRecords;
	showCreditCheck;
	showCaseRemarks;
	selectedcase;

	get hasDefaultValue() {
		console.log('hasDefaultValue--'+this.selectedAssetId);
		this.discountsEnabled=false;
		this.billSettingsEnabled=false;
		this.Termination=false;
		this.Renewal=false;
		this.Status=false;
		this.modifyOptions=false;
		this.showCreditCheck = false;
		this.showCaseRemarks = false;
		this.currentContent=this.selectedActions[0];
		if(this.currentContent=="Discounts"){
			this.discountsEnabled=true;
			this.showCreditCheck = true;
			this.showCaseRemarks = true;
		}else if(this.currentContent=="Billing Settings"){
			this.billSettingsEnabled=true;
			this.showCreditCheck = true;
			this.showCaseRemarks = true;
		}else if(this.currentContent=="Termination"){
			this.Termination=true;
			this.showCreditCheck = true;
			this.showCaseRemarks = true;
		}else if(this.currentContent=="Renewal"){
			this.Renewal=true;
			this.showCaseRemarks = true;
		}else if(this.currentContent=="Status"){
			this.Status=true;
		}else if(this.currentContent=="Add/Remove Options"){
			this.modifyOptions=true;
			this.showCreditCheck = true;
			this.showCaseRemarks = true;
		}else if(this.currentContent=="Contract Change"){
			this.contractChange=true;
			this.showCreditCheck = true;
		}
		return this.currentContent;
	}
	handleCreditBlock(event){
		this.showToast(false,`When credit proposal applied on the future conversion orders where it was not included earlier then it is applicable for the billing schedules of the future Ready for Invoice date.`,'warning','sticky');
		const customEventCheck = new CustomEvent('selected', {
			detail: {val:event.target.value,checked:event.target.checked}
		});
		this.dispatchEvent(customEventCheck);
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
	handleInvRemark(event){
		const customEventCheck = new CustomEvent('invoiceremark', {
			detail: event.target.value
		});
		this.dispatchEvent(customEventCheck);
	}
	handleSelected(event){
		console.log('SelectedCase'+event.detail);
        this.selectedcase = undefined;
		//if(event && !res.includes('Remove Selected')){
			this.selectedcase = event.detail;    
			const customEventCheck = new CustomEvent('casechange', {
				detail: event.detail
			});
			this.dispatchEvent(customEventCheck);        
        //} 
	}
	// handleSelectedAssets(event)
    // {
	// 	this.assetRecords=event.detail;
	// 	this.dispatchEvent(
	// 		new CustomEvent("selectedassets", {
	// 		  detail: this.assetRecords
	// 		})
	// 	  );  
    // }
    // handleSelect(event) {
    //     const selected = event.detail.name;
	// 	this.discountsEnabled=false;
	// 	this.billSettingsEnabled=false;
	// 	this.Termination=false;
	// 	this.Renewal=false;
	// 	this.Status=false;
	// 	if(event.detail.name=="Discounts")
	// 	this.discountsEnabled=true;
	// 	else if(event.detail.name=="Billing Settings")
	// 	this.billSettingsEnabled=true;
	// 	else if(event.detail.name=="Termination")
	// 	this.Termination=true;
	// 	else if(event.detail.name=="Renewal")
	// 	this.Renewal=true;
	// 	else if(event.detail.name=="Status")
	// 	this.Status=true;

    //     this.currentContent = selected;
    // }    
}

/* if (event.target.name == "Termination" && (element.name == "" || element.name == "Renewal" || element.name == )) {
                    element.disabled = true;
                }*/