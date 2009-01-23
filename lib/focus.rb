class Focus
  VERSION = '1.0.0'
end

class Module
  def focus *wanteds
    wanteds.map! { |m| m.to_s }
    unwanteds = public_instance_methods(false).grep(/test_/) - wanteds
    unwanteds.each do |unwanted|
      remove_method unwanted
    end
  end
end
