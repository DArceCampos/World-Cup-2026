Rails.application.routes.draw do
  root "dashboard#index"

  resources :groups, only: %i[index show]

  get  "matches",           to: "matches#index",  as: :matches
  patch "matches/:id/result", to: "matches#result", as: :match_result

  get "knockout", to: "knockout#index", as: :knockout
end
