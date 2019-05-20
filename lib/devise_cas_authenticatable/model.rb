# frozen_string_literal: true

module Devise
  module Models
    # Extends your User class with support for CAS ticket authentication.
    module CasAuthenticatable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Authenticate a CAS ticket and return the resulting user object.  Behavior is as follows:
        #
        # * Check ticket validity using RubyCAS::Client.  Return nil if the ticket is invalid.
        # * Find a matching user by username (will use find_for_authentication if available).
        # * If the user does not exist, but Devise.cas_create_user is set, attempt to create the
        #   user object in the database.  If cas_extra_attributes= is defined, this will also
        #   pass in the ticket's extra_attributes hash.
        # * Return the resulting user object.
        def authenticate_with_cas_ticket(ticket)
          ::Devise.cas_client.validate_service_ticket(ticket) unless ticket.has_been_validated?

          if ticket.is_valid?
            identifier = nil
            ticket_response = ticket.respond_to?(:user) ? ticket : ticket.response

            identifier = extract_user_identifier(ticket_response)

            # If cas_user_identifier isn't in extra_attributes,
            # or the value is blank, then we're done here
            return log_and_exit if identifier.nil?

            conditions = {
              ::Devise.cas_username_column => identifier,
              soci: extract_user_soci(ticket_response),
              decidim_organization_id: extract_organization_id(ticket_response)
            }
            resource = find_or_build_resource_from_conditions(conditions, ticket_response)
            return nil unless resource

            resource.cas_extra_attributes = ticket_response.extra_attributes \
              if resource.respond_to?(:cas_extra_attributes=)

            resource.save
            resource
          end
        end

        private

        def should_create_cas_users?
          respond_to?(:cas_create_user?) ? cas_create_user? : ::Devise.cas_create_user?
        end

        def extract_user_identifier(response)
          return response.user if ::Devise.cas_user_identifier.blank?
          response.extra_attributes[::Devise.cas_user_identifier]
        end

        def extract_user_soci(response)
          response.extra_attributes.dig('soci')
        end

        def extract_organization_id(response)
          host = URI.parse(response.service).host
          organization = Decidim::Organization.find_by(host: host)
          organization.try(:id)
        end

        def extract_attributes(response, record)
          extra_attributes = response.extra_attributes

          attributes = {
            email: extra_attributes['email']
          }

          if record.username.blank?
            attributes = attributes.merge(
              username: extra_attributes['username']
            )
          end

          if record.new_record?
            attributes = attributes.merge(
              name: %(#{extra_attributes['first_name']} #{extra_attributes['last_name']}),
              decidim_organization_id: extract_organization_id(response),
              tos_agreement: true,
              nickname: nicknamize(name),
              password: Devise.friendly_token.first(name.length)
            )
          end

          attributes
        end

        def log_and_exit
          logger.warn("Could not find a value for [#{::Devise.cas_user_identifier}] in cas_extra_attributes so we cannot find the User.")
          logger.warn('Make sure config.cas_user_identifier is set to a field that appears in cas_extra_attributes')
          nil
        end

        def find_or_build_resource_from_conditions(conditions, response)
          resource = find_resource_with_conditions(conditions, response.extra_attributes)
          resource = new if resource.nil? && should_create_cas_users?

          attributes = extract_attributes(response, resource)
          resource.assign_attributes(attributes)
          resource.confirm
          resource
        end

        def find_resource_with_conditions(conditions, extra_conditions = {})
          # We don't want to override Devise 1.1's find_for_authentication
          if respond_to?(:find_for_authentication)
            resource = find_for_authentication(conditions)
            return resource ||= find_by(email: extra_conditions['email']) if extra_conditions.present? # search with email
          end
          find(:first, conditions: conditions)
        end
      end
    end
  end
end
