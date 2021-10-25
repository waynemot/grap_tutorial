Rails.application.routes.draw do
  get 'calendar/index'
  get 'calendar/new'
  get 'home/index'
  root 'home#index'

  # Add future routes here
  # Add route for OmniAuth callback
  match '/auth/:provider/callback', :to => 'auth#callback', :via => [:get, :post]
  get 'auth/signout'
  get 'calendar', :to => 'calendar#index'

end
