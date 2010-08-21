class Voeis::DataStreamsController < Voeis::BaseController

  # Properly override defaults to ensure proper controller behavior
  # @see Voeis::BaseController
  defaults  :route_collection_name => 'data_streams',
            :route_instance_name => 'data_stream',
            :collection_name => 'data_streams',
            :instance_name => 'data_stream',
            :resource_class => Voeis::DataStream

  # alows us to upload csv file to be processed into data
  #
  # @example http://localhost:3000/project/upload_stream/1/
  #
  # @param [Hash] params
  # @option params [Hash] :upload
  #
  # @return [String] Accepts the upload of a CSV file
  #
  # @author Yogo Team
  #
  # @api public
  def pre_upload
   #@project = Project.first(:id => params[:project_id])
    puts @variables = His::Variables.all
    puts @sites = parent.managed_repository{Voeis::Site.all}
    @sites.each do |site|
      puts site.id.to_s
      puts site.site_name 
    end
    if !params[:datafile].nil? && datafile = params[:datafile]
      if ! ['text/csv', 'text/comma-separated-values', 'application/vnd.ms-excel',
            'application/octet-stream','application/csv'].include?(datafile.content_type)
        flash[:error] = "File type #{datafile.content_type} not allowed"
        redirect_to(:controller =>"projects", :action => "add_stream", :params => {:id => params[:project_id]})
      else

        # Read the logger file header
        if params[:header_box] == "Campbell"
          @start_line = 4
          @header_info = parse_logger_csv_header(datafile.path)

          @start_row = @header_info.last

          @row_size = @start_row.size - 1
          if @header_info.empty?
            flash[:error] = "CSV File improperly formatted. Data not uploaded."
            #redirect_to :controller =>"projects", :action => "add_stream", :params => {:id => params[:project_id]}
          end
        else
          @start_line = params[:start_line].to_i
          @start_row = get_row(datafile.path, params[:start_line].to_i)
          @row_size = @start_row.size-1
        end
      end
      @var_array = Array.new
      @var_array[0] = ["","","",""]
      # if params[:data_template] != "None"
      #   data_template = DataStream.first(:id => params[:data_template])
          # (0..@row_size).each do |i|
          #    puts i
          #    data_col = data_template.data_stream_columns.first(:column_number => i)
          #    if data_col.variables.empty?
          #      @var_array[i] = [data_col.name, data_col.unit, data_col.type,"",data_col.min, data_col.min, data_col.difference]
          #    else
          #      @var_array[i] = [data_col.name, data_col.unit, data_col.type,data_col.variables.first.id,data_col.min, data_col.min, data_col.difference]
          #    end
          #  end
          # else
            (0..@row_size).each do |i|
              @var_array[i] = ["","","","","","",""]
             end
          # end

      respond_to do |format|
        format.html
      end
    end
  end



  def create_stream
    #create and save new DataStream
    #
    data_stream = parent.managed_repository{Voeis::DataStream.create(
                                 :name => params[:data_stream_name],
                                 :description => params[:data_stream_description],
                                 :filename => params[:datafile],
                                 :start_line => params[:start_line].to_i)}
    #Add site association to data_stream
    # 
    site = parent.managed_repository{Voeis::Site.first(:id => params[:site])}
    data_stream.sites << site
    data_stream.save
    #create DataStreamColumns 
    #    
    range = params[:rows].to_i
    (0..range).each do |i|
      #create the Timestamp column
      if i == params[:timestamp].to_i
        @his_var = His::Variables.first(:id => params["column"+i.to_s])
        parent.managed_repository{
        data_stream_column = Voeis::DataStreamColumn.create(
                              :column_number => i,
                              :name => "Timestamp",
                              :type =>"Timestamp",
                              :unit => "NA",
                              :original_var => params["variable"+i.to_s])
        data_stream.data_stream_columns << data_stream_column
        data_stream.save}
      else #create other data_stream_columns and create sensor_types
        parent.managed_repository{
        data_stream_column = Voeis::DataStreamColumn.create(
                              :column_number => i,
                              :name => params["variable"+i.to_s],
                              :original_var => params["variable"+i.to_s],
                              :unit => params["unit"+i.to_s],
                              :type => params["type"+i.to_s])
       
        variable = Voeis::Variable.first_or_create(
                    :variable_code => @his_var.variable_code,
                    :variable_name => @his_var.variable_name,
                    :speciation =>  @his_var.speciation,
                    :variable_units_id => @his_var.variable_units_id,
                    :sample_medium =>  @his_var.sample_medium,
                    :value_type => @his_var.value_type,
                    :is_regular => @his_var.is_regular,
                    :time_support => @his_var.time_support,
                    :time_units_id => @his_var.time_units_id,
                    :data_type => @his_var.data_type,
                    :general_category => @his_var.general_category,
                    :no_data_value => @his_var.no_data_value)
        data_stream_column.variables << variable
        data_stream_column.data_streams << data_stream
        data_stream_column.save
        sensor_type = Voeis::SensorType.first_or_create(
                      :name => params["variable"+i.to_s] + site.site_name,
                      :min => params["min"+i.to_s].to_f,
                      :max => params["max"+i.to_s].to_f,
                      :difference => params["difference"+i.to_s].to_f)
        #Add sites and variable associations to senor_type
        site.sensor_types << sensor_type
        site.save
        sensor_type.variables <<  variable
        sensor_type.save}
      end
    end
    # Parse the csv file using the newly created data_stream template and
    # save the values as sensor_values
    parse_logger_csv(params[:datafile], data_stream, site)
    flash[:notice] = "File parsed and stored successfully."
    redirect_to project_path(params[:project_id])
  end



  def index
    @project_array = Array.new
    parent.managed_repository do
      @sites = Voeis::Site.all
      @project_hash = Hash.new
      @site_data = Hash.new
      num_hash = Hash.new
      site_count=-1
      @sites.each do |site|
        site_count +=1
        @plot_data = "{"
        senscount = 0
        @site_hash = Hash.new
        @sensor_types = site.sensor_types
        @sensor_types.each do |s_type|
          if senscount != 0 &&
           @plot_data +=  ","
          end
          senscount+=1
          count = 0
      
          @plot_data += '"' + s_type.name + "-" + site.site_code + '"' + ": {data:["
          @sensor_hash = Hash.new
          num = 24
          cur_date = s_type.sensor_values.first(:order => [:timestamp.desc]).timestamp
          begin_date = (cur_date.to_time - num.hours).to_datetime
          tmp_data = ""
          sense_data = s_type.sensor_values(:timestamp.gt => begin_date, :timestamp.lt => cur_date)
          sense_data.each do |val|
            tmp_data = tmp_data + ",[" + (val.timestamp.to_time.to_i*1000).to_s + ","                        + val.value.to_s + "]"
          end
          tmp_data = tmp_data.slice(1..tmp_data.length)
          array_data = Array.new()
          puts value_results = s_type.sensor_values(:timestamp.gt => begin_date, :timestamp.lt => cur_date).collect{
          |val|
             temp_array= Array.new()
             if params[:hourly].nil?
               temp_array.push(val.timestamp.to_time.to_i*1000, val.value)
               array_data.push(temp_array)
             else
               if val.timestamp.min == 0
                 temp_array.push(val.timestamp.to_time.localtime.to_i*1000, val.value)
                 array_data.push(temp_array)
               end
             end
           }
           if !tmp_data.nil?
             @plot_data += tmp_data
           end
           @sensor_hash["data"] = array_data
           @sensor_hash["label"] = s_type.variables.first.variable_name
           @thelabel = s_type.variables.first.variable_name
           if !s_type.sensor_values.last.units.nil?
             @sensor_hash["units"] = s_type.sensor_values.last.units
           else
             @sensor_hash["units"] = "nil"
           end
           @site_hash[s_type.name] = @sensor_hash
           @plot_data += "] , label: \"#{@thelabel}\" }"
        end #end sensor_type      
        @plot_data += "}"
        temp_hash = Hash.new
        temp_hash["sitecode"]=site.site_code
        temp_hash["sitename"]=site.site_name
        temp_hash["sensors"]=@site_hash
        @project_array.push(temp_hash)
        num_hash[site.site_code] = site_count
        @site_data[site.site_code] = @plot_data
      end  #site
      @project_hash["sites"] = @project_array
    end
    respond_to do |format|
      format.html
    end
  end

   
   # parse the header of a logger file
   # assumes Campbell scientific header style at the moment
   # @example parse_logger_csv_header("filename")
   #
   # @param [String] csv_file
   #
   # @return [Array] an array whose elements are a hash
   #
   # @author Yogo Team
   #
   # @api public
   def parse_logger_csv_header(csv_file)
     require "lib/yogo/model/csv"
     csv_data = CSV.read(csv_file)
     path = File.dirname(csv_file)

     #look at the first hour lines -
     #line 0 is a description -so skip that one
     #line 1 is the variable names
     #line 2 is the units
     #line 3 is the type
     #store the variable,unit and type for a column as a hash in an array
     header_data=Array.new
     (0..csv_data[1].size-1).each do |i|
       item_hash = Hash.new
       item_hash["variable"] = csv_data[1][i].to_s
       item_hash["unit"] = csv_data[2][i].to_s
       item_hash["type"] = csv_data[3][i].to_s
       header_data << item_hash
     end

     header_data << csv_data[4]
   end

   # Returns the specified row of a csv
   # 
   # @example get_row("filename",4)
   #
   # @param [String] csv_file
   # @param [Integer] row
   # 
   # @return [Array] an array whose elements are a csv-row columns
   #
   # @author Yogo Team
   #
   # @api public
   def get_row(csv_file, row)
     require "lib/yogo/model/csv"
     csv_data = CSV.read(csv_file)
     path = File.dirname(csv_file)

     csv_data[row-1]
   end

   # Parses a csv file using an existing data_column template
   # column values are stored in sensor_values
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
   def parse_logger_csv(csv_file, data_stream_template, site)
     require "yogo/model/csv"
     csv_data = CSV.read(csv_file)
     path = File.dirname(csv_file)
     sensor_type_array = Array.new
     data_stream_col = Array.new
     data_stream_template.data_stream_columns.each do |col|
       sensor_type_array[col.column_number] = parent.managed_repository{Voeis::SensorType.first(:name => col.original_var + site.site_name)}
       data_stream_col[col.column_number] = col
     end
     data_timestamp_col = data_stream_template.data_stream_columns.first(:name => "Timestamp").column_number
     csv_data[data_stream_template.start_line..-1].each do |row|
       (0..row.size-1).each do |i|
         if i != data_timestamp_col
           #save to sensor_value and sensor_type
           parent.managed_repository{
           sensor_value = Voeis::SensorValue.new(                                     
                                         :value => row[i],
                                         :units => data_stream_col[i].unit,
                                         :timestamp => row[data_timestamp_col])
           sensor_value.save
           sensor_value.sensor_type << sensor_type_array[i]
           sensor_value.site << site
           sensor_value.save}
         end
       end
     end
   end
end
