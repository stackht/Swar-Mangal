// PM2 ecosystem for Swar Mangal on aaPanel.
//
// Usage:
//   pm2 start deploy/aapanel/ecosystem.config.cjs
//   pm2 save
//   pm2 startup   # (run the printed command to auto-start on boot)
//
// Environment variables live in /opt/swarmangal/.env (or wherever APP_DIR points).
// pm2-dotenv or ecosystem env_file loads them at start.

module.exports = {
  apps: [
    {
      name: "swarmangal-app",
      cwd: "/opt/swarmangal",
      script: "node_modules/.bin/next",
      args: "start -p 3000",
      env_file: "/opt/swarmangal/.env",
      env: {
        NODE_ENV: "production",
        PORT: 3000,
      },
      instances: 1,
      exec_mode: "fork",
      max_memory_restart: "512M",
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      error_file: "/var/log/swarmangal/app-error.log",
      out_file: "/var/log/swarmangal/app-out.log",
      merge_logs: true,
      autorestart: true,
      max_restarts: 10,
      restart_delay: 5000,
    },
    {
      name: "swarmangal-sheets",
      cwd: "/opt/swarmangal",
      script: "sync/worker.mjs",
      interpreter: "node",
      env_file: "/opt/swarmangal/.env",
      env: {
        NODE_ENV: "production",
      },
      instances: 1,
      exec_mode: "fork",
      max_memory_restart: "256M",
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      error_file: "/var/log/swarmangal/sheets-error.log",
      out_file: "/var/log/swarmangal/sheets-out.log",
      merge_logs: true,
      autorestart: true,
      max_restarts: 10,
      restart_delay: 5000,
    },
  ],
};
