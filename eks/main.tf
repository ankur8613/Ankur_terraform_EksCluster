resource "aws_vpc" "main"{
    cidr_block = "172.41.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags ={
      Name = "main"
    }
}
output "vpc_id"{
    value = aws_vpc.main.id
    description = "VPC id."
    sensitive = false
}

resource "aws_internet_gateway" "main"{
    vpc_id = "aws_vpc.main.id"
}

resource "aws_subnet" "public_1"{
    vpc_id = "aws_vpc.main.id"
    cidr_block = "172.41.0.0/16"
    availability_zone = "us-west-1"
    map_public_ip_on_launch = true

    tags = {
      Name = "public-us-west-1"
      "kubernetes.io/cluster/eks" = "shared"
      "kubernetes.io/role/elb" = 1
    }

}

resource "aws_subnet" "public_2"{
    vpc_id = "aws_vpc.main.id"
    cidr_block = "172.41.0.0/16"
    availability_zone = "us-west-1"
    map_public_ip_on_launch = true

    tags = {
      Name = "public2-us-west-1"
      "kubernetes.io/cluster/eks" = "shared"
      "kubernetes.io/role/elb" = 1
    }

}

resource "aws_subnet" "public_3"{
    vpc_id = "aws_vpc.main.id"
    cidr_block = "172.41.0.0/16"
    availability_zone = "us-west-1"
    map_public_ip_on_launch = true

    tags = {
      Name = "public3-us-west-1"
      "kubernetes.io/cluster/eks" = "shared"
      "kubernetes.io/role/elb" = 1
    }

}

resource "aws_subnet" "private_1"{
    vpc_id = "aws_vpc.main.id"
    cidr_block = "172.41.0.0/16"
    availability_zone = "us-west-1"
    tags = {
      Name = "private1-us-west-1"
      "kubernetes.io/cluster/eks" = "shared"
      "kubernetes.io/role/elb" = 1
    }
}

resource "aws_subnet" "private_2"{
    vpc_id = "aws_vpc.main.id"
    cidr_block = "172.41.0.0/16"
    availability_zone = "us-west-1"
    tags = {
      Name = "private2-us-west-1"
      "kubernetes.io/cluster/eks" = "shared"
      "kubernetes.io/role/elb" = 1
    }
}


resource "aws_subnet" "private_3"{
    vpc_id = "aws_vpc.main.id"
    cidr_block = "172.41.0.0/16"
    availability_zone = "us-west-1"
    tags = {
      Name = "private3-us-west-1"
      "kubernetes.io/cluster/eks" = "shared"
      "kubernetes.io/role/elb" = 1
    }
}
resource "aws_eip" "nat1"{
    depends_on = [aws_internet_gateway.main]
}
resource "aws_nat_gateway" "gw"{
    allocation_id = aws_eip.nat1.id
    subnet_id = aws_subnet.public_1.id
    tags = {
      Name = "NAT1"
    }
}

resource "aws_route_table" "public"{
    vpc_id = aws_vpc.main.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = "aws_internet_gateway.main.id"
    }
    tags = {
      Name = "public"
    }
}

resource "aws_route_table" "private"{
    vpc_id = aws_vpc.main.id
    route{
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "aws_nat_gateway.gw.id"
    }
    tags = {
      Name = "private"
    }
}

resource "aws_route_table_association" "public1"{
    subnet_id = "aws_subnet.public_1.id"
    route_table_id = "aws_route_table.public.id"
}

resource "aws_route_table_association" "public2"{
    subnet_id = "aws_subnet.public_2.id"
    route_table_id = "aws_route_table.public.id"
}

resource "aws_route_table_association" "public3"{
    subnet_id = "aws_subnet.public_3.id"
    route_table_id = "aws_route_table.public.id"
}

resource "aws_route_table_association" "private1"{
    subnet_id = "aws_subnet.private_1.id"
    route_table_id = "aws_route_table.private.id"
}

resource "aws_route_table_association" "private2"{
    subnet_id = "aws_subnet.private_2.id"
    route_table_id = "aws_route_table.private.id"
}

resource "aws_route_table_association" "private3"{
    subnet_id = "aws_subnet.private_3.id"
    route_table_id = "aws_route_table.private.id"
}

resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks" {
  name = "eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version = "1.21"

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access = true

    subnet_ids = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id,
      aws_subnet.public_3.id,
      aws_subnet.private_1.id,
      aws_subnet.private_2.id,
      aws_subnet.private_3.id
    ]
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

resource "aws_iam_role" "nodes_general" {
  name = "eks-node-group-general"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy_general" {
  role       = aws_iam_role.nodes_general.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy_general" {
  role       = aws_iam_role.nodes_general.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  role       = aws_iam_role.nodes_general.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "nodes_general"{
  cluster_name = aws_eks_cluster.eks.name
  node_group_name = "nodes_general"
  node_role_arn = aws_iam_role.nodes_general.arn

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id,
    aws_subnet.private_3.id
  ]
  scaling_config {
    desired_size = 1 
    max_size = 1
    min_size = 1
  }
  capacity_type = "ON_DEMAND"
  disk_size = 20
  force_update_version = false
  instance_types = ["t3.medium"]
  labels = {
    role = "nodes_general"
  }
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy_general,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy_general,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only
  ]
  
}



