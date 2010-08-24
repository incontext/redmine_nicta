ActionController::Routing::Routes.draw do |map|
  map.resources :results
  map.resources :experiments, :member => { :edit_copy => :get, :copy => :post }
  map.resources :reservations, :member => { :approve => :put, :change_experiment => :get, :change_experiment_version => :get}
  #map.resources :projects do |project|
  #  project.resources :experiment_scripts
  #end

  map.connect 'projects/:project_id/scripts/:version/:script',
    :controller => 'scripts',
    :action => 'edit',
    :project_id => /[^\/\.]+/,
    :version => /[^\/\.]+/,
    :script => /.+/
end
