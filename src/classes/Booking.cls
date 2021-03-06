global class Booking extends CoreObject{
    public Integer id {get; set;}  
    public String full_describe {get; set;}  
    public String person_name {get; set;}  
    public String date_time {get; set;}  
    public Integer duration {get; set;}  
    public Integer company_id {get; set;}  
    public String updated_at {get; set;}  
    public String created_at {get; set;}  
    public Integer client_id {get; set;} 
    public Integer service_id {get; set;} 
    public Integer resource_id {get; set;} 
    public Integer person_id {get; set;}  
    public Integer session_id {get; set;}  
    public Integer price {get; set;}
    public Integer paid {get; set;}
    public Integer purchase_id {get; set;}
    public Boolean is_cancelled {get; set;}
    public String long_id {get; set;}
    public String reference {get; set;}
    public Map<String, String> settings {get; set;}
    public List<Answer> answers_summary {get; set;}
    
    public Booking() {}
    
    public Booking(Integer id, 
                   String full_describe, 
                   String person_name, 
                   String date_time, 
                   Integer duration, 
                   Integer company_id, 
                   String updated_at, 
                   String created_at,
                   Integer client_id,
                   Integer service_id,
                   Integer session_id,
                   Integer resource_id,
                   Integer person_id,
                   Integer price,
                   Integer paid,
                   Integer purchase_id,
                   Boolean is_cancelled,
                   String long_id,
                   Map<String, String> settings,
                   List<Answer> answers_summary) {
        
        this.id = id;
        this.full_describe = full_describe;
        this.person_name = person_name;
        this.date_time = date_time;
        this.duration = duration;
        this.company_id = company_id;
        this.updated_at = updated_at;
        this.created_at = created_at;  
        this.client_id = client_id;
        this.service_id = service_id;
        this.session_id = session_id;
        this.resource_id = resource_id;
        this.person_id = person_id;
        this.purchase_id = purchase_id;
        this.price = price;
        this.is_cancelled = is_cancelled;
		this.long_id = long_id;
        this.settings = settings;
		this.answers_summary = answers_summary;
    }
 
 
    public String getAnswer(String q)
    {
    	if (answers_summary != null){
	    	for (Answer a : answers_summary){
	    		if (a.name == q) 
	    			return a.answer;
	    	}	
    	}
    	return null;
    }

    public boolean anotherMentodQuestion(Integer some_param) {
        return false;
    }
 
}