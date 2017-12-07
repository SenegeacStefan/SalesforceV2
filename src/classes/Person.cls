global class Person { 
    
    public Integer id {get; set;}
    public String name {get; set;}
    public String email {get; set;}
    public Integer company_id {get; set;}
    
    public Person() {}
    
    public Person(Integer id,
                  String name,
                  String email,
                  Integer company_id) {
                             
        this.id = id;
        
        if (name != null) {
            this.name = name;
        } else {
            this.name = '';
        }
        
        this.email = email;
        this.company_id = company_id;
    }
}