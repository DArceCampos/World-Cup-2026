# Be sure to restart your server when you modify this file.

# Configuración de CORS para permitir que el frontend React (Vite, puerto 5173)
# consuma la API durante el desarrollo.
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:5173", "http://127.0.0.1:5173"

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
