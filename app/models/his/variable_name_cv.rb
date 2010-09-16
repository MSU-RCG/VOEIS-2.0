# VariableNameCV
#
# The VariableName CV table contains the controlled vocabulary for the VariableName field in
# the Variables and SeriesCatalog tables.
#
class His::VariableNameCV < His::Base
  storage_names[:his] = "variable_name_cvs"

  property :term,       String, :required => true, :key => true, :format => /[^\t|\n|\r]/
  property :definition, String

  has n,   :variables, :model => "His::Variable"
end
