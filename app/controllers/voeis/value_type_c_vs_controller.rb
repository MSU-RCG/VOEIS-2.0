class Voeis::ValueTypeCVsController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  ### GET /value_type_c_vs/new
  def new
    @value_type = Voeis::ValueTypeCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  ### LOCAL: POST /value_type_c_vs
  def create
    @project = parent
    @project.managed_repository{
      cvparams = params
      cvparams = params[:value_type_c_v] if !params[:value_type_c_v].nil?
      @value_type = Voeis::ValueTypeCV.with_deleted{Voeis::ValueTypeCV.get(cvparams[:id])}
      if @value_type.nil?
        @value_type = Voeis::ValueTypeCV.create(:id=>cvparams[:id],
                                :term=>cvparams[:term],
                                :definition=>cvparams[:definition],
                                :provenance_comment=>cvparams[:provenance_comment])
      else
        #@vertical_datum.deleted_at  #need to reference 'deleted_at' because of lazy loading
        @value_type.update(:term=>cvparams[:term],
                              :definition=>cvparams[:definition],
                              :provenance_comment=>cvparams[:provenance_comment],
                              :deleted_at=>nil)
      end
    
      respond_to do |format|
        format.html do
          flash[:notice] = 'Value Type was successfully created.'
          redirect_to(new_value_type_c_v_path())
        end
        format.json do
          render :json => @value_type.as_json, :callback => params[:jsoncallback]
        end
      end
    }
  end

  ### LOCAL: PUT /value_type_c_vs
  def update
    @project = parent
    @project.managed_repository{
      cvparams = params
      cvparams = params[:value_type_c_v] if !params[:value_type_c_v].nil?
      @value_type = Voeis::ValueTypeCV.get(cvparams[:id])
      cvparams.each do |key, value|
        @value_type[key] = value.blank? ? nil : value
      end
      @value_type.updated_at = Time.now
      
      respond_to do |format|
        if @value_type.save
          format.html do
            flash[:notice] = 'Value Type was successfully updated.'
            redirect_to(new_value_type_c_v_path()) 
          end
          format.json do
            render :json => @value_type.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html { render :action => "new" }
        end
      end
    }
  end

  ### LOCAL: DELETE /value_type_c_vs
  def destroy
    @project = parent
    @project.managed_repository{
      value_type = Voeis::ValueTypeCV.get(params[:id])
      #debugger
      if !value_type.destroy
        #FAILED!
        #format.html { render :action => "update" }
        error_notice = 'Value Type delete FAILED!'
        respond_to do |format|
          format.html {
            flash[:error] = error_notice
            redirect_to(value_type_path())
          }
          format.json {
            render :json=>{:id=>value_type.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = 'Value Type was successfully deleted.'
            redirect_to(value_type_path())
          }
          format.json {
            render :json => {:id=>value_type.id}.as_json, :callback=>params[:jsoncallback]
          }
        end
      end
    }
  end
  
  def show
  end
  
  ### LOCAL: GET /value_type_c_vs -- List ValueType entries
  def index
    @project = parent
    if User.current.nil? || 
        !@project.users.include?(User.current) ||
        (!User.current.has_role?('Principal Investigator',@project) &&
        !User.current.has_role?('Data Manager',@project))
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
      return
    end
    ### LOCAL ValueType
    @global = false
    @cv_data0 = @project.managed_repository{Voeis::ValueTypeCV.all}
    #@cv_data = @cv_data0.map{|d| d.attributes.update({:used=>!@project.sites.first(:variable_name_id=>d[:id]).nil?})}
    @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false})}
    @copy_data = Voeis::ValueTypeCV.all(:id.not=>@cv_data0.collect(&:id)) #, :order=>[:term.asc])
    @cv_title = 'Value Type'
    @cv_title2 = 'value_type'
    @cv_title2cv = 'value_type_c_v'
    @cv_id = 'id'
    @cv_name = 'term'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @copy_columns = [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"15%", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"18%", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}]
    render 'voeis/cv_index.html.haml'
  end

  ### LOCAL: ValueType HISTORY!
  def versions
    @global = false
    @project = parent
    @cv_item = @project.managed_repository{Voeis::ValueTypeCV.get(params[:id])}
    #@cv_versions = @project.managed_repository{Voeis::VerticalDatumCV.get(params[:id]).versions}
    #@cv_versions = @project.managed_repository{@cv_item.versions_array}
    @cv_versions = @project.managed_repository.adapter.select('SELECT * FROM voeis_value_type_cv_versions WHERE id=%s ORDER BY updated_at DESC'%@cv_item.id)
    @cv_title = 'Value Type'
    @cv_title2 = 'value_type'
    @cv_term = 'term'
    @cv_name = 'term'
    @cv_id = 'id'

    @cv_refs = []

    @cv_properties = [
      #{:label=>"Version", :name=>"version"},
      #{:label=>"ID", :name=>"id"},
      {:label=>"Term", :name=>"term"},
      {:label=>"Definition", :name=>"definition"}
    ]
    #render 'spatial_references/versions.html.haml'
    render 'voeis/cv_versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end