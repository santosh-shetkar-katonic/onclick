#!/bin/bash

echo "Welcome to Katonic"

echo "Choose your choice: "
echo "1. Deploy the katonic platform \n"
echo "2. Remove the katonic platform \n"
echo "Enter the number:  "
read choice

#Checking VPC
# VPCs=$(aws ec2 describe-vpcs --vpc-ids | grep VpcId | grep -oh "vpc-\w*" | wc -l)
# if [[ "${VPCs}" -ge "5" ]]
# then
#         echo "More VPC"
# else
#         echo "well done"
# fi
#check this link
#https://ryanstutorials.net/bash-scripting-tutorial/bash-if-statements.php

# Update me

Region="us-east-1"
VpcCIDR="10.10.0.0/21"
PublicSubnets="10.10.0.0/24,10.10.1.0/24,10.10.2.0/24"
SSHKey="katonic-santosh"
StackName="katonic-vpc"
Bucket="santosh-deployment-update"
EnableVPCPeering="false"
EnvType="dev"
os=$(sudo cat /etc/os-release | grep NAME -w | awk -F '"'  '{print $2}')


# EKS
StackNameEKS="katonic-cluster-eks"
#Region="us-east-1"
EksCluster="$StackNameEKS"
VpcName="katonic-vpc"

EksClusterStack="eksctl-katonic-cluster-eks-cluster"
EksClusterNodegroupStack="eksctl-katonic-cluster-eks-nodegroup-worker"

eks_version="1.21"
nodegroup_name="worker"
node_type="t2.medium"
deploy_nodes="2"
deploy_nodes_min="2"
deploy_nodes_max="3"
node_volume_size="50"

export AWS_DEFAULT_REGION=${Region}


if [[ "${choice}" == "1" ]]
then

# Fix
YAML="vpc.yaml"
Name="$StackName"

echo '
---
AWSTemplateFormatVersion: '2010-09-09'
Description: Basic VPC
Mappings:
  ARNNamespace:
    us-east-1:
      Partition: aws
    us-east-2:
      Partition: aws
    us-west-2:
      Partition: aws
    us-west-1:
      Partition: aws
    us-east-1:
      Partition: aws
    eu-central-1:
      Partition: aws
    ap-southeast-1:
      Partition: aws
    ap-northeast-1:
      Partition: aws
    ap-southeast-2:
      Partition: aws
    sa-east-1:
      Partition: aws
    us-gov-west-1:
      Partition: aws-us-gov
  S3Region:
    us-east-1:
      Region: us-east-1
    us-east-2:
      Region: us-east-2
    us-west-2:
      Region: us-east-1
    us-west-1:
      Region: us-east-1
    us-east-1:
      Region: us-east-1
    eu-central-1:
      Region: us-east-1
    ap-southeast-1:
      Region: us-east-1
    ap-northeast-1:
      Region: us-east-1
    ap-southeast-2:
      Region: us-east-1
    sa-east-1:
      Region: us-east-1
    us-gov-west-1:
      Region: us-gov-west-1
Parameters:
  Name:
    Type: String
    Description: Name references build template for automation
  Region:
    Type: String
  Bucket:
    Type: String
    Default: cloudgeeksca-deployment
  DeployBucketPrefix:
    Type: String
    Default: ""
  EnableVPCPeering:
    Type: String
    Default: false
    AllowedValues: ['false', 'true']
  VpcCIDR:
    Type: String
    Default: 10.10.0.0/21
  PublicSubnets:
    Type: CommaDelimitedList
    Description: List of 3 subnets
    Default: 10.10.0.0/24,10.10.1.0/24,10.10.2.0/24
  EnvType:
    Type: String
  SSHKey:
    Type: AWS::EC2::KeyPair::KeyName
    Default: devops
Conditions:
  CreatePeer: !Equals [ !Ref EnableVPCPeering, true]
Resources:
  Vpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsSupport: 'true'
      EnableDnsHostnames: 'true'
      Tags:
        - Key: Name
          Value:
            Ref: AWS::StackName
        - Key: kubernetes.io/role/elb
          Value: shared
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"

  InternetGateway:
    Type: AWS::EC2::InternetGateway

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId:
        Ref: Vpc
      InternetGatewayId:
        Ref: InternetGateway

  PubSubnetAz1:
    Type: AWS::EC2::Subnet
    Properties:
      MapPublicIpOnLaunch: true
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [0, !Ref PublicSubnets]
      AvailabilityZone:
        Fn::Select:
          - '0'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Public Subnet (AZ1)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Public-Subnet-AZ1
          Value: !Sub ${AWS::StackName}-Public-Subnet-AZ1


  PubSubnetAz2:
    Type: AWS::EC2::Subnet
    Properties:
      MapPublicIpOnLaunch: true
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [1, !Ref PublicSubnets]
      AvailabilityZone:
        Fn::Select:
          - '1'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Public Subnet (AZ2)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Public-Subnet-AZ2
          Value: !Sub ${AWS::StackName}-Public-Subnet-AZ2

  PubSubnetAz3:
    Type: AWS::EC2::Subnet
    Properties:
      MapPublicIpOnLaunch: true
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [2, !Ref PublicSubnets]
      AvailabilityZone:
        Fn::Select:
          - '2'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Public Subnet (AZ3)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Public-Subnet-AZ3
          Value: !Sub ${AWS::StackName}-Public-Subnet-AZ3

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Public Routes
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"

  DefaultPublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PubSubnetAz1

  PublicSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PubSubnetAz2

  PublicSubnet3RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PubSubnetAz3

  NoIngressSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupName: "no-ingress-sg"
      GroupDescription: "Security group with no ingress rule"
      VpcId: !Ref Vpc

  VPCPeeringConnection:
    Type: 'AWS::EC2::VPCPeeringConnection'
    Condition: CreatePeer
    Properties:
      VpcId: !Ref Vpc
      PeerVpcId: vpc-283cac51
      PeerRegion: us-east-1
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} peer with Main_Production

Outputs:
  VpcID:
    Description: Created VPC ID
    Value:
      Ref: Vpc
    Export:
      Name: !Sub ${AWS::StackName}-VpcID
  PublicSubnetAz1:
    Description: Public Subnet AZ1 created in VPC
    Value:
      Ref: PubSubnetAz1
  PublicSubnetAz2:
    Description: Public Subnet AZ2 created in VPC
    Value:
      Ref: PubSubnetAz2
  PublicSubnetAz3:
    Description: Public Subnet AZ2 created in VPC
    Value:
      Ref: PubSubnetAz3
  PublicSubnetGroup:
    Value: !Sub ${PubSubnetAz1},${PubSubnetAz2},${PubSubnetAz3}
    Export:
      Name: !Sub ${AWS::StackName}-PublicSubnetGroup
  VpcCidr:
    Description: VPC network block
    Value: !Ref VpcCIDR
    Export:
      Name: !Sub ${AWS::StackName}-VpcCidr
  StackName:
    Description: Output Stack Name
    Value: !Ref AWS::StackName
  Region:
    Description: Stack location
    Value: !Ref AWS::Region
 ' > $YAML


 # Parameters

 cat << EOF > parameters.json
 [
  {
    "ParameterKey": "Bucket",
    "ParameterValue": "$Bucket"
    },
   {
     "ParameterKey": "EnableVPCPeering",
     "ParameterValue": "$EnableVPCPeering"
    },
    {
      "ParameterKey": "EnvType",
      "ParameterValue": "$EnvType"
    },
    {
    "ParameterKey": "PublicSubnets",
    "ParameterValue": "$PublicSubnets"
    },
    {
    "ParameterKey": "Region",
    "ParameterValue": "$Region"
    },
    {
    "ParameterKey": "SSHKey",
    "ParameterValue": "$SSHKey"
    },
    {
    "ParameterKey": "VpcCIDR",
    "ParameterValue": "$VpcCIDR"
    },
    {
     "ParameterKey": "Name",
    "ParameterValue": "$Name"
    }


]
EOF

# Creating a key pair for EC2 Workers Nodes

mkdir ~/.ssh 2>&1 >/dev/null

aws ec2 create-key-pair --key-name $SSHKey --query 'KeyMaterial' --output text > ~/.ssh/$SSHKey.pem


# Create VPC Stack via Cloudformation
aws cloudformation create-stack --stack-name ${StackName} --template-body file://${YAML} --parameters file://parameters.json

echo "Katonic VPC is creating (takes 3 min to create).............."
#sleep 3m 30s


export Region
export AWS_DEFAULT_REGION=${Region}

PubSubnetAz1=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Public-Subnet-AZ1,Values="${VpcName}-Public-Subnet-AZ1" | grep SubnetId | awk -F '"' '{print $4}'`
PubSubnetAz2=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Public-Subnet-AZ1,Values="${VpcName}-Public-Subnet-AZ1" | grep SubnetId | awk -F '"' '{print $4}'`
PubSubnetAz3=`aws ec2 describe-subnets --region "${Region}" --filters Name=tag:Public-Subnet-AZ3,Values="${VpcName}-Public-Subnet-AZ3" | grep SubnetId | awk -F '"' '{print $4}'`

KEY_NAME="santosh_eks"

# Creating a key pair for EC2 Workers Nodes

mkdir ~/.ssh 2>&1 >/dev/null

aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ~/.ssh/$KEY_NAME.pem

export AWS_DEFAULT_REGION=${Region}


#Kubectl and eksctl installation
# Kubectl Installation
echo "Installing kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

chmod +x ./kubectl
cp ./kubectl /usr/bin/kubectl
mv ./kubectl /root/bin/

# EKSCTL Installation
echo "Installing eksctl"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/bin/eksctl
eksctl version

# Eks Cluster SetUp
echo "Creating EKS cluster(it takes 20 min to create cluster)................."

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

echo "Your eks cluster is ready!!!"

#Installing some dependencies to deploy platform

if [[ "${os}" == "Ubuntu" ]]
then
    sudo apt update -y
    sudo apt install -y python3 python3-pip
    sudo apt install ansible -y
    sudo apt install -y python3 python3-pip
    sudo ansible --version
elif [[ "${os}" == "CentOS Linux" ]]
then
    sudo yum update -y
    sudo yum install epel-release -y
    sudo yum install -y python3 python3-pip
    sudo yum install ansible -y
    sudo ansible --version
fi

cat > /etc/ansible/hosts << 'EOF'
[all]
localhost
EOF

#create a directory to clone thw repo into that directory
  #mkdir /root/katonic

#Go to that directory
  #cd /root/katonic

#git clone https://github.com/katonic-dev/platform_deployment_community.git  /root/katonic/cloudformation/aws/eks-cloudformation/katonic/
#git clone --branch with-minio https://raj-katonic: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@github.com/katonic-dev/platform_deployment_community.git /root/katonic

cp platform_deployment_community/deploy.yaml .

#Run the playbook to deploy the platform
echo "Deploying Platform........................."
ansible-playbook -b deploy.yaml




# UPDATE YOUR ./kube
################################################################
### MUST ###
###---> aws eks update-kubeconfig --name katonic-cluster-eks --region us-east-1 <---
##################################################################


elif  [[ "${choice}" == "2" ]]
then
    aws cloudformation delete-stack --stack-name ${EksClusterNodegroupStack} --region us-east-1
    echo "eks cluster nodegroup stack deleting(it takes some time)............."
    sleep 10m
    aws cloudformation delete-stack --stack-name ${EksClusterStack} --region us-east-1
    echo "eks cluster stack deleting(it takes some time)............."
    sleep 5m
    aws cloudformation delete-stack --stack-name ${StackName} --region us-east-1
    echo "katonic vpc deleting(it takes some time)............."
    sleep 3m
else 
    echo "No able to deploy"
fi
