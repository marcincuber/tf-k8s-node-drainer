# tf-k8s-node-drainer
Gracefully drain Kubernetes pods from EKS worker nodes during autoscaling scale-in events.

The code provides an AWS Lambda function that integrates as an [Amazon EC2 Auto
Scaling Lifecycle Hook](https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html).
When called, the Lambda function calls the Kubernetes API to cordon and evict all evictable pods from the node being 
terminated. It will then wait until all pods have been evicted before the Auto Scaling group continues to terminate the
EC2 instance. The lambda may be killed by the function timeout before all evictions complete successfully, in which case
the lifecycle hook may re-execute the lambda to try again. If the lifecycle heartbeat expires then termination of the EC2
instance will continue regardless of whether or not draining was successful. You may need to increase the function and
heartbeat timeouts in template.yaml if you have very long grace periods.

Using this approach can minimise disruption to the services running in your cluster by allowing Kubernetes to 
reschedule the pod prior to the instance being terminated enters the TERMINATING state. It works by using 
[Amazon EC2 Auto Scaling Lifecycle Hooks](https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html)
to trigger an AWS Lambda function that uses the Kubernetes API to cordon the node and evict the pods.

This lambda can also be used against a non-EKS Kubernetes cluster by reading a `kubeconfig` file from an S3 bucket
specified by the `KUBE_CONFIG_BUCKET` and `KUBE_CONFIG_OBJECT` environment variables. If these two variables are passed 
in then Drainer function will assume this is a non-EKS cluster and the IAM authenticator signatures will _not_ be added 
to Kubernetes API requests. It is recommended to apply the principle of least privilege to the IAM role that governs
access between the Lambda function and S3 bucket.

This lambda function is deployed using Terraform 0.12 which should nicely fit into your terraform templates that you use for EKS deployment.

Lambda has been tested with EKS 1.12, 1.13, 1.14, 1.15, 1.16.

## Requirements

* AWS CLI
* Python 3 (tested with 3.8)
* Terraform 0.12

## Deploying

[Terraform folder](./terraform) contains an example configuration of lambda function that can be deployed using Terraform. In order to deploy it you can run the following (ensure to adapt variables inside [terraform/vars/dev.tfvars](./terraform/vars/dev.tfvars):

```
cd terraform
make tf-plan-dev
make tf-apply-dev
```

Zip with lambda is already commited. But if you decide to generate a new zip with some lambda changes, you can simply run:

```
make build-lambda-node-drainer
```

## Autoscaling group lifecycle hook configuration example

Following lifecycle transition should be used inside your ASG lifecycle hook:

```
resource "aws_autoscaling_group" "asg" {
  name                      = "terraform-test"
  ...

  initial_lifecycle_hook {
    name                 = "test"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 180
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  }
  ...
}
```

## Kubernetes Permissions

After deployment there will be an IAM role associated with the lambda that needs to be mapped to a user or group in 
the EKS cluster. To create the Kubernetes `ClusterRole` and `ClusterRoleBinding` run the following shell command from the root 
directory of the project:

```bash
kubectl apply -R -f terraform/node_drainer/k8s_rbac/
```

You may now create the mapping to the IAM role created when deploying the Drainer function. 
You can find this role by checking the `DrainerRole` output of the CloudFormation stack created by the `sam deploy`
command above. Run `kubectl edit -n kube-system configmap/aws-auth` and add the following `yaml`:

```yaml
mapRoles: | 
# ...
    - rolearn: <DrainerFunction IAM role>
      username: lambda-node-drainer
```

## Testing the Drainer function

Run the following command to simulate an EC2 instance being terminated as part of a scale-in event:

```bash
aws autoscaling terminate-instance-in-auto-scaling-group --no-should-decrement-desired-capacity --instance-id <instance-id>
```

You must use this command for Auto Scaling Lifecycle hooks to be used. Terminating the instance via the EC2 Console or APIs will immediately terminate the instance, bypassing the lifecycle hooks.

## Fetch, tail, and filter Lambda function logs

Check cloudwatch log group for your lambda.

# Appendix

## Limitations

This lambda function requires to be deployed per cluster per autoscaling group. In case you have multiple autoscaling groups will require a separate deployment for each group. Usual setup if you run spot instances is that you would have a single autoscaling group per availability zone.

This lambda will not attempt to evict DaemonSets or mirror pods.

## Credits

Majority of lambda code has been taken from [amazon-k8s-node-drainer](https://github.com/aws-samples/amazon-k8s-node-drainer)