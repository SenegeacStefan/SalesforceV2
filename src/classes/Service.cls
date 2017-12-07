global class Service {
    public Integer id {get; set;}  
    public String name {get; set;}  
    public List<Decimal> duration {get; set;}  
    public List<Decimal> prices {get; set;}   
    public Integer company_id {get; set;}
    
    public Service() {}
    
    public Service(Integer id, 
                   String name,
                   List<Decimal> duration,
                   List<Decimal> prices,
                   Integer company_id) {      
        this.id = id;
        this.name = name;
        this.duration = duration;
        this.prices = prices;
        this.company_id = company_id;
    }
}