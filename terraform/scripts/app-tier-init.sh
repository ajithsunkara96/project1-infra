#!/bin/bash
#############################################################
# App Tier Initialization Script
# Purpose: Install Node.js and deploy API server
#############################################################

set -e  # Exit on any error

# Update system packages
echo "=== Updating system packages ==="
apt-get update -y

# Install Node.js 18 LTS
echo "=== Installing Node.js 18 LTS ==="
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Verify installation
echo "=== Verifying Node.js installation ==="
node --version
npm --version

# Create application directory
echo "=== Setting up application directory ==="
mkdir -p /opt/app
cd /opt/app

# Create package.json
echo "=== Creating package.json ==="
cat > /opt/app/package.json <<'EOF'
{
  "name": "project1-app-tier",
  "version": "1.0.0",
  "description": "App Tier API Server",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mssql": "^10.0.1",
    "body-parser": "^1.20.2",
    "cors": "^2.8.5"
  }
}
EOF

# Install npm packages
echo "=== Installing npm packages ==="
npm install

# Get instance metadata
INSTANCE_NAME=$(hostname)
PRIVATE_IP=$(hostname -I | awk '{print $1}')
ZONE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/zone?api-version=2021-02-01&format=text" || echo "unknown")

# Create the Node.js API server
echo "=== Creating API server ==="
cat > /opt/app/server.js <<'EOFSERVER'
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const sql = require('mssql');
const os = require('os');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// SQL Database configuration (from environment variables)
const sqlConfig = {
  server: process.env.SQL_SERVER || 'project1-sqlserver.database.windows.net',
  database: process.env.SQL_DATABASE || 'project1db',
  authentication: {
    type: 'default',
    options: {
      userName: process.env.SQL_USER || 'sqladminuser',
      password: process.env.SQL_PASSWORD || 'P@ssword123!'
    }
  },
  options: {
    encrypt: true,
    trustServerCertificate: false,
    enableArithAbort: true
  }
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    instance: os.hostname(),
    timestamp: new Date().toISOString()
  });
});

// Get server info
app.get('/api/info', (req, res) => {
  const networkInterfaces = os.networkInterfaces();
  const privateIP = networkInterfaces.eth0 
    ? networkInterfaces.eth0[0].address 
    : 'unknown';

  res.json({
    instance: os.hostname(),
    privateIP: privateIP,
    nodeVersion: process.version,
    uptime: process.uptime(),
    message: 'App Tier API Server is running!'
  });
});

// Test database connection
app.get('/api/db-test', async (req, res) => {
  try {
    const pool = await sql.connect(sqlConfig);
    const result = await pool.request().query('SELECT @@VERSION as version');
    
    res.json({
      status: 'success',
      message: 'Database connection successful!',
      instance: os.hostname(),
      dbVersion: result.recordset[0].version
    });
    
    await pool.close();
  } catch (err) {
    console.error('Database connection error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Database connection failed',
      error: err.message,
      instance: os.hostname()
    });
  }
});

// User registration endpoint (we'll implement this fully later)
app.post('/api/register', async (req, res) => {
  const { username, email, password } = req.body;
  
  // Basic validation
  if (!username || !email || !password) {
    return res.status(400).json({
      status: 'error',
      message: 'Missing required fields'
    });
  }

  try {
    // TODO: Implement database insert
    // For now, just return success
    res.json({
      status: 'success',
      message: 'User registration endpoint ready',
      instance: os.hostname(),
      data: {
        username: username,
        email: email
      }
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({
      status: 'error',
      message: 'Registration failed',
      error: err.message
    });
  }
});

// Get all users (we'll implement this fully later)
app.get('/api/users', (req, res) => {
  res.json({
    status: 'success',
    message: 'Users endpoint ready',
    instance: os.hostname(),
    users: []
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Project1 App Tier API',
    instance: os.hostname(),
    endpoints: [
      'GET  /health',
      'GET  /api/info',
      'GET  /api/db-test',
      'POST /api/register',
      'GET  /api/users'
    ]
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`App Tier API Server running on port ${PORT}`);
  console.log(`Instance: ${os.hostname()}`);
  console.log(`Node.js version: ${process.version}`);
});
EOFSERVER

# Create systemd service for auto-start
echo "=== Creating systemd service ==="
cat > /etc/systemd/system/app-tier.service <<'EOFSERVICE'
[Unit]
Description=Project1 App Tier API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node /opt/app/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables (we'll update these later with secure values)
Environment="SQL_SERVER=project1-sqlserver.database.windows.net"
Environment="SQL_DATABASE=project1db"
Environment="SQL_USER=sqladminuser"
Environment="SQL_PASSWORD=P@ssword123!"

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Reload systemd, enable and start service
echo "=== Starting App Tier service ==="
systemctl daemon-reload
systemctl enable app-tier.service
systemctl start app-tier.service

# Wait a moment for service to start
sleep 3

# Verify service is running
echo "=== Verifying App Tier service status ==="
systemctl status app-tier.service --no-pager

# Test the API locally
echo "=== Testing API locally ==="
curl -s http://localhost:3000/health || echo "API not responding yet"

echo "=== App Tier initialization complete! ==="
echo "Instance: ${INSTANCE_NAME}"
echo "Private IP: ${PRIVATE_IP}"
echo "Zone: ${ZONE}"
echo "API running on port 3000"