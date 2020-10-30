module Admin
  class ModeratorsQuery
    DEFAULT_OPTIONS = {
      state: :trusted
    }.with_indifferent_access.freeze

    NAMES_FOR_POTENTIAL = %i[banned warned trusted comment_banned].freeze

    def self.call(relation: User.all, options: {})
      options = DEFAULT_OPTIONS.merge(options)
      state, search = options.values_at(:state, :search)

      relation = if state.to_s == "potential"
                   relation.where(
                     "id NOT IN (SELECT user_id FROM users_roles WHERE role_id IN (?))",
                     potential_role_ids,
                   ).order("users.comments_count" => :desc)
                 else
                   relation.joins(:roles)
                     .where(users_roles: { role_id: Role.find_by(name: state)&.id })
                 end

      relation = search_relation(relation, search) if search.presence

      relation
    end

    def self.potential_role_ids
      Role.where(name: NAMES_FOR_POTENTIAL).select(:id)
    end

    def self.search_relation(relation, search)
      relation.where(
        "users.username ILIKE :search OR users.name ILIKE :search",
        search: "%#{search}%",
      )
    end
  end
end
