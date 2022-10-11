import { LightningElement, api, wire } from 'lwc';
export default class UnitView extends LightningElement {
    @api
    thisUnits;//lista de Id de unidades que estan completadas (unit service: passedUnitIds)
    @api 
    unit;

    get completedUnit(){
        return this.thisUnits.includes(this.unit.Id);
    }

}