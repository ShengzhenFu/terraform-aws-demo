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
        "metrics_collection_interval": 10,
        "run_as_user": "cwagent",
        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
      },
      "metrics": {
        "namespace": "ImprovedEC2Monitoring",
        "metrics_collected": {
          "cpu": {
            "resources": [
              "*"
            ],
            "measurement": [
              "cpu_usage_idle",
              "cpu_usage_iowait",
              "cpu_usage_user",
              "cpu_usage_system"
            ],
            "totalcpu": false,
            "metrics_collection_interval": 10
          },
          "disk": {
            "resources": [
              "/"
            ],
            "measurement": [
              {"name": "free", "rename": "DISK_FREE", "unit": "Gigabytes"},
              {"name": "total", "unit": "Gigabytes"},
              {"name": "used", "unit": "Gigabytes"},
              "disk_used_percent"
            ],
             "ignore_file_system_types": [
              "sysfs", "devtmpfs"
            ],
            "metrics_collection_interval": 60
          },
          "mem": {
            "measurement": [
              "mem_used",
              "mem_cached",
              "mem_total",
              "mem_used_percent"
            ],
            "metrics_collection_interval": 10
          }
        },
        "append_dimensions": {
          "InstanceId": "${aws:InstanceId}",
          "InstanceType": "${aws:InstanceType}"
        },
        "force_flush_interval" : 30
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
                "log_group_name": "amazon-cloudwatch-agent-${aws:InstanceId}.log",
                "log_stream_name": "amazon-cloudwatch-agent-${aws:InstanceId}.log",
                "timezone": "Local",
                "retention_in_days": 3
              },
              {
                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/test.log",
                "log_group_name": "test.log",
                "log_stream_name": "test.log",
                "timezone": "UTC",
                "retention_in_days": 1
              }
            ]
          }
        },
        "log_stream_name": "cw-log-${aws:InstanceId}",
        "force_flush_interval" : 15
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