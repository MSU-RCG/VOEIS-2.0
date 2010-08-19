class Voeis::SitesController < Voeis::BaseController
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'sites',
            :route_instance_name => 'site',
            :collection_name => 'sites',
            :instance_name => 'site',
            :resource_class => Voeis::Site

  def create
    # This should be handled by the framework, but isn't when using jruby.
    params[:site][:latitude] = params[:site][:latitude].strip
    params[:site][:longitude] = params[:site][:longitude].strip

    create! do |success, failure|
      success.html { redirect_to project_url(parent) }
    end
  end
end