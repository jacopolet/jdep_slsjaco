import { LightningElement } from 'lwc';

export default class AptsOrderInfoPage extends LightningElement {
    selectedAccount;
    value = ['option1'];

    get options() {
        return [
            { label: 'Delivery Only', value: 'option1' },
            { label: 'Stop Over', value: 'option2' },
            { label: 'Swap', value: 'option3' },
            { label: 'Project ID', value: 'option4' },

        ];
    }

    get selectedValues() {
        return this.value.join(',');
    }

    handleChange(e) {
        this.value = e.detail.value;
    }

    handleSelected(event){
        this.selectedAccount = undefined;
        let res = JSON.stringify(event.detail);
        if(event && !res.includes('Remove Selected')){
            this.selectedAccount = event.detail;            
        }        
      //  this.enableCascade();
    }


}