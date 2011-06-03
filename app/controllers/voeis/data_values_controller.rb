require 'responders/rql'

class Voeis::DataValuesController < Voeis::BaseController
  
  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  responders :rql
  defaults  :route_collection_name => 'data_values',
            :route_instance_name => 'data_value',
            :collection_name => 'data_values',
            :instance_name => 'data_value',
            :resource_class => Voeis::DataValue
  
  # Gather information necessary to store sample data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process
    @project = parent
    @general_categories = Voeis::GeneralCategoryCV.all
  end
  
  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process_samples_and_data
    @project = parent
    @templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sample")}
    @general_categories = Voeis::GeneralCategoryCV.all
  end

  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process_samples_file_upload
    @project = parent
    @data_templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sample")}
    @general_categories = Voeis::GeneralCategoryCV.all
  end

  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process_varying_samples_with_data
    @project = parent
    @templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sample")}
    @general_categories = Voeis::GeneralCategoryCV.all
  end

  # Gather information necessary to store sample data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_upload
     require 'csv_helper'
     @sites = parent.managed_repository{ Voeis::Site.all }
     @project = parent
     #@project = Project.first(:id => params[:project_id])
      @variables = Voeis::Variable.all
      @sites = parent.managed_repository{ Voeis::Site.all }
      @samples = parent.managed_repository{ Voeis::Sample.all }
      if !params[:datafile].nil? && datafile = params[:datafile]
        if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
              'application/octet-stream','application/csv'].include?(datafile.content_type)
          flash[:error] = "File type #{datafile.content_type} not allowed"
          redirect_to(:controller =>"voeis/data_values", :action => "pre_process", :params => {:id => params[:project_id]})

        else
          name = Time.now.to_s + params['datafile'].original_filename
          directory = "temp_data"
          @new_file = File.join(directory,name)
          File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
          
          @start_line = params[:start_line].to_i
          @start_row = get_row(@new_file, params[:start_line].to_i)
          @row_size = @start_row.size-1
          
          header_row = Array.new
          
          @var_array = Array.new
          @var_array[0] = ["","","","","","",""]
          @opts_array = Array.new
          @variables.all(:general_category => params[:general_category], :order => [:variable_name.asc]).each do |var|
            @opts_array << [var.variable_name+":"+var.sample_medium+':'+ var.data_type+':'+Voeis::Unit.get(var.variable_units_id).units_name, var.id.to_s]
          end
          if params[:start_line].to_i != 1
            header_row = get_row(@new_file, params[:start_line].to_i - 1)
          
            (0..@row_size).each do |i|
               @var_array[i] = [header_row[i],"","",opts_for_select(@opts_array),"","",""]
              end
          else
            (0..@row_size).each do |i|
              @var_array[i] = ["","","",opts_for_select(@opts_array),"","",""]
             end
          end
          
          #parse csv file into array
          @csv_array = Array.new
          csv_data = CSV.read(@new_file)
          i = @start_line
          csv_data[@start_line-1..-1].each do |row|
            @csv_array[i] = row.map! { |k| "#{k}" }.join(",")
            i = i + 1
          end
          @csv_size = i -1

      end
     end
  end
  
  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_upload_samples_and_data
    require 'csv_helper'
     
    @project = parent
    @variables = Variable.all
    @sites = parent.managed_repository{ Voeis::Site.all }
    @samples = parent.managed_repository{ Voeis::Sample.all }
    @sample_types = Voeis::SampleTypeCV.all
    @sample_materials = Voeis::SampleMaterial.all
    @project_sample_materials = @project.managed_repository{Voeis::SampleMaterial.all}
    @lab_methods = @project.managed_repository{Voeis::LabMethod.all}
     
    #save uploaded file if possible
    if !params[:datafile].nil? && datafile = params[:datafile]
      if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
            'application/octet-stream','application/csv'].include?(datafile.content_type)
        flash[:error] = "File type #{datafile.content_type} not allowed"
        redirect_to(:controller =>"voeis/data_values", :action => "pre_process", :params => {:id => params[:project_id]})

      else
        #file can be saved
        name = Time.now.to_s + params['datafile'].original_filename
        directory = "temp_data"
        @new_file = File.join(directory,name)
        File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
        
        @start_line = params[:start_line].to_i
        #get the first row that has information in the CSV file
        @start_row = get_row(@new_file, params[:start_line].to_i)
        @row_size = @start_row.size-1
        
        @header_row = Array.new
        
        @var_array = Array.new
        @var_array[0] = ["","","","","","",""]
        @opts_array = Array.new
        @variables.all(:general_category => params[:general_category], :order => [:variable_name.asc]).each do |var|
          @opts_array << [var.variable_name+":"+var.sample_medium+':'+ var.data_type+':'+Unit.get(var.variable_units_id).units_name, var.id.to_s]
        end
        if params[:start_line].to_i != 1
          @header_row = get_row(@new_file, params[:start_line].to_i - 1)
        end
        @timestamp_column = ""
        @sample_column = ""
        @template_name = ""
        if params[:template] != "None"
            data_template = parent.managed_repository {Voeis::DataStream.first(:id => params[:template])}
            (0..@row_size).each do |i|
               puts i
               if !data_template.data_stream_columns.first(:column_number => i).nil?
                 data_col = data_template.data_stream_columns.first(:column_number => i)
                 if data_col.name != "Timestamp" && data_col.name != "SampleID"
                   if data_col.variables.empty?
                     @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"", "", "",data_col.name]
                   else
                     @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array,Variable.first(:variable_code => data_col.variables.first.variable_code).id.to_s),"", "", "",data_col.name]
                   end
                  else
                    @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"","","",""]
                  end
                else
                  @var_array[i] = ["","","",opts_for_select(@opts_array),"","","",""]
                end
            end
            if !data_template.data_stream_columns.first(:name => "Timestamp").nil?
              @timestamp_column = data_template.data_stream_columns.first(:name => "Timestamp").column_number
            end
            @sample_column = data_template.data_stream_columns.first(:name => "SampleID").column_number
            @template_name = data_template.name
        else
          (0..@row_size).each do |i|
            @var_array[i] = ["","","",opts_for_select(@opts_array),"","",""]
           end
        end
 
        #parse csv file into array
        @csv_array = Array.new
        csv_data = CSV.read(@new_file)
        i = @start_line
        csv_data[@start_line-1..-1].each do |row|
          @csv_array[i] = row.map! { |k| "#{k}" }.join(",")
          i = i + 1
        end
        @csv_size = i -1

    end
   end
  end
  
  
  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_upload_varying_samples_with_data
    require 'csv_helper'
     
    @project = parent
    @variables = Voeis::Variable.all
    @sites = parent.managed_repository{ Voeis::Site.all }
    @samples = parent.managed_repository{ Voeis::Sample.all }
    @sample_types = Voeis::SampleTypeCV.all
    @sample_materials = Voeis::SampleMaterial.all
    @project_sample_materials = @project.managed_repository{Voeis::SampleMaterial.all}
    @lab_methods = @project.managed_repository{Voeis::LabMethod.all}
     
    #save uploaded file if possible
    if !params[:datafile].nil? && datafile = params[:datafile]
      if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
            'application/octet-stream','application/csv'].include?(datafile.content_type)
        flash[:error] = "File type #{datafile.content_type} not allowed"
        redirect_to(:controller =>"voeis/data_values", :action => "pre_process", :params => {:id => params[:project_id]})

      else
        #file can be saved
        name = Time.now.to_s + params['datafile'].original_filename
        directory = "temp_data"
        @new_file = File.join(directory,name)
        File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
        
        @start_line = params[:start_line].to_i
        #get the first row that has information in the CSV file
        @start_row = get_row(@new_file, params[:start_line].to_i)
        @row_size = @start_row.size-1
        
        @header_row = Array.new
        
        @var_array = Array.new
        @var_array[0] = ["","","","","","",""]
        @opts_array = Array.new
        @variables.all(:general_category => params[:general_category], :order => [:variable_name.asc]).each do |var|
          @opts_array << [var.variable_name+":"+var.sample_medium+':'+ var.data_type+':'+Unit.get(var.variable_units_id).units_name, var.id.to_s]
        end
        if params[:start_line].to_i != 1
          @header_row = get_row(@new_file, params[:start_line].to_i - 1)
        end
        @timestamp_column = ""
        @sample_column = ""
        @template_name = ""
        if params[:template] != "None"
            data_template = parent.managed_repository {Voeis::DataStream.first(:id => params[:template])}
            (0..@row_size).each do |i|
               puts i
               if !data_template.data_stream_columns.first(:column_number => i).nil?
                 data_col = data_template.data_stream_columns.first(:column_number => i)
                 if data_col.name != "Timestamp" && data_col.name != "SampleID"
                   if data_col.variables.empty?
                     @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"", "", "",data_col.name]
                   else
                     @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array,Variable.first(:variable_code => data_col.variables.first.variable_code).id.to_s),"", "", "",data_col.name]
                   end
                  else
                    @var_array[i] = [data_col.original_var, data_col.unit, data_col.type,opts_for_select(@opts_array),"","","",""]
                  end
                else
                  @var_array[i] = ["","","",opts_for_select(@opts_array),"","","",""]
                end
            end
            if !data_template.data_stream_columns.first(:name => "Timestamp").nil?
              @timestamp_column = data_template.data_stream_columns.first(:name => "Timestamp").column_number
            end
            @sample_column = data_template.data_stream_columns.first(:name => "SampleID").column_number
            @template_name = data_template.name
        else
          (0..@row_size).each do |i|
            @var_array[i] = ["","","",opts_for_select(@opts_array),"","",""]
           end
        end
 
        #parse csv file into array
        @csv_array = Array.new
        csv_data = CSV.read(@new_file)
        i = @start_line
        csv_data[@start_line-1..-1].each do |row|
          @csv_array[i] = row.map! { |k| "#{k}" }.join(",")
          i = i + 1
        end
        @csv_size = i -1

    end
   end
  end
  
  
  def opts_for_select(opt_array, selected = nil)
     option_string =""
     if !opt_array.empty?
       opt_array.each do |opt|
         if opt[1] == selected
           option_string = option_string + '<option selected="selected" value='+opt[1]+'>'+opt[0]+'</option>'
         else
           option_string = option_string + '<option value='+opt[1]+'>'+opt[0]+'</option>'
         end
       end
     end
     option_string
  end
  
  # Parses a csv file containing sample data values
   #
   # @example parse_logger_csv_header("filename")
   #
   # @param [String] csv_file
   # @param [Object] data_stream_template
   # @param [Object] site
   #
   # @return
   #
   # @author Yogo Team
   #
   # @api public
   def parse_sample_data_csv(csv_file, data_stream_template, site)
     csv_data = CSV.read(csv_file)
     path = File.dirname(csv_file)
     sensor_type_array = Array.new
     data_stream_col = Array.new
     data_stream_template.data_stream_columns.each do |col|
       sensor_type_array[col.column_number] = parent.managed_repository{Voeis::SensorType.first(:name => col.original_var + site.name)}
       data_stream_col[col.column_number] = col
     end
     data_timestamp_col = data_stream_template.data_stream_columns.first(:name => "Timestamp").column_number
     csv_data[data_stream_template.start_line..-1].each do |row|
       (0..row.size-1).each do |i|
         if i != data_timestamp_col
           puts data_stream_col
           if data_stream_col[i].name != "ignore"
             #save to sensor_value and sensor_type
             parent.managed_repository{
             sensor_value = Voeis::SensorValue.new(
                                           :value => row[i],
                                           :units => data_stream_col[i].unit,
                                           :timestamp => row[data_timestamp_col],
                                           :published => false)
             sensor_value.save
             sensor_value.sensor_type << sensor_type_array[i]
             sensor_value.site << site
             sensor_value.save}
          end
         end
       end
     end
   end
   
   
   
   # Parses a csv file containing samples and data values
    #
    # @example parse_logger_csv_header?datafile='myfilename'&start_line=3&replicate=2&column1=23&column2=24
    #
    # @param [File] datafile the csv file containing the data
    # @param [Integer] replicate a row that defines a replicate identifier
    # @param [Integer] start_line the row of the csv file that the data begins
    # @param [Integer] column/d stores the project variable id to associate with the csv column
    #
    # @return
    #
    # @author Sean Cleveland
    #
    # @api public
    def store_varying_samples_with_data

      data_stream =""
      site = parent.managed_repository{Voeis::Site.first(:id => params[:site])}
      redirect_path =Hash.new
      if params[:no_save] != "no"
        #create a parsing template
        #create and save new DataStream
        parent.managed_repository do
          data_stream = Voeis::DataStream.create(:name => params[:template_name],
            :description => "NA",
            :filename => params[:datafile],
            :start_line => params[:start_line].to_i,
            :type => "Sample")
          #Add site association to data_stream
          #
          data_stream.sites << site
          data_stream.save
        end
        @timestamp_col = -1
        range = params[:row_size].to_i
        (0..range).each do |i|
          #create the Timestamp column
          if i == params[:timestamp_col].to_i && params[:timestamp_col] != "None"
            #puts params["column"+i.to_s]
            @timestamp_col = params[:timestamp_col].to_i
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name => "Timestamp",
                                    :type =>"Timestamp",
                                    :unit => "NA",
                                    :original_var => params["variable"+i.to_s])
              data_stream_column.data_streams << data_stream
              data_stream_column.save
            end
          elsif i == params[:sample_id].to_i
            @sample_col = params[:sample_id].to_i
             parent.managed_repository do
               data_stream_column = Voeis::DataStreamColumn.create(
                                     :column_number => i,
                                     :name => "SampleID",
                                     :type =>"SampleID",
                                     :unit => "NA",
                                     :original_var => params["variable"+i.to_s])
               data_stream_column.data_streams << data_stream
               data_stream_column.save
             end
          else #create other data_stream_columns and create sensor_types
            #puts params["column"+i.to_s]
            var = Voeis::Variable.get(params["column"+i.to_s])
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name =>         params["variable"+i.to_s].empty? ? "unknown" : params["variable"+i.to_s],
                                    :original_var => params["variable"+i.to_s].empty? ? "unknown" : params["variable"+i.to_s],
                                    :unit =>         "NA",
                                    :type =>         "NA")
              if !params["ignore"+i.to_s]            
                variable = Voeis::Variable.first_or_create(
                            :variable_code => var.variable_code,
                            :variable_name => var.variable_name,
                            :speciation =>  var.speciation,
                            :variable_units_id => var.variable_units_id,
                            :sample_medium =>  var.sample_medium,
                            :value_type => var.value_type,
                            :is_regular => var.is_regular,
                            :time_support => var.time_support,
                            :time_units_id => var.time_units_id,
                            :data_type => var.data_type,
                            :general_category => var.general_category,
                            :no_data_value => var.no_data_value)
                data_stream_column.variables << variable
                data_stream_column.data_streams << data_stream
                data_stream_column.save
              else
                data_stream_column.name = "ignore"
                data_stream_column.data_streams << data_stream
                data_stream_column.save
              end #end if
            end #end managed repository
          end #end if
        end #end range.each
        @sample_col = params[:sample_id].to_i
      else #use the existing template
        data_stream = parent.managed_repository{Voeis::DataStream.first(:name => params[:template_name])}
        if !data_stream.data_stream_columns.first(:name => "Timestamp").nil?
          @timestamp_col = data_stream.data_stream_columns.first(:name => "Timestamp").column_number
        else
          @timestamp_col = -1
        end
        @sample_col = data_stream.data_stream_columns.first(:name => "SampleID").column_number
      end #end if 'no_save'
      range = params[:row_size].to_i
      #store all the Variables in the managed repository
      @col_vars = Array.new
      (0..range).each do |i|
         @var = Variable.get(params["column"+i.to_s])
         parent.managed_repository do
           if !params["ignore"+i.to_s]            
             variable = Voeis::Variable.first_or_create(
                         :variable_code => @var.variable_code,
                         :variable_name => @var.variable_name,
                         :speciation =>  @var.speciation,
                         :variable_units_id => @var.variable_units_id,
                         :sample_medium =>  @var.sample_medium,
                         :value_type => @var.value_type,
                         :is_regular => @var.is_regular,
                         :time_support => @var.time_support,
                         :time_units_id => @var.time_units_id,
                         :data_type => @var.data_type,
                         :general_category => @var.general_category,
                         :no_data_value => @var.no_data_value)
             @col_vars[i] = variable
           end #end if
         end#managed repo
      end  #end i loop

      #create csv_row array
      @csv_row = Array.new
      csv_data = CSV.read(params[:datafile])
      i = params[:start_line].to_i-1
      d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
      csv_data[params[:start_line].to_i-1..-1].each do |row|
        @csv_row[i] = row
            i = i + 1
            @row_num = i
          end#end row loop
          (params[:start_line].to_i-1..params[:csv_size].to_i).each do |row|
            if !@csv_row[row].nil?
            parent.managed_repository do
              #create sample
              puts @csv_row[row][@sample_col]
              @sample = Voeis::Sample.new(:sample_type =>   params["sample_type"+@row_num.to_s],
                                          :material => params["material"+@row_num.to_s],
                                          :lab_sample_code => @csv_row[row][@sample_col],
                                          :lab_method_id => params["lab_method_id"+@row_num.to_s].to_i,
                                          :local_date_time => @timestamp_col == -1 ? d_time : @csv_row[row][@timestamp_col].to_time)
              @sample.valid?
              puts @sample.errors.inspect()
              @sample.save
              @sample.sites << site
              @sample.save
              (0..range).each do |i|
                if @sample_col != i && @timestamp_col != i && @csv_row[row][i] != ""&& !params["ignore"+i.to_s]
                    new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
                       :local_date_time => @sample.local_date_time,
                       :utc_offset => @sample.local_date_time.to_time.utc_offset/(60*60),  
                       :date_time_utc => @sample.local_date_time.to_time.utc.to_datetime,  
                       :replicate => 0,
                       :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i]) 
                  new_data_val.valid?
                  puts new_data_val.errors.inspect() 
                  new_data_val.save
                  new_data_val.variable << @col_vars[i]
                  new_data_val.save
                  new_data_val.sample << @sample
                  new_data_val.save
                  @sample.variables << @col_vars[i]
                  @sample.save
                  samp_site = @sample.sites.first
                  samp_site.variables << @col_vars[i]
                  samp_site.save
                  # @sample.sites.each do |samp_site|
                  #                    samp_site.variables << @col_vars[i]
                  #                    samp_site.save
                  #                  end
                 end #end if
                end #end i loop
               end #end if @csv_array.nil?
            end #end managed repo
          end #end row loop
          parent.publish_his
          flash[:notice] = "File parsed and stored successfully."
          redirect_to project_path(params[:project_id])
    end# end def
   
   # Parses a csv file containing samples and data values
   #
   # @example parse_logger_csv_header?datafile='myfilename'&start_line=3&replicate=2&column1=23&column2=24
   #
   # @param [File] datafile the csv file containing the data
   # @param [Integer] replicate a row that defines a replicate identifier
   # @param [Integer] start_line the row of the csv file that the data begins
   # @param [Integer] column/d stores the project variable id to associate with the csv column
   #
   # @return
   #
   # @author Sean Cleveland
   #
   # @api public
   def store_samples_and_data
     
     data_stream =""
     site = parent.managed_repository{Voeis::Site.first(:id => params[:site])}
     redirect_path =Hash.new
     if params[:no_save] != "no"
       #create a parsing template
       #create and save new DataStream
       parent.managed_repository do
         data_stream = Voeis::DataStream.create(:name => params[:template_name],
           :description => "NA",
           :filename => params[:datafile],
           :start_line => params[:start_line].to_i,
           :type => "Sample")
         #Add site association to data_stream
         #
         data_stream.sites << site
         data_stream.save
       end
       @timestamp_col = -1
       range = params[:row_size].to_i
       (0..range).each do |i|
         #create the Timestamp column
         if i == params[:timestamp_col].to_i && params[:timestamp_col] != "None"
           #puts params["column"+i.to_s]
           @timestamp_col = params[:timestamp_col].to_i
           parent.managed_repository do
             data_stream_column = Voeis::DataStreamColumn.create(
                                   :column_number => i,
                                   :name => "Timestamp",
                                   :type =>"Timestamp",
                                   :unit => "NA",
                                   :original_var => params["variable"+i.to_s])
             data_stream_column.data_streams << data_stream
             data_stream_column.save
           end
         elsif i == params[:sample_id].to_i
           @sample_col = params[:sample_id].to_i
            parent.managed_repository do
              data_stream_column = Voeis::DataStreamColumn.create(
                                    :column_number => i,
                                    :name => "SampleID",
                                    :type =>"SampleID",
                                    :unit => "NA",
                                    :original_var => params["variable"+i.to_s])
              data_stream_column.data_streams << data_stream
              data_stream_column.save
            end
         else #create other data_stream_columns and create sensor_types
           #puts params["column"+i.to_s]
           var = Voeis::Variable.get(params["column"+i.to_s])
           parent.managed_repository do
             data_stream_column = Voeis::DataStreamColumn.create(
                                   :column_number => i,
                                   :name =>         params["variable"+i.to_s].empty? ? "unknown" : params["variable"+i.to_s],
                                   :original_var => params["variable"+i.to_s].empty? ? "unknown" : params["variable"+i.to_s],
                                   :unit =>         "NA",
                                   :type =>         "NA")
             if !params["ignore"+i.to_s]            
               variable = Voeis::Variable.first_or_create(
                           :variable_code => var.variable_code,
                           :variable_name => var.variable_name,
                           :speciation =>  var.speciation,
                           :variable_units_id => var.variable_units_id,
                           :sample_medium =>  var.sample_medium,
                           :value_type => var.value_type,
                           :is_regular => var.is_regular,
                           :time_support => var.time_support,
                           :time_units_id => var.time_units_id,
                           :data_type => var.data_type,
                           :general_category => var.general_category,
                           :no_data_value => var.no_data_value)
               data_stream_column.variables << variable
               data_stream_column.data_streams << data_stream
               data_stream_column.save
             else
               data_stream_column.name = "ignore"
               data_stream_column.data_streams << data_stream
               data_stream_column.save
             end #end if
           end #end managed repository
         end #end if
       end #end range.each
       @sample_col = params[:sample_id].to_i
     else #use the existing template
       data_stream = parent.managed_repository{Voeis::DataStream.first(:name => params[:template_name])}
       if !data_stream.data_stream_columns.first(:name => "Timestamp").nil?
         @timestamp_col = data_stream.data_stream_columns.first(:name => "Timestamp").column_number
       else
         @timestamp_col = -1
       end
       @sample_col = data_stream.data_stream_columns.first(:name => "SampleID").column_number
     end #end if 'no_save'
     range = params[:row_size].to_i
     #store all the Variables in the managed repository
     @col_vars = Array.new
     (0..range).each do |i|
        @var = Voeis::Variable.get(params["column"+i.to_s])
        parent.managed_repository do
          if !params["ignore"+i.to_s]            
            variable = Voeis::Variable.first_or_create(
                        :variable_code => @var.variable_code,
                        :variable_name => @var.variable_name,
                        :speciation =>  @var.speciation,
                        :variable_units_id => @var.variable_units_id,
                        :sample_medium =>  @var.sample_medium,
                        :value_type => @var.value_type,
                        :is_regular => @var.is_regular,
                        :time_support => @var.time_support,
                        :time_units_id => @var.time_units_id,
                        :data_type => @var.data_type,
                        :general_category => @var.general_category,
                        :no_data_value => @var.no_data_value)
            @col_vars[i] = variable
          end #end if
        end#managed repo
     end  #end i loop
 
     #create csv_row array
     @csv_row = Array.new
     csv_data = CSV.read(params[:datafile])
     i = params[:start_line].to_i-1
     
     
     d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
     csv_data[params[:start_line].to_i-1..-1].each do |row|
       @csv_row[i] = row
           i = i + 1
         end#end row loop
         (params[:start_line].to_i-1..params[:csv_size].to_i).each do |row|
           if !@csv_row[row].nil?
           parent.managed_repository do
             #create sample
             puts @csv_row[row][@sample_col]
             @sample = Voeis::Sample.new(:sample_type =>   params[:sample_type],
                                         :material => params[:material],
                                         :lab_sample_code => @csv_row[row][@sample_col],
                                         :lab_method_id => params[:lab_method_id].to_i,
                                         :local_date_time => @timestamp_col == -1 ? d_time : @csv_row[row][@timestamp_col].to_time)
             @sample.valid?
             puts @sample.errors.inspect()
             @sample.save
             @sample.sites << site
             @sample.save
             (0..range).each do |i|
               if @sample_col != i && @timestamp_col != i && @csv_row[row][i] != ""&& !params["ignore"+i.to_s]
                   new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
                      :local_date_time => @sample.local_date_time,
                      :utc_offset => @sample.local_date_time.to_time.utc_offset/(60*60),  
                      :date_time_utc => @sample.local_date_time.to_time.utc.to_datetime,  
                      :replicate => 0,
                      :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i]) 
                 new_data_val.valid?
                 puts new_data_val.errors.inspect() 
                 new_data_val.save
                 new_data_val.variable << @col_vars[i]
                 new_data_val.save
                 new_data_val.sample << @sample
                 new_data_val.save
                 @sample.variables << @col_vars[i]
                 @sample.save
                 samp_site = @sample.sites.first
                 samp_site.variables << @col_vars[i]
                 samp_site.save
                 # @sample.sites.each do |samp_site|
                 #                    samp_site.variables << @col_vars[i]
                 #                    samp_site.save
                 #                  end
                end #end if
               end #end i loop
              end #end if @csv_array.nil?
           end #end managed repo
         end #end row loop
         parent.publish_his
         flash[:notice] = "File parsed and stored successfully."
         redirect_to project_path(params[:project_id])
   end# end def
   
   # Parses a csv file containing sample data values
   #
   # @example parse_logger_csv_header?datafile='myfilename'&start_line=3&replicate=2&column1=23&column2=24
   #
   # @param [File] datafile the csv file containing the data
   # @param [Integer] replicate a row that defines a replicate identifier
   # @param [Integer] start_line the row of the csv file that the data begins
   # @param [Integer] column/d stores the project variable id to associate with the csv column
   #
   # @return
   #
   # @author Sean Cleveland
   #
   # @api public
   def store_sample_data

     range = params[:row_size].to_i
     #store all the Variables in the managed repository
     @col_vars = Array.new
     (0..range).each do |i|
        @var = Voeis::Variable.get(params["column"+i.to_s])
        parent.managed_repository do
          if !params["ignore"+i.to_s]            
            variable = Voeis::Variable.first_or_create(
                        :variable_code => @var.variable_code,
                        :variable_name => @var.variable_name,
                        :speciation =>  @var.speciation,
                        :variable_units_id => @var.variable_units_id,
                        :sample_medium =>  @var.sample_medium,
                        :value_type => @var.value_type,
                        :is_regular => @var.is_regular,
                        :time_support => @var.time_support,
                        :time_units_id => @var.time_units_id,
                        :data_type => @var.data_type,
                        :general_category => @var.general_category,
                        :no_data_value => @var.no_data_value)
            @col_vars[i] = variable
          end #end if
        end#managed repo
     end  #end i loop
 
     #create csv_row array
     @csv_row = Array.new
     csv_data = CSV.read(params[:datafile])
     i = params[:start_line].to_i-1

     csv_data[params[:start_line].to_i-1..-1].each do |row|
       @csv_row[i] = row
       i = i + 1
     end#end row loop
     (params[:start_line].to_i-1..params[:csv_size].to_i).each do |row|
       if !@csv_row[row].nil?
       parent.managed_repository do
         @sample = Voeis::Sample.get(params["csv_sample-"+(row+1).to_s])
         (0..range).each do |i|
           if params[:replicate].to_i != i && params[:timestamp_col].to_i != i && @csv_row[row][i] != ""&& !params["ignore"+i.to_s]
             #store data value for this column(i) and row
             #sort out replicate
             if params[:replicate] == "None"
               rep = "0"
             else
               rep = @csv_row[row][params[:replicate].to_i]
             end
             #need to store either the timestamp col or the applied timestamp
             #if params[:timestamp_col] == "None"
               #store the applied timestamp
               #d_time = DateTime.parse("#{params[:time]["stamp(1i)"]}-#{params[:time]["stamp(2i)"]}-#{params[:time]["stamp(3i)"]}T#{params[:time]["stamp(4i)"]}:#{params[:time]["stamp(5i)"]}:00#{ActiveSupport::TimeZone[params[:time][:zone]].utc_offset/(60*60)}:00")
               
               new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
                  :local_date_time => @sample.local_date_time,
                  :utc_offset => @sample.local_date_time.to_time.utc_offset/(60*60),  
                  :date_time_utc => @sample.local_date_time.to_time.utc.to_datetime,  
                  :replicate => rep,
                  :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i]) 
               new_data_val.valid?
               puts new_data_val.errors.inspect() 
               new_data_val.save

             new_data_val.variable << @col_vars[i]
             new_data_val.save
             new_data_val.sample << @sample
             new_data_val.save
             @sample.variables << @col_vars[i]
             @sample.save
             @sample.sites.each do |site|
               site.variables << @col_vars[i]
               site.save
             end
            end #end if
           end #end i loop
          end #end if @csv_array.nil?
       end #end managed repo
     end #end row loop
     #parent.publish_his
     flash[:notice] = "File parsed and stored successfully."
     redirect_to project_path(params[:project_id])
   end# end def

  def pre_process_samples
    @columns = [1,2,3,4,5,6]
  end
  

  # Gather information necessary to store samples and data
  #
  #
  #
  # @author Sean Cleveland
  #
  # @api public
  def pre_process_sample_file_upload
    @project = parent
    @templates = parent.managed_repository{Voeis::DataStream.all(:type => "Sample")}
  end
  
  
  # def pre_process_sample_file
  # 
  #   require 'csv_helper'
  #    
  #   @project = parent
  #    
  #   #save uploaded file if possible
  #   if !params[:datafile].nil? && datafile = params[:datafile]
  #     if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
  #           'application/octet-stream','application/csv'].include?(datafile.content_type)
  #       flash[:error] = "File type #{datafile.content_type} not allowed"
  #       redirect_to(:controller =>"voeis/data_values", :action => "pre_process_samples_file_upload", :params => {:id => params[:project_id]})
  # 
  #     else
  #       #file can be saved
  #       name = Time.now.to_s + params['datafile'].original_filename
  #       directory = "temp_data"
  #       @new_file = File.join(directory,name)
  #       File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
  #       
  #       @start_line = params[:start_line].to_i
  #       #get the first row that has information in the CSV file
  #       @start_row = get_row(@new_file, params[:start_line].to_i)
  #       @row_size = @start_row.size-1
  #       
  #       @header_rows = @start_line < 2 ? -1 : @start_line -2
  #   
  #       
  #       @columns = Array.new
  #       (1..@start_row.size).map{|x| @columns << x}
  #       @vars = Hash.new
  # 
  #       Voeis::Variable.all.each do |v| 
  # 
  #         @vars=@vars.merge({v.variable_name => v.id})
  #       end
  #       @sites = {"None"=>"None"}
  #       parent.managed_repository{Voeis::Site.all}.each do |s|
  #         @sites = @sites.merge({s.name => s.id})
  #       end
  # 
  #       @variables = Voeis::Variable.all
  #       @var_properties = Array.new
  #       Voeis::Variable.properties.each do |prop|
  #         @var_properties << prop.name
  #       end
  #       @var_properties.delete_if {|x| x.to_s == "id" || x.to_s == "his_id" || x.to_s == "time_units_id" || x.to_s == "is_regular" || x.to_s == "time_support" || x.to_s == "variable_code" || x.to_s == "created_at" || x.to_s == "updated_at"}
  #   
  #       debugger
  #       @variable = Voeis::Variable.new
  #       @units = Voeis::Unit.all
  #       @variable_names = Voeis::VariableNameCV.all
  #       @sample_mediums= Voeis::SampleMediumCV.all
  #       @sample_types = Voeis::SampleTypeCV.all
  #       @value_types= Voeis::ValueTypeCV.all
  #       @speciations = Voeis::SpeciationCV.all
  #       @data_types = Voeis::DataTypeCV.all
  #       @general_categories = Voeis::GeneralCategoryCV.all
  # 
  #       @label_array = Array["Variable Name","Variable Code","Unit Name","Speciation","Sample Medium","Value Type","Is Regular","Time Support","Time Unit ID","Data Type","General Cateogry"]
  #       @current_variables = Array.new     
  #       @variables.all(:order => [:variable_name.asc]).each do |var|
  #         @temp_array =Array[var.variable_name, var.variable_code,@units.get(var.variable_units_id).units_name, var.speciation,var.sample_medium, var.value_type, var.is_regular.to_s, var.time_support.to_s, var.time_units_id.to_s, var.data_type, var.general_category]
  #         @current_variables << @temp_array
  #       end
  #       
  #       @sample_type_options = Array.new
  #       @sample_types.all(:order => [:term.asc]).each do |samp_type|
  #         @sample_type_options <<[samp_type.term]  
  #       end
  # 
  #       @sample_medium_options = Array.new
  #       @sample_mediums.all(:order => [:term.asc]).each do |mat|
  #         @sample_medium_options << [mat.term]
  #       end
  #       #parse csv file into array
  #       @csv_array = Array.new
  #       csv_data = CSV.read(@new_file)
  #       i = 0
  #       csv_data[0..-1].each do |row|
  #         temp_array = Array.new
  #         row.map! { |k| temp_array << k }
  #         @csv_array[i] = temp_array
  #         i = i + 1
  #       end
  #       @csv_size = i -1
  #     end       
  # 
  #   else
  #       redirect_to(:controller =>"voeis/data_values", :action => "pre_process_sample_file_upload", :params => {:id => params[:project_id]})
  #     end
  #   
  # end
  
  def pre_process_samples_file
    
       require 'csv_helper'
       @data_template = parent.managed_repository{Voeis::DataStream.get(params[:data_template_id].to_i)}  
       @project = parent
       @current_user = current_user
       #save uploaded file if possible
       if !params[:datafile].nil? && datafile = params[:datafile]
         if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
               'application/octet-stream','application/csv'].include?(datafile.content_type)
           flash[:error] = "File type #{datafile.content_type} not allowed"
           redirect_to(:controller =>"voeis/data_values", :action => "pre_process_samples_file_upload", :params => {:id => params[:project_id]})
    
         else
           #file can be saved
           name = Time.now.to_s + params['datafile'].original_filename
           directory = "temp_data"
           @new_file = File.join(directory,name)
           File.open(@new_file, "wb"){ |f| f.write(params['datafile'].read)}
           
           @start_line = params[:start_line].to_i
           #get the first row that has information in the CSV file
           @start_row = get_row(@new_file, params[:start_line].to_i)
           @row_size = @start_row.size-1
           
           @header_rows = @start_line < 2 ? -1 : @start_line -2
       
           
           @columns = Array.new
           (1..@start_row.size).map{|x| @columns << x}
           @vars = Hash.new
    
           Voeis::Variable.all.each do |v| 
    
             @vars=@vars.merge({v.variable_name => v.id})
           end
           
           
           
           @site_offset = Hash.new
           @sites = {"None"=>"None"}
           parent.managed_repository{Voeis::Site.all}.each do |s|
             @sites = @sites.merge({s.name => s.id})
             @site_offset = @site_offset.merge({s.id => s.time_zone_offset})
             if s.time_zone_offset.to_s == "unknown"
               begin
                 s.fetch_time_zone_offset
               rescue
                 #do nothing
               end
             end
           end
           @utc_offset_options=Hash.new
           (-12..12).map{|k| @utc_offset_options = @utc_offset_options.merge({k => k})}           
           @sources = {"None"=>"None", "Example:SampleName"=>-1}
            Voeis::Source.all.each do |s|
              @sources = @sources.merge({s.organization + ':' + s.contact_name => s.id})
            end
           
           @variables = Voeis::Variable.all
           @var_properties = Array.new
           Voeis::Variable.properties.each do |prop|
    
             @var_properties << prop.name
           end
           @var_properties.delete_if {|x| x.to_s == "id" || x.to_s == "his_id" || x.to_s == "time_units_id" || x.to_s == "is_regular" || x.to_s == "time_support" || x.to_s == "variable_code" || x.to_s == "created_at" || x.to_s == "updated_at" || x.to_s == "updated_by" || x.to_s == "updated_comment"}
       
    
           @variable = Voeis::Variable.new
           @lab_methods = Voeis::LabMethod.all
           @field_methods = Voeis::FieldMethod.all
           @units = Voeis::Unit.all
           @offset_units = @units
           @spatial_offset_types = Voeis::SpatialOffsetType.all
           @time_units = Voeis::Unit.all(:units_type.like=>'%Time%')
           @variable_names = Voeis::VariableNameCV.all
           @quality_control_levels = Voeis::QualityControlLevel.all
           @sample_mediums= Voeis::SampleMediumCV.all
           @sample_types = Voeis::SampleTypeCV.all
           @value_types= Voeis::ValueTypeCV.all
           @speciations = Voeis::SpeciationCV.all
           @data_types = Voeis::DataTypeCV.all
           @general_categories = Voeis::GeneralCategoryCV.all
    
           @label_array = Array["Variable Name","Variable Code","Unit Name","Speciation","Sample Medium","Value Type","Is Regular","Time Support","Time Unit ID","Data Type","General Cateogry"]
           @current_variables = Array.new     
           @variables.all(:order => [:variable_name.asc]).each do |var|
             @temp_array =Array[var.variable_name, var.variable_code,@units.get(var.variable_units_id).units_name, var.speciation,var.sample_medium, var.value_type, var.is_regular.to_s, var.time_support.to_s, var.time_units_id.to_s, var.data_type, var.general_category]
             @current_variables << @temp_array
           end
           
           @sample_type_options = Array.new
           @sample_types.all(:order => [:term.asc]).each do |samp_type|
             @sample_type_options <<[samp_type.term]  
           end
    
           @sample_medium_options = Array.new
           @sample_mediums.all(:order => [:term.asc]).each do |mat|
             @sample_medium_options << [mat.term]
           end
           #parse csv file into array
           @csv_array = Array.new
           csv_data = CSV.read(@new_file)
           i = 0
           csv_data[0..-1].each do |row|
             temp_array = Array.new
             row.map! { |k| temp_array << k }
             @csv_array[i] = temp_array
             i = i + 1
           end
           @csv_size = i -1
         end       
    
       else
           redirect_to(:controller =>"voeis/data_values", :action => "pre_process_sample_file_upload", :params => {:id => params[:project_id]})
         end
       
     end
 
  # Parses a csv file containing samples and data values
   #
   # @example parse_logger_csv_header?datafile='myfilename'&start_line=3&replicate=2&column1=23&column2=24
   #
   # @param [File] datafile the csv file containing the data
   # @param [Integer] replicate a row that defines a replicate identifier
   # @param [Integer] start_line the row of the csv file that the data begins
   # @param [Integer] column/d stores the project variable id to associate with the csv column
   #
   # @return
   #
   # @author Sean Cleveland
   #
   # @api public
   def store_samples_and_data_from_file
     require 'chronic'
     data_stream =""
     timestamp_col =""
     sample_id_col = ""
     vertical_offset_col = ""
     
     site = parent.managed_repository{Voeis::Site.first(:id => params[:site])}
     redirect_path =Hash.new
     @source = Voeis::Source.get(params[:source])
     @project_source = nil
     parent.managed_repository do
       if Voeis::Source.first(:organization => @source.organization,      
                              :source_description => @source.source_description,
                              :source_link => @source.source_link,       
                              :contact_name => @source.contact_name,      
                              :phone => @source.phone,             
                              :email =>@source.email,             
                              :address => @source.address,           
                              :city => @source.city,              
                              :state => @source.state,             
                              :zip_code => @source.zip_code,          
                              :citation => @source.citation,          
                              :metadata_id =>@source.metadata_id).nil?       
          Voeis::Source.create(@source.attributes)
        else
          @project_source = Voeis::Source.first(:organization => @source.organization,      
                                  :source_description => @source.source_description,
                                  :source_link => @source.source_link,       
                                  :contact_name => @source.contact_name,      
                                  :phone => @source.phone,             
                                  :email =>@source.email,             
                                  :address => @source.address,           
                                  :city => @source.city,              
                                  :state => @source.state,             
                                  :zip_code => @source.zip_code,          
                                  :citation => @source.citation,          
                                  :metadata_id =>@source.metadata_id)
        end
     end
     #put this back in later
       #if params[:no_save] != "no"
     
     #create a parsing template
     #create and save new DataStream
     columns_array = Array.new
     ignore_array = Array.new
     (1..params[:row_size].to_i).each do |i|
       columns_array[i-1]  = params["column"+i.to_s]
       ignore_array[i-1] = params["ignore"+i.to_s]
       if params["column"+i.to_s] == "timestamp"
         timestamp_col = i-1
       elsif params["column"+i.to_s] == "sample_id"
         sample_id_col = i-1
       elsif params["column"+i.to_s] == "vertical_offset"
          vertical_offset_col = i-1
       end
     end
     

     #use this when we decide to save templates and reuse them
     if params[:save_template] == "yes"
       
       data_stream_id = create_sample_and_data_parsing_template(params[:template_name], timestamp_col, sample_id_col, columns_array, ignore_array, site, params[:datafile], params[:start_line], params[:row_size])
     end
     @sample_col = params[:sample_id].to_i
       
    
     #put this back in at a later time 

     if params[:save_template] == "yes"
       data_stream = parent.managed_repository{Voeis::DataStream.get(data_stream_id[:data_template_id])}

       if !data_stream.data_stream_columns.first(:name => "Timestamp").nil?
         @timestamp_col = data_stream.data_stream_columns.first(:name => "Timestamp").column_number
      else
        @timestamp_col = -1
      end
      @sample_col = data_stream.data_stream_columns.first(:name => "SampleID").column_number
    end #end if 
      
     
     range = params[:row_size].to_i - 1
     #store all the Variables in the managed repository
     @col_vars = Array.new
     (0..range).each do |i|
       if columns_array[i] != nil && columns_array[i] != "ignore" && i != timestamp_col && i != sample_id_col && i != vertical_offset_col
         @var = Voeis::Variable.get(columns_array[i].to_i)
         parent.managed_repository do
           if !params["ignore"+i.to_s]            
             variable = Voeis::Variable.first_or_create(
                        :variable_code => @var.variable_code,
                        :variable_name => @var.variable_name,
                        :speciation =>  @var.speciation,
                        :variable_units_id => @var.variable_units_id,
                        :sample_medium =>  @var.sample_medium,
                        :value_type => @var.value_type,
                        :is_regular => @var.is_regular,
                        :time_support => @var.time_support,
                        :time_units_id => @var.time_units_id,
                        :data_type => @var.data_type,
                        :general_category => @var.general_category,
                        :no_data_value => @var.no_data_value)
              @col_vars[i] = variable
            end #end if
          end#managed repo
        end #end if
     end  #end i loop
 
     #create csv_row array
     @csv_row = Array.new
     csv_temp_data = CSV.read(params[:datafile])
     csv_size = csv_temp_data.length
     csv_data = CSV.read(params[:datafile])
     
     
     i = params[:start_line].to_i
     csv_data[params[:start_line].to_i-1..-1].each do |row|
       @csv_row[i] = row
           i = i + 1
     end#end row loop
         (params[:start_line].to_i-1..csv_size.to_i).each do |row|
           if !@csv_row[row].nil?
           parent.managed_repository do
             #create sample
 
             sample_datetime = Chronic.parse(@csv_row[row][timestamp_col]).to_datetime
             if !params[:DST].nil?
               utc_offset = params[:utc_offset].to_i + 1
               dst = true
             else
              utc_offset = params[:utc_offset].to_i
              dst = false
             end
             
             if params[:time_support] == "UTC"
              sampletime = DateTime.civil(sample_datetime.year,sample_datetime.month,sample_datetime.day,sample_datetime.hour,sample_datetime.min, sample_datetime.sec, 0)
             else
             sampletime = DateTime.civil(sample_datetime.year,sample_datetime.month,sample_datetime.day,sample_datetime.hour,sample_datetime.min, sample_datetime.sec, utc_offset/24.to_f)
             end
             @sample = Voeis::Sample.new(:sample_type =>   params[:sample_type],
                                         :material => params[:sample_medium],
                                         :lab_sample_code => @csv_row[row][@sample_col],
                                         :lab_method_id => -1,
                                         :local_date_time => sampletime)           
             @sample.valid?
             puts @sample.errors.inspect()
             
             @sample.save
             @sample.sites << site
             @sample.save
             (0..range).each do |i|
               if columns_array[i] != "ignore" && sample_id_col != i && timestamp_col != i && @csv_row[row][i] != ""&& !params["ignore"+i.to_s] && columns_array[i] != nil && vertical_offset_col != i
                  
                   new_data_val = Voeis::DataValue.new(:data_value => /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(@csv_row[row][i].to_s) ? @csv_row[row][i].to_f : -9999.0, 
                      :local_date_time => sampletime,
                      :utc_offset => utc_offset,
                      :observes_daylight_savings => dst,
                      :date_time_utc => sampletime.utc,  
                      :replicate => 0,
                      :quality_control_level=>@col_vars[i].quality_control.to_i,
                      :string_value =>  @csv_row[row][i].blank? ? "Empty" : @csv_row[row][i],
                      :vertical_offset =>  vertical_offset_col == "" ? nil : @csv_row[row][vertical_offset_col].to_i) 
                 new_data_val.valid?
                 puts new_data_val.errors.inspect() 
                 new_data_val.save
                 site.data_values << new_data_val
                 site.save
                 new_data_val.variable << @col_vars[i]
                 new_data_val.save
                 new_data_val.source = @project_source
                 new_data_val.save
                 new_data_val.sample << @sample
                 new_data_val.save
                 if params[:save_template] == "yes"
                   new_data_val.data_streams << data_stream
                   new_data_val.save
                   @sample.data_streams << data_stream
                   @sample.save
                 end
                 @sample.variables << @col_vars[i]
                 @sample.save
                 samp_site = @sample.sites.first
                 samp_site.variables << @col_vars[i]
                 samp_site.save
                 # @sample.sites.each do |samp_site|
                 #                    samp_site.variables << @col_vars[i]
                 #                    samp_site.save
                 #                  end
                end #end if
               end #end i loop
              end #end if @csv_array.nil?
           end #end managed repo
         end #end row loop
         parent.publish_his
         flash[:notice] = "File parsed and stored successfully."
         redirect_to project_path(params[:project_id])
   end# end def

    
    
    
   
   
   #columns is an array of the columns that store the variable id
   def create_sample_and_data_parsing_template(template_name, timestamp_col, sample_id_col, columns_array, ignore_array, site, datafile, start_line, row_size)
      @data_stream
      parent.managed_repository do
        @data_stream = Voeis::DataStream.create(:name => template_name.to_s,
          :description => "NA",
          :filename => datafile,
          :start_line => start_line.to_i,
          :type => "Sample")
        #Add site association to data_stream

        @data_stream.sites << site
       @data_stream.save
      end
      @timestamp_col = -1

      range = row_size.to_i-1
      (0..range).each do |i|
        #create the Timestamp column
        if i == timestamp_col.to_i && timestamp_col != "None"
          #puts params["column"+i.to_s]
          @timestamp_col = timestamp_col.to_i
          parent.managed_repository do
            data_stream_column = Voeis::DataStreamColumn.create(
                                  :column_number => i,
                                  :name => "Timestamp",
                                  :type =>"Timestamp",
                                  :unit => "NA",
                                  :original_var => "NA")
            data_stream_column.data_streams << @data_stream

            data_stream_column.save
          end
        elsif i == sample_id_col.to_i
          @sample_col = sample_id_col.to_i
           parent.managed_repository do
             data_stream_column = Voeis::DataStreamColumn.create(
                                   :column_number => i,
                                   :name => "SampleID",
                                   :type =>"SampleID",
                                   :unit => "NA",
                                   :original_var => "NA")
             data_stream_column.data_streams << @data_stream
             data_stream_column.save
           end
        elsif  columns_array[i] != nil#create other data_stream_columns and create sensor_types
          #puts params["column"+i.to_s]
          var = Voeis::Variable.get(columns_array[i].to_i)
          parent.managed_repository do
            data_stream_column = Voeis::DataStreamColumn.create(
                                  :column_number => i,
                                  :name =>         var.variable_code,
                                  :original_var => var.variable_name,
                                  :unit =>         "NA",
                                  :type =>         "NA")
            if !ignore_array[i].nil?            
              variable = Voeis::Variable.first_or_create(
                          :variable_code => var.variable_code,
                          :variable_name => var.variable_name,
                          :speciation =>  var.speciation,
                          :variable_units_id => var.variable_units_id,
                          :sample_medium =>  var.sample_medium,
                          :value_type => var.value_type,
                          :is_regular => var.is_regular,
                          :time_support => var.time_support,
                          :time_units_id => var.time_units_id,
                          :data_type => var.data_type,
                          :general_category => var.general_category,
                          :no_data_value => var.no_data_value)
              data_stream_column.variables << variable
              data_stream_column.data_streams << @data_stream
              data_stream_column.save
            else
              data_stream_column.name = "ignore"
              data_stream_column.data_streams << @data_stream
              data_stream_column.save
            end #end if
          end #end managed repository
        end #end if
      end #end range.each
      data_template_hash = Hash.new
      #return our Awesome new data_stream or template if you would be so kind
      data_template_hash = {:data_template_id => @data_stream.id}
   end
  

end
