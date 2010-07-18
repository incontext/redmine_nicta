ActionController::Routing::Routes.draw do |map|
  map.resources :results
  map.resources :experiments
  map.resources :reservations
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
