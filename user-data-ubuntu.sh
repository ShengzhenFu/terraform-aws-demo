#!/bin/bash

#####################################################
# Update the apt package index
#####################################################

sudo apt-get -y update

#####################################################
# Install CLOUD WATCH AGENT
#####################################################
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
CWCONFIGFILE=/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
if [ ! -f "$CWCONFIGFILE" ]; then
  echo "CW config json File does not exist."
  sudo touch /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
fi
sudo chmod o+w /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
	"agent": {
		"metrics_collection_interval": 60,
		"run_as_user": "root"
	},
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/apache2/error.log",
            "log_group_name": "apache-log-group",
            "log_stream_name": "ec2-{instance_id}-apache-error-logs",
            "retention_in_days": 1
          },
          {
            "file_path": "/var/log/apache2/access.log",
            "log_group_name": "apache-log-group",
            "log_stream_name": "ec2-{instance_id}-apache-access-logs",
            "retention_in_days": 1
          }
        ]
      }
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

#####################################################
# HTTPD WEB SERVER
#####################################################
sudo apt-get update -y
sudo apt-get install -y apache2
INDEXFILE=/var/www/html/index.html
if [ ! -f "$INDEXFILE" ]; then
  echo "File does not exist."
  sudo touch /var/www/html/index.html
fi
sudo chmod 777 /var/www/html/index.html
sudo echo "Welcome ! from instance $(hostname -f)" > /var/www/html/index.html
sudo echo "Welcome ! from instance $(hostname -f)" > /var/www/html/main.html
sudo systemctl start apache2