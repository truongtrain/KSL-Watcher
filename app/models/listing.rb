# == Schema Information
#
# Table name: listings
#
#  id                    :integer          not null, primary key
#  alerted_at            :datetime
#  description           :text
#  last_time_on_the_moon :datetime
#  price                 :float
#  pricing               :string
#  reviewed_at           :datetime
#  status                :integer
#  title                 :string
#  url                   :string
#  walks_like_a_duck     :boolean          default(FALSE)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  listings_poll_id      :integer
#
# Indexes
#
#  index_listings_on_listings_poll_id  (listings_poll_id)
#

class Listing < ApplicationRecord
  has_many :listing_searches
  has_many :searches, through: :listing_searches
  has_many :users, through: :searches  
  belongs_to :listings_poll

  # one way of doing the scopes...
  scope :low_cost,    -> { where(price: 0..99.99) }
  scope :medium_cost, -> { where(price: 100..499.99) }
  scope :high_cost,   -> { where(price: 500..Float::INFINITY) }

  scope :by_ids, ->(list_of_ids) { where(id: list_of_ids) }
  scope :newest_first, -> { order(updated_at: :desc)}

  # We don't need this now that we're moving to a 'status' atttribute...
  # scope :reviewed, -> { where.not(reviewed_at: nil) }
  # scope :not_reviewed, -> { where(reviewed_at: nil) }

  # scope :alerted, -> { where.not(alerted_at: nil) }
  # scope :not_alerted, -> { where(alerted_at: nil) }

  # TODO 1.2:  declare the enumerated type attribute, status, here. 
  # It needs to have three possible values: :not_yet_seen, :watch, :ignore
  # Note that the order here is important, or at least the first one
  # is important.  why?

  enum status: [:not_yet_seen, :ignore, :watch]

  def mark_as_alerted
    self.alerted_at = Time.now 
    self.save!
  end

  # doing this to be backwards compatible -- if you have an old session
  # object from the prior assignment, it might want to reference the
  # Listing.not_reviewed scope which doesn't exist anymore.  This just
  # redirects the call to our enumerated status attribute as not_yet_seen.
  # This can also be done using an alias command.
  def self.not_reviewed
   # self.not_yet_seen
  end

  # apply a status change to a collection of listings all at once (i.e. using
  # a single SQL command instead of one for each listing that needs updating).
  #  listings_scope - a collection of Listing objects (optional)  This is 
  #                   typically used to restrict the update to a known set
  #                   of listings, e.g. current_user.listings
  #  list_of_ids    - is an array of ids of the Listing objects to target
  #  status_to_set  - a symbol or string matching a possible status
  def self.mass_set_status(listings_scope = Listing.all, list_of_ids, status_to_set)
    # verify the status to set is legit
    unless Listing.statuses.has_key?(status_to_set)
      raise ArgumentError, 'No such status to set: ' + status_to_set
    end
    listings_scope.by_ids(list_of_ids).update_all(status: status_to_set)
  end
end
