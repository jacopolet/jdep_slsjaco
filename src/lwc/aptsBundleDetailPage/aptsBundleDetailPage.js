import { LightningElement, wire, track ,api} from "lwc";

export default class AptsBundleDetailPage extends LightningElement {

    @track bShowActionModal = false;   
    @track selectedActions;
	@track bShowChangeAssetModal;
	@track isStatusScreen = false;
    value = ['option1'];

    get options() {
        return [
            { label: 'Require installation', value: 'option1' },
            { label: 'Stair Climber', value: 'option2' },
            { label: 'Commercial Machine', value: 'option3' },
            { label: 'Owned By Customer', value: 'option4' },
            { label: 'Smoking Area', value: 'option5' },
            { label: 'Collect COunters', value: 'option6' },
            { label: 'Auto Renew', value: 'option7' },

        ];
    }

    get selectedValues() {
        return this.value.join(',');
    }

    handleChange(e) {
        this.value = e.detail.value;
    }

    


}