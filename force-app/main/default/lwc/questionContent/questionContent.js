import { LightningElement, api, track } from 'lwc';
import metodoDos from '@salesforce/apex/UnitService.metodoDos';
import metodo from '@salesforce/apex/UnitService.metodo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class QuestionContent extends LightningElement {
    @api unitId
    @api thisQuestions
    submitAnswersLenght = [];
    submitAnswers = {};
    keysArray = [];

    renderedCallback(){
        metodo({unitId: this.unitId})
        .then(
            console.log('Todo joya')
        )
        .catch((error) =>
            console.log(error.body.message)
        )
    }

    handleClick(event){
        const optionId = event.target.dataset.id;
        const questionId = event.target.dataset.qid;

        this.submitAnswers[questionId] = optionId;
        this.submitAnswersLenght = Object.values(this.submitAnswers);
    }

    handleSubmit(){
        console.log(this.submitAnswers);
        if(this.submitAnswersLenght.length == this.thisQuestions.length){
            metodoDos({unitId: this.unitId, optionByQuestion: JSON.stringify(this.submitAnswers)})
            .then((status)=>{
                if(status == 'Success'){
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'WOOHOO!',
                        message: 'Youve got a shiny new badge',
                        variant: 'success'
                    }));
                }else{
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Try again',
                        message: 'Youve got one or more wrong answers',
                        variant: 'error'
                    }));
                }
            })
            .catch((error) =>{
                console.log(error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.message,
                    variant: 'error'
                }));
            })
        } else{
            this.dispatchEvent(new ShowToastEvent({
                title: 'Try again',
                message: 'Youve got to answer all the questions before submitting them',
                variant: 'error'
            }));
        }
    }
}