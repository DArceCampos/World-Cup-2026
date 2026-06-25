Rails.application.routes.draw do
  root "dashboard#index"

  resources :groups, only: %i[index show] do
    post :simulate, on: :member
  end

  get   "matches",              to: "matches#index",    as: :matches
  patch "matches/:id/result",  to: "matches#result",   as: :match_result
  post  "matches/:id/simulate", to: "matches#simulate", as: :match_simulate

  get   "knockout",                        to: "knockout#index",    as: :knockout
  patch "knockout/matches/:id/result",    to: "knockout#result",   as: :knockout_result
  post  "knockout/matches/:id/simulate",  to: "knockout#simulate", as: :knockout_simulate

  get  "stats",               to: "stats#index",        as: :stats

  get  "admin",               to: "admin#index",        as: :admin
  post "admin/simulate",            to: "admin#simulate",            as: :admin_simulate
  post "admin/simulate_tournament", to: "admin#simulate_tournament", as: :admin_simulate_tournament
  post "admin/reset_groups",        to: "admin#reset_groups",        as: :admin_reset_groups
  patch "admin/teams/:id",    to: "admin#update_team",   as: :admin_team
  post "admin/advance_knockout", to: "admin#advance_knockout", as: :admin_advance_knockout
  post "admin/reset_teams",      to: "admin#reset_teams",      as: :admin_reset_teams
end
