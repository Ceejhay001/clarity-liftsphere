;; LiftSphere - Weightlifting Companion Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))

;; Data Variables
(define-data-var workout-counter uint u0)

;; Events
(define-data-var last-event-id uint u0)
(define-map events 
    { event-id: uint }
    { event-type: (string-ascii 32), user: principal, timestamp: uint }
)

;; [Previous map definitions remain the same...]

;; Private Functions
(define-private (calculate-total-weight (sets (list 10 uint)) (reps (list 10 uint)) (weights (list 10 uint)))
    (fold + (map * (map * sets reps) weights) u0)
)

(define-private (validate-workout-input (sets (list 10 uint)) (reps (list 10 uint)) (weights (list 10 uint)))
    (and
        (is-eq (len sets) (len reps))
        (is-eq (len sets) (len weights))
        (> (len sets) u0)
        (fold and (map > weights (list u0 u0 u0 u0 u0 u0 u0 u0 u0 u0)) true)
    )
)

(define-private (log-event (event-type (string-ascii 32)))
    (let ((event-id (var-get last-event-id))
          (timestamp (unwrap! (get-block-info? time) false)))
        (if timestamp
            (begin
                (map-set events
                    { event-id: event-id }
                    { 
                        event-type: event-type,
                        user: tx-sender,
                        timestamp: timestamp
                    }
                )
                (var-set last-event-id (+ event-id u1))
                true
            )
            false
        )
    )
)

;; Public Functions
(define-public (create-workout (name (string-ascii 64)) 
                             (description (string-ascii 256))
                             (exercises (list 10 (string-ascii 64))))
    (let ((workout-id (var-get workout-counter)))
        (asserts! (> (len exercises) u0) err-invalid-input)
        (map-set workouts
            { workout-id: workout-id }
            {
                name: name,
                description: description,
                exercises: exercises,
                created-by: tx-sender
            }
        )
        (var-set workout-counter (+ workout-id u1))
        (ok workout-id)
    )
)

(define-public (log-workout (workout-id uint)
                          (sets (list 10 uint))
                          (reps (list 10 uint))
                          (weights (list 10 uint)))
    (let (
        (current-time (unwrap! (get-block-info? time) (err u500)))
        (total-weight (calculate-total-weight sets reps weights))
        (workout (unwrap! (map-get? workouts { workout-id: workout-id }) err-not-found))
      )
        ;; Input validation
        (asserts! (validate-workout-input sets reps weights) err-invalid-input)
        
        ;; Update workout history
        (map-set workout-history
            { user: tx-sender, date: current-time }
            {
                workout-id: workout-id,
                sets: sets,
                reps: reps,
                weights: weights,
                total-weight: total-weight
            }
        )
        
        ;; Update user stats and log event
        (let ((stats (default-to { total-workouts: u0, total-weight-lifted: u0, last-workout: u0 }
                (map-get? user-stats { user: tx-sender }))))
            (map-set user-stats
                { user: tx-sender }
                {
                    total-workouts: (+ (get total-workouts stats) u1),
                    total-weight-lifted: (+ (get total-weight-lifted stats) total-weight),
                    last-workout: current-time
                }
            )
            (log-event "workout-logged")
        )
        
        (ok true)
    )
)

[... rest of the contract remains the same ...]
