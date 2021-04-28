import { LightningElement, wire, track ,api} from "lwc";
import getAgreement from '@salesforce/apex/APTS_CreateOrderNewUXCtrl.getAgreement';
const columns = [
    
    { label: 'SAPCustomerId', fieldName: 'SAPCustomerId', type: 'text' },
    { label: 'AccName', fieldName: 'AccName', type: 'text' }
];

export default class AptsnewMachineInsta extends LightningElement {

    @api recordId;   
    @api recordName;
    @api sapName;
    @track error;
    @track allRecords;  
    @track cssClass = 'slds-button slds-button_neutral';
    @track iconName = '';
   
    
    
    buttonClicked; 
  @api enabledSelections;
  @api isLoaded;
  @wire(getAgreement,{recordId: '$recordId'})
  wAgreements({ error, data }) { 
    if(data){
        let recs = [];      
        //var SAPCustomerId = [];
        for(let i=0; i<data.length; i++){
           // console.log('Lav accname'+this.Apttus__APTS_Agreement__c.fields.Apttus__Account__r.Name.value);
            let agree = {};
            agree.Name = data[i].Name;
            agree = Object.assign(agree, data[i]); 
            recs.push(agree);

        }
        this.allRecords = recs;
        //console.log('Lavanya'+recs);
    }else{
        this.error = error;
    }       
  }

  buttonClicked; //defaulted to false

 
  // Handles click on the 'Show/hide content' button
  handleToggleClick() {
      this.buttonClicked = !this.buttonClicked; //set to true if false, false if true.
      this.cssClass = this.buttonClicked ? 'slds-button slds-button_outline-brand' : 'slds-button slds-button_neutral';
      this.iconName = this.buttonClicked ? 'utility:check' : '';
  }
}