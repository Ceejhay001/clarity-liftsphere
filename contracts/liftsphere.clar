;; LiftSphere - Weightlifting Companion Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Data Variables
(define-data-var achievement-counter uint u0)

;; Data Maps
(define-map workouts
    { workout-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        exercises: (list 10 (string-ascii 64)),
        created-by: principal
    }
)

(define-map workout-history
    { user: principal, date: uint }
    {
        workout-id: uint,
        sets: (list 10 uint),
        reps: (list 10 uint),
        weights: (list 10 uint)
    }
)

(define-map achievements 
    { achievement-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        requirement: uint,
        achievement-type: (string-ascii 32)
    }
)

(define-map user-achievements
    { user: principal, achievement-id: uint }
    { earned: bool, date-earned: uint }
)

;; Public Functions
(define-public (create-workout (name (string-ascii 64)) 
                             (description (string-ascii 256))
                             (exercises (list 10 (string-ascii 64))))
    (let ((workout-id (var-get achievement-counter)))
        (map-set workouts
            { workout-id: workout-id }
            {
                name: name,
                description: description,
                exercises: exercises,
                created-by: tx-sender
            }
        )
        (ok workout-id)
    )
)

(define-public (log-workout (workout-id uint)
                          (sets (list 10 uint))
                          (reps (list 10 uint))
                          (weights (list 10 uint)))
    (let ((current-time (unwrap! (get-block-info? time) (err u500))))
        (map-set workout-history
            { user: tx-sender, date: current-time }
            {
                workout-id: workout-id,
                sets: sets,
                reps: reps,
                weights: weights
            }
        )
        (ok true)
    )
)

(define-public (create-achievement (name (string-ascii 64))
                                 (description (string-ascii 256))
                                 (requirement uint)
                                 (achievement-type (string-ascii 32)))
    (if (is-eq tx-sender contract-owner)
        (let ((achievement-id (+ (var-get achievement-counter) u1)))
            (map-set achievements
                { achievement-id: achievement-id }
                {
                    name: name,
                    description: description,
                    requirement: requirement,
                    achievement-type: achievement-type
                }
            )
            (var-set achievement-counter achievement-id)
            (ok achievement-id)
        )
        err-owner-only
    )
)

(define-public (award-achievement (user principal) (achievement-id uint))
    (if (is-eq tx-sender contract-owner)
        (let ((current-time (unwrap! (get-block-info? time) (err u500))))
            (map-set user-achievements
                { user: user, achievement-id: achievement-id }
                { earned: true, date-earned: current-time }
            )
            (ok true)
        )
        err-owner-only
    )
)

;; Read-only functions
(define-read-only (get-workout (workout-id uint))
    (ok (map-get? workouts { workout-id: workout-id }))
)

(define-read-only (get-user-workout-history (user principal))
    (ok (map-get? workout-history { user: user, date: (unwrap! (get-block-info? time) (err u500)) }))
)

(define-read-only (get-achievement (achievement-id uint))
    (ok (map-get? achievements { achievement-id: achievement-id }))
)

(define-read-only (check-achievement (user principal) (achievement-id uint))
    (ok (map-get? user-achievements { user: user, achievement-id: achievement-id }))
)