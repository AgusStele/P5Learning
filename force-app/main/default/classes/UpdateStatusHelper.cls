public with sharing class UpdateStatusHelper {

    //update e insertar
    public static void afterUpdateHelper ( List<Unit_Progress__c> triggerNew) {
        
        Set<Id> unitIds = new Set<Id>();
        for(Unit_Progress__c unit: triggerNew){
            if(unit.Status__c == 'Answered'){
                unitIds.add(unit.Id);
            }
        }

        if(unitIds.size() != 0){

            List<Unit_Progress__c> unitProgressQuery = [SELECT Id, Name, Status__c, Counter__c, Points__c, User__c, (SELECT Id, Option__c,Option__r.isCorrect__c FROM Questions_Progress__r) FROM Unit_Progress__c WHERE Id IN :unitIds ];

            
            //Este set ↓ va a contener los User Ids obtenidos en la lista unitProgressQuery[linea 12], que estan vinculados con los Units_Progress__c. Estos Ids sirven para asegurarnos de que en usersFromUnitProgress[linea 22] llegen los mismos usuarios que recibimos como relacion(User__c) en unitProgressQuery[linea 12]
            Set<Id> userSet = new Set<Id>();
            
            for(Unit_Progress__c uProgress: unitProgressQuery){
                userSet.add(uProgress.User__c);
                System.debug(uProgress.Points__c);
            }
            
            //Necesitamos esta lista para poder setear los Points__c de User ↓ 
            List<User> usersFromUnitProgress = [SELECT Points__c, (SELECT Id FROM Units_Progress__r) FROM USER WHERE Id IN: userSet];

            System.debug(usersFromUnitProgress);
            //Este mapa ↓ vincula los mismos Ids de Unit_Progress__c que nos llegan en unitProgressQuery[linea 12], y que tambien pedimos en usersFromUnitProgress[linea 22], con los Users correctos(para poder hacer los loops[linea 27 y 28] y que correspondan). Esto va a servir para que cuando estemos haciendo loops[linea 34 y 35] sobre los registros que pedimos en unitProgressQuery[linea 12](Unit_Progress__c y Question_Progress__c) tambien podamos setear los Points__c de los Users correspondientes).
            Map<Id, Integer> userIndexByUnitProgress = new Map<Id, Integer>();
            for(User user: usersFromUnitProgress){
                for(Unit_Progress__c unitPro: user.Units_Progress__r){
                    System.debug(unitPro.Id);
                    System.debug( usersFromUnitProgress.indexOf(user));
                    System.debug(usersFromUnitProgress[usersFromUnitProgress.indexOf(user)].Points__c);
                    userIndexByUnitProgress.put(unitPro.Id, usersFromUnitProgress.indexOf(user));
                }
            }

            //!COMENTARIO 09/10 mientras recorro las respuestas de las preguntas sumo en un contador las que fueron respodidas correctamente. Si la cantidad de respuesta respondidas correctamente iguala a la cantidad de preguntas seteo el unitProgress.Status__c en 'success' y cambiar par de cosas
            if(unitProgressQuery.size() != 0 ){
                for(Unit_Progress__c unitProgress : unitProgressQuery){
                    if(unitProgress.Counter__c == null){
                        unitProgress.Counter__c = 1;
                    }
                    Integer questionsAnsweredCorrectly = 0;
                    for(Question_Progress__c question : unitProgress.Questions_Progress__r) {
                        if(question.Option__r.IsCorrect__c){
                            questionsAnsweredCorrectly++;
                        }
                    }
                    if(questionsAnsweredCorrectly == unitProgress.Questions_Progress__r.size()){
                        unitProgress.Status__c = 'Success';
                        if(userIndexByUnitProgress.containsKey(unitProgress.Id)){
                            System.debug(unitProgress.Points__c);
                            //Le pedimos al mapa userIndexByUnitProgress[linea 26] a traves de cada key(Id de UnitProgress[linea 34]) obtenida en las iteracionnes de unitProgress[linea 34] que nos devuelva un indice. Esto permite setear Points__c de cada User y que esten correctamente relacionados
                            usersFromUnitProgress[userIndexByUnitProgress.get(unitProgress.Id)].Points__c += unitProgress.Points__c;

                        }
                    }else if(unitProgress.Counter__c == 0){
                        unitProgress.Counter__c += 1; 
                        unitProgress.Status__c = 'Fail';
                        unitProgress.Points__c = unitProgress.Points__c/2;
                    }else if(unitProgress.Counter__c == 1){
                        unitProgress.Counter__c += 1; 
                        unitProgress.Status__c = 'Fail';
                        unitProgress.Points__c = unitProgress.Points__c/2;
                    }else if(unitProgress.Counter__c >= 2){
                        unitProgress.Counter__c += 1; 
                        unitProgress.Status__c = 'Fail';
                    }
                }
            }

           update  unitProgressQuery;
           update usersFromUnitProgress;

        }
    }
}


