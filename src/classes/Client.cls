global class Client extends CoreObject{ 

    public Integer id {get; set;}
    public String first_name {get; set;}
    public String last_name {get; set;}
    public String address1 {get; set;}
    public String address2 {get; set;}
    public String address3 {get; set;}
    public String address4 {get; set;}
    public String postcode {get; set;}
    public String country {get; set;}
    public String phone {get; set;}
    public String mobile {get; set;}
    public String phone_prefix {get; set;}
    public String mobile_prefix {get; set;}
    public String email {get; set;}
    public String reference {get; set;} 
    public Links links {get; set;} 
    public Boolean deleted {get; set;} 
    public Integer company_id {get; set;}  
    public List<Answer> answers {get; set;}
    //public File[] files {get; set;} 
    
    public Client() {}
    
    public Client(Integer id,
                    String first_name,
                    String last_name,
                    String address1,
                    String address2,
                    String address3,
                    String address4,
                    String postcode,
                    String country,
                    String phone,
                    String mobile,
                    String email,
                    String reference,
                    Links links,
                    Boolean deleted,
                    List<Answer> answers) {
                    //File[] files) {
                             
        this.id = id;
        this.first_name = first_name;
        this.last_name = last_name;
        this.address1 = address1;
        this.address2 = address2;
        this.address3 = address3;
        this.address4 = address4;
        this.postcode = postcode;
        this.country = country;
        this.phone = phone;
        this.mobile = mobile;
        this.email = email;
        this.reference = reference;
        this.links = links;
        this.deleted = deleted;
        this.answers = answers;
		
	        

       // this.files = files;
    }
    
    public String getAnswer(String q)
    {
    	if (answers != null){
	    	for (Answer a : answers){
	    		if (a.name == q) 
	    			return a.answer;
	    	}	
    	}
    	return null;
    }

    public class Links {
        public hrefLink self {get; set;}   
        
        public Links(hrefLink self) {
            this.self = self;
        }
    } 
    
    public class hrefLink {
        public String href {get; set;}   
        
        public hrefLink(String href) {
            this.href = href;
        }
    } 
    
    /*
    public class File {
        public String link {get; set;}  
        public String name {get; set;}    
        
        public File(String link, 
                    String name) {
            this.link = link;
            this.name = name;
        }
    }    */
}