public with sharing class UnitService {
    
    //el metodo se encarga de insertar module_progress e inserta la unidadPro
    @AuraEnabled
    public  static void metodo(Id unitId) {//JSON STRING
 		Id userId = UserInfo.getUserId();
        Unit__c unitQuery = [SELECT Id, Points__c, (SELECT Id FROM Units_Progress__r WHERE User__c =:userId) FROM Unit__c WHERE Id = :unitId]; //WITH SECURITY_ENFORCED
        //Funciona SELECT Id, Name, Unit__c FROM Unit_Progress__c WHERE Unit__c = 'a033t00000gn6nNAAQ'
        //List<Question_Progress__c> questionsToInsert = new List<Question_Progress__c>();

        Unit_Progress__c unitProSearch = null;
        for ( Unit_Progress__c up : unitQuery.Units_Progress__r) {
            unitProSearch = up;
        }

        if(unitProSearch == null){
            Unit__c unitIdQuery = [SELECT Module__c FROM Unit__c WHERE Id = :unitId];

            Module__c checkModule = [SELECT (SELECT Id FROM Modules_Progress__r WHERE User__c = :userId) FROM Module__c WHERE Id = :unitIdQuery.Module__c];

            if(checkModule.Modules_Progress__r.size() == 0){
                Module_Progress__c moduleProToInsert = new Module_Progress__c(Module__c = unitIdQuery.Module__c, User__c = userId);
            
                insert moduleProToInsert;
            }
            

            Module__c moduleId = [SELECT Id, (SELECT Name, Id FROM Units__r WHERE Id = :unitId), (SELECT Name, Id FROM Modules_Progress__r WHERE User__c = :userId) FROM Module__c WHERE Id IN (SELECT Module__c FROM Unit__c WHERE Id = :unitId) ];

                                    
            Map<Id, Id> mProgressByUnit = new Map<Id, Id>(); 
            Id key;
            Id value;
            for(Unit__c unit: moduleId.Units__r){
                if(!mProgressByUnit.containsKey(unit.Id)){
                    key = unit.Id;
                }
            }
            for(Module_Progress__c mpro: moduleId.Modules_Progress__r){
                value = mpro.Id;
            }
            mProgressByUnit.put(key ,value);
            
            if(moduleId.Trails_Modules__r != null){
                Id trailModuleId;
                Map<Id, Id> trailByTrailModule = new Map<Id, Id>();
                for(Trail_Modele__c trailModule: moduleId.Trails_Modules__r){
                    trailByTrailModule.put(trailModule.Id, trailModule.Trail__c);
                    trailModuleId = trailModule.Id;
                }
                Map<Id, Set<Id>> trailIdByModuleProgressId = new Map<Id, Set<Id>>();
                Set<Id> trailId = new Set<Id>();
    
                for(Module_Progress__c modulePro: moduleId.Modules_Progress__r){
                    for(Trail_Modele__c trailMod: moduleId.Trails_Modules__r){
                        if(trailByTrailModule.get(trailModuleId) != null){//map.get(key) != null
                                trailId.add(trailByTrailModule.get(trailMod.Id));
                        }
                    }
                    trailIdByModuleProgressId.put(modulePro.Id, trailId);
                }
            }

            Unit_Progress__c unitProToInsert = new Unit_Progress__c(Module_Progress__c = mProgressByUnit.get(unitId), User__c =userId, Unit__c= unitId, Status__c = 'Draft', Points__c = unitQuery.Points__c);

            insert unitProToInsert;  
        }  
    }

    //este metodo se encarga de insertar question progress y cambia el status de unitPro
    @AuraEnabled(cacheable=false)
    public static String metodoDos(Id unitId, String optionByquestion){
		Id userId = UserInfo.getUserId();
        System.debug(unitId + ' ' + optionByQuestion);

        
        //TRAER QUESTION PROGRESS PARA VER SI EXISTE. SI EXISTE NO CREAR UNO NUEVO Y ACTUALIZAR LOS DATOS
        //CASO CONTRARIO CREAR QUESTION PROGRESS
        Unit_Progress__c insertedUnitProgress = [SELECT Id, Status__c, Counter__c, Points__c, Unit__r.Points__c, (SELECT Question__c, Option__c FROM Questions_Progress__r) FROM Unit_Progress__c WHERE Unit__c = :unitId AND User__c = :userId];
        System.debug(optionByQuestion);

        Map<Id, Id> optsByQuestion = (Map<Id, Id>)JSON.deserializeStrict( optionByquestion, Map<Id, Id>.class);

        System.debug(insertedUnitProgress.Questions_Progress__r.size());
        //insertedUnitProgress.Questions_Progress__r.size() <= 0 || insertedUnitProgress.Questions_Progress__r == null
        //insertedUnitProgress.Questions_Progress__r.size() > 0 || insertedUnitProgress.Questions_Progress__r != null


        if(insertedUnitProgress.Questions_Progress__r.size() <= 0 || insertedUnitProgress.Questions_Progress__r == null){
            insertedUnitProgress.Status__c = 'Answered';
    
            List<Question_Progress__c> questionProgressToInsert = new List<Question_Progress__c>();
            
            Set<Id> questionIds = optsByQuestion.keySet();
            for (Id question : questionIds) {
                Question_Progress__c questionProgress = new Question_Progress__c(Unit_Progress__c = insertedUnitProgress.Id, Question__c = question, Option__c = optsByQuestion.get(question));
                questionProgressToInsert.add(questionProgress);
            }
    
            insert questionProgressToInsert;
    
            update insertedUnitProgress;
        } else if(insertedUnitProgress.Questions_Progress__r.size() > 0 || insertedUnitProgress.Questions_Progress__r != null){
            insertedUnitProgress.Status__c = 'Answered';

            List<Question_Progress__c> questionProgressToUpdate= new List<Question_Progress__c>();
            for(Question_Progress__c questionProgress: insertedUnitProgress.Questions_Progress__r){
                questionProgressToUpdate.add(questionProgress);
            }
            
            for(Question_Progress__c questionPro: questionProgressToUpdate){
                System.debug(questionPro);
                if(optsByQuestion.containsKey(questionPro.Question__c)){
                    questionPro.Option__c = optsByQuestion.get(questionPro.Question__c);
                }
            }

            update questionProgressToUpdate;

            update insertedUnitProgress;
        }

        Unit_Progress__c refreshedUnit = [SELECT Id, Status__c FROM Unit_Progress__c WHERE User__c = :userId AND Unit__c = :unitId AND Id = :insertedUnitProgress.Id];
        
        //setea los valores deñ trigger
        System.debug(refreshedUnit + 'QUERY REFRESHEDUNIT METODO DOS');
        System.debug(refreshedUnit.Status__c);
        
        return refreshedUnit.Status__c;

        //probar el codigo con sus parametros.
    }


    public with sharing class TrailWrapper{
        @AuraEnabled 
        public Trail__c trail; 
        //Registro de Trail solicitado
        @AuraEnabled 
        public Integer progressTrail; 
        //Porcentaje de progreso del Alumno en el Trail
        //Módulos con Unidades relacionadas
        @AuraEnabled 
        public List<Module__c> modules = new List<Module__c>();
        @AuraEnabled 
        public List<Module_Progress__c> passedModuleIds = new List<Module_Progress__c>();
        //Ids de módulos relacionados al Trail actual en los que el Alumno ya aprobó
        @AuraEnabled 
        public List<Id> passedUnitIds = new List<Id>();
        //Ids de Unidades relacionadas a módulos del Trail actual que el Alumno ya aprobó
        
         public TrailWrapper(Trail__c trail, List<Module__c> modules, List<Module_Progress__c> passedModuleIds, List<Id> passedUnitIds){
            this.trail = trail;
            this.modules = modules;
            this.progressTrail = (passedModuleIds.size()*100) / modules.size();
            this.passedModuleIds = passedModuleIds;
            this.passedUnitIds = passedUnitIds;
        }
    }

    //↓ Esto es lo que llamo desde el front y hace referencia a la clase TrailWrapper y su constructor para poder crear la instancia con el trailId pasado como parametro
    @AuraEnabled(cacheable=true)
    public static TrailWrapper getTrailWrapper(Id trailId){
        Id userId = UserInfo.getUserId();

        TrailWrapper trail = new TrailWrapper(([SELECT Name, Description__c, Time__c, Points__c FROM Trail__c WHERE Id = :trailId]), getModule(trailId), getCompletedModules(trailId), getUnitsWithProgress(trailId));
        return trail;
    }
    
    //Lineas 120 y 132 son lo mismo
    public static Set<Id> getTrailModule(Id trailId){

        List<Trail_Modele__c> trailModulesFromTrail = [SELECT Id FROM Trail_Modele__c WHERE Trail__c = :trailId ];

        Set<Id> trailModuleIds = new Set<Id>();

        for(Trail_Modele__c trailModule: trailModulesFromTrail){
            trailModuleIds.add(trailModule.Id);
        }
        return trailModuleIds;
    }

    public static List<Module__c> getModule(Id trailId){
        Id userId = UserInfo.getUserId();
        Set<Id> trailModuleIds = getTrailModule(trailId);
        

        //!9-10 falta campo Url__c de units
        List<Module__c> modules = [SELECT Name, Description__c, Time__c, Points__c,image__c, Url__c, (SELECT  Name, Time__c, Points__c, Url__c FROM Units__r), (SELECT Id, Module__c FROM Modules_Progress__r WHERE Status__c = 'Completed' AND User__c = :userId) FROM Module__c WHERE Id IN (SELECT Module__c FROM Trail_Modele__c WHERE Id IN :trailModuleIds) ];

        return modules;
    }

    public static List<Id> getUnitsWithProgress(Id trailId){
        Id userId = UserInfo.getUserId();
       List<Module__c> modules = getModule(trailId);

       Set<Id> unitIds = new Set<Id>();
       for(Module__c module: modules){
            for(Unit__c unit: module.Units__r){
                unitIds.add(unit.Id);
            }
        }

        List<Unit__c> unitsWithCompletedStatus =  [SELECT Id FROM Unit__c WHERE Id IN :unitIds AND Id IN(SELECT Unit__c FROM Unit_Progress__C WHERE Status__c = 'Success' AND User__c = :userId)];

        List<Id> completedUnitIds = new List<Id>();
        for(Unit__c unit: unitsWithCompletedStatus){
            completedUnitIds.add(unit.Id);
        }

        return completedUnitIds;
    }

    public static List<Module_Progress__c> getCompletedModules(Id trailId){
        List<Module__c> modules = getModule(trailId);

        List<Module_Progress__c> moduleProgress = new List<Module_Progress__c>();
        for(Module__c module: modules){
            for(Module_Progress__c modulePro: module.Modules_Progress__r){
                moduleProgress.add(modulePro);
            }
        }
        return moduleProgress;
    }
    
    public class UnitWrapper{
        @AuraEnabled
        public Unit__c thisUnit;
        //Registro de Unidad solicitada
        @AuraEnabled
        public List<Question__c> thisQuestions = new List<Question__c>();  
        //Listado de Preguntas con Opciones relacionadas

        public UnitWrapper(Unit__c thisUnit, List<Question__c> thisQuestions){
            this.thisUnit = thisUnit;
            this.thisQuestions = thisQuestions;
        }
    }

    @AuraEnabled(cacheable=true)
    public static UnitWrapper getUnitWrapper(Id unitId){

        // TrailWrapper trail = new TrailWrapper(([SELECT Name, Description__c, Time__c, Points__c FROM Trail__c WHERE Id = :trailId]), getModule(trailId), getCompletedModules(trailId), getUnitsWithProgress(trailId));
        // return trail;

        UnitWrapper unitWrapper = new UnitWrapper(([SELECT Content__c, Points__c, Time__c, Name FROM Unit__c WHERE Id = :unitId]), getQuestionsFromUnit(unitId));
        return unitWrapper;
    }

    // @AuraEnabled(cacheable=true)
    // public static Unit__c getUnit(Id unitId){
    //     Unit__c unit = [SELECT Name, Content__c, Points__c, Time__c FROM Unit__c WHERE Id = :unitId];
    //     return unit;
    // }

    public static List<Question__c> getQuestionsFromUnit(Id unitId){
        List<Question__c> questions = [SELECT Content__c, (SELECT Id, Content__c, IsCorrect__c FROM Optios__r), (SELECT IsCompleted__c, Option__c, Question__c FROM Questions_Progress__r) FROM Question__c WHERE Unit__c =: unitId];

        return questions;
    }
}
