#!/bin/bash -e
#
# Script to deploy AWS SAM to create a node drainer for a node ASG of a EKS cluster

# Functions

# Color palette
declare -r RESET='\033[0m'
declare -r GREEN='\033[38;5;2m'
declare -r RED='\033[38;5;1m'
declare -r YELLOW='\033[38;5;3m'

log() {
    printf "%b\n" "${*}" >&2
}

function print_title {
  echo
  echo "-----------------------------------------------------------------------"
  echo "--- $1"
  echo "-----------------------------------------------------------------------"
  echo
}

function usage(){
  echo "$0 [-h] -b bucket -a asg -c cluster -s stack_name"
  echo "    -b: S3 bucket that the sam package command will use to store the deployment package"
  echo "    -a: EKS node austoscaling group name"
  echo "    -c: EKS cluster name"
  echo "    -s: Cloudformation stack name"
  exit 1
}

# Main

while getopts "hb:a:c:s:" name
do
  case $name in
    h) usage;;
    b) bucket="$OPTARG";;
    a) asg="$OPTARG";;
    c) cluster="$OPTARG";;
    s) stack="$OPTARG";;
  esac
done

if [[ -z $bucket ]]; then
  echo "ERROR: Bucket has not been specified"
  usage
  exit 1
elif [[ -z $asg ]]; then
  echo "ERROR: ASG has not been specified"
  usage
  exit 1
elif [[ -z $cluster ]]; then
  echo "ERROR: EKS cluster has not been specified"
  usage
  exit 1
elif [[ -z $stack ]]; then
  echo "ERROR: Cloudforamtion stack has not been specified"
  usage
  exit 1
fi

PS3="Select environment: "
options=("QA" "PROD" "exit")
select opt in "${options[@]}"
do
    case $opt in
        "QA")
            environment="qa"
            break
            ;;
        "PROD")
            environment="prod"
            break
            ;;
        "exit")
            echo "Bye ;)"
            exit 0
            ;;
        *) echo "invalid option $opt";;
    esac
done

cp templates/template-$environment.yaml ./template.yaml

print_title "Building drainer application for $opt cluster"
sam build --use-container --skip-pull-image

print_title "Packaging drainer application. Bucket: '${bucket}'"
sam package --s3-bucket ${bucket} --output-template-file packaged.yaml

print_title "Deploying drainer application"
sam deploy --template-file packaged.yaml --stack-name ${stack} --capabilities CAPABILITY_IAM --parameter-overrides AutoScalingGroup=${asg} EksCluster=${cluster}

print_title "Configuring Kubernetes Permissions"
kubectl apply -R -f k8s_rbac/
ROLE=$(aws cloudformation describe-stacks --stack-name eks-qa-sidekiq-drainer | jq '.Stacks[0].Outputs[0].OutputValue' | tr -d '"')
echo
echo "[INFO] Please, add the following role to 'aws-auth' configMap in your K8s cluster and kube-system namespace"
echo
log "${GREEN}${ROLE}${RESET}"
echo
echo "Bye ;)"
