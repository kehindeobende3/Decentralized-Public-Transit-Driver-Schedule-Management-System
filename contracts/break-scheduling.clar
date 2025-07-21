;; Break Scheduling Contract
;; Ensures drivers receive required rest periods

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-BREAK-NOT-FOUND (err u401))
(define-constant ERR-INVALID-BREAK-TIME (err u402))
(define-constant ERR-BREAK-CONFLICT (err u403))
(define-constant ERR-SHIFT-NOT-FOUND (err u404))
(define-constant MINIMUM-BREAK-DURATION u1800) ;; 30 minutes in seconds
(define-constant MAXIMUM-WORK_BEFORE_BREAK u14400) ;; 4 hours in seconds
(define-constant LUNCH-BREAK-DURATION u3600) ;; 1 hour in seconds

;; Data Variables
(define-data-var next-break-id uint u1)
(define-data-var contract-admin principal CONTRACT-OWNER)

;; Data Maps
(define-map scheduled-breaks
  { break-id: uint }
  {
    shift-id: uint,
    driver-id: (string-ascii 50),
    break-type: (string-ascii 20), ;; "short", "lunch", "rest"
    start-time: uint,
    end-time: uint,
    duration: uint,
    status: (string-ascii 20), ;; "scheduled", "active", "completed", "missed"
    location: (string-ascii 100)
  }
)

(define-map shift-break-requirements
  { shift-id: uint }
  {
    total-duration: uint,
    required-breaks: uint,
    scheduled-breaks: (list 10 uint),
    compliance-status: (string-ascii 20)
  }
)

(define-map driver-break-history
  { driver-id: (string-ascii 50), date: uint }
  {
    total-break-time: uint,
    breaks-taken: uint,
    missed-breaks: uint,
    compliance-score: uint
  }
)

(define-map break-locations
  { location-id: (string-ascii 50) }
  {
    name: (string-ascii 100),
    capacity: uint,
    current-occupancy: uint,
    facilities: (string-ascii 200)
  }
)

;; Private Functions
(define-private (is-authorized (caller principal))
  (or (is-eq caller (var-get contract-admin))
      (is-eq caller CONTRACT-OWNER))
)

(define-private (is-valid-break-duration (duration uint) (break-type (string-ascii 20)))
  (if (is-eq break-type "lunch")
    (>= duration LUNCH-BREAK-DURATION)
    (>= duration MINIMUM-BREAK-DURATION)
  )
)

(define-private (calculate-required-breaks (shift-duration uint))
  (if (> shift-duration u28800) ;; 8+ hours
    u3 ;; 2 short breaks + 1 lunch
    (if (> shift-duration u21600) ;; 6+ hours
      u2 ;; 1 short break + 1 lunch
      u1 ;; 1 short break
    )
  )
)

(define-private (get-date-from-timestamp (timestamp uint))
  (/ timestamp u86400) ;; Convert to days since epoch
)

;; Public Functions

;; Schedule a break for a driver
(define-public (schedule-break (shift-id uint) (driver-id (string-ascii 50)) (break-type (string-ascii 20)) (start-time uint) (end-time uint) (location (string-ascii 100)))
  (let ((break-id (var-get next-break-id))
        (duration (- end-time start-time)))
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (> end-time start-time) ERR-INVALID-BREAK-TIME)
      (asserts! (is-valid-break-duration duration break-type) ERR-INVALID-BREAK-TIME)

      (map-set scheduled-breaks
        { break-id: break-id }
        {
          shift-id: shift-id,
          driver-id: driver-id,
          break-type: break-type,
          start-time: start-time,
          end-time: end-time,
          duration: duration,
          status: "scheduled",
          location: location
        }
      )

      ;; Update shift break requirements
      (let ((current-requirements (default-to
              { total-duration: u0, required-breaks: u0, scheduled-breaks: (list), compliance-status: "pending" }
              (map-get? shift-break-requirements { shift-id: shift-id }))))
        (map-set shift-break-requirements
          { shift-id: shift-id }
          (merge current-requirements {
            scheduled-breaks: (unwrap! (as-max-len? (append (get scheduled-breaks current-requirements) break-id) u10) ERR-BREAK-CONFLICT)
          })
        )
      )

      (var-set next-break-id (+ break-id u1))
      (ok break-id)
    )
  )
)

;; Start a break
(define-public (start-break (break-id uint))
  (let ((break-data (unwrap! (map-get? scheduled-breaks { break-id: break-id }) ERR-BREAK-NOT-FOUND)))
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status break-data) "scheduled") ERR-BREAK-CONFLICT)

      (ok (map-set scheduled-breaks
        { break-id: break-id }
        (merge break-data { status: "active" })
      ))
    )
  )
)

;; Complete a break
(define-public (complete-break (break-id uint))
  (let ((break-data (unwrap! (map-get? scheduled-breaks { break-id: break-id }) ERR-BREAK-NOT-FOUND)))
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status break-data) "active") ERR-BREAK-CONFLICT)

      ;; Update break status
      (map-set scheduled-breaks
        { break-id: break-id }
        (merge break-data { status: "completed" })
      )

      ;; Update driver break history
      (let ((driver-id (get driver-id break-data))
            (date (get-date-from-timestamp (get start-time break-data)))
            (duration (get duration break-data)))

        (let ((current-history (default-to
                { total-break-time: u0, breaks-taken: u0, missed-breaks: u0, compliance-score: u100 }
                (map-get? driver-break-history { driver-id: driver-id, date: date }))))
          (map-set driver-break-history
            { driver-id: driver-id, date: date }
            {
              total-break-time: (+ (get total-break-time current-history) duration),
              breaks-taken: (+ (get breaks-taken current-history) u1),
              missed-breaks: (get missed-breaks current-history),
              compliance-score: u100 ;; Full compliance for completed break
            }
          )
        )
      )

      (ok true)
    )
  )
)

;; Mark break as missed
(define-public (mark-break-missed (break-id uint))
  (let ((break-data (unwrap! (map-get? scheduled-breaks { break-id: break-id }) ERR-BREAK-NOT-FOUND)))
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)

      ;; Update break status
      (map-set scheduled-breaks
        { break-id: break-id }
        (merge break-data { status: "missed" })
      )

      ;; Update driver break history with missed break
      (let ((driver-id (get driver-id break-data))
            (date (get-date-from-timestamp (get start-time break-data))))

        (let ((current-history (default-to
                { total-break-time: u0, breaks-taken: u0, missed-breaks: u0, compliance-score: u100 }
                (map-get? driver-break-history { driver-id: driver-id, date: date }))))
          (map-set driver-break-history
            { driver-id: driver-id, date: date }
            {
              total-break-time: (get total-break-time current-history),
              breaks-taken: (get breaks-taken current-history),
              missed-breaks: (+ (get missed-breaks current-history) u1),
              compliance-score: (if (> (get missed-breaks current-history) u0) u50 u75) ;; Reduced compliance
            }
          )
        )
      )

      (ok true)
    )
  )
)

;; Auto-schedule breaks for a shift
(define-public (auto-schedule-shift-breaks (shift-id uint) (driver-id (string-ascii 50)) (shift-start uint) (shift-end uint))
  (let ((shift-duration (- shift-end shift-start))
        (required-breaks (calculate-required-breaks shift-duration)))
    (begin
      (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)

      ;; Set shift break requirements
      (map-set shift-break-requirements
        { shift-id: shift-id }
        {
          total-duration: shift-duration,
          required-breaks: required-breaks,
          scheduled-breaks: (list),
          compliance-status: "auto-scheduled"
        }
      )

      ;; Schedule lunch break at midpoint for long shifts
      (if (> shift-duration u21600) ;; 6+ hours need lunch
        (let ((lunch-start (+ shift-start (/ shift-duration u2)))
              (lunch-end (+ lunch-start LUNCH-BREAK-DURATION)))
          (unwrap! (schedule-break shift-id driver-id "lunch" lunch-start lunch-end "Main Terminal") ERR-BREAK-CONFLICT)
        )
        u0
      )

      (ok required-breaks)
    )
  )
)

;; Register break location
(define-public (register-break-location (location-id (string-ascii 50)) (name (string-ascii 100)) (capacity uint) (facilities (string-ascii 200)))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)

    (ok (map-set break-locations
      { location-id: location-id }
      {
        name: name,
        capacity: capacity,
        current-occupancy: u0,
        facilities: facilities
      }
    ))
  )
)

;; Read-only functions

;; Get break details
(define-read-only (get-break (break-id uint))
  (map-get? scheduled-breaks { break-id: break-id })
)

;; Get shift break requirements
(define-read-only (get-shift-break-requirements (shift-id uint))
  (map-get? shift-break-requirements { shift-id: shift-id })
)

;; Get driver break history
(define-read-only (get-driver-break-history (driver-id (string-ascii 50)) (date uint))
  (map-get? driver-break-history { driver-id: driver-id, date: date })
)

;; Get break location info
(define-read-only (get-break-location (location-id (string-ascii 50)))
  (map-get? break-locations { location-id: location-id })
)

;; Check break compliance for shift
(define-read-only (check-shift-compliance (shift-id uint))
  (match (map-get? shift-break-requirements { shift-id: shift-id })
    requirements (get compliance-status requirements)
    "not-scheduled"
  )
)

;; Calculate break compliance score
(define-read-only (calculate-compliance-score (driver-id (string-ascii 50)) (date uint))
  (match (map-get? driver-break-history { driver-id: driver-id, date: date })
    history (get compliance-score history)
    u100 ;; Default full compliance if no history
  )
)

;; Get total scheduled breaks
(define-read-only (get-total-breaks)
  (- (var-get next-break-id) u1)
)
