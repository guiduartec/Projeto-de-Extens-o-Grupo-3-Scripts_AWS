from diagrams import Diagram, Cluster
from diagrams.aws.general import User
from diagrams.onprem.compute import Server
from diagrams.aws.network import InternetGateway, ELB, RouteTable
from diagrams.aws.compute import EC2
from diagrams.aws.storage import S3, EFS
from diagrams.generic.blank import Blank

with Diagram("Arq AWS", show=False, direction="TB"):

    with Cluster("Usuários"):
        usuario = User("Usuário")
        admin = Server("Admin\nSSH")

    with Cluster("AWS"):
        igw = InternetGateway("Internet Gateway")

        with Cluster("VPC"):
            lb = ELB("Load Balancer")
            rt = RouteTable("Route Table")
            efs = EFS("EFS")

            with Cluster("Zona de Disponibilidade 1a"):
                with Cluster("SubnetPública"):
                    ec2_pub1 = EC2("EC2 Pública 1a")
                    grupo_web = Blank("Grupo de Destino Web")

                with Cluster("SubnetPrivada"):
                    ec2_priv1 = EC2("EC2 Privada 1a")

            with Cluster("Zona de Disponibilidade 1c"):
                with Cluster("SubnetPública"):
                    ec2_pub2 = EC2("EC2 Pública 1c")

                with Cluster("SubnetPrivada"):
                    ec2_priv2 = EC2("EC2 Privada 1c")

            with Cluster("Zona de Disponibilidade 1d"):
                with Cluster("SubnetPrivada"):
                    ec2_priv3 = EC2("EC2 Privada 1d")

    with Cluster("S3 Data Lake"):
        raw = S3("Raw")
        trusted = S3("Trusted")
        curated = S3("Curated")


    admin >> ec2_priv1
    admin >> ec2_priv2
    admin >> ec2_priv3

    admin >> igw
    usuario >> igw

    igw >> lb

    lb >> ec2_pub1
    lb >> ec2_pub2

    grupo_web >> ec2_pub1

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
