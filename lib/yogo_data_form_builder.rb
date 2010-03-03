class YogoDataFormBuilder < ActionView::Helpers::FormBuilder
  
  # Analysis (Analyze?) a DataMapper parameter to create the correct form element type.
  #
  def field_for_param(param, *args)
    if param.type == DataMapper::Types::YogoFile
      file_field(param.name, *args)
    elsif param.type == DataMapper::Types::Boolean
      radio_button(param.name, true, *args) + " " + label(param.name, "True", :value => true) + "<br>" +
      radio_button(param.name, false, *args) + " " + label(param.name, "False", :value => false)
    elsif param.type == DateTime
      options = args.last.is_a?(Hash) ? args.pop : {}
      args << (options.has_key?(:class) ? options.merge(:class => options[:class]+",date-picker") : options.merge(:class => 'date-picker'))
      text_field(param.name, *args)
    else
      text_field(param.name, *args)
    end
  end
  
end