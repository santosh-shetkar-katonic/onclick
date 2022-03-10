#!/bin/bash
# Purpose: Automated & Highly Secure Setup for aws EKS cluster


# EKS
StackName="santosh-cluster-eks"
Region="us-east-1"
EksCluster="$StackName"
eks_version="1.21"
nodegroup_name="worker"
node_type="t2.medium"
deploy_nodes="2"
deploy_nodes_min="2"
deploy_nodes_max="3"
node_volume_size="50"

export Region
export AWS_DEFAULT_REGION=${Region}
# Private Subnets
# PrivSubnetAz1=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Private-Subnet-AZ1,Values="${EksCluster}-Private-Subnet-AZ1" | grep SubnetId | awk -F '"' '{print $4}'`
# PrivSubnetAz2=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Private-Subnet-AZ2,Values="${EksCluster}-Private-Subnet-AZ2" | grep SubnetId | awk -F '"' '{print $4}'`
# PrivSubnetAz3=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Private-Subnet-AZ3,Values="${EksCluster}-Private-Subnet-AZ3" | grep SubnetId | awk -F '"' '{print $4}'`


PubSubnetAz1=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Public-Subnet-AZ1,Values="${EksCluster}-Public-Subnet-AZ1" | grep SubnetId | awk -F '"' '{print $4}'`
PubSubnetAz2=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Public-Subnet-AZ1,Values="${EksCluster}-Public-Subnet-AZ1" | grep SubnetId | awk -F '"' '{print $4}'`
PubSubnetAz3=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Public-Subnet-AZ3,Values="${EksCluster}-Public-Subnet-AZ3" | grep SubnetId | awk -F '"' '{print $4}'`

KEY_NAME="santosh_eks"

# Creating a key pair for EC2 Workers Nodes

mkdir ~/.ssh 2>&1 >/dev/null

aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ~/.ssh/$KEY_NAME.pem

export AWS_DEFAULT_REGION=${Region}

# Eks Cluster SetUp

eksctl create cluster \
  --name ${EksCluster} \
  --version ${eks_version} \
  --vpc-public-subnets=$PubSubnetAz1,$PubSubnetAz2,$PubSubnetAz3 \
  --region ${Region} \
  --nodegroup-name ${nodegroup_name} \
  --node-type ${node_type} \
  --nodes ${deploy_nodes} \
  --nodes-min ${deploy_nodes_min} \
  --nodes-max ${deploy_nodes_max} \
  --ssh-access \
  --node-volume-size ${node_volume_size} \
  --ssh-public-key ${KEY_NAME} \
  --appmesh-access \
  --full-ecr-access \
  --alb-ingress-access \
  --managed \
  --asg-access \
  --verbose 3


# UPDATE YOUR ./kube
################################################################
### MUST ###
###---> aws eks update-kubeconfig --name cloudgeeksca-eks --region us-east-1 <---
##################################################################

# Update Public to Private End Points
###---> aws eks update-cluster-config --name cloudgeeksca-eks --region us-east-1 --resources-vpc-config endpointPublicAccess=false,endpointPrivateAccess=true
#END
