# PSM Enterprise - Terraform Infrastructure
# Layer 6: Infrastructure as Code

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "psm-terraform"
    storage_account_name = "psmtfstate"
    container_name       = "tfstate"
    key                  = "psm-enterprise.tfstate"
  }
}

# Variables
variable "project_name" {
  default = "psm-enterprise"
}

variable "domain" {
  default = "purplesquirrel.media"
}

variable "environment" {
  default = "production"
}

# =====================
# AZURE RESOURCES
# =====================
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "psm" {
  name     = "${var.project_name}-rg"
  location = "East US"

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Static Web App
resource "azurerm_static_web_app" "main" {
  name                = var.project_name
  resource_group_name = azurerm_resource_group.psm.name
  location            = "East US 2"
  sku_tier            = "Free"
  sku_size            = "Free"
}

# Cognitive Services - Vision
resource "azurerm_cognitive_account" "vision" {
  name                = "${var.project_name}-vision"
  location            = azurerm_resource_group.psm.location
  resource_group_name = azurerm_resource_group.psm.name
  kind                = "ComputerVision"
  sku_name            = "F0"
}

# Cognitive Services - Speech
resource "azurerm_cognitive_account" "speech" {
  name                = "${var.project_name}-speech"
  location            = azurerm_resource_group.psm.location
  resource_group_name = azurerm_resource_group.psm.name
  kind                = "SpeechServices"
  sku_name            = "F0"
}

# Cognitive Services - Language
resource "azurerm_cognitive_account" "language" {
  name                = "${var.project_name}-language"
  location            = azurerm_resource_group.psm.location
  resource_group_name = azurerm_resource_group.psm.name
  kind                = "TextAnalytics"
  sku_name            = "F0"
}

# Azure Functions
resource "azurerm_service_plan" "functions" {
  name                = "${var.project_name}-asp"
  resource_group_name = azurerm_resource_group.psm.name
  location            = azurerm_resource_group.psm.location
  os_type             = "Linux"
  sku_name            = "Y1"  # Consumption plan
}

# =====================
# AWS RESOURCES
# =====================
provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for storage
resource "aws_s3_bucket" "psm_storage" {
  bucket = "${var.project_name}-storage"

  tags = {
    Name        = "${var.project_name}-storage"
    Environment = var.environment
  }
}

# Lambda Function
resource "aws_lambda_function" "psm_api" {
  function_name = "${var.project_name}-api"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  memory_size   = 256
  timeout       = 30

  filename = "../functions/aws/lambda.zip"

  environment {
    variables = {
      NODE_ENV = var.environment
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# DynamoDB Table
resource "aws_dynamodb_table" "psm_data" {
  name           = "${var.project_name}-data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "pk"
  range_key      = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-data"
    Environment = var.environment
  }
}

# =====================
# GCP RESOURCES
# =====================
provider "google" {
  project = var.project_name
  region  = "us-central1"
}

# Cloud Function
resource "google_cloudfunctions_function" "psm_function" {
  name        = "${var.project_name}-function"
  description = "PSM Enterprise API"
  runtime     = "nodejs20"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.functions.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  trigger_http          = true
  entry_point           = "handler"
}

resource "google_storage_bucket" "functions" {
  name     = "${var.project_name}-functions"
  location = "US"
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "function.zip"
  bucket = google_storage_bucket.functions.name
  source = "../functions/gcp/function.zip"
}

# Firestore Database
resource "google_firestore_database" "psm" {
  project     = var.project_name
  name        = "(default)"
  location_id = "us-central"
  type        = "FIRESTORE_NATIVE"
}

# =====================
# CLOUDFLARE RESOURCES
# =====================
provider "cloudflare" {}

resource "cloudflare_worker_script" "psm_api" {
  account_id = var.cloudflare_account_id
  name       = "psm-api"
  content    = file("../../workers/cloudflare/src/index.js")
  module     = true
}

# =====================
# OUTPUTS
# =====================
output "azure_static_web_url" {
  value = azurerm_static_web_app.main.default_host_name
}

output "azure_vision_endpoint" {
  value = azurerm_cognitive_account.vision.endpoint
}

output "aws_s3_bucket" {
  value = aws_s3_bucket.psm_storage.bucket
}

output "aws_lambda_arn" {
  value = aws_lambda_function.psm_api.arn
}

output "gcp_function_url" {
  value = google_cloudfunctions_function.psm_function.https_trigger_url
}
