# SpeciatonCV
#
# The SpeciationCV table contains the controlled vocabulary for the Speciation field in the
# Variables table.
# This table is pre-populated within the ODM.  Changes to this controlled vocabulary can be
# requested at http://water.usu.edu/cuahsi/odm/.
#
class SpeciationCV
  include DataMapper::Resource
  
  property :his_id, Integer
  property :term,       String, :required => true, :key => true, :format => /[^\t|\n|\r]/
  property :definition, Text
  property :updated_at, DateTime, :required => true,  :default => DateTime.now

  is_versioned :on => :updated_at
  
  before(:save) {
    self.updated_at = DateTime.now
  }
  has n,   :variables, :model => "Variable", :through => Resource
  
  
  def self.load_from_his
    his_speciations = His::SpeciationCV.all

    his_speciations.each do |his_sp|
      if self.first(:his_id => his_sp.id).nil?
        self.create(:his_id => his_sp.id,
                    :term => his_sp.term,
                    :definition=> his_sp.definition)
      end
    end
  end

  def store_to_his(u_id)
    speciation_to_store = self.first(:id => u_id)
    if speciation_to_store.is_regular == true
      reg = 1
    else
      reg =0
    end
    new_his_speciation = His::SpeciationCV.new(:term => speciation_to_store.term,
                                        :definition => speciation_to_store.definition)
    new_his_speciation.save
    puts new_his_speciation.errors.inspect
    speciation_to_store.his_id = new_his_speciation.id
    speciation_to_store.save
    new_his_speciation
  end
end