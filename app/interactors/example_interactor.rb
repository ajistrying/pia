class ExampleInteractor < BaseInteractor
  required_context :name, :age

  def call
    puts "I'm calling #{context.name}"
  end
end