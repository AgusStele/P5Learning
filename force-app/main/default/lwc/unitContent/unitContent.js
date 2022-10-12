import { LightningElement, api, wire, track } from 'lwc';
import getUnitWrapper from '@salesforce/apex/UnitService.getUnitWrapper';
export default class UnitContent extends LightningElement {
    @api recordId
    error = undefined;
    wrapper;
    thisQuestions;
    thisUnit;
    

    @wire(getUnitWrapper, {unitId: '$recordId'})
    unit({ data, error }) {
        if(data) {
            this.wrapper = data;
            this.thisUnit = data.thisUnit;
            this.thisQuestions = data.thisQuestions;
        }else if(error) {
            this.error = error;
        }
    }
}