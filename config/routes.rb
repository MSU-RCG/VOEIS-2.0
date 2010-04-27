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
  map.resources :projects, :except => [ :edit, :update ], 
                :member => { :upload => :post, :list_models => :get }, 
                :collection => { :loadexample => :post, :search => :get} do |project|
    
    # /projects/:project_id/yogo_data/:model_name
    # /projects/:project_id/yogo_data/:model_name/:id
    project.resources :yogo_data, :as => 'yogo_data/:model_id', 
                      :collection => { :upload => :post, :search => :get, 
                                       :histogram_attribute => :get, 
                                       :pick_attribute => :get, 
                                       :remove_attribute => :get},
                      :member => { :download_asset => :get, :show_asset => :get }
                          
    # /projects/:project_id/yogo_models/:model_name
    project.resources :yogo_models,
                      :member => { :list_attributes => :get }
    
  end
  map.resources :yogo_settings
  map.resources :tutorial
  map.resources :dashboard, :only => [ :index, :show ]

  map.connect "/mockup/:action", :controller => 'mockup'
  
  # Wizard stuff
  map.start_wizard "/project_wizard/name", :controller => 'project_wizard', :action => 'name'
  map.csv_question "/project_wizard/csv_question/:id", :controller => 'project_wizard', :action => 'csv_question'
  map.import_csv   "/project_wizard/import_csv/:id", :controller => 'project_wizard', :action => 'import_csv'
  
  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.welcome "/welcome", :controller => "welcome"
  map.root :controller => "dashboard"
end