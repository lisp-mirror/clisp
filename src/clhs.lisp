;;; Sam Steingold 2000-2008, 2010-2011, 2017-2018
;;; Bruno Haible 2017, 2024
;;; This file is a part of CLISP (http://clisp.org), and, as such,
;;; is distributed under the GNU GPL v2+ (http://www.gnu.org/copyleft/gpl.html)

(in-package "EXT")

(export '(clhs clhs-root browse-url open-http with-http-input http-proxy
          starts-with-p))

(in-package "SYSTEM")

;;; ============== Presenting data from the Internet to the user ==============

(defvar *browsers*
  '(;; Desktop-independent GUI browsers.
    (:netscape        "netscape" "~a")
    (:netscape-window "netscape" "-remote" "openURL(~a,new-window)")
    (:netscape-tab    "netscape" "-remote" "openURL(~a,new-tab)")
    (:mozilla        "mozilla" "~a")
    (:mozilla-window "mozilla" "-remote" "openURL(~a,new-window)")
    (:mozilla-tab    "mozilla" "-remote" "openURL(~a,new-tab)")
    (:firefox        "firefox" "~a")
    (:firefox-window "firefox" "-new-window" "~a")
    (:firefox-tab    "firefox" "-new-tab" "~a")
    ;; GUI browsers for specific desktops.
    ; KDE
    (:konqueror "kfmclient" "openURL" "~a")
    (:falkon        "falkon" "~a")
    (:falkon-window "falkon" "--new-window" "~a")
    (:falkon-tab    "falkon" "--new-tab" "~a")
    ; Haiku
    #+haiku (:webpositive "/boot/system/apps/WebPositive" "~a")
    ;; Text browsers.
    (:lynx "lynx" "~a")
    #+unix (:lynx-xterm "xterm" "-e" "lynx" "~a")
    (:links "links" "~a")
    #+unix (:links-xterm "xterm" "-e" "links" "~a")
    (:w3m "w3m" "~a")
    #+unix (:w3m-xterm "xterm" "-e" "w3m" "~a")
    ;; Other.
    (:chromium "chromium" "~a")
    (:conkeror "conkeror" "~a")
    (:opera "opera" "~a")
    (:tor "tor" "~a")
    (:emacs "emacsclient" "--eval" "(browse-url ~s)")
    ;; Redirections to suitable browsers.
    ; GNOME's wrapper.
    (:gnome "gnome-www-browser" "~a")
    ; Debian's wrapper around 'x-www-browser' and 'www-browser'.
    #+unix (:sensible-browser "sensible-browser" "~a")
    #+cygwin (:default "cygstart" "~a")
    #+macos (:default "open" "~a")
   )
  "Alist of browsers and commands that invoke them.
`~a' will be replaced with the URL to view.")
(defvar *browser* nil
  "The default browser - a key in `*browsers*' or a list of strings.")

(defun browse-url (url &key (browser *browser*) (out *standard-output*))
  "Run the browser (a keyword in *BROWSERS* or a list) on the URL."
  #+WIN32
  (when (eq browser :default) ; feed url to ShellExecute
    (when out
      (format out "~&;; starting the default system browser with url ~s..." url)
      (force-output (if (eq out t) *standard-output* out)))
    (ext::shell-execute "open" url nil nil) ;to start default browser
    (when out (format out "done~%"))
    (return-from browse-url))
  (let* ((command
          (etypecase browser
            (list browser)
            (symbol (or (cdr (assoc browser *browsers* :test #'eq))
                        (error "unknown browser: `~s' (must be a key in `~s')"
                               browser '*browsers*)))))
         (args (mapcar (lambda (arg) (format nil arg url)) (cdr command))))
    (cond (command
           (when out
             (format out "~&;; running [~s~{ ~s~}]..." (car command) args)
             (force-output (if (eq out t) *standard-output* out)))
           (#+WIN32 ext::launch #-WIN32 run-program (car command) :arguments args :wait nil)
           (when out
             (format out "done~%")))
          (t (format t "~s: no browser specified; please point your browser at
 --> <URL:~a>~%" 'browse-url url)))))

;;; ===================== Reading data from the Internet =====================

(defun starts-with-p (string prefix)
  "Check whether the string starts with the supplied prefix (case-insensitive)."
  (string-equal string prefix :end1 (min (length string) (length prefix))))
#+(or)                          ; not worth it
(define-compiler-macro starts-with-p (string prefix &whole form)
  "Inline and pre-compute prefix length."
  (print (list string prefix form))
  (if (stringp prefix)
      `(string-equal ,string ,prefix :end1 (min (length ,string) ,(length prefix)))
      form))

(defvar *http-log-stream* (make-synonym-stream '*terminal-io*))
;;; keep in sync with clocc/cllib/url.lisp
(defvar *http-proxy* nil
  "A list of 3 elements (user:password host port), parsed from $http_proxy
\[http://]proxy-user:proxy-password@proxy-host:proxy-port[/]
by HTTP-PROXY.")
(defconstant *http-port* 80)
(defun http-proxy (&optional (proxy-string (getenv "http_proxy") proxy-p))
  "When the argument is supplied or *HTTP-PROXY* is NIL, parse the argument,
set *HTTP-PROXY*, and return it; otherwise just return *HTTP-PROXY*."
  (when (or proxy-p (and (null *http-proxy*) proxy-string))
    (check-type proxy-string string)
    (let* ((start (if (starts-with-p proxy-string #1="http://")
                      #.(length #1#) 0))
           (at (position #\@ proxy-string :start start))
           (colon (position #\: proxy-string :start (or at start)))
           (slash (position #\/ proxy-string :start (or colon at start))))
      (setq *http-proxy*
            (list (and at (subseq proxy-string start at))
                  (subseq proxy-string (if at (1+ at) start) (or colon slash))
                  (if colon
                      (parse-integer proxy-string :start (1+ colon) :end slash)
                      *http-port*)))
      (format *http-log-stream* "~&;; ~S=~S~%" '*http-proxy* *http-proxy*)))
  *http-proxy*)

(defmacro with-http-input ((var url) &body body)
  (if (symbolp var)
      `(with-open-stream (,var (open-http ,url)) ,@body)
      (multiple-value-bind (body-rest declarations) (SYSTEM::PARSE-BODY body)
        `(multiple-value-bind ,var (open-http ,url)
           (DECLARE (READ-ONLY ,@var) ,@declarations)
           (UNWIND-PROTECT
                (MULTIPLE-VALUE-PROG1 (PROGN ,@body-rest)
                  (when ,(first var) (CLOSE ,(first var))))
             (when ,(first var) (CLOSE ,(first var) :ABORT T)))))))
(defun open-http (url &key (if-does-not-exist :error)
                  ((:log *http-log-stream*) *http-log-stream*))
  (unless (starts-with-p url #1="http://")
    (error "~S: ~S is not an HTTP URL" 'open-http url))
  (format *http-log-stream* "~&;; connecting to ~S..." url)
  (force-output *http-log-stream*)
  (http-proxy)
  (let* ((host-port-end (position #\/ url :start #2=#.(length #1#)))
         (port-start (position #\: url :start #2# :end host-port-end))
         (url-host (subseq url #2# (or port-start host-port-end)))
         (host (if *http-proxy* (second *http-proxy*) url-host))
         (url-port (if port-start
                       (parse-integer url :start (1+ port-start)
                                      :end host-port-end)
                       *http-port*))
         (port (if *http-proxy* (third *http-proxy*) url-port))
         (path (if *http-proxy* url
                   (if host-port-end (subseq url host-port-end) "/")))
         (sock (handler-bind ((error (lambda (c)
                                       (unless (eq if-does-not-exist :error)
                                         (format *http-log-stream*
                                                 "cannot connect to ~S:~D: ~A~%"
                                                 host port c)
                                         (return-from open-http nil)))))
                 (socket:socket-connect port host :external-format :dos)))
         status code content-length)
    (format *http-log-stream* "connected...") (force-output *http-log-stream*)
    ;; http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.23
    ;; http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    (format sock "GET ~A HTTP/1.0~%User-agent: ~A ~A~%Host: ~A:~D~%" path
            (lisp-implementation-type) (lisp-implementation-version)
            url-host url-port)
    #+unicode ; base64 requires unicode for some weird infrastructure reasons
    (when (first *http-proxy*) ; auth: http://www.ietf.org/rfc/rfc1945.txt
      ;; http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.34
      (format sock "Proxy-Authorization: Basic ~A~%"
              (convert-string-from-bytes
               (convert-string-to-bytes (first *http-proxy*)
                                        *http-encoding*)
               charset:base64)))
    ;; http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    ;; http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.10
    (format sock "Accept: */*~%Connection: close~2%") ; finish request
    (write-string (setq status (read-line sock))) (force-output)
    (let* ((pos1 (position #\Space status))
           (pos2 (position #\Space status :start (1+ pos1))))
      (setq code (parse-integer status :start pos1 :end pos2)))
    (when (>= code 400)
      ;; dump headers
      (loop :for line = (read-line sock nil nil) :while line
        :do (format *http-log-stream* "~&;; ~S~%" line))
      (case if-does-not-exist
        (:error (error (TEXT "~S: error ~D: ~S") 'open-http code status))
        (t (close sock)
           (return-from open-http nil))))
    (if (>= code 300)        ; redirection
        (loop :for res = (read-line sock)
          :until (starts-with-p res #3="Location: ")
          :finally (let ((new-url (subseq res #.(length #3#))))
                     (format *http-log-stream* " --> ~S~%" new-url)
                     (when (starts-with-p new-url "https://")
                       (error (TEXT "~S(~S): HTTPS protocol is not supported yet")
                              'open-http new-url))
                     (unless (starts-with-p new-url #1#)
                       (setq new-url (string-concat #1# host new-url)))
                     (return-from open-http (open-http new-url))))
        ;; drop response headers
        (loop :for line = (read-line sock) :while (plusp (length line)) :do
          (when (starts-with-p line #5="Content-Length: ")
            (format *http-log-stream* "...~:D bytes"
                    (setq content-length (parse-integer line :start #.(length #5#)))))
          :finally (terpri)))
    (values sock content-length)))

(defun open-url (path &rest options)
  (cond ((starts-with-p path "http://")
         (apply #'open-http path options))
        ((starts-with-p path #1="file:/")
         ;; Tomas Zellerin writes in bug#344:
         ;; I think that proper RFC compliant URL of this kind is
         ;; file://<machine>/<path>, where machine may be the empty string
         ;; for localhost and path should be an absolute path (including
         ;; the leading slash on Unix), but browsers usually do not require
         ;; four slashes in row.
         (let ((path-beg (position #\/ path :test-not #'eql :start #.(length #1#))))
           ;; we first try stripping all leading slashes to catch things like
           ;; file:///c:/foo/bar and then resort to keeping one leading #\/
           (apply #'open (or #+(or win32 cygwin)
                             (probe-file (subseq path path-beg))
                             (subseq path (1- path-beg)))
                  options)))
        (t (open path))))

;;; ========== Common Lisp HyperSpec and CLISP implementation notes ==========

;;; the CLHS & IMPNOTES documentation:
;; * symbols (and packages for IMPNOTES) can have a doc string that points
;;   to the position of the documentation text in the CLHS or IMPNOTES.
;; * (documentation foo 'sys::clhs) and (documentation foo 'sys::impnotes)
;;   return a valid URL that can be printed or passed to the browser
;; * (setf (documentation foo 'sys::clhs) "bar") and
;;   (setf (documentation foo 'sys::impnotes) "bar")
;;   "bar" is the URL sans (clhs-root) and (impnotes-root)

;;; ============ Using the Common Lisp HyperSpec as documentation ============

;; (clhs-root) is defined in cfgunix.lisp or cfgwin32.lisp.
;; The CLHS is not free documentation: the legal notices state that it must
;; not be "made or distributed or displayed or transmitted for direct
;; commercial advantage". Therefore neither Linux distros nor CLISP source
;; or binary packages may include it. Instead, the only options to use it are:
;; * Reference it on the web. The most common (official) URLs are
;;   (1996) http://www.ai.mit.edu/projects/iiip/doc/CommonLISP/HyperSpec/FrontMatter/
;;          http://cliki.net/site/HyperSpec/FrontMatter/index.html
;;   (2001) http://yon.maclisp.org/clhs/HyperSpec/Front/
;;   (2005) http://www.lispworks.com/documentation/HyperSpec/Front/
;;          http://clhs.lisp.se/Front/index.htm
;; * Let the user download it as a complete package and install it in their
;;   file system.
;;   Download location:
;;   ftp://ftp.lispworks.com/pub/software_tools/reference/HyperSpec-7-0.tar.gz

(defun get-clhs-map (stream)
  "Download and install the CLHS map."
  (format *http-log-stream* "~&;; ~S(~S)..." 'get-clhs-map stream)
  (force-output *http-log-stream*)
  (loop :with good = 0 :for symbol-name = (read-line stream nil nil)
    :and destination = (read-line stream nil nil)
    :and total :upfrom 0
    :while (and symbol-name destination) :do
    (multiple-value-bind (symbol status) (find-symbol symbol-name "COMMON-LISP")
      (cond (status
             (incf good)
             (setf (documentation symbol 'sys::clhs)
                   (subseq destination #.(length "../"))))
            (t (warn (TEXT "~S is not found") symbol-name))))
    :finally (format *http-log-stream* "~:D/~:D symbol~:P~%" good total)))

(let ((clhs-map-source nil) (clhs-map-good nil))
  ;; if clhs-map-source is the same as (clhs-root), do nothing and
  ;; return (clhs-root); otherwise set clhs-map-source to (clhs-root)
  ;; and try to get the clhs map from (clhs-root)
  ;; nil return value means no map exists
(defun ensure-clhs-map ()
  "make sure that the CLHS map is present"
  (let ((clhs-root (clhs-root)))
    (when (and clhs-root (string/= clhs-map-source clhs-root))
      (setq clhs-map-source clhs-root)
      ;; The symbol map exists under different names:
      ;;   (1996) http://www.ai.mit.edu/projects/iiip/doc/CommonLISP/HyperSpec/Data/Symbol-Table.text
      ;;          http://cliki.net/site/HyperSpec/Data/Symbol-Table.text
      ;;   (2001) http://yon.maclisp.org/clhs/HyperSpec/Data/Map_Sym.txt
      ;;   (2005) http://www.lispworks.com/documentation/HyperSpec/Data/Map_Sym.txt
      ;;          http://clhs.lisp.se/Data/Map_Sym.txt
      ;; We support both names.
      ;; If you are scared of logging on the screen,
      ;; bind or set *HTTP-LOG-STREAM*
      (flet ((get-map-1996 ()
               (open-url (string-concat clhs-root "Data/Symbol-Table.text") :if-does-not-exist nil))
             (get-map-2001 ()
               (open-url (string-concat clhs-root "Data/Map_Sym.txt") :if-does-not-exist nil)))
        (with-open-stream (s (cond ((or (search "ai.mit.edu/" clhs-root)
                                        (search "cliki.net/" clhs-root))
                                    (get-map-1996))
                                   ((or (search "maclisp.org/" clhs-root)
                                        (search "lispworks.com/" clhs-root)
                                        (search "lisp.se/" clhs-root))
                                    (get-map-2001))
                                   (t (or (get-map-1996) (get-map-2001)))))
          (unless s
            (warn (TEXT "~S returns invalid value ~S, fix it, ~S, ~S, or ~S")
                  'clhs-root clhs-root '(getenv "CLHSROOT")
                  '*clhs-root-default* '*http-proxy*)
            (return-from ensure-clhs-map))
          (get-clhs-map s)))
      (setq clhs-map-good t))
    (and clhs-map-good clhs-root))))

(defmethod documentation ((obj symbol) (type (eql 'sys::clhs)))
  (when (and (eq (symbol-package obj) #,(find-package "CL")) (ensure-clhs-map))
    (let ((doc (call-next-method)))
      (when doc (string-concat (clhs-root) doc)))))

(defun clhs (symbol &key (browser *browser*) (out *standard-output*))
  "Dump the CLHS doc for the symbol."
  (warn "function ~S is deprecated, set ~S and use ~S instead"
        'clhs '*browser* 'describe)
  (browse-url (or (documentation symbol 'sys::clhs)
                  (error "No HyperSpec doc for ~S" symbol))
              :browser browser :out out))

;;; ========== Using the CLISP implementation notes as documentation ==========

(defun get-string-map (stream &aux (table (make-hash-table :test 'equal)))
  (format *http-log-stream* "~&;; ~S(~S)..." 'get-string-map stream)
  (force-output *http-log-stream*)
  (loop :for total :upfrom 0 :and id = (read-line stream nil nil)
    :and destination = (read-line stream nil nil)
    :while (and id destination) :do
    (when (or (find-if #'whitespacep id) (find-if #'whitespacep destination)
              (zerop (length id)) (zerop (length destination)))
      (warn "~S: invalid map ~S --> ~S" 'get-string-map id destination)
      (return-from get-string-map nil))
    (let ((old (gethash id table)))
          (when old (warn "~S: remapping ~S: ~S --> ~S"
                          'get-string-map id old destination)))
    (setf (gethash id table) destination)
    :finally (format *http-log-stream* "~:D ID~:P~%" total))
  table)

(let ((impnotes-map-source nil) (impnotes-map-good nil) id-href
      (dest (lambda (id) (string-concat "#" id))))
  ;; if impnotes-map-source is the same as (impnotes-root), do nothing
  ;; and return (and impnotes-map-good (impnotes-root));
  ;; otherwise set impnotes-map-source to (impnotes-root) and try to get
  ;; the impnotes map from (impnotes-root)
  ;; nil return value means no map exists
(defun ensure-impnotes-map (&optional check-symbol-map)
  "make sure that the impnotes map is present"
  (let ((impnotes-root (impnotes-root)))
    (when (and impnotes-root (string/= impnotes-map-source impnotes-root))
      (setq impnotes-map-source impnotes-root)
      (case (char impnotes-root (1- (length impnotes-root)))
        ((#\/ #+win32 #\\) ; chunked impnotes ==> get id-href
         (setq id-href (string-concat impnotes-root "id-href.map"))
         (with-open-stream (s (open-url id-href :if-does-not-exist nil))
           (unless s
             #2=(warn (TEXT "~S returns invalid value ~S, fix it, ~S, ~S, or ~S")
                      'impnotes-root impnotes-root '(getenv "IMPNOTES")
                      '*impnotes-root-default* '*http-proxy*)
             (return-from ensure-impnotes-map))
           (let ((table (get-string-map s)))
             (unless table   ; no table --> bail out
               #2# (return-from ensure-impnotes-map))
             (setq dest (lambda (id) (gethash id table)))))))
      (with-open-file (in (clisp-data-file "Symbol-Table.text"))
        (format *http-log-stream* "~&;; ~S(~S)..."
                'ensure-impnotes-map (truename in))
        (force-output *http-log-stream*)
        (loop :for count :upfrom 0
          :and symbol-printname = (read-line in nil nil)
          :and id = (read-line in nil nil)
          :while (and symbol-printname id) :do
          (let ((destination (funcall dest id)))
            (if destination
                (multiple-value-bind (symbol error)
                    (ignore-errors (read-from-string symbol-printname))
                  (if (integerp error)
                    (setf (documentation symbol 'sys::impnotes)
                          destination)
                    (and check-symbol-map
                         (not (gethash symbol-printname
                                       #S(HASH-TABLE EQUALP
                                          #-(or win32 cygwin) ("CUSTOM:*DEVICE-PREFIX*" . t)
                                          #-(or win32 cygwin) ("POSIX:FILE-PROPERTIES" . t)
                                          ("CUSTOM:*DEFAULT-TIME-ZONE*" . t)
                                          ("CLOS:MAKE-METHOD-LAMBDA" . t)
                                          ("SYS::DYNLOAD-MODULES" . t))))
                         ;; *default-time-zone* sys::dynload-modules ...
                         (warn (TEXT "~S: invalid symbol ~S with id ~S: ~A")
                               'ensure-impnotes-map symbol-printname
                               id error))))
                (warn (TEXT "~S: invalid id ~S for symbol ~S")
                      'ensure-impnotes-map id symbol-printname)))
          :finally (format *http-log-stream* "~:D ID~:P~%" count)))
      (setq impnotes-map-good t)) ; success
    (and impnotes-map-good impnotes-root)))

(defmethod documentation ((obj package) (type (eql 'sys::impnotes)))
  (let ((doc (sys::package-documentation obj)))
    (and (consp doc) (ensure-impnotes-map)
         (let ((suffix (funcall dest (second doc))))
           (if suffix (string-concat (impnotes-root) suffix)
               (cerror (TEXT "Ignore") (TEXT "~S(~S): ~S does not know about ~S; the Implementation Notes must be regenerated")
                       'documentation obj id-href (second doc))))))))

(defmethod documentation ((obj symbol) (type (eql 'sys::impnotes)))
  (let ((pack (symbol-package obj)))
    ;; do not search impnotes for user symbols
    (when (and pack
               (or (eq pack #,(find-package "CUSTOM"))
                   ;; CUSTOM is not in *SYSTEM-PACKAGE-LIST*
                   ;; because it must not be locked
                   (member (package-name pack) *system-package-list*
                           :test #'equal))
               (ensure-impnotes-map))
      (let ((doc (call-next-method)))
        (if doc
          (string-concat (impnotes-root) doc)
          (documentation pack 'sys::impnotes))))))

(defmethod (setf documentation) (new-value (obj package)
                                 (type (eql 'sys::impnotes)))
  (let ((doc (sys::package-documentation obj)))
    (if (consp doc)
        (setf (second doc) new-value)
        (setf (sys::package-documentation obj)
              (list "see the implementation notes" new-value)))))

;; what is the right place for these?
(setf (documentation (find-package "GRAY") 'sys::impnotes) "gray")
(setf (documentation (find-package "CL-USER") 'sys::impnotes) "clupack")
(setf (documentation (find-package "CS-CL-USER") 'sys::impnotes) "cs-clu")
(setf (documentation (find-package "CS-CL") 'sys::impnotes) "package-case")
#+screen (setf (documentation (find-package "SCREEN") 'sys::impnotes) "screen")
#+sockets (setf (documentation (find-package "SOCKET") 'sys::impnotes) "socket")
#+generic-streams
(setf (documentation (find-package "GSTREAM") 'sys::impnotes) "gstream")
(setf (documentation (find-package "I18N") 'sys::impnotes) "i18n")
#+FFI
(setf (documentation (find-package "FFI") 'sys::impnotes) "dffi")
(setf (documentation (find-package "CUSTOM") 'sys::impnotes) "customize")
#+UNICODE
(setf (documentation (find-package "CHARSET") 'sys::impnotes) "charset")
(setf (documentation (find-package "CLOS") 'sys::impnotes) "classes")
(setf (documentation (find-package "EXT") 'sys::impnotes) "ext-pac")
#+MT (setf (documentation (find-package "THREADS") 'sys::impnotes) "mt")

;;; ===========================================================================
