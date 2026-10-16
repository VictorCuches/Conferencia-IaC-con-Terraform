#!/bin/bash
set -e

# Instalar y arrancar Nginx
dnf install -y nginx
systemctl enable --now nginx

# Página HTML con datos del ambiente
cat > /usr/share/nginx/html/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${label} — Terraform Demo</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #f5f5f5;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
    }
    .card {
      background: white;
      border-radius: 12px;
      box-shadow: 0 4px 24px rgba(0,0,0,.12);
      padding: 48px 56px;
      max-width: 480px;
      width: 90%;
      text-align: center;
    }
    .badge {
      display: inline-block;
      background: ${bg_color};
      color: ${color};
      border: 2px solid ${border_color};
      border-radius: 8px;
      font-size: 2.4rem;
      font-weight: 800;
      letter-spacing: .12em;
      padding: 12px 32px;
      margin-bottom: 32px;
    }
    h1 { font-size: 1.5rem; color: #333; margin-bottom: 8px; }
    .subtitle { color: #777; font-size: .95rem; margin-bottom: 32px; }
    table { width: 100%; border-collapse: collapse; text-align: left; }
    td { padding: 10px 12px; border-bottom: 1px solid #eee; font-size: .9rem; }
    td:first-child { color: #777; width: 45%; }
    td:last-child { font-weight: 600; color: #333; }
    .footer { margin-top: 32px; font-size: .78rem; color: #aaa; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">${label}</div>
    <h1>Terraform IaC Demo</h1>
    <p class="subtitle">Infraestructura gestionada con Terraform Workspaces</p>

    <table>
      <tr><td>Ambiente</td>         <td>${environment}</td></tr>
      <tr><td>Availability Zone</td><td>${az}</td></tr>
      <tr><td>Instancias totales</td><td>${replica_count}</td></tr>
      <tr><td>Tipo EC2</td>         <td>${instance_type}</td></tr>
    </table>

    <p class="footer">Desplegado con <strong>terraform apply</strong> · workspace: ${environment}</p>
  </div>
</body>
</html>
HTMLEOF
