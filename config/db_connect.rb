class DbConnect
  def initialize
    @config= load_db_credentials
  end
  
  def load_db_credentials
    YAML.load_file( "config/db.yml")    
  end
  
  def connection_string
    "#{@config['adapter']}://#{@config['user']}@#{@config['server']}/#{@config['database']}"
  end
end
