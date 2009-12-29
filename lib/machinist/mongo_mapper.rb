require 'machinist'
require 'machinist/blueprints'

module Machinist
  
  module MongoMapperExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods
      def make(*args, &block)
        lathe = Lathe.run(Machinist::MongoMapperAdapter, self.new, *args)
        unless Machinist.nerfed?
          lathe.object.save!
          lathe.object.reload rescue nil
        end
        lathe.object(&block)
      end
    end
  end
  
  class MongoMapperAdapter
    def self.has_association?(object, attribute)
      false
    end
  end
  
end

class Object
  include Machinist::Blueprints
  include Machinist::MongoMapperExtensions
end
