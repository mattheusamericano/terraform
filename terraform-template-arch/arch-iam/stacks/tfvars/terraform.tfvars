#
#IAM
#
iam_settings = {
    
    #1
    "iam" = {
        project_id                  = "__project_id__"
    }
}

#
#SERVICE_ACCOUNT
#
sa_settings = {

    #1 Global
    "sa-global" = {
        project_id                  = "__project_id__"
        display_name                = "SA Global by Terraform"
        sigla                       = "__sigla__"
    }
    #2 Integration
    "sa-itg" = {
        project_id                  = "__project_id__"
        display_name                = "SA Integração by Terraform"
        sigla                       = "__sigla__"
    }
    #3 CloudRun
    "sa-clrun" = {
        project_id                  = "__project_id__"
        display_name                = "SA Cloudrun by Terraform"
        sigla                       = "__sigla__"
    }
    #4 Composer
    "sa-comp" = {
        project_id                  = "__project_id__"
        display_name                = "SA Composer by Terraform"
        sigla                       = "__sigla__"
    }
    #5 Dataform Runner
    "sa-dt-run" = {
        project_id                  = "__project_id__"
        display_name                = "SA Dataform Runner by Terraform"
        sigla                       = "__sigla__"
    } 
    #6 Core Secret Accessor
    "sa-cr-acc" = {
        project_id                  = "__project_id__"
        display_name                = "SA Core Secret Acessor by Terraform"
        sigla                       = "__sigla__"
    }
    #7 Log Viewer Service
    "sa-lg-vw" = {
        project_id                  = "__project_id__"
        display_name                = "SA Log Viewer Service by Terraform"
        sigla                       = "__sigla__"
    }
    #8 Log Writer Service
    "sa-lg-wr" = {
        project_id                  = "__project_id__"
        display_name                = "SA Log Writer Service by Terraform"
        sigla                       = "__sigla__"
    }
    #9 Log Admin Service
    "sa-lg-adm" = {
        project_id                  = "__project_id__"
        display_name                = "SA Log Admin Service by Terraform"
        sigla                       = "__sigla__"
    }
}

#
#Grupos para Custom Roles
#
ml_engineer_org_group               = "group:__group_ml_engineer__"
ml_data_scientist_org_group         = "group:__group_data_scientist__"
data_engineer_org_group             = "group:__group_data_engineer__"