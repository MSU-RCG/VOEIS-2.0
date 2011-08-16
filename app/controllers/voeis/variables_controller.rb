class Voeis::VariablesController < Voeis::BaseController
  
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'variables',
            :route_instance_name => 'variable',
            :collection_name => 'variables',
            :instance_name => 'variable',
            :resource_class => Voeis::Variable

  has_widgets do |root|
    root << widget(:flot_graph)
  end

  def show
    @project = parent
    #@sites = Voeis::Site.all
    @project.managed_repository{
      @variable = Voeis::Variable.get(params[:id].to_i)
      @sites = Voeis::Site.all
      if !params[:site_id].nil?
        @site =  Voeis::Site.get(params[:site_id].to_i)
        @site_variable_stats = Voeis::SiteDataCatalog.all(:variable_id=>params[:id].to_i, :site_id=>params[:site_id].to_i)
        @graph_data = @variable.last_ten_values_graph(@site)
        @data = @variable.last_ten_values(@site)
        @TEST = 'TESTING controller'
      end
    }
    logger.debug('>>>> graph_data = '+@graph_data.to_s)
    logger.debug('>>>> data = '+@data.to_s)
    #@versions = parent.managed_repository{Voeis::Site.get(params[:id]).versions}
    
  end

  # GET /variables/new
  def new

    @variables = Voeis::Variable.all
    @variable = Voeis::Variable.new
    @units = Voeis::Unit.all
    @time_units = Voeis::Unit.all(:units_type.like=>'%Time%')
    @variable_names = Voeis::VariableNameCV.all
    @sample_mediums= Voeis::SampleMediumCV.all
    @value_types= Voeis::ValueTypeCV.all
    @speciations = Voeis::SpeciationCV.all
    @data_types = Voeis::DataTypeCV.all
    @general_categories = Voeis::GeneralCategoryCV.all
    @label_array = Array["Variable Name","Variable Code","Unit Name","Speciation","Sample Medium","Value Type","Is Regular","Time Support","Time Unit ID","Data Type","General Cateogry", "Detection Limit"]

    @current_variables = Array.new     
    @variables.all(:order => [:variable_name.asc]).each do |var|
      @temp_array =Array[var.variable_name, var.variable_code,@units.get(var.variable_units_id).units_name, var.speciation,var.sample_medium, var.value_type, var.is_regular.to_s, var.time_support.to_s, var.time_units_id.to_s, var.data_type, var.general_category, var.detection_limit.to_s]
      @current_variables << @temp_array
    end         
    @project = parent
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  # POST /variables
  def create

    @variable = Voeis::Variable.new(params[:variable])
    if @variable.variable_code.nil? || @variable_code =="undefined"
      @variable.variable_code = @variable.id.to_s+@variable.variable_name+@variable.speciation+Voeis::Unit.get(@variable.variable_units_id).units_name
    end
    if params[:variable][:detection_limit].empty?
      @variable.detection_limit = nil
    end
    if params[:variable][:field_method_id].empty?
      @variable.field_method_id = nil
    end
    if params[:variable][:lab_id].empty?
      @variable.lab_id = nil
    end
    if params[:variable][:lab_method_id].empty?
      @variable.lab_method_id = nil
    end
    if params[:variable][:spatial_offset_type].empty?
      @variable.spatial_offset_type = nil
    end
    if @variable.save  
      respond_to do |format|
        flash[:notice] = 'Variable was successfully created.'
        redirect_to(new_project_variable_path(parent))
        format.json do
           render :json => @variable.as_json, :callback => params[:jsoncallback]
        end
        return
      end
    else
      respond_to do |format|
        flash[:warning] = 'There was a problem saving the Variables.'
        format.html { render :action => "new" }
        format.json do
           render :json => @variable.as_json, :callback => params[:jsoncallback]
        end
        return
      end
    end
  end
end
