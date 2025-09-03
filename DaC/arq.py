from diagrams import Diagram, Cluster
from diagrams.aws.general import User
from diagrams.onprem.compute import Server
from diagrams.aws.network import InternetGateway, ELB, RouteTable
from diagrams.aws.compute import EC2
from diagrams.aws.storage import S3, EFS
from diagrams.generic.blank import Blank
from diagrams.custom import Custom

with Diagram("Arq AWS", show=False):

    with Cluster(""):
        usuario = User("Usuário")
        admin = User("Admin\nSSH")

    with Cluster("AWS"):
        igw = InternetGateway("Internet Gateway")

        with Cluster("VPC"):
            lb = ELB("Load Balancer")
            rt = Custom("Route Table", "./route_table.png")

            with Cluster("Zona de Disponibilidade 1a"):
                with Cluster("Sub-rede Pública"):
                    ec2_pub1 = Custom("", "./ec2.png")

                with Cluster("Sub-rede Privada"):    
                    ec2_priv1 = Custom("", "./ec2.png")

            efs = EFS("EFS")

            with Cluster("Zona de Disponibilidade 1c"):
                with Cluster("Sub-rede Pública"):
                    ec2_pub2 = Custom("", "./ec2.png")
        

                with Cluster("Sub-rede Privada"):
                    ec2_priv2 = Custom("", "./ec2.png")

            with Cluster("Zona de Disponibilidade 1d"):
                with Cluster("Sub-rede Privada"):
                    ec2_priv3 = Custom("", "./ec2.png")

    with Cluster("S3 Data Lake"):
        raw = S3("Raw")
        trusted = S3("Trusted")
        curated = S3("Curated")

    usuario >> igw
    admin >> igw 

    igw >> lb

    lb >> ec2_pub1
    lb >> ec2_pub2

    ec2_pub1 >> efs
    ec2_pub2 >> efs

    efs >> ec2_priv1
    efs >> ec2_priv2

    rt >> ec2_priv1
    rt >> ec2_priv2
    rt >> ec2_priv3

    ec2_priv1 >> raw
    ec2_priv2 >> trusted
    ec2_priv3 >> curated
