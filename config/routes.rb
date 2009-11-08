ActionController::Routing::Routes.draw do |map|
  map.resources :results

  map.connect 'projects/:project_id/scripts/:version/:script',
    :controller => 'scripts',
    :action => 'show',
    :project_id => /[^\/\.]+/,
    :version => /[^\/\.]+/,
    :script => /.+/

  map.connect 'projects/:project_id/scripts/new',
    :controller => 'scripts',
    :action => 'new',
    :project_id => /[^\/\.]+/
end
