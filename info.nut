class gelignAIte extends AIInfo
{
   function GetAuthor()      { return "Marcel Glacki"; }
   function GetName()        { return "gelignAIte"; }
   function GetVersion()     { return 1; }
   function GetDate()        { return "2010-10-20"; }
   function CreateInstance() { return "gelignAIte"; }
   function GetShortName()   { return "GELI"; }
   function GetURL()         { return "http://dev.openttdcoop.org/projects/ai-gelignaite"; }
   function GetDescription() {
     return "Non-competitive AI that builds one passenger-service (2 buses) after the AI started and a mail-service (4 trucks) when the biggest 
has >= 9k inhabitants and loan is <= 20 %.";
   }

   function GetSettings() 
   {
/*
     AddSetting({name = "bool_setting",
                 description = "a bool setting, default off", 
                 easy_value = 0, 
                 medium_value = 0, 
                 hard_value = 0, 
                 custom_value = 0, 
                 flags = AICONFIG_BOOLEAN});
                 
     AddSetting({name = "bool2_setting", 
                description = "a bool setting, default on", 
                easy_value = 1, 
                medium_value = 1, 
                hard_value = 1, 
                custom_value = 1, 
                flags = AICONFIG_BOOLEAN});
                
     AddSetting({name = "int_setting", 
                 description = "an int setting", 
                 easy_value = 30, 
                 medium_value = 20, 
                 hard_value = 10, 
                 custom_value = 20, 
                 flags = 0, 
                 min_value = 1, 
                 max_value = 100});    	
*/
   }
 }

/* Tell the core we are an AI */
RegisterAI(gelignAIte());

