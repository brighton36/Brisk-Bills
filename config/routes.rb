ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  map.login  'sign-in',  :controller => 'authentication', :action => 'login'
  map.logout 'sign-out', :controller => 'authentication', :action => 'logout'

  map.connect 'reset-forgotten-password/*email_address', :controller => 'authentication', :action => 'reset_password_via_token'

  map.root :controller => 'authentication', :action => 'index'

  # Default routes:
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'


end
