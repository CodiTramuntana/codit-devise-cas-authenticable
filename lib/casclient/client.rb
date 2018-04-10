module CASClient
  class Client

    def add_service_to_login_url(service_url)
      uri = URI.parse(login_url)
      params = ["service=#{CGI.escape(service_url)}"]
      params << "locale=#{I18n.locale}" if Rails.const_defined?(:I18n)
      uri.query = (uri.query ? uri.query + "&" : "") + params.join("&")
      uri.to_s
    end

  end
end
