require 'machinist'
require 'machinist/blueprints'
require 'sham'
require 'mongo_mapper'

module Machinist
  module MongoMapperExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.assigned_attributes_without_associations(lathe)
      attributes = {}
      lathe.assigned_attributes.each_pair do |attribute, value|
        association = lathe.object.class.reflect_on_association(attribute)
        if association && association.macro == :belongs_to && !value.nil?
          attributes[association.primary_key_name.to_sym] = value.id
        else
          attributes[attribute] = value
        end
      end
      attributes
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

      def make_unsaved(*args)
        object = Machinist.with_save_nerfed { make(*args) }
        yield object if block_given?
        object
      end

      def plan(*args)
        lathe = Lathe.run(Machinist::MongoMapperAdapter, self.new, *args)
        Machinist::MongoMapperAdapter.assigned_attributes_without_associations(lathe)
      end
    end
  end

  class MongoMapperAdapter
    def self.has_association?(object, attribute)
      object.class.associations[attribute]
    end

    def self.class_for_association(object, attribute)
      association = object.class.associations[attribute]
      association && association.klass
    end

    def self.assigned_attributes_without_associations(lathe)
      attributes = {}
      lathe.assigned_attributes.each_pair do |attribute, value|
        association = lathe.object.class.associations[attribute]
        if association && association.belongs_to? && !value.nil?
          attributes[association.foreign_key.to_sym] = value.id
        else
          attributes[attribute] = value
        end
      end
      attributes
    end
  end
end

MongoMapper::Document.append_inclusions(Machinist::Blueprints::ClassMethods)
MongoMapper::Document.append_inclusions(Machinist::MongoMapperExtensions)

