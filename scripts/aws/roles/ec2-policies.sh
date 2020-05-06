vault write aws/roles/ec2-fullaccess \
    credential_type=iam_user \
    policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    }
  ]
}
EOF

vault write aws/roles/ec2-readonly \
    policy_arns=arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess \
    credential_type=iam_user 
