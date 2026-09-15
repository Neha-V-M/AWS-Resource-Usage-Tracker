#!/bin/bash

###############################
#
#Author : Neha V M
#
#Date: 15/09/2026
#
#This script outputs the AWS resource usage - AWS S3, AWS EC2, AWS Lambda, AWS IAM Users
#
#version : v1
#
###############################

export AWS_PAGER=""

set -x

#list S3 buckets
aws s3 ls

#list EC2 instances
aws ec2 describe-instances | jq '.Reservations[].Instances[].InstanceId'

#list lamda
aws lambda list-functions

#list IAM users
aws iam list-users | jq '.Users[].UserName'


#AWS CLI auto-pipes long output through a "pager" (like less) so it doesn't all scroll past at once on a real terminal.
#The pager needs terminal info (TERM) to work properly; env -i strips that, so it fell back to a dumb mode asking you to press Enter.
#Commands piped into jq (like ec2 describe-instances) skip the pager entirely, since output goes to another program, not a screen.
#Commands with no pipe (like lambda list-functions) go straight to the screen, so the CLI tries to page them — and that's where the prompt appeared.
#Fix: add export AWS_PAGER="" near the top of your script so no command ever tries to invoke the pager, piped or not.
