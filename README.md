# Azure Local Solution Deployment of AVD and AKS with GitHub Actions

This repository contains the necessary files to deploy a simple Azure solution using GitHub Actions, Azure Federated credentials, Bicep, JSON, and App registration.

## Prerequisites
- **Azure Account**: Ensure you have an active Azure subscription.
- **GitHub Account**: Make sure you have a GitHub account and a repository to store your code.
- **Azure CLI**: Install the Azure CLI on your local machine.
- **App Registrations**: Create the necessary app registrations in Azure AD.
- **GitHub Federation**: Set up GitHub federation with Azure AD for federated credentials.

## Components
- **Azure Kubernetes Service (AKS) enabled by Azure Arc**
- **Storage Spaces Direct-based virtualized storage**
- **Windows and Linux virtual machines as Arc-enabled servers**
- **Azure Virtual Desktop**

## Files
- `main.bicep`: Bicep file to define Azure resources.
- `avd.json`: JSON file for Azure Virtual Desktop.
- `.github/workflows/deploy.yml`: GitHub Actions workflow file.

## Setup Instructions

### 1. Create an Azure Resource Group
```bash
az group create --name exampleRG --location norwayeast
