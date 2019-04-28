require_relative "../config/environment.rb"
require "active_support/inflector"
require "pry"

class InteractiveRecord
  def self.table_name
    self.name.downcase + "s"
  end

  def self.column_names
    names = []
    table_info = DB[:conn]
      .execute("PRAGMA table_info('#{table_name}');")
      .each do |row|
      names << row["name"]
    end
    names
  end

  def initialize(attributes = Hash.new)
    attributes.each { |key, value| self.send(("#{key}="), value) }
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names
        .filter { |col| col != "id" }
        .join(", ")
  end

  def values_for_insert
    self.col_names_for_insert
        .split(", ")
        .map { |col| send(col) }
        .map { |val| "'#{val}'" }
        .join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].results_as_hash = true
    DB[:conn].execute(sql)
    @id = DB[:conn].last_insert_row_id
  end

  def self.find_by_name(name)
    DB[:conn].execute "SELECT * FROM #{self.table_name} WHERE name IS '#{name}';"
  end

  def self.find_by(instance)
    field = instance.keys.pop
    value = instance.values.pop
    DB[:conn].execute "SELECT * FROM #{self.table_name} WHERE #{field} IS '#{value}';"
  end
end
