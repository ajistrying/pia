class BaseInteractor
  include Interactor

  before do
    validate_required_context!
  end

  def self.required_context(*key_args)
    @required_context = key_args.flatten
  end

  private

  def validate_required_context!
    return if self.class.instance_variable_get(:@required_context).nil? || self.class.instance_variable_get(:@required_context).empty?

    missing_keys = self.class.instance_variable_get(:@required_context) - context.to_h.keys
    if missing_keys.any?
      context.fail!(error: "Missing required context: #{missing_keys.join(', ')}")
    end
  end
end