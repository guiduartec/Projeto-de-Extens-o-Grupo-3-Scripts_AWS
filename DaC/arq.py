from diagrams import Diagram, Cluster
from diagrams.aws.general import User
from diagrams.onprem.compute import Server
from diagrams.aws.network import InternetGateway, ELB, RouteTable
from diagrams.aws.compute import EC2
from diagrams.aws.storage import S3, EFS
from diagrams.generic.blank import Blank
from diagrams.custom import Custom

with Diagram("Arq AWS", show=False, direction="BT", 
             graph_attr={"splines": "ortho", "nodesep": "0.25", "ranksep": "3"}, node_attr={"fontsize": "17"}):


    with Cluster(""):
        usuario = User("Usuário")
        admin = User("Admin\nSSH")

    internet = Custom("Internet", "./internet.jpg", width="2", height="2", imagescale="true", fixedsize="true")

    with Cluster("AWS", graph_attr={"bgcolor": "#FCF1E3", "color": "#F7981F", "fontsize": "25"}):

        igw = InternetGateway("Internet Gateway", )

        with Cluster("VPC", graph_attr={"bgcolor":"#dbe7f0", "fontsize": "25"}):
            lb = ELB("Load Balancer")
            
            rt = Custom("Route Table", "./route_table.png")

            with Cluster("Zona de Disponibilidade 1a", graph_attr={"fontsize": "17"}):
                filler = Blank("", width="0.01", height="0.1")

                with Cluster("Sub-rede Pública", graph_attr={"bgcolor":"#c6e9b3", "fontsize": "17"}):
                    filler = Blank("", width="0.01", height="0.1")
                    security_group = Custom("", "./security_group.png", width="0.7", height="0.7", imagescale="true", fixedsize="true")
                    ec2_pub1 = Custom("", "./ec2.png")
                    ebs = Custom("", "./EBS.png", width="1", height="1", imagescale="true", fixedsize="true")
                    filler = Blank("", width="0.01")

                with Cluster("Sub-rede Privada", graph_attr={"bgcolor":"#a3dcdd", "fontsize": "17"}):
                    filler = Blank("", width="0.01", height="0.1")
                    security = Custom("", "./security_group.png", width="0.7", height="0.7", imagescale="true", fixedsize="true")    
                    ec2_priv1 = Custom("", "./ec2.png")
                    ebs = Custom("", "./EBS.png", width="1", height="1", imagescale="true", fixedsize="true")
                    filler = Blank("", width="0.01", height="0.1")

            efs = EFS("EFS")

            with Cluster("Zona de Disponibilidade 1c", graph_attr={"fontsize": "17"}):
                filler = Blank("", width="0.01", height="0.1")

                with Cluster("Sub-rede Pública", graph_attr={"bgcolor":"#c6e9b3", "fontsize": "17"}):
                    filler = Blank("", width="0.01", height="0.1")
                    security_group = Custom("", "./security_group.png", width="0.7", height="0.7", imagescale="true", fixedsize="true")
                    ec2_pub2 = Custom("", "./ec2.png")
                    ebs = Custom("", "./EBS.png", width="1", height="1", imagescale="true", fixedsize="true")
                    filler = Blank("", width="0.01", height="0.1")

                with Cluster("Sub-rede Privada", graph_attr={"bgcolor":"#a3dcdd", "fontsize": "17"}):
                    filler = Blank("", width="0.01", height="0.1")
                    security_group = Custom("", "./security_group.png", width="0.7", height="0.7", imagescale="true", fixedsize="true")
                    ec2_priv2 = Custom("", "./ec2.png")
                    ebs = Custom("", "./EBS.png", width="1", height="1", imagescale="true", fixedsize="true")
                    filler = Blank("", width="0.01", height="0.1")

            
            with Cluster("Zona de Disponibilidade 1d", graph_attr={"fontsize": "17"}):
                filler = Blank("", width="0.01", height="0.1")
                with Cluster("Sub-rede Privada", graph_attr={"bgcolor":"#a3dcdd", "fontsize": "17"}):
                    filler = Blank("", width="0.01", height="0.1")
                    security_group = Custom("", "./security_group.png", width="0.7", height="0.7", imagescale="true", fixedsize="true")
                    ec2_priv3 = Custom("", "./ec2.png")
                    bd = Custom("", "./mysql.png", width="1.5", height="1.5", imagescale="true", fixedsize="true")
                    filler = Blank("", width="0.01", height="0.1")

        with Cluster("S3 Data Lake", graph_attr={"fontsize": "19"}):
            raw = S3("Raw")
            trusted = S3("Trusted")
            curated = S3("Curated")                

    usuario >> internet >> igw
    admin >> internet >> igw 

    igw >> lb

    lb >> [ec2_pub1, ec2_pub2]

    # ec2_pub1 >> efs
    # ec2_pub2 >> efs

    rt >> [ec2_pub1, ec2_pub2]

    efs >> [ec2_pub1, ec2_pub2]

    ec2_priv1 >> ec2_priv3
    ec2_priv2 >> ec2_priv3     

    ec2_pub1 >> raw
