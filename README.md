# Publish Azure Functions code with Terraform

Blog post: [Publish Azure Functions code with Terraform](https://www.maxivanov.io/publish-azure-functions-code-with-terraform/).

There's a dev container for VS Code included to start quickly.

There are 2 Terraform modules to demonstrate different modes of running Azure Functions from pacakges:

- `terraform-az-cli` shows how to deploy the code to the App Service (`RUN_FROM_PACKAGE=1`)
- `terraform-sas` shows how to deploy the code the Blob storage (`RUN_FROM_PACKAGE=<url>`)

Each module creates 4 function apps to test compatibility across platforms and hosting plans:

- Linux Premium
- Linux Consumption
- Windows Premium
- Windows Consumption

## Run

```bash
cd terraform-az-cli

terraform init

terraform apply
```

Function app's hostname will be displayed in the output.
