;; LiftSphere - Weightlifting Companion Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))

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
        weights: (list 10 uint),
        total-weight: uint
    }
)

(define-map user-stats
    { user: principal }
    {
        total-workouts: uint,
        total-weight-lifted: uint,
        last-workout: uint
    }
)

(define-map personal-records
    { user: principal, exercise: (string-ascii 64) }
    {
        weight: uint,
        date: uint
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
    { earned: bool, date-earned: uint, progress: uint }
)

;; Private Functions
(define-private (calculate-total-weight (sets (list 10 uint)) (reps (list 10 uint)) (weights (list 10 uint)))
    (fold + (map * (map * sets reps) weights) u0)
)

(define-private (update-personal-records (user principal) (exercise (string-ascii 64)) (weight uint) (current-time uint))
    (let ((current-pr (default-to { weight: u0, date: u0 } 
            (map-get? personal-records { user: user, exercise: exercise }))))
        (if (> weight (get weight current-pr))
            (map-set personal-records 
                { user: user, exercise: exercise }
                { weight: weight, date: current-time })
            false)
    )
)

;; Public Functions
(define-public (create-workout (name (string-ascii 64)) 
                             (description (string-ascii 256))
                             (exercises (list 10 (string-ascii 64))))
    (let ((workout-id (var-get achievement-counter)))
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
        
        ;; Update user stats
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
        )
        
        ;; Update PRs for each exercise
        (map update-personal-records 
            (make-list (len (get exercises workout)) tx-sender)
            (get exercises workout)
            weights
            (make-list (len weights) current-time)
        )
        
        (ok true)
    )
)

[... rest of the contract remains the same ...]
