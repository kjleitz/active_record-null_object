require "active_record/null_object/railtie"

module ActiveRecord
  module NullObject
    @_model_class = ActiveRecord::Base

    class << self
      def mimics(model_class)
        @_model_class = model_class
      end

      private

      def model_class
        @_model_class
      end
    end

    def method_missing(method, *_args)
      if attribute_is_association?(method) || attribute_has_column?(attribute)
        default_for_attribute(method)
      end

      super
    end

    private
  
    def respond_to_missing?(method, *_args)
      model_class.new.respond_to?(method) || super
    end

    def model_class
      self.class.model_class
    end

    def default_for_attribute(attribute)
      case
      when attribute_is_collection_association?(attribute)
        default_for_collection_association_attribute(attribute)
      when attribute_is_belongs_to_association?(attribute)
        default_for_single_association_attribute(attribute)
      else
        default_for_content_attribute(attribute)
      end
    end

    def default_for_collection_association_attribute(attribute)
      association = association_for_attribute(attribute)
      return if association.blank? || !association.collection?
      
      # could allow the user to specify "default 10 of :offers" or something,
      # then return a collection of 10 offer null objects? future todo.
      association.klass.none
    end

    def default_for_single_association_attribute(attribute)
      association = association_for_attribute(attribute)
      return if association.blank? || association.collection?
      return unless attribute_must_be_present?(attribute)

      column = column_for_attribute(attribute) # only works for belongs_to (not has_one--foreign key is on the wrong table in that one)
      return if column.blank? || column.null

      null_class_name = "#{association.class_name}NullObject"
      null_class = Class.new(self.class) { mimics association.klass }
      self.class.const_set(null_class_name, null_class)

      # should allow the user to specify NullObject classes for associations,
      # and/or just pull them from files already defined for that model. future
      # todo.
      null_class.new
    end

    def default_for_content_attribute(attribute)
      default_value_for_content_attribute(attribute)
    end

    def column_name_for_attribute(attribute)
      # return if attribute_is_collection_association?(attribute)
      # return if attribute_is_has_one_association?(attribute)
      column = model_class.column_for_attribute(attribute)
      return attribute if column.present? && !column.type.nil?

      association = association_for_attribute(attribute)
      return association.foreign_key if association.present? && association.belongs_to?

      # being explicit here: returns nil if attr has no column or no foreign key
      # on the model_class' table.
      nil
    end

    def attribute_must_be_present?(attribute)
      return true if attribute_is_validated_for_absolute_presence?(attribute)
      return true if attribute_is_constrained_for_absolute_presence?(attribute)
      return true if attribute_is_collection_association?(attribute)
      false
    end

    def attribute_is_validated_for_absolute_presence?(attribute)
      validators = model_class.validators_on(attribute)
      # if there are options (like if/unless/on) on the presence validator, the
      # attribute value could theoretically be nil.
      validators.any? { |v| v.kind == :presence && v.options.empty? }
    end

    def attribute_is_constrained_for_absolute_presence?(attribute)
      column_name = column_name_for_attribute(column_name)
      column = model_class.column_for_attribute(column_name)
      column.present? && !column.null
    end

    def attribute_is_association?(attribute)
      model_class.reflect_on_association(attribute).present?
    end

    def attribute_has_column?(attribute)
      column_for_attribute(attribute).present?
    end

    def attribute_is_belongs_to_association?(attribute)
      !!model_class.reflect_on_association(attribute)&.belongs_to?
    end

    def attribute_is_has_one_association?(attribute)
      !!model_class.reflect_on_association(attribute)&.has_one?
    end

    def attribute_is_collection_association?(attribute)
      !!model_class.reflect_on_association(attribute)&.collection?
    end

    def association_for_attribute(attribute)
      model_class.reflect_on_association(attribute)
    end

    def column_for_attribute(attribute)
      column_name = column_name_for_attribute(column_name)
      column = model_class.column_for_attribute(column_name)
      column unless column.blank? || column.type.nil?
    end

    def default_value_for_content_attribute(attribute)
      column = column_for_attribute(attribute)
      return if column.blank?

      default_str = column.default
      return if default_str.nil?

      case column.type
      when :integer  then default_str.to_i
      when :float    then default_str.to_f
      when :decimal  then default_str.to_d
      when :datetime then default_str.to_datetime
      when :boolean  then { 'true' => true, 'false' => false }[default_str]
      else default_str
      end
    end
  end
end
