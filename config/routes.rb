ActionController::Routing::Routes.draw do |map|
  map.resources :projects do |project|
    project.resources :experiments, :member => { :edit_copy => :get, :copy => :post }
    project.connect 'oedl/:id/:version', :controller => :experiments, :action => :show
    project.resources :reservations, :member => { :approve => :put, :change_experiment => :get, :change_experiment_version => :get}
    project.resources :experiment_outcomes
  end
end
