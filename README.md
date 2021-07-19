[![CircleCI](https://circleci.com/gh/giantswarm/giantnetes-terraform.svg?style=shield)](https://circleci.com/gh/giantswarm/giantnetes-terraform)

# Giant Swarm control plane terraform manifests

Terraform manifests for installing Giant Swarm's control plane.

## Prerequisites


Install terraform plugin: `terraform-provider-gotemplate`

```
GO111MODULE="on" GOBIN=${HOME}/.terraform.d/plugins/giantswarm.io/operations/gotemplate/0.1.0/$(go env GOOS)_amd64/ go get -u github.com/giantswarm/terraform-provider-gotemplate
```


## Installation


Please follow:
- [installation guide for AWS](docs/installation-guide-aws.md).
- [installation guide for Azure](docs/installation-guide-azure.md).
- [installation guide for VMWare](docs/installation-guide-vmware.md).


## Debug procedure

### Exported logs

The easiest way to debug issues in failed build, is enabling logs export into Logentries. 
This can be done via `.circleci/config.yaml` configuration by setting `LOGENTRIES_ENABLED: "true"`:

```
  e2eTestAzureMultiMaster: &e2eTestAzureMultiMaster
    docker:
      - image: quay.io/giantswarm/docker-terraform-and-stuff:latest
    environment:
      MASTER_COUNT: 3
      LOGENTRIES_ENABLED: "false"
    steps:
    - checkout
    - run: ./misc/e2e-azure.sh
```

Logs can be found in [Rapid7 Insight](https://insight.rapid7.com) platform under *Control Plane*/*Terraform CI* log set.
Credentials to *Rapid7 Insight* can be found in Keepass under *Logentries / Rapid7*.
