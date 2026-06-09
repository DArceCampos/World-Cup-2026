Rails.application.routes.draw do
  # Health check para verificar que la app arranca sin errores.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Estado global del torneo y avance de fases.
      get  "tournament",          to: "tournaments#show"
      patch "tournament/advance", to: "tournaments#advance"

      # CRUD de grupos y equipos.
      resources :groups, only: %i[index show create update destroy]
      resources :teams,  only: %i[index show create update destroy]

      # Partidos: listado y registro de resultados.
      resources :matches, only: %i[index] do
        member do
          patch :result
        end
      end

      # Fase eliminatoria: bracket y clasificados.
      get "knockout/bracket",    to: "knockout#bracket"
      get "knockout/qualifiers", to: "knockout#qualifiers"

      # Simulación automática de resultados a distintos niveles.
      post "simulations/match/:id", to: "simulations#match"
      post "simulations/group/:id", to: "simulations#group"
      post "simulations/groups",    to: "simulations#groups"
      post "simulations/tournament", to: "simulations#tournament"
    end
  end
end
