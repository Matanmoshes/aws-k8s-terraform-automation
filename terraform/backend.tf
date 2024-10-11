terraform {
    backend "s3" {
        bucket         = "terraform-backend-bucket-ioioio20"          
        key            = "terraform/state.tfstate"  
        region         = "us-east-1"                
        encrypt        = true                       
        dynamodb_table = "state_locking"    
    }
}