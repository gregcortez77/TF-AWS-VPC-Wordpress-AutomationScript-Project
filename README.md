# TF-AWS-VPC-Wordpress-AutomationScript-Project
Terraform automation script that creates a full VPC environment (VPC, Public/Private subnet, NAT gateway, IGW,  Routing tables w/ associations, Web/Database servers, Elastic IP, and Security Groups). Also contains user data script for webserver instance, which installs updates, mariadb, php, and Wordpress.


# Instructions/Details

1. Run the "main.tf" script in Terraform. The script will create the following resources in your AWS account;

    - A VPC in us-east-1, w/ a CIDR block of 10.0.0.0/16. (region & CIDR block can be changed within code)
    - Internet & NAT Gateway.
    - Public Subnet w/ a CIDR block of 10.0.0.0/20 & mapping public IP at launch. (CIDR block can be changed within code, and public IP mapping can be disabled as well, if needed)
    - Private Subnet w/ a CIDR block of 10.0.16.0/20. (Again, CIDR block can be changed)
    - Public routing table, with route to IGW that is created within script.
    - Private routing table, with route to NAT Gateway that is created within script.
    - Route table association between Public Subnet & Public Routing table.
    - Route table association between Private Subnet & Private Routing table.
    - Security group for Public instances, with ports 22, 80, & 443 open.
    - Public instance which launches in the created Public Subnet w/ Amazon linux 2 AMI & t2.micro instance type (these can parameters can also be changed within the code). Also contains a User data script, which will automatically install updates, mariadb, php 7.2, httpd, and Wordpress (also modifies test.php file, changes "wordpress" file in html directory to "blog", as well as changes "wp-config-sample.php" to "wp-config.php").
    - An elastic IP which attaches to the Webserver/Public instance.
    - Private/Database instance which launched in the created Private Subnet 2/ Amazon Linux 2 AMI & t2.micro instance type (again, these can parameters can also be changed within the code). It is also not currently configured with any security group or user data script.
    - Set to output the Elastic IP that is created/attached to the Public instance.
  
2. Webserver/Public instance will have mariadb and Wordpress installed already. You will next simply have to log into the Public instance, and configure a database name, username, and password for the database. Then, add these parameters to the "wp-config.php" file. For more details/steps on how to do so, see the "To create a database user and database for your WordPress installation" section in the document below;
    - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hosting-wordpress.html#install-wordpress
    
3. Once completed, you can now access your Wordpress site, and continue setup/installation from there. To access your Wordpress/blog site, use the URL below;
    - http://ec2-50-17-15-27.compute-1.amazonaws.com/blog (Use your public DNS name)
    

# Additional Info

Create an FTP server:

  - https://silicondales.com/tutorials/aws-ec2/setup-ftp-sftp/
