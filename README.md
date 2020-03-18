# Azure Load Balancer + Linux VM Terraform lab templates


## Overview

 In this hands-on lab, you will setup a virtual network with two linux VM that run Apache and publish a Web Site using Azure Load Balancer.

## Network Architecture

TBD

## Requirements

- Valid the Azure subscription account. If you don’t have one, you can create your free azure account (https://azure.microsoft.com/en-us/free/).

## How to use the templates

1. Download terraform files:
   * main.tf
   * variables.tf
   * terraform.tfvars
   
   > In the Module-Version folder you will find the same Terraform templated with files divided by Azure Modules to make easier to you    find what resource you need to create and how to do it.
   
2. Edit main.tf file and change the following configuration:
   * Locate Provider AzureRM and change to match your subscription information:
     * subscription_id = Your Azure Subscription ID
     * client_id       = Your Azure Service Principal App ID
     * client_secret   = Your Azure Service Principal Client Secret
     * tenant_id       = Your Azure Tenant ID
    * If you do not have a service principal, please follow this guide to create one:
    https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html
    
3. Edit terraform.tfvars file and change the following variable values:
   * location = Azure Region where you want to deploy
   * prefix = Prefix string that will be used for resource creation
   * adminname = Windows VM Local Admin Name
   * adminpwd = Windows VM Local Admin Password (must be complex and 12 char long)
   
> You can use Azure Cloud Shell to execute your terraform template: https://shell.azure.com 

4. Initiliaze your terraform environment:
   
   > terraform init
   
5. Plan and review your terraform deployment:
   
   > terraform plan
   
6. Apply your terraform template (It takes at least 45 minutes to be complete):

   > terraform apply

## Test your lab deployment

* Terraform will output the Website Public IP. You can use it to access the website and validate it works: http://XX.YY.WW.ZZ

## Clean All Resources after the lab

After you have successfully completed the Azure Networking Terraform lab , you will want to delete the Resource Groups. Run following terraform command:

   > terraform destroy

