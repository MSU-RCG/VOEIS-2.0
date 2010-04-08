class YogoDataFormBuilder < ActionView::Helpers::FormBuilder
  ##
  # Creates the correct form field element for a DataMapper Type
  #
  # @example field_for_param(DM_Object_Boolean, {:checked => "checked"})
  #
  # @param [Object] param has a .type and .name
  # @param [Hash] *args hash of options
  #
  # @return [String] Analyze a DataMapper parameter to create the correct form element type
  #
  # @author Yogo Team
  #
  # @api public
  def field_for_param(param, *args)
    if param.type == DataMapper::Types::YogoFile || param.type == DataMapper::Types::YogoImage
      file_field(param.name, *args)
    elsif param.type == DataMapper::Types::Boolean
      radio_button(param.name, true, *args) + " " + label(param.name, "True", :value => true) + "<br>" +
      radio_button(param.name, false, *args) + " " + label(param.name, "False", :value => false)
    elsif param.type == Date
      options = args.last.is_a?(Hash) ? args.pop : {}
      args << (options.has_key?(:class) ? options.merge(:class => options[:class]+",date-picker") : options.merge(:class => 'date-picker'))
      text_field(param.name, *args)
    else
      text_field(param.name, *args)
    end
  end
  
end