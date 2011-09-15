class Voeis::DataValue
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,                         Serial
  property :data_value,                 Float,    :required => true,  :default => 0
  property :value_accuracy,             Float
  property :local_date_time,            DateTime, :required => true,  :default => DateTime.now, :index => true
  property :utc_offset,                 Float,    :required => true,  :default => 1.0
  property :date_time_utc,              DateTime, :required => true,  :default => DateTime.now
  property :observes_daylight_savings,  Boolean,  :required => true, :default => false
  property :replicate,                  String,   :required => true,  :default => "original"
  property :vertical_offset,            Float,    :required=>false
  property :end_vertical_offset,        Float,    :required=>false
  property :string_value,               String,   :required => true, :default => "Unknown"
  property :quality_control_level,      Integer,  :required=>true, :default=>0
  property :datatype,                  String,    :default =>"Sample", :index =>true
  property :published,                  Boolean,  :required => false
  property :site_id,                    Integer,  :index => true
  property :variable_id,                Integer, :index => true
  yogo_versioned
  #timestamps :at
  
  has 1, :site,       :model => "Voeis::Site",     :through => Resource
  has 1,:source,       :model => "Voeis::Source",       :through => Resource
   
  has 1, :sample,     :model => "Voeis::Sample",   :through => Resource
  has n, :meta_tags,  :model => "Voeis::MetaTag",  :through => Resource
  has 1, :variable,   :model => "Voeis::Variable", :through => Resource
  has n, :data_streams,  :model => "Voeis::DataStream", :through => Resource
  has 1, :sensor_type,  :model => "Voeis::SensorType", :through => Resource
  has n, :data_sets,  :model =>"Voeis::DataSet", :through => Resource
  #has n, :method,     :model => "Voeis::Method", :through => Resource
  
  
  # Parses a csv file using an existing data_column template
  # column values are stored in data_values
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
  # @api publicsenosr
  def self.parse_logger_csv(csv_file, data_stream_template_id, site_id, start_line, sample_type, sample_medium)
    #Determine how the time is stored
    
    if !Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "Timestamp").nil?
      data_timestamp_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "Timestamp").column_number
      date_col=""
      time_col=""
    else
      data_timestamp_col = ""
      date_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "Date").column_number
      time_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "Time").column_number
    end
    if !Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "VerticalOffset").nil?
      vertical_offset_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "VerticalOffset").column_number
    else
      vertical_offset_col = ""
    end
     if !Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "EndingVerticalOffset").nil?
        end_vertical_offset_col = Voeis::DataStream.get(data_stream_template_id).data_stream_columns.first(:name => "EndingVerticalOffset").column_number
      else
        end_vertical_offset_col = ""
      end
    if start_line.nil?
      start_line = Voeis::DataStream.get(data_stream_template_id).start_line
    end
    #site = Voeis::Site.get(site_id)
    data_col_array = Array.new
    sensor_col_array = Array.new
    sensor_cols = Array.new
    variable_cols = Array.new
    sample_id = -1
    Voeis::DataStream.get(data_stream_template_id).data_stream_columns.each do |col|
      data_col_array[col.column_number] = [col.variables.first, col.unit, col.name]
      if col.name != "Ignore"  && col.name != "Timestamp"  && col.name != "Time" && col.name != "Date" && col.name !=  "VerticalOffset" && col.name !=  "EndingVerticalOffset" && col.name !=  "SampleID"
        variable_cols << col.column_number
      elsif col.name ==  "SampleID"
        sample_id = col.column_number
      end
      sensor_col_array[col.column_number] = [col.sensor_types.first, col.unit, col.name]
      if col.name != "ignore"  && col.name != "Timestamp"  && col.name != "Time" && col.name != "Date" && col.name !=  "VerticalOffset"
        sensor_cols << col.column_number
      end
    end
    
    if Voeis::DataValue.last(:order =>[:id.asc]).nil?
      starting_id = -9999
    else
      starting_id = Voeis::DataValue.last(:order =>[:id.asc]).id
    end
    rows_parsed = 0
    header_row=""  
    source_id = Voeis::DataStream.get(data_stream_template_id).source.id
    dst_time = 0
    dst = false
    if Voeis::DataStream.get(data_stream_template_id).DST
       dst_time = 1
       dst = true
    end
    user_id = User.current.id
    create_comment = "Created at #{created_at} by #{User.current.first_name} #{User.current.last_name} [#{User.current.login}]"
    
    CSV.foreach(csv_file) do |row|
      if rows_parsed > start_line-1
      #   (1..start_line-1).each do
      #     header_row = csv.readline
      #   end
      # end
      #while row = csv.readline #&& !row.empty?
        if !row.empty?        
        Rails.logger.info '#{row.join(', ')}'
        #puts row.join(', ')
          parse_logger_row(data_timestamp_col, data_stream_template_id, vertical_offset_col, date_col, time_col,  row, site_id, data_col_array, variable_cols, sample_id, sample_type, sample_medium, end_vertical_offset_col,sensor_col_array,sensor_cols, source_id, dst_time, dst, user_id, create_comment)
        else 
          #puts "EMPTY ROW"
        end
      end
      rows_parsed += 1 
    end
    #end
    total_records = 0
    data_value = Voeis::DataValue.last(:order =>[:id.asc]) 
    if starting_id == -9999  && !Voeis::DataValue.first(:order => [:id.asc]).nil?
      total_records = data_value.id - Voeis::DataValue.first(:order => [:id.asc]).id
    elsif !Voeis::DataValue.last(:order =>[:id.asc]).nil? 
      total_records = data_value.id - starting_id
    end
    return_hash = {:total_records_saved => total_records, :total_rows_parsed => rows_parsed, :last_record => data_value.as_json}
  end
  
  
  
  # Parses a csv row using an existing data_column template
  # column values are stored in sensor_values
  #
  # TODO wrap associations in A POSTGRES Transaction
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
  def self.parse_logger_row(data_timestamp_col, data_stream_id, vertical_offset_col, date_col, time_col, row, site_id, data_col_array, variable_cols, sample_id, sample_type, sample_medium, end_vertical_offset_col, sensor_col_array,sensor_cols, source_id, dst_time, dst, user_id, create_comment)
    require 'chronic'  #for robust timestamp parsing
    name = 2
    variable = 0
    sensor = 0
    unit = 1
    #Voeis::SensorValue.transaction do
    #timestamp = (data_timestamp_col == "") ? Time.parse(row[date_col].to_s + ' ' + row[time_col].to_s).strftime("%Y-%m-%dT%H:%M:%S%z") : row[data_timestamp_col.to_i]
    vertical_offset = vertical_offset_col == "" ? 0.0 : row[vertical_offset_col.to_i].to_f
  end_vertical_offset = end_vertical_offset_col == "" ? 0.0 : row[end_vertical_offset_col.to_i].to_f
    data_stream = Voeis::DataStream.get(data_stream_id)
    sample_datetime = Chronic.parse(row[data_timestamp_col]).to_datetime
    timestamp = DateTime.civil(sample_datetime.year,sample_datetime.month,
                   sample_datetime.day,sample_datetime.hour,sample_datetime.min,
                   sample_datetime.sec, (data_stream.utc_offset+dst_time)/24.to_f)
    #if t = Date.parse(timestamp) rescue nil?
    #if (Voeis::DataValue.first(:local_date_time => timestamp) & 
    if Voeis::DataValue.first(:datatype=>data_stream.type, :local_date_time=>timestamp, :site_id=> site_id, :variable_id => data_col_array[variable_cols[0]][variable].id).nil?
          created_at = updated_at = Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
          row_values = []
          (0..row.size-1).each do |i|
            if i != data_timestamp_col && i != date_col && i != time_col && i != vertical_offset_col && data_col_array[i][name] != "Ignore" && data_col_array[i][name] != "EndingVerticalOffset" && data_col_array[i][name] != "SampleID" && data_col_array[i][name] != "Ignore" 
                cv = /^[-]?[\d]+(\.?\d*)(e?|E?)(\-?|\+?)\d*$|^[-]?(\.\d+)(e?|E?)(\-?|\+?)\d*$/.match(row[i]) ? row[i].to_f : -9999.0

                row_values << "(#{cv.to_s}, '#{timestamp}', #{vertical_offset},FALSE, '#{row[i].to_s}', '#{created_at}', '#{updated_at}', #{user_id},'#{create_comment}', #{data_stream.utc_offset+dst_time},'#{timestamp.utc}','#{dst}',#{end_vertical_offset},#{data_col_array[i][variable].quality_control.to_f},'#{data_stream.type}', #{site_id},  #{data_col_array[i][variable].id} )"
                #puts "(#{cv.to_s}, '#{timestamp}', #{vertical_offset},FALSE, '#{row[i].to_s}', '#{created_at}', '#{updated_at}', #{user_id},'#{create_comment}', #{data_stream.utc_offset+dst_time},'#{timestamp.utc}','#{dst}',#{end_vertical_offset},#{data_col_array[i][variable].quality_control.to_f},'#{data_stream.type}', #{site_id},  #{data_col_array[i][variable].id} )"
              end #end if
          end #end loop
          if !row_values.empty?
            sql = "INSERT INTO \"#{self.storage_name}\" (\"data_value\",\"local_date_time\",\"vertical_offset\",\"published\",\"string_value\",\"created_at\",\"updated_at\",\"updated_by\",\"updated_comment\", \"utc_offset\",\"date_time_utc\", \"observes_daylight_savings\", \"end_vertical_offset\", \"quality_control_level\", \"datatype\", \"site_id\", \"variable_id\") VALUES "
            sql << row_values.join(',')
            sql << " RETURNING \"id\""
            result_ids = repository.adapter.select(sql)
            variable_sql = Array.new
            site_sql = Array.new
            data_stream_sql = Array.new
            source_sql = Array.new
            (0..result_ids.length-1).each do |i|
              variable_sql << "(#{result_ids[i]},#{data_col_array[variable_cols[i]][variable].id})"
              site_sql << "(#{result_ids[i]},#{site_id})"
              data_stream_sql <<  "(#{result_ids[i]},#{data_stream_id})"
              source_sql << "(#{result_ids[i]},#{source_id})"
            end
            sql = "INSERT INTO \"voeis_data_value_variables\" (\"data_value_id\",\"variable_id\") VALUES "
            sql << variable_sql.join(',')
            repository.adapter.execute(sql)
            sql = "INSERT INTO \"voeis_data_value_sites\" (\"data_value_id\",\"site_id\") VALUES "
            sql << site_sql.join(',')
            repository.adapter.execute(sql)
            sql = "INSERT INTO \"voeis_data_stream_data_values\" (\"data_value_id\",\"data_stream_id\") VALUES "
            sql << data_stream_sql.join(',')
            repository.adapter.execute(sql)
            sql = "INSERT INTO \"voeis_data_value_sources\" (\"data_value_id\",\"source_id\") VALUES "
            sql << source_sql.join(',')
            repository.adapter.execute(sql)
            
            
            # sql = "INSERT INTO \"voeis_data_value_variables\" (\"data_value_id\",\"variable_id\") VALUES "
            # sql << (0..result_ids.length-1).collect{|i|
            #   "(#{result_ids[i]},#{data_col_array[variable_cols[i]][variable].id})"
            # }.join(',')
            # repository.adapter.execute(sql)
            # sql = "INSERT INTO \"voeis_data_value_sites\" (\"data_value_id\",\"site_id\") VALUES "
            # sql << (0..result_ids.length-1).collect{|i|
            #   "(#{result_ids[i]},#{site_id})"
            # }.join(',')
            # repository.adapter.execute(sql)
            # sql = "INSERT INTO \"voeis_data_stream_data_values\" (\"data_value_id\",\"data_stream_id\") VALUES "
            # sql << (0..result_ids.length-1).collect{|i|
            #   "(#{result_ids[i]},#{data_stream_id})"
            # }.join(',')
            # repository.adapter.execute(sql)
            # sql = "INSERT INTO \"voeis_data_value_sources\" (\"data_value_id\",\"source_id\") VALUES "
            # sql << (0..result_ids.length-1).collect{|i|
            #   "(#{result_ids[i]},#{source_id})"
            # }.join(',')
            # repository.adapter.execute(sql)
            
            if sample_id != -1
              sample_value=[]
              sql = "INSERT INTO \"voeis_samples\" (\"sample_type\",\"material\",\"lab_sample_code\",\"local_date_time\",\"created_at\",\"updated_at\",\"updated_by\",\"updated_comment\") VALUES "
              sql << "('#{sample_type}', '#{sample_medium}','#{row[sample_id]}', '#{timestamp}','#{created_at}', '#{updated_at}', #{user_id},'#{create_comment}')"
              #sql << sample_value.join(',')
              sql << " RETURNING \"id\""
              newsample_id = repository.adapter.execute(sql)
              sql = "INSERT INTO \"voeis_data_value_samples\" (\"data_value_id\",\"sample_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                "(#{result_ids[i]},#{newsample_id.insert_id})"
              }.join(',')
              repository.adapter.execute(sql)
              sql = "INSERT INTO \"voeis_sample_sites\" (\"sample_id\",\"site_id\") VALUES "
              sql << "(#{newsample_id.insert_id},#{site_id})"
              repository.adapter.execute(sql)
              sql = "INSERT INTO \"voeis_sample_variables\" (\"sample_id\",\"variable_id\") VALUES "
              sql << (0..result_ids.length-1).collect{|i|
                "(#{newsample_id.insert_id},#{data_col_array[variable_cols[i]][variable].id})"
              }.join(',')
              repository.adapter.execute(sql)
            else
               sql = "INSERT INTO \"voeis_data_value_sensor_types\" (\"data_value_id\",\"sensor_type_id\") VALUES "
               sql << (0..result_ids.length-1).collect{|i|
                 "(#{result_ids[i]},#{sensor_col_array[sensor_cols[i]][sensor].id})"
               }.join(',')
               repository.adapter.execute(sql)
           end
        end#end if

    end
  end
  
end
