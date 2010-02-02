# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: routes.rb
# 
#
ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  map.resources :projects, :except => [ :edit, :update ], :member => { :upload => :post }, :collection => { :rereflect => :post, :loadexample => :post } do |project|
    
    # /projects/:project_id/yogo_data/:model_name
    # /projects/:project_id/yogo_data/:model_name/:id
    project.resources :yogo_data, :as => 'yogo_data/:model_id', :collection => { :upload => :post }
    
    # /projects/:project_id/yogo_models/:model_name
    project.resources :yogo_models
  end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "welcome"
end