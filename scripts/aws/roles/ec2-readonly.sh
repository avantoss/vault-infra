vault write aws/roles/ec2-readonly \
    policy_arns=arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess \
    credential_type=iam_user 
