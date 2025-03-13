;; Property Registration Contract
;; Records details of available affordable housing units

;; Data variables
(define-data-var property-counter uint u0)
(define-data-var property-type-counter uint u0)
(define-data-var location-counter uint u0)

;; Data maps
(define-map properties
{ id: uint }
{
  property-type-id: uint,
  location-id: uint,
  address: (string-ascii 128),
  units: uint,
  bedrooms: uint,
  bathrooms: uint,
  square-feet: uint,
  monthly-rent: uint,
  income-restricted: bool,
  accessibility-features: bool,
  available-units: uint,
  status: (string-ascii 16),
  owner: principal
}
)

(define-map property-types
{ id: uint }
{
  name: (string-ascii 32),
  description: (string-ascii 128),
  active: bool
}
)

(define-map locations
{ id: uint }
{
  city: (string-ascii 64),
  state: (string-ascii 32),
  zip-code: (string-ascii 10),
  neighborhood: (string-ascii 64),
  active: bool
}
)

(define-map property-managers
{ address: principal }
{ active: bool }
)

;; Initialize contract
(define-public (initialize)
(begin
  (map-set property-managers { address: tx-sender } { active: true })
  (ok true)
)
)

;; Check if address is property manager
(define-read-only (is-property-manager (address principal))
(default-to false (get active (map-get? property-managers { address: address })))
)

;; Add a property manager
(define-public (add-property-manager (address principal))
(begin
  ;; Only property managers can add property managers
  (asserts! (is-property-manager tx-sender) (err u403))

  (map-set property-managers
    { address: address }
    { active: true }
  )

  (ok true)
)
)

;; Register a property type
(define-public (register-property-type (name (string-ascii 32)) (description (string-ascii 128)))
(let ((new-id (+ (var-get property-type-counter) u1)))
  ;; Only property managers can register property types
  (asserts! (is-property-manager tx-sender) (err u403))

  ;; Update counter
  (var-set property-type-counter new-id)

  ;; Store property type data
  (map-set property-types
    { id: new-id }
    {
      name: name,
      description: description,
      active: true
    }
  )

  (ok new-id)
)
)

;; Register a location
(define-public (register-location
  (city (string-ascii 64))
  (state (string-ascii 32))
  (zip-code (string-ascii 10))
  (neighborhood (string-ascii 64)))
(let ((new-id (+ (var-get location-counter) u1)))
  ;; Only property managers can register locations
  (asserts! (is-property-manager tx-sender) (err u403))

  ;; Update counter
  (var-set location-counter new-id)

  ;; Store location data
  (map-set locations
    { id: new-id }
    {
      city: city,
      state: state,
      zip-code: zip-code,
      neighborhood: neighborhood,
      active: true
    }
  )

  (ok new-id)
)
)

;; Register a property
(define-public (register-property
  (property-type-id uint)
  (location-id uint)
  (address (string-ascii 128))
  (units uint)
  (bedrooms uint)
  (bathrooms uint)
  (square-feet uint)
  (monthly-rent uint)
  (income-restricted bool)
  (accessibility-features bool))
(let ((new-id (+ (var-get property-counter) u1)))
  ;; Only property managers can register properties
  (asserts! (is-property-manager tx-sender) (err u403))

  ;; Property type and location must exist
  (asserts! (and
              (is-some (map-get? property-types { id: property-type-id }))
              (is-some (map-get? locations { id: location-id })))
            (err u404))

  ;; Basic validation
  (asserts! (and
              (> units u0)
              (> bedrooms u0)
              (> square-feet u0))
            (err u400))

  ;; Update counter
  (var-set property-counter new-id)

  ;; Store property data
  (map-set properties
    { id: new-id }
    {
      property-type-id: property-type-id,
      location-id: location-id,
      address: address,
      units: units,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      square-feet: square-feet,
      monthly-rent: monthly-rent,
      income-restricted: income-restricted,
      accessibility-features: accessibility-features,
      available-units: units,
      status: "available",
      owner: tx-sender
    }
  )

  (ok new-id)
)
)

;; Update property availability
(define-public (update-property-availability (property-id uint) (available-units uint) (status (string-ascii 16)))
(let ((property (map-get? properties { id: property-id })))
  ;; Only property managers can update availability
  (asserts! (is-property-manager tx-sender) (err u403))

  ;; Property must exist
  (asserts! (is-some property) (err u404))

  ;; Only property owner can update
  (asserts! (is-eq tx-sender (get owner (unwrap-panic property))) (err u403))

  ;; Available units cannot exceed total units
  (asserts! (<= available-units (get units (unwrap-panic property))) (err u400))

  ;; Status must be valid
  (asserts! (or
              (is-eq status "available")
              (is-eq status "limited")
              (is-eq status "unavailable")
              (is-eq status "maintenance"))
            (err u400))

  ;; Store updated property
  (map-set properties
    { id: property-id }
    (merge (unwrap-panic property) {
      available-units: available-units,
      status: status
    })
  )

  (ok true)
)
)

;; Get property details
(define-read-only (get-property (property-id uint))
(map-get? properties { id: property-id })
)

;; Get property type details
(define-read-only (get-property-type (property-type-id uint))
(map-get? property-types { id: property-type-id })
)

;; Get location details
(define-read-only (get-location (location-id uint))
(map-get? locations { id: location-id })
)

;; Check if property is available
(define-read-only (is-property-available (property-id uint))
(let ((property (map-get? properties { id: property-id })))
  (and
    (is-some property)
    (> (get available-units (unwrap-panic property)) u0)
    (is-eq (get status (unwrap-panic property)) "available")
  )
)
)

;; Search properties by criteria
(define-read-only (search-properties-by-bedrooms (bedrooms uint))
;; This is a simplified implementation
;; In a real contract, you would need to iterate through properties
(filter-properties-by-bedrooms bedrooms)
)

;; Helper function to filter properties by bedrooms
;; In a real implementation, this would search through all properties
(define-read-only (filter-properties-by-bedrooms (bedrooms uint))
;; Placeholder implementation
(list)
)
