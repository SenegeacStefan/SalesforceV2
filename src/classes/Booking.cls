global class Booking extends CoreObject{
    //update
    public Integer id {get; set;}  
    public String full_describe {get; set;}  
    public String person_name {get; set;}  
    public String date_time {
        get;
        set {
            date_time = String.valueOf(Util.stringToDate(value));
        }
    }
    public String end_date_time {
        get;
        set {
            end_date_time = String.valueOf(Util.stringToDate(value));
        }
    }
    public Integer duration {get; set;}  
    public Boolean on_waitlist {get; set;}
    public Integer company_id {get; set;}  
    public Boolean attended {get; set;} 
    public String updated_at {get; set;}  
    public String created_at {get; set;}  
    public Integer member_id {get; set;} 
    public Integer service_id {get; set;} 
    public Integer resource_id {get; set;} 
    public Integer person_id {get; set;}  
    public Integer session_id {get; set;}  
    public Decimal price {get; set;}
    public Decimal paid {get; set;}
    public Integer purchase_id {get; set;}
    public Boolean is_cancelled {get; set;}
    public String long_id {get; set;}
    public String reference {get; set;}
    public Map<String, String> settings {get; set;}
    public List<Answer> questions {get; set;}
    
    public Booking() {}
    
    public Booking(Integer id, 
                   String full_describe, 
                   String person_name, 
                   String date_time,
                   String end_date_time,
                   Integer duration, 
                   Boolean on_waitlist,
                   Integer company_id, 
                   Boolean attended,
                   String updated_at, 
                   String created_at,
                   Integer member_id,
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
                   List<Answer> questions ) {
        
        this.id = id;
        this.full_describe = full_describe;
        this.person_name = person_name;
        this.date_time = date_time;
        this.end_date_time = end_date_time;
        this.duration = duration;
        this.on_waitlist = on_waitlist;
        this.company_id = company_id;
        this.attended = attended;
        this.updated_at = updated_at;
        this.created_at = created_at;  
        this.member_id = member_id;
        this.service_id = service_id;
        this.session_id = session_id;
        this.resource_id = resource_id;
        this.person_id = person_id;
        this.purchase_id = purchase_id;
        this.price = price;
        this.is_cancelled = is_cancelled;
        this.long_id = long_id;
        this.settings = settings;
        this.questions = questions ;
    }
 
 
    public String getAnswer(String q)
    {
        if (questions != null){
            for (Answer a : questions ){
                if (a.question == q) 
                    return a.answer;
            }   
        }
        return null;
    }
}