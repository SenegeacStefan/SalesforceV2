public abstract class CoreObject{
    public Object get(String param_name){
            String json_instance = Json.serialize(this);
            Map<String, Object> untyped_instance;
            untyped_instance= (Map<String, Object>)JSON.deserializeUntyped(json_instance);
            return untyped_instance.get(param_name);
    }
}