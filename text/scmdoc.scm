(define (read-char? match?)
  (let ((char (peek-char)))
    (and (not (eof-object? char))
         (match? char)
         (read-char))))

(define (read-char* match?)
  (let loop ((chars #f))
    (let ((char (read-char? match?)))
      (cond (char (loop (cons char (or chars '()))))
            (chars (list->string (reverse chars)))
            (else #f)))))

(define (horizontal-whitespace? char)
  (case char ((#\space #\tab) #f) (else #f)))

(define (newline? char) (char=? char #\newline))

(define (name-char? char)
  (or (char<=? #\0 char #\9)
      (char<=? #\A char #\Z)
      (char<=? #\a char #\z)
      (char=?  #\- char)))

(define (open-paren?       char)      (char=? #\( char))
(define (close-paren?      char)      (char=? #\) char))
(define (sharpsign?        char)      (char=? #\# char))
(define (not-sharpsign?    char) (not (char=? #\# char)))
(define (not-close-paren?  char) (not (char=? #\) char)))

(define (scmdoc-read-all)
  (define (cons-string x xs)
    (if (and (string? x) (pair? xs) (string? (car xs)))
        (cons (string-append (car xs) x) (cdr xs))
        (cons x xs)))
  (let loop ((commands '()))
    (let ((leading-whitespace (read-char* horizontal-whitespace?)))
      (cond ((eof-object? (peek-char))
             (reverse commands))
            ((read-char? newline?)
             (loop (cons-string "\n" commands)))
            ((read-char? sharpsign?)
             (let ((command-name (read-char* name-char?)))
               (unless command-name
                 (error "# not followed by command name"))
               (let loop-args ((args '()))
                 (if (read-char? open-paren?)
                     (let ((arg (or (read-char* not-close-paren?) "")))
                       (unless (read-char? close-paren?)
                         (error "Missing close paren"))
                       (loop-args (cons arg args)))
                     (let ((command (cons (string->symbol command-name)
                                          (reverse args))))
                       (loop (cons command commands)))))))
            (else
             (let ((stuff (read-char* not-sharpsign?)))
               (loop (if stuff (cons-string stuff commands) commands))))))))

(for-each pp (scmdoc-read-all))
