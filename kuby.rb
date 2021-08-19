require "active_support/core_ext"
require "active_support/encrypted_configuration"

# Define a production Kuby deploy environment
Kuby.define("App") do
  environment(:production) do
    # Because the Rails environment isn't always loaded when
    # your Kuby config is loaded, provide access to Rails
    # credentials manually.
    app_creds = ActiveSupport::EncryptedConfiguration.new(
      config_path: File.join("config", "credentials.yml.enc"),
      key_path: File.join("config", "master.key"),
      env_key: "RAILS_MASTER_KEY",
      raise_if_missing_key: true
    )

    docker do
      # Configure your Docker registry credentials here. Add them to your
      # Rails credentials file by running `bundle exec rake credentials:edit`.
      credentials do
        username app_creds[:DIGITALOCEAN_API_TOKEN]
        password app_creds[:DIGITALOCEAN_API_TOKEN]
      end

      # Configure the URL to your Docker image here, eg:
      image_url "registry.digitalocean.com/mikerogers0/sample-app"
    end

    kubernetes do
      # Add a plugin that facilitates deploying a Rails app.
      add_plugin :rails_app do
        hostname "sample-app.mikerogers.io"

        manage_database false

        env do
          data do
            add "DATABASE_URL", app_creds[:DATABASE_URL]
          end
        end
      end

      provider :digitalocean do
        access_token app_creds[:DIGITALOCEAN_API_TOKEN]
        cluster_id "ae71564d-7986-43ed-aa20-af7a45858ce1"
      end
    end
  end
end
