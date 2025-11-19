#!/bin/bash
#############################################################
# Web Tier Initialization Script
# Purpose: Install Nginx and deploy simple web page
#############################################################

set -e  # Exit on any error

# Update system packages
echo "=== Updating system packages ==="
apt-get update -y

# Install Nginx
echo "=== Installing Nginx ==="
apt-get install -y nginx

# Get instance metadata (which VM am I?)
INSTANCE_NAME=$(hostname)
PRIVATE_IP=$(hostname -I | awk '{print $1}')
ZONE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/zone?api-version=2021-02-01&format=text" || echo "unknown")

# Create a custom index page
echo "=== Creating custom web page ==="
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project1 - Web Tier</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 50px;
            border-radius: 20px;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            backdrop-filter: blur(4px);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        h1 {
            font-size: 3em;
            margin: 0;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .info {
            margin-top: 30px;
            font-size: 1.2em;
        }
        .badge {
            display: inline-block;
            background: rgba(255, 255, 255, 0.2);
            padding: 10px 20px;
            margin: 10px;
            border-radius: 10px;
            font-weight: bold;
        }
        .success {
            color: #4ade80;
            font-size: 1.5em;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Project1 Web Tier</h1>
        <div class="success">✅ Nginx is Running!</div>
        <div class="info">
            <div class="badge">🖥️ Instance: ${INSTANCE_NAME}</div>
            <div class="badge">🌐 Private IP: ${PRIVATE_IP}</div>
            <div class="badge">📍 Zone: ${ZONE}</div>
        </div>
        <p style="margin-top: 30px; font-size: 0.9em;">
            Load Balanced by Azure | Auto-Scaled | Multi-Zone
        </p>
    </div>
</body>
</html>
EOF

# Start and enable Nginx
echo "=== Starting Nginx ==="
systemctl start nginx
systemctl enable nginx

# Allow HTTP through firewall (if UFW is enabled)
if command -v ufw &> /dev/null; then
    ufw allow 'Nginx HTTP' || true
fi

# Verify Nginx is running
echo "=== Verifying Nginx status ==="
systemctl status nginx --no-pager

echo "=== Web Tier initialization complete! ==="
echo "Instance: ${INSTANCE_NAME}"
echo "Private IP: ${PRIVATE_IP}"
echo "Zone: ${ZONE}"