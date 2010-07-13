ActionController::Routing::Routes.draw do |map|
  map.resources :results
  map.resources :experiments
  map.resources :experiment_scripts
  map.resources :reservations

  map.connect 'projects/:project_id/scripts/:version/:script',
    :controller => 'scripts',
    :action => 'edit',
    :project_id => /[^\/\.]+/,
    :version => /[^\/\.]+/,
    :script => /.+/
end
