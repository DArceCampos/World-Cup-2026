Rails.application.routes.draw do
  root "dashboard#index"

  resources :groups, only: %i[index show]

  get   "matches",             to: "matches#index",  as: :matches
  patch "matches/:id/result",  to: "matches#result", as: :match_result

  get   "knockout",                       to: "knockout#index",  as: :knockout
  patch "knockout/matches/:id/result",    to: "knockout#result", as: :knockout_result

  get  "stats",               to: "stats#index",        as: :stats

  get  "admin",               to: "admin#index",        as: :admin
  post "admin/simulate",      to: "admin#simulate",      as: :admin_simulate
  post "admin/reset_groups",  to: "admin#reset_groups",  as: :admin_reset_groups
  patch "admin/teams/:id",    to: "admin#update_team",   as: :admin_team
end
