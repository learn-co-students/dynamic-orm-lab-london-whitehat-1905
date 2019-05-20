#require_relative "../config/environment.rb"
#require 'active_support/inflector'

class InteractiveRecord
    def initialize(args)
        args.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        sql = "SELECT name FROM sqlite_master WHERE type='table';"
        DB[:conn].execute(sql)[0]
    end

    def column_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(', ')        
    end

    def values_for_insert
        values = []
        columns = self.class.column_names.delete_if {|col| col == "id"}
        columns.each do |col|
            values << "#{self.send(col)}"
        end
        values.join(', ')
    end

    def save
        sql = <<-SQL
        INSERT INTO #{self.table_name} (#{column_for_insert}) VALUES {#{values_for_insert}}; 
        SQL
        DB[:conn].execute(sql)
        
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end
end