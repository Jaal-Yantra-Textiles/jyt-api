module TestModels
    def self.create_category_model
      return if Object.const_defined?(:Category)

      Class.new(ApplicationRecord) do
        self.table_name = 'categories'
      end.tap { |klass| Object.const_set(:Category, klass) }
    end

    def self.remove_category_model
      Object.send(:remove_const, :Category) if Object.const_defined?(:Category)
    end
end
