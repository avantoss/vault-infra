# Avant Terraform Vault Setup

**Please Note:** We take Avant's security very seriously. If you believe you have found a security issue in this module, please responsibly disclose by contacting us at security@avant.com.

At Avant we use [Vault](https://www.vaultproject.io/) to manage secrets throughout our infrastructure. Because Vault manages sensitive information it is imperative that it is set up securely. The Packer Builder and Terraform Module in this repo are meant to accomplish just that.

There are a number of features unique to this module that make it attractive for a Vault setup:

- Uses only AWS services, so there are no external dependencies or backends to manage
- HA Storage via DynamoDB easily handles node failures
- The S3 storage backend and cross region replication make region failover simple and reliable
- Versioning on the S3 buckets allows for secret recovery
- S3 and DynamoDB scale with usage, meaning cost is automatically optimized
- The Packer builder allows for simple live Vault upgrades
- The ALB will only route to a healthy Vault leader, preventing unnecessary redirects

## Vault Architecture

![Architecture Map](https://raw.githubusercontent.com/avantoss/vault-infra/HEAD/_docs/architecture.png)

## Getting Started

1. Modify the variables at the top of `packer/vault.json` to reflect your infrastructure
1. From the Packer directory run `packer build -only=ec2-amazonlinux2 vault.json`. You can modify `-only` for other other supported operating systems.
1. Make sure, you have an AWS SSH Keypair for the Vault instances. This module doesn't handle it. See [#3](https://github.com/avantoss/vault-infra/pull/3) for details.
1. This module creates instances in private subnets by default. Make sure to create a [VPC Endpoint for Amazon S3](https://aws.amazon.com/blogs/aws/new-vpc-endpoint-for-amazon-s3/), [VPC Endpoint for DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/vpc-endpoints-dynamodb.html), and [VPC Endpoint for KMS](https://docs.aws.amazon.com/kms/latest/developerguide/kms-vpc-endpoint.html) in your VPC. These endpoints are required for an instance to be able to communicate with S3 and DynamoDB as Vault's backends and be able to communicate with KMS for auto-unseal feature. S3. See [#3](https://github.com/avantoss/vault-infra/pull/3) for details. Caveats: if you use external Auth methods e.g. [GitHub Auth Method](https://www.vaultproject.io/docs/auth/github.html), you will need AWS NAT gateways in each subnet as well
1. From the example file, create a terraform.tfvars file with values that match your infrastructure
1. If you are using remote state create a file named `terraform/main/remote_state.tf` with your configuration
1. Run `terraform plan` followed by `terraform apply`
1. Verify that all of the correct infrastructure was created and resolve any issues (please open an issue for any module errors)
1. Copy the SSL certs to the resources bucket using the CLI

    ```bash
    aws s3 cp cert.crt s3://BUCKET_NAME/resources/ssl/cert.crt --sse AES256
    aws s3 cp privkey.key s3://BUCKET_NAME/resources/ssl/privkey.key --sse AES256
    ```

1. Upload the SSH key used to access Vault instances

    ```bash
    aws s3 cp ssh_key.pem s3://BUCKET_NAME/resources/ssh_key/KEY_NAME.pem --sse AES256
    ```

1. Terminate all existing Vault instances so that they come back up with the SSL certs
1. Temporarily attach an SSH security group to all Vault instances, SSH in, and become root
1. Initialize Vault on one of the nodes

    ```bash
    vault operator init
    ```

1. Copy all of the recovery keys and the root key locally and then to the correct folders in S3 using the CLI

    ```bash
    aws s3 cp root_key.txt s3://BUCKET_NAME/resources/root_key/root_key.txt --sse AES256
    aws s3 cp recovery_key_one.txt s3://BUCKET_NAME/resources/recovery_keys/recovery_key_one.txt --sse AES256
    aws s3 cp recovery_key_two.txt s3://BUCKET_NAME/resources/recovery_keys/recovery_key_two.txt --sse AES256
    aws s3 cp recovery_key_three.txt s3://BUCKET_NAME/resources/recovery_keys/recovery_key_three.txt --sse AES256
    aws s3 cp recovery_key_four.txt s3://BUCKET_NAME/resources/recovery_keys/recovery_key_four.txt --sse AES256
    aws s3 cp recovery_key_five.txt s3://BUCKET_NAME/resources/recovery_keys/recovery_key_five.txt --sse AES256
    ```

1. Vault should automatically unseal using KMS

1. Clear your history and exit

    ```bash
    cat /dev/null > ~/.bash_history && history -c && exit
    ```

1. Remove the temporary SSH security group
1. Unless you've set `route53_enabled` to be `true`, you need to assign DNS to your ALB that matches the certificate that you are using
1. This module can automatically request a certificate from AWS ACM unless `alb_certificate_arn` is directly specified. If you are using your own certificate, you can specify it's ARN with `alb_certificate_arn` variable
1. Locally export your new Vault address. You can now start using Vault

## Packer Architecture

This builder assumes that you have proper AWS access and your keys are exported in the environment running the Packer builder. All necessary Packer configuration can be found in the variables section at the top of `vault.json`.

You must modify `builder_region`, `builder_vpc_id`, and `builder_subnet_id` to match the region, vpc, and subnet that you wish to build your image in. You should also change `ami_regions` and `ami_users` to match the regions and accounts that you want the AMI in. You can also modify any other piece of the configuration, if you wish to change tags etc...

The Packer builder uses Ansible to install Vault securely, following all relevant recommendations in Hashicorp's [Production Hardening](https://www.vaultproject.io/guides/production.html) guide. Namely, it creates a Vault service user, installs Vault with a verified checksum, creates the necessary files/folders, and adds a Vault systemd service.

The Packer builder also exports a global `VAULT ADDR` at `127.0.0.1:9200`, which is used as a local only listener in the Vault configuration.

To reduce the attack surface we do not store secrets in the Packer image; they are pulled on startup from a securely configured S3 bucket.

### Upgrading Vault

Vault can be upgraded by manually modifying `vault_version` and `vault_version_checksum` to match the newest version. Then simply rebuild the Packer image, modify `terraform.tfvars` with the new `ami_id` and `terraform apply`.

Due to the extremely sensitive nature of the Vault program, we do not support automatic upgrading and building of the latest version. Every upgrade should include a careful review of the Vault [Changelog](https://github.com/hashicorp/vault/blob/v0.8.3/CHANGELOG.md) and a manual copying of the checksum and version into your Packer variables. This protects against scenarios where Hashicorp is compromised and malicious versions are pushed to the download servers.

## Terraform Architecture

The goal of this Terraform module is to provide a Vault installation that is as secure as possible, uses only AWS managed services, can handle AZ failure with less than 1 minute of downtime, and permanent region failure with no data loss and less than an hour of downtime.

### Overview

This module sets up two S3 buckets, one for Vault data and one for Vault resources. Access to the buckets is strictly limited to the necessary IAM roles. For example, Vault instances have read/write on the data bucket, but only read access on specific paths in the resources bucket.

By default we create an ASG with a desired capacity of 3, which can handle 2 AZ failures automatically. The Vault service uses TLS 1.2 and pulls SSL certs from the resources bucket on startup.

An Application Load Balancer routes traffic to only the Vault leader, based on a health check. SSL is handled at the ALB level and on the Vault instances. Security groups restrict access to the Vault instances to only the ALB, which should be the only method of accessing Vault.

We also enable a localhost listener directly on the node with TLS disabled so that the root user can access Vault normally. Since this listener is insecure it is on a special port and only accessible from the node itself. Access to the Vault nodes should be carefully controlled, even though access to the node does not imply access to secrets.

### S3 Storage Backend

We use S3 as the backend because it is very reliable, scalable, and simple to set up. AWS promises 99.999999999% data reliability, and with cross region replication we virtually eliminate any chance of data loss. S3 can also scale to any Vault use case we have encountered at Avant, eliminating cumbersome management of backend performance required for other supported storage backends. Finally, S3 is simple to set up and secure, because we can use Terraform to manage bucket policies and IAM instance profiles to manage read/write access.

This bucket is not encrypted because cross region replication does not support encrypted objects. However Vault encrypts all objects before it ever writes them to S3.

### S3 Resources Bucket

We use a second S3 bucket to store all Vault resources, including access logs, SSL certs, unseal keys, recovery keys, the root key, the SSH key, and the Vault configuration file. The idea behind this bucket is that it stores all secrets necessary to get Vault up and running, which should store and manage all other secrets at the organization.

To properly harden this configuration the SSL cert should only be issued for the exact domain that you will use to host Vault. Do not use a wildcard cert. If you plan on storing the SSH key to the Vault instances in this bucket make sure it is only used for those instances. Furthermore, while we support storing the root and unseal/recovery keys within this bucket, you're better off distributing them to trusted individuals or groups and not storing them all in one place.

Certain paths in this bucket enforce encryption, so you will need to upload with AES256 SSE. Cross region replication does not support other encryption methods.

### DynamoDB HA Backend

S3 does not support locking and therefore cannot manage an HA Vault setup. However we can use DynamoDB with the [ha_storage](https://www.vaultproject.io/docs/configuration/index.html#ha_storage) option to manage HA and still use S3 as the storage backend. With the proper IAM permissions Vault can manage the Dynamo table on its own, and since we only use it for HA coordination, the table can be provisioned with minimal cost.

### Automated Unsealing

Vault 1.0.0 announced cloud auto unseal using KMS in open source. Using this method 'unseal keys' are now 'recovery keys' and unseals will happen
automatically with the correct KMS key, permissions, and seal stanza. If you are upgrading to 1.0.0 and using this module, see this document for
instructions on migrating to auto unseal: <https://www.vaultproject.io/docs/concepts/seal.html#seal-migration>.

### Node Failure

If a node fails or even seals for whatever reason the simplest method of remediation is to simply terminate the instance. The ASG will spin up a fresh new instance that will unseal automatically.

### AZ Failure

In the event of an AZ failure Vault should automatically fail over to a backup node. The primary will start failing health checks, a new leader will be chosen and its health checks will start passing, and traffic will be routed to the new leader. This should all occur automatically in less than 60 seconds.

### Region Failure

In the event of a region failure the best option is most likely to wait until AWS resolves the issue. If the failure is permanent or lasts longer than you can afford to wait you can fail to the DR region.

If you want to be as prepared as possible you should have a single node always ready in your DR region that is unsealed and pointing at the DR data bucket. Then, in a failover scenario, all you need to do is change DNS to point at the instance in the new region. You could also have a DR DNS record already assigned and simply change your local `VAULT_ADDR`. However, make sure that you never write to the DR bucket on accident, which could cause issues with cross region replication.

DR in the event of a region failure is currently focused on retaining data and limited Vault functionality. Keep in mind that failing over means moving to a single node (not HA) setup, and that failing back to your primary region requires significant manual work. Cross region replication only works in one direction, so failing back means copying and recreating your setup all over again.

### Secret Version Recovery

Because we use S3 with versioning enabled it is possible (but not simple) to recover an old version of a secret. This should only be used in extreme circumstances and requires Vault downtime.

1. Seal and stop all Vault services
1. In S3 navigate to the secret and restore to the desired previous version
1. Start and unseal all Vault services
1. The previous key should now be restored.

Downtime is required because the Vault service maintains a cache that could overwrite any version recovery when it is flushed to the backend.

### Access Logs

Access logs are enabled on the ALB and the S3 resources bucket. They are both pushed to `logs/` directory in the resources bucket and can be imported or audited by other services. By default these logs are not included in cross region replication.

## Further Considerations

Some useful features of this module have been removed to make it usable for a wider audience. They are discussed below.

### Vault Logging

Logging in to Vault is handled through the [Audit Backends](https://www.vaultproject.io/docs/audit/index.html). You should enable at least two backends for HA logging. At Avant we log to a local file and to syslog, which is configured to push to our Sumologic account.

### Telemetry

At Avant we also install Datadog on the Vault nodes and enable [dogstatsd](https://www.vaultproject.io/docs/configuration/telemetry.html#dogstatsd) telemetry in the Vault configuration. It's been removed from this module due to the wide variety of options, but we highly recommend using a telemetry service.

### Automated AMI Discovery

For ease of use this module requires that you manually enter the AMI ID of the Packer AMI you've just created in your `terraform.tfvars` file. A better, more automated solution that we use is to implement the [aws_ami](https://www.terraform.io/docs/providers/aws/d/ami.html) data provider in Terraform to always find the latest built image.

## License

This project is licensed under the MIT License:

Copyright (c) 2014-2022, Avant, Sean Lingren

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Authors

This module was originally created at [Avant](https://github.com/avantoss)
by Sean Lingren, sean@lingrino.com. Additional contributors include Kyle Nehring and Andrew Fox.
