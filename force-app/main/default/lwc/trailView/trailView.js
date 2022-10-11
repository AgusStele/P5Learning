import { LightningElement, api, wire, track } from 'lwc';
import getTrailWrapper from '@salesforce/apex/UnitService.getTrailWrapper';

export default class TrailView extends LightningElement {
    @api recordId;
    error = undefined;
    //@track
    wrapper;
    thisTrail;
    progressTrail;
    thisModule;
    thisUnits;

    //agregar progressTrail

    @wire(getTrailWrapper, {trailId: '$recordId'})
    trail({ data, error }) {
        if(data) {
            this.wrapper = data;
            this.thisTrail = data.trail;
            this.progressTrail = data.progressTrail;
            this.thisModule = data.modules;
            this.thisUnits = data.passedUnitIds;
        }else if(error) {
            this.error = error;
        }
    }
    
    //progress = parseFloat(progressTrail).toFixed(0)+"%"

    get style() {
        return `width: ${this.progressTrail}%`;
    }
    
    // handleClick() {
    //     console.log(this.thisUnits);
    // }
}